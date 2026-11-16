# Kamus Data Data Warehouse — Penjualan Reseller

Dokumen ini berisi definisi struktur seluruh tabel pada Data Warehouse proses bisnis **Penjualan Reseller** berdasarkan rancangan **Star Schema v2**. Setiap tabel dilengkapi dengan tipe data, penjelasan fungsional, contoh nilai, serta catatan teknis untuk kebutuhan ETL dan analisis OLAP.

---

## 1. Tabel Fakta: `fact_penjualan_reseller`

Tabel fakta utama yang menyimpan metrik transaksi penjualan reseller pada tingkat granularitas **satu baris per item produk dalam satu pesanan (*line item*)**.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `fakta_penjualan_key` | `BIGINT` | Surrogate key unik untuk setiap baris detail transaksi penjualan reseller | `10001` | Primary Key (PK), *auto-increment*, unik per baris item pesanan. |
| `tanggal_pesan_key` | `INT` | Foreign key yang merujuk ke tanggal pesanan dibuat pada dimensi waktu | `20110531` | Not Null (NN), *role-playing dimension* yang merujuk ke `dim_tanggal.tanggal_key`. |
| `tanggal_kirim_key` | `INT` | Foreign key yang merujuk ke tanggal pesanan dikirim pada dimensi waktu | `20110607` | Not Null (NN), *role-playing dimension* dari `dim_tanggal.tanggal_key`. Bernilai `-1` jika barang belum dikirim. |
| `produk_key` | `INT` | Foreign key yang merujuk ke produk yang dibeli pada dimensi produk | `312` | Not Null (NN), merujuk ke versi atribut produk yang aktif saat transaksi terjadi (SCD Tipe 2). |
| `reseller_key` | `INT` | Foreign key yang merujuk ke toko atau mitra reseller pembeli | `45` | Not Null (NN), merujuk ke `dim_reseller.reseller_key`. |
| `sales_person_key` | `INT` | Foreign key yang merujuk ke tenaga penjual yang menangani pesanan | `12` | Not Null (NN), merujuk ke `dim_sales_person.sales_person_key`. |
| `wilayah_key` | `INT` | Foreign key yang merujuk ke wilayah geografis penjualan | `4` | Not Null (NN), merujuk ke `dim_wilayah.wilayah_key`. |
| `promosi_key` | `INT` | Foreign key yang merujuk ke skema promosi atau penawaran khusus yang berlaku | `1` | Not Null (NN), merujuk ke `dim_promosi.promosi_key` (nilai `1` menandakan tanpa diskon). |
| `metode_kirim_key` | `INT` | Foreign key yang merujuk ke layanan logistik pengiriman barang | `5` | Not Null (NN), merujuk ke `dim_metode_kirim.metode_kirim_key`. |
| `mata_uang_key` | `INT` | Foreign key yang merujuk ke mata uang dan kurs pada tanggal transaksi | `102` | Not Null (NN), merujuk ke `dim_mata_uang.mata_uang_key`. |
| `sales_order_id` | `INT` | Nomor identitas unik header pesanan dari sistem transaksional sumber | `43659` | *Degenerate dimension* untuk menelusuri kembali transaksi ke database OLTP. |
| `sales_order_number` | `VARCHAR` | Kode dokumen pesanan penjualan yang digunakan dalam administrasi bisnis | `SO43659` | *Degenerate dimension* untuk keperluan audit dan pelacakan nomor faktur. |
| `jumlah_unit` | `INT` | Kuantitas unit produk yang dipesan pada baris item transaksi | `3` | *Measure* aditif, diambil dari kolom `OrderQty` pada sistem sumber. |
| `harga_satuan` | `DECIMAL(12,4)` | Harga jual per satu unit produk setelah dipotong diskon satuan | `2024.9940` | *Measure* non-aditif, merepresentasikan harga transaksi aktual per unit. |
| `nilai_penjualan` | `DECIMAL(12,2)` | Total pendapatan bersih yang dihasilkan dari baris item pesanan | `6074.98` | *Measure* aditif (`jumlah_unit` × `harga_satuan`), berasal dari `LineTotal`. |
| `biaya_standar_produk` | `DECIMAL(12,2)` | Total harga pokok produksi standar untuk seluruh unit pada baris pesanan | `5694.27` | *Measure* aditif (`jumlah_unit` × `biaya_standar` produk) sebagai dasar perhitungan margin. |
| `harga_jual_standar` | `DECIMAL(12,2)` | Total nilai penjualan berdasarkan harga katalog resmi sebelum potongan | `10199.97` | *Measure* aditif (`jumlah_unit` × `harga_jual` katalog) untuk analisis selisih harga. |
| `laba_kotor_reseller` | `DECIMAL(12,2)` | Selisih antara harga katalog standar dengan nilai yang dibayarkan reseller | `4124.99` | *Measure* aditif (`harga_jual_standar` − `nilai_penjualan`), mengukur potensi margin bagi reseller. |
| `laba_kotor_perusahaan` | `DECIMAL(12,2)` | Keuntungan kotor bersih yang diperoleh perusahaan dari baris transaksi | `380.71` | *Measure* aditif (`nilai_penjualan` − `biaya_standar_produk`), mengukur profitabilitas aktual perusahaan. |

---

## 2. Tabel Dimensi: `dim_tanggal`

Tabel dimensi waktu (*conformed dimension*) yang menyimpan atribut kalender untuk mendukung analisis tren harian, mingguan, bulanan, kuartalan, hingga tahunan. Tabel ini tidak diambil dari tabel transaksi sumber, melainkan dibangkitkan secara terprogram menggunakan skrip generator dimensi tanggal.

* **Versi Skrip Generator:** `v1.0` (Skrip generator dimensi waktu berbasis standar ISO 8601 dengan rentang tanggal operasional ditambah 1 baris khusus untuk tanggal tidak diketahui).
* **Strategi SCD:** SCD Tipe 0 (*Retain Original*), karena atribut kalender bersifat mutlak dan tidak pernah berubah.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `tanggal_key` | `INT` | Surrogate key unik untuk setiap tanggal kalender | `20110531` | Primary Key (PK). Berformat `YYYYMMDD` (*smart key*) dan bukan angka urut (`1, 2, 3`) agar mudah dibaca, mempercepat filter rentang tanggal tanpa perlu *join* tabel, serta memudahkan partisi data. Baris khusus bernilai `-1` disediakan untuk tanggal yang belum diketahui. |
| `tanggal` | `DATE` | Nilai tanggal kalender lengkap berformat standar SQL | `2011-05-31` | Not Null (NN) dan unik. Pada baris `-1`, kolom ini diisi `1900-01-01` sebagai penanda tanggal tidak diketahui (*unknown date*) karena berada jauh di luar rentang transaksi bisnis sehingga mencegah nilai `NULL` pada *foreign key* tabel fakta. |
| `tahun` | `INT` | Tahun kalender empat digit | `2011` | Not Null (NN). Digunakan untuk agregasi tahunan yang presisi dibandingkan kolom nomor minggu. |
| `semester` | `INT` | Pembagian paruh tahun kalender (1 atau 2) | `1` | Not Null (NN). Bernilai `1` untuk periode Januari–Juni dan `2` untuk periode Juli–Desember. |
| `kuartal` | `INT` | Pembagian triwulan dalam satu tahun kalender (1 sampai 4) | `2` | Not Null (NN). Bernilai `1` (Q1) hingga `4` (Q4) untuk pelaporan performa kuartalan. |
| `bulan` | `INT` | Nomor urut bulan dalam satu tahun (1 sampai 12) | `5` | Not Null (NN). Digunakan untuk pengurutan kronologis bulan pada grafik atau laporan. |
| `nama_bulan` | `VARCHAR(15)` | Nama lengkap bulan kalender | `Mei` | Not Null (NN). Digunakan sebagai label tampilan pada laporan dan visualisasi dashboard. |
| `minggu_dalam_tahun` | `INT` | Nomor urut minggu dalam satu tahun menurut standar ISO 8601 (1 sampai 53) | `22` | Not Null (NN). Tanggal 1 Januari bisa masuk ke minggu 52 atau 53 tahun sebelumnya sesuai aturan ISO 8601; untuk analisis tahunan selalu gunakan kolom `tahun`. |
| `tanggal_dalam_bulan` | `INT` | Nomor urut hari dalam satu bulan kalender (1 sampai 31) | `31` | Not Null (NN). Berguna untuk menganalisis pola transaksi pada awal, tengah, atau akhir bulan. |
| `hari_dalam_minggu` | `INT` | Nomor urut hari dalam satu minggu (1 sampai 7) | `2` | Not Null (NN). Hari pertama minggu ditetapkan sebagai Senin (`1 = Senin` s.d. `7 = Minggu`) mengikuti standar ISO 8601 agar selaras dengan perhitungan minggu tahunan serta menempatkan akhir pekan di ujung siklus kerja. |
| `nama_hari` | `VARCHAR(15)` | Nama hari dalam satu minggu | `Selasa` | Not Null (NN). Digunakan untuk analisis distribusi volume penjualan per hari. |
| `is_akhir_pekan` | `BOOLEAN` | Penanda status apakah tanggal jatuh pada akhir pekan | `false` | Not Null (NN). Bernilai `true` untuk hari Sabtu dan Minggu (`hari_dalam_minggu` 6 dan 7), serta `false` untuk hari kerja. |

---

## 3. Tabel Dimensi: `dim_produk`

Tabel dimensi yang menyimpan katalog produk beserta hierarki kategori dan riwayat perubahan harga/biaya standar.

* **Strategi SCD:** SCD Tipe 2 (*Add New Row*), untuk menjaga keakuratan riwayat harga jual dan biaya standar produk pada saat transaksi terjadi.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `produk_key` | `INT` | Surrogate key unik untuk setiap versi baris data produk | `312` | Primary Key (PK), *auto-increment*. Bertambah jika terjadi perubahan atribut historis produk. |
| `produk_id` | `INT` | Natural key identitas produk dari tabel sumber `Production.Product` | `776` | Not Null (NN). Dapat muncul lebih dari satu baris apabila produk memiliki riwayat versi SCD Tipe 2. |
| `nama_produk` | `VARCHAR(50)` | Nama lengkap produk yang dipasarkan | `Mountain-100 Black, 42` | Nama deskriptif produk untuk keperluan tampilan laporan. |
| `nomor_produk` | `VARCHAR(25)` | Kode SKU atau nomor seri unik produk | `BK-M82B-42` | Kode identifikasi stok internal perusahaan. |
| `warna` | `VARCHAR(15)` | Warna fisik varian produk | `Black` | Diisi nilai default seperti `'N/A'` saat proses ETL jika bernilai `NULL` pada tabel sumber. |
| `subkategori` | `VARCHAR(50)` | Nama subkategori produk hasil penggabungan dari `ProductSubcategory` | `Mountain Bikes` | Hasil denormalisasi hierarki produk untuk mempercepat pengelompokan analisis. |
| `kategori` | `VARCHAR(50)` | Nama kategori utama produk hasil penggabungan dari `ProductCategory` | `Bikes` | Level tertinggi hierarki produk untuk ringkasan performa per lini bisnis. |
| `biaya_standar` | `DECIMAL(12,4)` | Biaya produksi standar per unit produk pada versi catatan tersebut | `1898.0944` | Atribut SCD Tipe 2; perubahan nilai biaya memicu pembuatan baris versi baru. |
| `harga_jual` | `DECIMAL(12,4)` | Harga jual katalog resmi per unit produk pada versi catatan tersebut | `3374.9900` | Atribut SCD Tipe 2; menjaga keakuratan perbandingan harga katalog historis. |
| `berlaku_mulai` | `DATE` | Tanggal mulai berlakunya versi atribut produk ini | `2011-05-31` | Metadata SCD Tipe 2 untuk menentukan batas awal validitas baris dimensi. |
| `berlaku_sampai` | `DATE` | Tanggal berakhirnya masa berlaku versi atribut produk ini | `9999-12-31` | Metadata SCD Tipe 2. Diisi `9999-12-31` atau `NULL` apabila baris masih berstatus aktif. |
| `is_current` | `BOOLEAN` | Penanda apakah baris ini merupakan versi data produk paling mutakhir | `true` | Not Null (NN). Bernilai `true` untuk versi aktif saat ini dan `false` untuk arsip riwayat lama. |

---

## 4. Tabel Dimensi: `dim_reseller`

Tabel dimensi yang menyimpan profil mitra toko reseller yang membeli produk dari perusahaan.

* **Strategi SCD:** SCD Tipe 1 (*Overwrite*), karena pembaruan profil toko maupun perbaikan ejaan nama langsung menimpa data lama.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `reseller_key` | `INT` | Surrogate key unik untuk entitas mitra toko reseller | `45` | Primary Key (PK), *auto-increment*. |
| `reseller_id` | `INT` | Natural key identitas toko dari tabel sumber `Sales.Store` | `292` | Not Null (NN), merujuk ke `BusinessEntityID` entitas toko reseller. |
| `nama_reseller` | `VARCHAR` | Nama toko atau perusahaan mitra reseller | `Next-Door Bike Store` | Nama resmi toko untuk pelaporan kinerja mitra. |
| `tipe_bisnis` | `VARCHAR` | Klasifikasi jenis usaha reseller | `Specialty Bike Shop` | Diekstrak dari kolom XML `Demographics` pada tabel `Sales.Store`. |
| `penjualan_tahunan` | `DECIMAL` | Estimasi nilai penjualan tahunan yang dimiliki oleh reseller | `800000.00` | Diekstrak dari XML `Demographics` untuk segmentasi skala bisnis mitra. |
| `jumlah_karyawan` | `INT` | Jumlah tenaga kerja yang dipekerjakan oleh toko reseller | `15` | Diekstrak dari XML `Demographics` sebagai indikator kapasitas operasional toko. |
| `tahun_buka` | `INT` | Tahun pertama kali toko reseller mulai beroperasi | `1996` | Diekstrak dari XML `Demographics` untuk analisis lama berdiri dan loyalitas mitra. |

---

## 5. Tabel Dimensi: `dim_sales_person`

Tabel dimensi yang menyimpan informasi tenaga penjual internal yang mengelola transaksi dengan pihak reseller.

* **Strategi SCD:** SCD Tipe 1 (*Overwrite*) untuk pembaruan profil dan target kuota aktif.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `sales_person_key` | `INT` | Surrogate key unik untuk tenaga penjual | `12` | Primary Key (PK), *auto-increment*. |
| `sales_person_id` | `INT` | Natural key identitas tenaga penjual dari `Sales.SalesPerson` | `279` | Not Null (NN), merujuk ke `BusinessEntityID` karyawan sales. |
| `nama_lengkap` | `VARCHAR` | Nama lengkap tenaga penjual | `Tsvi Michael Reiter` | Hasil penggabungan `FirstName`, `MiddleName`, dan `LastName` dari tabel `Person.Person`. |
| `komisi_persen` | `DECIMAL` | Persentase komisi penjualan yang diterima tenaga penjual | `0.0150` | Berasal dari kolom `CommissionPct` untuk analisis perhitungan insentif. |
| `kuota_penjualan` | `DECIMAL` | Target nominal penjualan yang dibebankan kepada tenaga penjual | `250000.00` | Berasal dari kolom `SalesQuota` untuk mengukur pencapaian KPI penjualan. |

---

## 6. Tabel Dimensi: `dim_wilayah`

Tabel dimensi geografis (*conformed dimension*) yang menyimpan hierarki area pemasaran dan negara.

* **Strategi SCD:** SCD Tipe 1 (*Overwrite*), untuk menyeragamkan penamaan wilayah administratif terbaru.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `wilayah_key` | `INT` | Surrogate key unik untuk wilayah geografis penjualan | `4` | Primary Key (PK), *auto-increment*. |
| `wilayah_id` | `INT` | Natural key identitas wilayah dari tabel `Sales.SalesTerritory` | `4` | Not Null (NN), merujuk ke `TerritoryID`. |
| `nama_wilayah` | `VARCHAR` | Nama region atau area pemasaran | `Southwest` | Nama wilayah operasional penjualan. |
| `kode_negara` | `VARCHAR` | Kode standar negara dua huruf (ISO) | `US` | Berasal dari `CountryRegionCode` untuk pengelompokan laporan tingkat negara. |
| `grup` | `VARCHAR` | Pengelompokan kawasan benua atau pasar global | `North America` | Level tertinggi hierarki geografis untuk analisis ringkasan regional. |

---

## 7. Tabel Dimensi: `dim_promosi`

Tabel dimensi (*conformed dimension*) yang menyimpan daftar program penawaran khusus dan potongan harga.

* **Strategi SCD:** SCD Tipe 0 (*Retain Original*), karena ketentuan dan persentase diskon program promosi historis tidak boleh diubah setelah periode berjalan.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `promosi_key` | `INT` | Surrogate key unik untuk program promosi atau diskon | `1` | Primary Key (PK), *auto-increment*. |
| `promosi_id` | `INT` | Natural key identitas promosi dari tabel `Sales.SpecialOffer` | `1` | Not Null (NN), merujuk ke `SpecialOfferID`. |
| `deskripsi` | `VARCHAR` | Keterangan lengkap mengenai nama atau ketentuan program promosi | `No Discount` | Menjelaskan jenis promo yang diterapkan pada transaksi. |
| `jenis` | `VARCHAR` | Tipe mekanisme pemberian promosi | `No Discount` | Mengelompokkan promo seperti `Volume Discount`, `Seasonal Discount`, atau `Discontinued Product`. |
| `kategori` | `VARCHAR` | Sasaran segmen penerima promosi | `No Discount` | Menunjukkan target promo, seperti `Reseller` atau `Customer`. |
| `persentase_diskon` | `DECIMAL` | Besaran persentase potongan harga yang diberikan | `0.00` | Berasal dari kolom `DiscountPct` dalam format desimal. |
| `mulai` | `DATE` | Tanggal dimulainya masa berlaku promosi | `2011-05-01` | Berasal dari `StartDate` untuk mengaudit kepatuhan periode promo. |
| `selesai` | `DATE` | Tanggal berakhirnya masa berlaku promosi | `2014-11-30` | Berasal dari `EndDate` sebagai batas akhir validitas penawaran. |

---

## 8. Tabel Dimensi: `dim_metode_kirim`

Tabel dimensi (*conformed dimension*) yang menyimpan jenis layanan kurir dan struktur tarif pengiriman barang.

* **Strategi SCD:** SCD Tipe 1 (*Overwrite*), untuk memperbarui nama layanan atau tarif dasar terbaru.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `metode_kirim_key` | `INT` | Surrogate key unik untuk metode pengiriman logistik | `5` | Primary Key (PK), *auto-increment*. |
| `metode_kirim_id` | `INT` | Natural key identitas layanan kirim dari `Purchasing.ShipMethod` | `5` | Not Null (NN), merujuk ke `ShipMethodID`. |
| `nama_metode` | `VARCHAR` | Nama layanan ekspedisi atau moda pengiriman | `CARGO TRANSPORT 5` | Menjelaskan jasa pengiriman yang dipilih pada saat pemesanan. |
| `biaya_dasar` | `DECIMAL` | Tarif tetap minimum pengiriman per pesanan | `8.99` | Berasal dari kolom `ShipBase` sebagai referensi komponen biaya kirim. |
| `tarif` | `DECIMAL` | Biaya tambahan pengiriman per satuan berat atau unit | `1.49` | Berasal dari kolom `ShipRate` untuk analisis efisiensi ongkos logistik. |

---

## 9. Tabel Dimensi: `dim_mata_uang`

Tabel dimensi (*conformed dimension*) yang menyimpan informasi mata uang serta nilai tukar harian saat transaksi dilakukan.

* **Strategi SCD:** SCD Tipe 1 (*Overwrite*), karena setiap catatan kurs sudah terikat pada tanggal transaksi spesifik (`tanggal_kurs`).

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `mata_uang_key` | `INT` | Surrogate key unik untuk entri nilai tukar mata uang | `102` | Primary Key (PK), *auto-increment*. |
| `currency_rate_id` | `INT` | Natural key identitas kurs dari tabel `Sales.CurrencyRate` | `102` | Diisi nilai default (misalnya `-1`) pada proses ETL jika transaksi menggunakan mata uang dasar USD tanpa konversi. |
| `kode_asal` | `VARCHAR(3)` | Kode mata uang sumber sebelum konversi (standar ISO 4217) | `USD` | Berasal dari kolom `FromCurrencyCode`. |
| `kode_tujuan` | `VARCHAR(3)` | Kode mata uang tujuan transaksi (standar ISO 4217) | `CAD` | Berasal dari kolom `ToCurrencyCode`. |
| `tanggal_kurs` | `DATE` | Tanggal berlakunya nilai tukar mata uang tersebut | `2011-05-31` | Berasal dari `CurrencyRateDate` untuk memastikan akurasi nilai tukar historis. |
| `average_rate` | `DECIMAL(10,4)` | Nilai tukar rata-rata harian pada tanggal transaksi | `0.9746` | Berasal dari `AverageRate` sebagai acuan konversi standar. |
| `end_of_day_rate` | `DECIMAL(10,4)` | Nilai tukar penutupan pada akhir hari transaksi | `0.9745` | Berasal dari `EndOfDayRate` untuk kebutuhan rekonsiliasi keuangan akhir hari. |


# Kamus Data Staging Area — Penjualan Reseller

Dokumen ini mendefinisikan struktur **15 tabel staging** pada database `dw_kelompok_1` yang dibangkitkan melalui skrip `00_staging_ddl.sql` (MySQL 8.0+). Lapisan *staging* berfungsi sebagai area pendaratan sementara (*landing zone*) untuk menampung data mentah hasil ekstraksi dari database transaksional AdventureWorks sebelum ditransformasi ke dalam skema bintang (**Star Schema v2**).

**Karakteristik Teknis Lapisan Staging:**
* **Tanpa Constraint (PK/FK):** Seluruh tabel dibuat tanpa *Primary Key* maupun *Foreign Key* agar pemuatan data mentah berjalan cepat tanpa terhambat validasi integritas referensial.
* **Strategi Truncate & Reload:** Seluruh tabel dikosongkan (`TRUNCATE`) setiap kali alur ETL/ELT dijalankan ulang untuk menghindari duplikasi data mentah.
* **Preservasi Tipe Waktu (`DATETIME`):** Atribut tanggal dipertahankan dalam format `DATETIME` sesuai tabel sumber sebelum dikonversi ke `DATE` atau kunci integer `YYYYMMDD` pada tahap transformasi.
* **Indeks Optimasi Transformasi:** Dilengkapi 7 indeks non-unik (`ix_stg_soh`, `ix_stg_sod`, `ix_stg_pch`, `ix_stg_plh`, `ix_stg_cust`, `ix_stg_store`, `ix_stg_curr`) untuk mempercepat proses `JOIN` antar-tabel *staging* saat pembentukan dimensi dan fakta.

---

## 1. `stg_salesorderheader`

Menampung data header pesanan penjualan mentah dari tabel sumber `Sales.SalesOrderHeader`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `salesorderid` | `INT` | ID unik header pesanan penjualan dari sistem sumber | `43659` | Diindeks (`ix_stg_soh`) untuk mempercepat `JOIN` dengan `stg_salesorderdetail`. |
| `salesordernumber` | `VARCHAR(25)` | Nomor dokumen faktur pesanan penjualan | `SO43659` | Diteruskan sebagai *degenerate dimension* ke `fact_penjualan_reseller`. |
| `orderdate` | `DATETIME` | Tanggal dan waktu pesanan dibuat | `2011-05-31 00:00:00` | Dikonversi menjadi format integer `YYYYMMDD` untuk mengisi `tanggal_pesan_key`. |
| `duedate` | `DATETIME` | Tanggal dan waktu jatuh tempo pembayaran atau pengiriman | `2011-06-12 00:00:00` | Disimpan sebagai referensi operasional dari sistem sumber. |
| `shipdate` | `DATETIME` | Tanggal dan waktu pesanan dikirimkan ke reseller | `2011-06-07 00:00:00` | Boleh `NULL`. Jika bernilai `NULL`, dipetakan ke `-1` pada `tanggal_kirim_key`. |
| `onlineorderflag` | `TINYINT(1)` | Penanda saluran transaksi (`0` = Reseller, `1` = Online) | `0` | Difilter dengan syarat `onlineorderflag = 0` agar hanya memuat penjualan reseller. |
| `customerid` | `INT` | ID pelanggan yang melakukan pemesanan | `29825` | Digunakan untuk *lookup* ke `stg_customer` guna memperoleh `storeid`. |
| `salespersonid` | `INT` | ID tenaga penjual yang menangani pesanan | `279` | Boleh `NULL`. Dipetakan ke `dim_sales_person.sales_person_id`. |
| `territoryid` | `INT` | ID wilayah geografis tempat transaksi berlangsung | `5` | Boleh `NULL`. Dipetakan ke `dim_wilayah.wilayah_id`. |
| `shipmethodid` | `INT` | ID metode pengiriman logistik yang dipilih | `5` | Dipetakan ke `dim_metode_kirim.metode_kirim_id`. |
| `currencyrateid` | `INT` | ID kurs mata uang yang berlaku saat transaksi | `102` | Boleh `NULL`. Nilai `NULL` menandakan transaksi menggunakan mata uang dasar USD. |
| `subtotal` | `DECIMAL(19,4)` | Total nilai pesanan sebelum pajak dan ongkos kirim pada tingkat header | `20565.6206` | Referensi audit untuk memvalidasi agregasi `linetotal` dari tabel detail. |
| `taxamt` | `DECIMAL(19,4)` | Nominal pajak transaksi pada tingkat header | `1971.5149` | Nilai pajak mentah dari database sumber OLTP. |
| `freight` | `DECIMAL(19,4)` | Total biaya pengiriman pada tingkat header | `616.0984` | Nilai ongkos kirim mentah dari database sumber OLTP. |

---

## 2. `stg_salesorderdetail`

Menampung rincian item produk per pesanan dari tabel sumber `Sales.SalesOrderDetail`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `salesorderid` | `INT` | ID header pesanan tempat item berada | `43659` | Diindeks (`ix_stg_sod`) untuk mempercepat penggabungan dengan `stg_salesorderheader`. |
| `salesorderdetailid` | `INT` | ID unik baris detail item dalam satu pesanan | `1` | Menentukan granularitas (*grain*) satu baris per *line item* pada tabel fakta. |
| `productid` | `INT` | ID produk yang dibeli pada baris item tersebut | `776` | Digunakan untuk *lookup* versi produk aktif di `dim_produk` berdasarkan tanggal pesan. |
| `specialofferid` | `INT` | ID skema promosi atau diskon yang berlaku pada item | `1` | Dipetakan ke `dim_promosi.promosi_id`. |
| `orderqty` | `INT` | Kuantitas unit produk yang dipesan | `1` | Dipetakan langsung ke metrik `jumlah_unit` pada `fact_penjualan_reseller`. |
| `unitprice` | `DECIMAL(19,4)` | Harga satuan produk setelah dipotong diskon satuan | `2024.9940` | Dipetakan ke metrik `harga_satuan` pada `fact_penjualan_reseller`. |
| `unitpricediscount` | `DECIMAL(19,4)` | Nominal potongan harga per unit produk | `0.0000` | Nilai diskon satuan mentah dari sistem sumber. |
| `linetotal` | `DECIMAL(19,4)` | Total nilai penjualan bersih per baris item pesanan | `2024.9940` | Dipetakan ke metrik `nilai_penjualan` pada `fact_penjualan_reseller`. |

---

## 3. `stg_product`

Menampung data induk katalog produk dari tabel sumber `Production.Product`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `productid` | `INT` | ID unik produk dari sistem sumber | `776` | Menjadi *natural key* (`produk_id`) pada tabel `dim_produk`. |
| `name` | `VARCHAR(50)` | Nama lengkap produk | `Mountain-100 Black, 42` | Dipetakan ke kolom `dim_produk.nama_produk`. |
| `productnumber` | `VARCHAR(25)` | Kode SKU atau nomor unik produk | `BK-M82B-42` | Dipetakan ke kolom `dim_produk.nomor_produk`. |
| `color` | `VARCHAR(15)` | Warna fisik varian produk | `Black` | Boleh `NULL`. Diisi nilai bawaan (seperti `'N/A'`) saat transformasi jika bernilai `NULL`. |
| `productsubcategoryid` | `INT` | ID subkategori tempat produk dikelompokkan | `1` | Boleh `NULL`. Digunakan untuk melakukan `LEFT JOIN` ke `stg_productsubcategory`. |
| `standardcost` | `DECIMAL(19,4)` | Biaya produksi standar terkini pada tabel master produk | `1898.0944` | Nilai cadangan (*fallback*) apabila produk tidak memiliki riwayat di `stg_productcosthistory`. |
| `listprice` | `DECIMAL(19,4)` | Harga jual katalog standar terkini pada tabel master produk | `3374.9900` | Nilai cadangan (*fallback*) apabila produk tidak memiliki riwayat di `stg_productlistpricehistory`. |

---

## 4. `stg_productsubcategory`

Menampung referensi subkategori produk dari tabel sumber `Production.ProductSubcategory`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `productsubcategoryid` | `INT` | ID unik subkategori produk | `1` | Kunci penghubung dari kolom `stg_product.productsubcategoryid`. |
| `productcategoryid` | `INT` | ID kategori utama induk dari subkategori tersebut | `1` | Kunci penghubung menuju tabel `stg_productcategory`. |
| `name` | `VARCHAR(50)` | Nama subkategori produk | `Mountain Bikes` | Didenormalisasi menjadi atribut `dim_produk.subkategori`. |

---

## 5. `stg_productcategory`

Menampung referensi kategori utama produk dari tabel sumber `Production.ProductCategory`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `productcategoryid` | `INT` | ID unik kategori utama produk | `1` | Kunci penghubung dari kolom `stg_productsubcategory.productcategoryid`. |
| `name` | `VARCHAR(50)` | Nama kategori utama produk | `Bikes` | Didenormalisasi menjadi atribut `dim_produk.kategori`. |

---

## 6. `stg_productcosthistory`

Menampung riwayat perubahan biaya standar produk dari tabel sumber `Production.ProductCostHistory` untuk membangun versi historis SCD Tipe 2.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `productid` | `INT` | ID produk yang mengalami perubahan biaya standar | `707` | Diindeks (`ix_stg_pch`) untuk mempercepat rekonstruksi versi SCD Tipe 2 pada `dim_produk`. |
| `startdate` | `DATETIME` | Tanggal dan waktu mulai berlakunya biaya standar baru | `2011-05-31 00:00:00` | Dikonversi menjadi tipe `DATE` untuk mengisi `dim_produk.berlaku_mulai`. |
| `enddate` | `DATETIME` | Tanggal dan waktu berakhirnya masa berlaku biaya standar | `2012-05-29 00:00:00` | Boleh `NULL`. Nilai `NULL` menandakan biaya standar tersebut masih berlaku aktif saat ini. |
| `standardcost` | `DECIMAL(19,4)` | Nominal biaya produksi standar pada periode tersebut | `12.0278` | Dipetakan ke `dim_produk.biaya_standar` sesuai rentang waktu validitasnya. |

---

## 7. `stg_productlistpricehistory`

Menampung riwayat perubahan harga jual katalog produk dari tabel sumber `Production.ProductListPriceHistory` untuk mendukung SCD Tipe 2.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `productid` | `INT` | ID produk yang mengalami perubahan harga jual katalog | `707` | Diindeks (`ix_stg_plh`) untuk mempercepat penggabungan riwayat harga dengan riwayat biaya produk. |
| `startdate` | `DATETIME` | Tanggal dan waktu mulai berlakunya harga jual baru | `2011-05-31 00:00:00` | Dikonversi menjadi tipe `DATE` sebagai penanda awal versi harga produk. |
| `enddate` | `DATETIME` | Tanggal dan waktu berakhirnya masa berlaku harga jual | `2012-05-29 00:00:00` | Boleh `NULL`. Nilai `NULL` menandakan harga katalog tersebut masih aktif. |
| `listprice` | `DECIMAL(19,4)` | Nominal harga jual katalog resmi pada periode tersebut | `33.6442` | Dipetakan ke `dim_produk.harga_jual` sesuai rentang waktu validitasnya. |

---

## 8. `stg_store`

Menampung data profil mitra toko reseller dari tabel sumber `Sales.Store`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `businessentityid` | `INT` | ID unik entitas bisnis toko reseller | `292` | Diindeks (`ix_stg_store`) dan dipetakan sebagai *natural key* `dim_reseller.reseller_id`. |
| `name` | `VARCHAR(100)` | Nama toko atau perusahaan mitra reseller | `Next-Door Bike Store` | Dipetakan ke `dim_reseller.nama_reseller`. |
| `salespersonid` | `INT` | ID tenaga penjual yang ditugaskan menangani toko tersebut | `279` | Boleh `NULL`. Informasi relasi penanggung jawab toko di sistem operasional. |
| `demographics` | `TEXT` | Data survei profil toko dalam format XML mentah | `<StoreSurvey ...>` | Boleh `NULL`. Diuraikan (*parsing*) saat ETL menggunakan `ExtractValue()` untuk mengisi `tipe_bisnis`, `penjualan_tahunan`, `jumlah_karyawan`, dan `tahun_buka`. |

---

## 9. `stg_customer`

Menampung data penghubung antara transaksi penjualan dengan entitas toko reseller dari tabel sumber `Sales.Customer`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `customerid` | `INT` | ID unik pelanggan yang tercatat pada header pesanan | `29825` | Diindeks (`ix_stg_cust`) sebagai kunci penghubung antara `stg_salesorderheader` dan `stg_store`. |
| `personid` | `INT` | ID kontak individu apabila pelanggan merupakan pembeli perorangan | `NULL` | Boleh `NULL`. |
| `storeid` | `INT` | ID toko reseller apabila pelanggan merupakan mitra toko | `292` | Boleh `NULL`. Merujuk ke `stg_store.businessentityid` untuk memperoleh `reseller_key`. |
| `territoryid` | `INT` | ID wilayah asal pelanggan | `5` | Boleh `NULL`. |

---

## 10. `stg_salesperson`

Menampung data target penjualan dan komisi tenaga penjual dari tabel sumber `Sales.SalesPerson`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `businessentityid` | `INT` | ID unik tenaga penjual | `279` | Menjadi *natural key* `dim_sales_person.sales_person_id` sekaligus kunci `JOIN` ke `stg_person`. |
| `territoryid` | `INT` | ID wilayah pemasaran yang ditugaskan kepada tenaga penjual | `5` | Boleh `NULL`. |
| `salesquota` | `DECIMAL(19,4)` | Target kuota penjualan yang dibebankan kepada tenaga penjual | `250000.0000` | Boleh `NULL`. Dipetakan ke `dim_sales_person.kuota_penjualan`. |
| `bonus` | `DECIMAL(19,4)` | Nominal bonus yang diperoleh tenaga penjual | `6700.0000` | Data pendukung kinerja dari sistem sumber. |
| `commissionpct` | `DECIMAL(10,4)` | Persentase komisi penjualan tenaga penjual | `0.0150` | Dipetakan ke `dim_sales_person.komisi_persen`. |

---

## 11. `stg_person`

Menampung atribut nama individu dari tabel sumber `Person.Person` untuk melengkapi profil tenaga penjual.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `businessentityid` | `INT` | ID unik entitas individu | `279` | Kunci penghubung dengan `stg_salesperson.businessentityid`. |
| `firstname` | `VARCHAR(50)` | Nama depan individu | `Tsvi` | Digabungkan dengan nama tengah dan belakang menjadi `dim_sales_person.nama_lengkap`. |
| `middlename` | `VARCHAR(50)` | Nama tengah individu | `Michael` | Boleh `NULL`. Menggunakan `CONCAT_WS` saat transformasi agar nilai `NULL` tidak menghapus keseluruhan string nama. |
| `lastname` | `VARCHAR(50)` | Nama belakang individu | `Reiter` | Digabungkan menjadi bagian akhir dari `dim_sales_person.nama_lengkap`. |

---

## 12. `stg_salesterritory`

Menampung data referensi wilayah pemasaran dari tabel sumber `Sales.SalesTerritory`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `territoryid` | `INT` | ID unik wilayah pemasaran | `4` | Menjadi *natural key* `dim_wilayah.wilayah_id`. |
| `name` | `VARCHAR(50)` | Nama wilayah pemasaran | `Southwest` | Dipetakan ke `dim_wilayah.nama_wilayah`. |
| `countryregioncode` | `VARCHAR(3)` | Kode standar negara dua huruf | `US` | Dipetakan ke `dim_wilayah.kode_negara`. |
| `group` | `VARCHAR(50)` | Kelompok kawasan benua atau pasar regional | `North America` | Diapit tanda *backtick* (`` `group` ``) pada skrip DDL karena merupakan *reserved keyword* di MySQL; dipetakan ke `dim_wilayah.grup`. |

---

## 13. `stg_specialoffer`

Menampung data daftar program promosi dan skema diskon dari tabel sumber `Sales.SpecialOffer`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `specialofferid` | `INT` | ID unik program penawaran khusus atau diskon | `1` | Menjadi *natural key* `dim_promosi.promosi_id`. |
| `description` | `VARCHAR(255)` | Keterangan lengkap nama atau aturan promosi | `No Discount` | Dipetakan ke `dim_promosi.deskripsi`. |
| `type` | `VARCHAR(50)` | Tipe atau mekanisme pemberian promosi | `No Discount` | Dipetakan ke `dim_promosi.jenis`. |
| `category` | `VARCHAR(50)` | Sasaran segmen penerima promosi | `No Discount` | Dipetakan ke `dim_promosi.kategori`. |
| `discountpct` | `DECIMAL(10,4)` | Besaran persentase diskon dalam format desimal | `0.0000` | Dipetakan ke `dim_promosi.persentase_diskon`. |
| `startdate` | `DATETIME` | Tanggal dan waktu dimulainya periode promosi | `2011-05-01 00:00:00` | Dikonversi ke `DATE` untuk mengisi `dim_promosi.mulai`. |
| `enddate` | `DATETIME` | Tanggal dan waktu berakhirnya periode promosi | `2014-11-30 00:00:00` | Dikonversi ke `DATE` untuk mengisi `dim_promosi.selesai`. |

---

## 14. `stg_shipmethod`

Menampung data referensi jasa pengiriman dari tabel sumber `Purchasing.ShipMethod`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `shipmethodid` | `INT` | ID unik metode pengiriman logistik | `5` | Menjadi *natural key* `dim_metode_kirim.metode_kirim_id`. |
| `name` | `VARCHAR(50)` | Nama layanan ekspedisi atau kurir pengiriman | `CARGO TRANSPORT 5` | Dipetakan ke `dim_metode_kirim.nama_metode`. |
| `shipbase` | `DECIMAL(19,4)` | Biaya dasar tetap minimum pengiriman per pesanan | `8.9900` | Dipetakan ke `dim_metode_kirim.biaya_dasar`. |
| `shiprate` | `DECIMAL(19,4)` | Tarif tambahan pengiriman per satuan unit | `1.4900` | Dipetakan ke `dim_metode_kirim.tarif`. |

---

## 15. `stg_currencyrate`

Menampung data historis nilai tukar valuta asing harian dari tabel sumber `Sales.CurrencyRate`.

| Kolom | Tipe | Arti | Contoh | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| `currencyrateid` | `INT` | ID unik entri nilai tukar mata uang harian | `102` | Diindeks (`ix_stg_curr`) dan dipetakan ke `dim_mata_uang.currency_rate_id`. |
| `currencyratedate` | `DATETIME` | Tanggal dan waktu berlakunya nilai tukar tersebut | `2011-05-31 00:00:00` | Dikonversi ke `DATE` untuk mengisi `dim_mata_uang.tanggal_kurs`. |
| `fromcurrencycode` | `VARCHAR(3)` | Kode mata uang asal sebelum konversi | `USD` | Dipetakan ke `dim_mata_uang.kode_asal`. |
| `tocurrencycode` | `VARCHAR(3)` | Kode mata uang tujuan transaksi | `CAD` | Dipetakan ke `dim_mata_uang.kode_tujuan`. |
| `averagerate` | `DECIMAL(19,4)` | Nilai tukar rata-rata harian | `0.9746` | Dipetakan ke `dim_mata_uang.average_rate`. |
| `endofdayrate` | `DECIMAL(19,4)` | Nilai tukar penutupan pada akhir hari | `0.9745` | Dipetakan ke `dim_mata_uang.end_of_day_rate`. |
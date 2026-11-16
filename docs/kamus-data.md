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
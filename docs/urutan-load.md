# Urutan Load Data & Ringkasan Alur ETL - Penjualan Reseller (Star Schema v2)

Dokumen ini menjelaskan urutan eksekusi persiapan skema dan pemuatan data (*load order*) dari database sumber (`adventureworks`) ke Data Warehouse (`dw_kelompok_1`) sesuai **Star Schema v2** (`docs/star-schema-v2.png`) dan ketentuan **Pertemuan 11**.

---

## Ringkasan Urutan Eksekusi

1. **Prasyarat Skema Fisik:** Pasang `dim_tanggal` standar sponsor terlebih dahulu, lalu jalankan skrip DDL tabel dimensi lainnya dan `fact_penjualan_reseller` (tanpa menghapus `dim_tanggal`).
2. **Alur Load ETL:** `stg_*` → `dim_tanggal` (sudah terpasang) → `dim_produk` (SCD 2) → dimensi pendukung lainnya (SCD 1) → `fact_penjualan_reseller` → rekonsiliasi & validasi.

---

## Tahap 1 — Pemuatan Area Staging (`stg_*`)

* **Jenis proses:** Ekstrak penuh (*full extract*) dari database sumber `adventureworks` melalui koneksi baca Pentaho ke database DW (`dw_kelompok_1`).
* **Aturan pembersihan:** Lakukan `TRUNCATE` pada seluruh tabel `stg_*` sebelum pengisian ulang setiap kali job ETL dijalankan.
* **Struktur staging:** Salinan mentah tanpa constraint sehingga proses transformasi berikutnya cukup memakai query SQL di dalam satu database DW (`dw_kelompok_1`) tanpa membebani database sumber.

| Tabel staging | Tabel sumber (`adventureworks`) | Target di DW |
|---|---|---|
| `stg_salesorderheader` | `sales.salesorderheader` | `fact_penjualan_reseller` |
| `stg_salesorderdetail` | `sales.salesorderdetail` | `fact_penjualan_reseller` |
| `stg_product` | `production.product` | `dim_produk` |
| `stg_productsubcategory` | `production.productsubcategory` | `dim_produk` |
| `stg_productcategory` | `production.productcategory` | `dim_produk` |
| `stg_productcosthistory` | `production.productcosthistory` | `dim_produk` (SCD 2) & `fact_penjualan_reseller` |
| `stg_productlistpricehistory` | `production.productlistpricehistory` | `dim_produk` (SCD 2) & `fact_penjualan_reseller` |
| `stg_store` | `sales.store` | `dim_reseller` |
| `stg_customer` | `sales.customer` | `dim_reseller`, `fact_penjualan_reseller` |
| `stg_salesperson` | `sales.salesperson` | `dim_sales_person` |
| `stg_person` | `person.person` | `dim_sales_person` |
| `stg_salesterritory` | `sales.salesterritory` | `dim_wilayah` |
| `stg_specialoffer` | `sales.specialoffer` | `dim_promosi` |
| `stg_shipmethod` | `purchasing.shipmethod` | `dim_metode_kirim` |
| `stg_currencyrate` | `sales.currencyrate` | `dim_mata_uang` |

---

## Tahap 2 — Pemasangan `dim_tanggal` (Skrip Standar Sponsor)

* **Sumber & metode:** Dijalankan satu kali langsung di database DW (`dw_kelompok_1`) menggunakan skrip SQL resmi dari sponsor (`dim_tanggal_mysql.sql`).
* **Isi & struktur standar:** 12 kolom (`tanggal_key`, `tanggal`, `tahun`, `semester`, `kuartal`, `bulan`, `nama_bulan`, `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`, `nama_hari`, `is_akhir_pekan`) dengan total **2.192 baris** (rentang `2010-01-01` s.d. `2015-12-31` ditambah 1 baris `-1` pada tanggal `1900-01-01`).
* **Aturan wajib:**
  * `dim_tanggal` **tidak boleh** di-generate sendiri di Pentaho.
  * `dim_tanggal` **tidak boleh** ikut di-`DROP` ketika skrip DDL atau ETL dijalankan ulang.
  * Struktur `dim_tanggal` standar **tidak boleh** diubah. Jika tim membutuhkan atribut kalender tambahan di luar 12 kolom standar (misalnya penanda hari libur nasional), buat tabel pendamping terpisah (mis. `dim_tanggal_libur`) yang terhubung lewat `tanggal_key`.

---

## Tahap 3 — Pemuatan `dim_produk` (SCD Campuran Tipe 0, 1, dan 2)

* Diproses lebih awal sebelum tabel fakta karena memiliki riwayat versi harga/biaya.
* Gabungkan `stg_product`, `stg_productsubcategory`, `stg_productcategory`, `stg_productcosthistory`, dan `stg_productlistpricehistory`.
* Terapkan strategi SCD:
  * **SCD Tipe 0:** `nomor_produk` (tetap).
  * **SCD Tipe 1:** `nama_produk`, `warna`, `subkategori`, `kategori` (timpa bila ada koreksi; isi `NULL` dengan `"Tidak ada"` / `"Tanpa kategori"`).
  * **SCD Tipe 2:** `biaya_standar` dan `harga_jual` berdasarkan rentang tanggal `berlaku_mulai`, `berlaku_sampai` (`9999-12-31` untuk versi aktif), dan flag `is_current` (dengan fallback ke nilai pada `stg_product` jika tidak ada riwayat).
* Pastikan baris `produk_key = -1` (`'Tidak diketahui'`) tersedia.

---

## Tahap 4 — Pemuatan Dimensi Pendukung (SCD Tipe 1)

Muat keenam dimensi pendukung secara paralel atau berurutan dengan strategi **SCD Tipe 1** (timpa nilai terbaru bila terjadi pembaruan di sumber), beserta baris default key `-1` (`'Tidak diketahui'`):

1. **`dim_reseller`** — dari `stg_store` dan `stg_customer` (ekstrak atribut XML `Demographics` dengan `ExtractValue`).
2. **`dim_sales_person`** — dari `stg_salesperson` dan `stg_person` (`Concat(FirstName, ' ', LastName)`).
3. **`dim_wilayah`** — dari `stg_salesterritory`.
4. **`dim_promosi`** — dari `stg_specialoffer`.
5. **`dim_metode_kirim`** — dari `stg_shipmethod`.
6. **`dim_mata_uang`** — dari `stg_currencyrate`, ditambah baris default transaksi **USD** (`rate = 1`) serta baris `-1`.

---

## Tahap 5 — Pemuatan Tabel Fakta (`fact_penjualan_reseller`)

Tabel fakta dimuat **paling akhir** setelah seluruh tabel dimensi terisi agar seluruh *lookup surrogate key* valid:

1. **Filter sumber:** Ambil gabungan `stg_salesorderheader` dan `stg_salesorderdetail` dengan filter `OnlineOrderFlag = 0` (khusus penjualan reseller).
2. **Konversi foreign key tanggal:**
   * `tanggal_pesan_key`: konversi `OrderDate` ke integer format `YYYYMMDD`.
   * `tanggal_kirim_key`: konversi `ShipDate` ke integer format `YYYYMMDD` (arahkan ke `-1` jika `NULL`).
3. **Lookup surrogate key ke dimensi:**
   * `produk_key`: lookup ke `dim_produk` berdasarkan `ProductID` dan kecocokan tanggal pesan dalam rentang SCD (`berlaku_mulai <= DATE(OrderDate) <= berlaku_sampai`). Jika tidak cocok, arahkan ke `-1`.
   * `reseller_key` (via `stg_customer.StoreID`), `sales_person_key`, `wilayah_key`, `promosi_key`, `metode_kirim_key`: lookup ke dimensi masing-masing (arahkan ke `-1` jika `NULL` atau tidak ditemukan).
   * `mata_uang_key`: lookup berdasarkan `CurrencyRateID` (arahkan ke baris USD / `-1` jika `CurrencyRateID` bernilai `NULL`).
4. **Simpan degenerate dimension & kalkulasi measure:**
   * Simpan `sales_order_id` dan `sales_order_number`.
   * Hitung measure:
     * `jumlah_unit = OrderQty`
     * `harga_satuan = UnitPrice`
     * `nilai_penjualan = LineTotal` (sudah dalam USD, tanpa konversi kurs ulang)
     * `biaya_standar_produk = StandardCost_historis × OrderQty`
     * `harga_jual_standar = ListPrice_historis × OrderQty`
     * `laba_kotor_reseller = harga_jual_standar - nilai_penjualan`
     * `laba_kotor_perusahaan = nilai_penjualan - biaya_standar_produk`

---

## Tahap 6 — Rekonsiliasi & Validasi Data

Setelah tabel fakta terisi, lakukan verifikasi akhir terhadap database sumber:

* **Validasi jumlah baris:** Jumlah baris `fact_penjualan_reseller` harus sama persis dengan jumlah baris detail pesanan reseller di sumber (**60.919 baris**).
* **Rekonsiliasi total nilai:** `SUM(nilai_penjualan)` di `fact_penjualan_reseller` harus cocok dengan `SUM(LineTotal)` pesanan reseller (`OnlineOrderFlag = 0`) di `adventureworks`.
* **Integritas foreign key:** Pastikan tidak ada kolom foreign key (`*_key`) di `fact_penjualan_reseller` yang bernilai `NULL` atau `0` (nilai yang tidak ditemukan harus diarahkan ke `-1`), dan pastikan `dim_tanggal` memiliki tepat **2.192 baris** dengan pemeriksaan tanggal `20130315` berhari Jumat.

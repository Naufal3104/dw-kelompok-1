# Source-to-Target Mapping (ETL) - Penjualan Reseller

Dokumen ini memuat pemetaan ekstraksi, transformasi, dan load (ETL) dari sumber data (OLTP AdventureWorks / `adventureworks2`) ke Data Warehouse (`dw_kelompok_1` — Star Schema v2).

## Target: dim_tanggal (Standar Sponsor — SCD: Tipe 0)

Sumber utama: Skrip SQL standar sponsor (`dim_tanggal_mysql.sql`, rentang `2010-01-01` s.d. `2015-12-31` + baris `-1` tanggal `1900-01-01`, total 2.192 baris).

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| ----- | ----- | ----- | ----- | ----- |
| tanggal_key | INT PK | \- | Format integer `YYYYMMDD` (baris `-1` bernilai `-1`) | \-1 |
| tanggal | DATE | \- | Tanggal kalender `YYYY-MM-DD` (baris `-1` bernilai `1900-01-01`) | \- |
| tahun | INT | \- | Tahun kalender 4 digit (`YEAR(tanggal)`) | \- |
| semester | INT | \- | Semester `1` (Jan–Jun) atau `2` (Jul–Des) | \- |
| kuartal | INT | \- | Kuartal `1` s.d. `4` (`QUARTER(tanggal)`) | \- |
| bulan | INT | \- | Nomor bulan `1` s.d. `12` (`MONTH(tanggal)`) | \- |
| nama_bulan | VARCHAR(15) | \- | Nama bulan dalam bahasa Indonesia (Januari–Desember) | \- |
| minggu_dalam_tahun | INT | \- | Nomor minggu ke-`1` s.d. `53` menurut standar ISO 8601 | \- |
| tanggal_dalam_bulan | INT | \- | Tanggal dalam bulan `1` s.d. `31` (`DAY(tanggal)`) | \- |
| hari_dalam_minggu | INT | \- | `1` = Senin s.d. `7` = Minggu menurut ISO 8601 | \- |
| nama_hari | VARCHAR(15) | \- | Nama hari dalam bahasa Indonesia (Senin–Minggu) | \- |
| is_akhir_pekan | BOOLEAN | \- | `TRUE` (`1`) jika Sabtu/Minggu, selain itu `FALSE` (`0`) | \- |

> **Catatan aturan `dim_tanggal`:** Tabel standar tidak boleh diubah strukturnya dan tidak boleh dibuat sendiri lewat Pentaho. Jika tim membutuhkan atribut tanggal tambahan di luar 12 kolom di atas (misalnya penanda hari libur nasional), atribut tersebut dibuat pada tabel pendamping terpisah (mis. `dim_tanggal_libur`) yang terhubung melalui `tanggal_key` sebagai `PRIMARY KEY` dan `FOREIGN KEY` ke `dim_tanggal (tanggal_key)`.

## Target: dim_produk (SCD: Campuran Tipe 0, 1, dan 2)

Sumber utama: `production.product`, `production.productsubcategory`, `production.productcategory`, `production.productcosthistory`, `production.productlistpricehistory`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| produk_key | INT PK | \- | surrogate key (Auto Increment) dari DW | \- | 
| produk_id | INT | `product.ProductID` | langsung (Natural Key) | \- | 
| nama_produk | VARCHAR(50) | `product.Name` | langsung (SCD 1) | \- | 
| nomor_produk | VARCHAR(25) | `product.ProductNumber` | langsung (SCD 0) | \- | 
| warna | VARCHAR(15) | `product.Color` | langsung (SCD 1) | "Tidak ada" | 
| subkategori | VARCHAR(50) | `productsubcategory.Name` | lookup (SCD 1) | "Tanpa kategori" | 
| kategori | VARCHAR(50) | `productcategory.Name` | lookup (SCD 1) | "Tanpa kategori" | 
| biaya_standar | DECIMAL(12,4) | `productcosthistory.StandardCost` | rentang tanggal historis (SCD 2) | Fallback ke `product` | 
| harga_jual | DECIMAL(12,4) | `productlistpricehistory.ListPrice` | rentang tanggal historis (SCD 2) | Fallback ke `product` | 
| berlaku_mulai | DATE | `StartDate` | awal periode SCD 2 | \- | 
| berlaku_sampai | DATE | `EndDate` | akhir periode SCD 2 | `9999-12-31` | 
| is_current | BOOLEAN | \- | flag (1 aktif, 0 lampau) | \- | 

## Target: dim_reseller (SCD: Tipe 1)

Sumber utama: `sales.store`, `sales.customer`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| reseller_key | INT PK | \- | surrogate key dari DW | \- | 
| reseller_id | INT | `customer.StoreID` | langsung (BusinessEntityID) | \- | 
| nama_reseller | VARCHAR(100) | `store.Name` | langsung | \- | 
| tipe_bisnis | VARCHAR(50) | `store.Demographics` | `ExtractValue` XML (Business Type) | "Tidak diketahui" | 
| penjualan_tahunan | DECIMAL(15,2) | `store.Demographics` | `ExtractValue` XML (Annual Sales) | 0 | 
| jumlah_karyawan | INT | `store.Demographics` | `ExtractValue` XML (Number Employees) | 0 | 
| tahun_buka | INT | `store.Demographics` | `ExtractValue` XML (Year Opened) | \-1 | 

## Target: dim_sales_person (SCD: Tipe 1)

Sumber utama: `sales.salesperson`, `person.person`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| sales_person_key | INT PK | \- | surrogate key dari DW | \- | 
| sales_person_id | INT | `salesperson.BusinessEntityID` | langsung | \- | 
| nama_lengkap | VARCHAR(100) | `person.FirstName`, `LastName` | Concat(FirstName, ' ', LastName) | \- | 
| komisi_persen | DECIMAL(10,4) | `salesperson.CommissionPct` | langsung | 0 | 
| kuota_penjualan | DECIMAL(15,2) | `salesperson.SalesQuota` | langsung | 0 | 

## Target: dim_wilayah (SCD: Tipe 1)

Sumber utama: `sales.salesterritory`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| wilayah_key | INT PK | \- | surrogate key dari DW | \- | 
| wilayah_id | INT | `salesterritory.TerritoryID` | langsung | \- | 
| nama_wilayah | VARCHAR(50) | `salesterritory.Name` | langsung | "Tidak diketahui" | 
| kode_negara | VARCHAR(3) | `salesterritory.CountryRegionCode` | langsung | "N/A" | 
| grup | VARCHAR(50) | `salesterritory.Group` | langsung | "Tidak diketahui" | 

## Target: dim_promosi (SCD: Tipe 1)

Sumber utama: `sales.specialoffer`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| promosi_key | INT PK | \- | surrogate key dari DW | \- | 
| promosi_id | INT | `specialoffer.SpecialOfferID` | langsung | \- | 
| deskripsi | VARCHAR(255) | `specialoffer.Description` | langsung | "Tidak ada promosi" | 
| jenis | VARCHAR(50) | `specialoffer.Type` | langsung | "N/A" | 
| kategori | VARCHAR(50) | `specialoffer.Category` | langsung | "N/A" | 
| persentase_diskon | DECIMAL(10,4) | `specialoffer.DiscountPct` | langsung | 0 | 
| mulai | DATE | `specialoffer.StartDate` | DATE() | \- | 
| selesai | DATE | `specialoffer.EndDate` | DATE() | \- | 

## Target: dim_metode_kirim (SCD: Tipe 1)

Sumber utama: `purchasing.shipmethod`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| metode_kirim_key | INT PK | \- | surrogate key dari DW | \- | 
| metode_kirim_id | INT | `shipmethod.ShipMethodID` | langsung | \- | 
| nama_metode | VARCHAR(50) | `shipmethod.Name` | langsung | "Tidak diketahui" | 
| biaya_dasar | DECIMAL(10,4) | `shipmethod.ShipBase` | langsung | 0 | 
| tarif | DECIMAL(10,4) | `shipmethod.ShipRate` | langsung | 0 | 

## Target: dim_mata_uang (SCD: Tipe 1)

Sumber utama: `sales.currencyrate`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| mata_uang_key | INT PK | \- | surrogate key dari DW | \- | 
| currency_rate_id | INT | `currencyrate.CurrencyRateID` | langsung | \- | 
| kode_asal | VARCHAR(3) | `currencyrate.FromCurrencyCode` | langsung | "USD" (Baris USD) | 
| kode_tujuan | VARCHAR(3) | `currencyrate.ToCurrencyCode` | langsung | "USD" (Baris USD) | 
| tanggal_kurs | DATE | `currencyrate.CurrencyRateDate` | DATE() | 1900-01-01 | 
| average_rate | DECIMAL(10,4) | `currencyrate.AverageRate` | langsung | 1 (Baris USD) | 
| end_of_day_rate | DECIMAL(10,4) | `currencyrate.EndOfDayRate` | langsung | 1 (Baris USD) | 

## Target: fact_penjualan_reseller (grain: 1 baris = 1 produk dalam 1 pesanan reseller)

Sumber utama: `sales.salesorderheader`, `sales.salesorderdetail` (filter: `OnlineOrderFlag = 0`)

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| fakta_penjualan_key | BIGINT PK | \- | surrogate key dari DW | \- | 
| tanggal_pesan_key | INT FK | `OrderDate` | `DATE(OrderDate)` ke format YYYYMMDD | \- | 
| tanggal_kirim_key | INT FK | `ShipDate` | `DATE(ShipDate)` ke format YYYYMMDD | \-1 | 
| produk_key | INT FK | \- | Lookup `dim_produk` via `ProductID` & rentang SCD (`OrderDate`) | \-1 | 
| reseller_key | INT FK | `sales_customer.StoreID` | Lookup `dim_reseller` via ID toko | \-1 | 
| sales_person_key | INT FK | `SalesPersonID` | Lookup `dim_sales_person` | \-1 | 
| wilayah_key | INT FK | `TerritoryID` | Lookup `dim_wilayah` | \-1 | 
| promosi_key | INT FK | `detail.SpecialOfferID` | Lookup `dim_promosi` | \-1 | 
| metode_kirim_key | INT FK | `ShipMethodID` | Lookup `dim_metode_kirim` | \-1 | 
| mata_uang_key | INT FK | `CurrencyRateID` | Lookup `dim_mata_uang` | \-1 (Arahkan ke baris USD) | 
| sales_order_id | INT | `SalesOrderID` | degenerate dimension | \- | 
| sales_order_number | VARCHAR(25) | `SalesOrderNumber` | degenerate dimension | "N/A" | 
| jumlah_unit | INT | `OrderQty` | langsung | 0 | 
| harga_satuan | DECIMAL(12,4) | `UnitPrice` | langsung | 0 | 
| nilai_penjualan | DECIMAL(12,2) | `LineTotal` | Omzet (dalam USD), tanpa konversi kurs ulang | 0 | 
| biaya_standar_produk | DECIMAL(12,2) | `StandardCost` historis | Lookup HPP saat tanggal pesan, kalikan `OrderQty` | 0 | 
| harga_jual_standar | DECIMAL(12,2) | `ListPrice` historis | Lookup harga jual saat tanggal pesan, kalikan `OrderQty` | 0 | 
| laba_kotor_reseller | DECIMAL(12,2) | \- | `harga_jual_standar - nilai_penjualan` | 0 | 
| laba_kotor_perusahaan | DECIMAL(12,2) | \- | `nilai_penjualan - biaya_standar_produk` | 0 | 

## Daftar Tabel Staging

Seluruh tabel staging (`stg_*`) berada di database DW (`dw_kelompok_1`), merupakan salinan mentah dari database sumber `adventureworks` tanpa constraint, dan dikosongkan (`TRUNCATE`) setiap kali ETL dijalankan.

| Tabel staging | Sumber di `adventureworks` | Dipakai untuk |
| ----- | ----- | ----- |
| `stg_salesorderheader` | `sales.salesorderheader` | `fact_penjualan_reseller` |
| `stg_salesorderdetail` | `sales.salesorderdetail` | `fact_penjualan_reseller` |
| `stg_product` | `production.product` | `dim_produk` |
| `stg_productsubcategory` | `production.productsubcategory` | `dim_produk` |
| `stg_productcategory` | `production.productcategory` | `dim_produk` |
| `stg_productcosthistory` | `production.productcosthistory` | `dim_produk` (SCD Tipe 2) & `fact_penjualan_reseller` |
| `stg_productlistpricehistory` | `production.productlistpricehistory` | `dim_produk` (SCD Tipe 2) & `fact_penjualan_reseller` |
| `stg_store` | `sales.store` | `dim_reseller` |
| `stg_customer` | `sales.customer` | `dim_reseller`, `fact_penjualan_reseller` |
| `stg_salesperson` | `sales.salesperson` | `dim_sales_person` |
| `stg_person` | `person.person` | `dim_sales_person` |
| `stg_salesterritory` | `sales.salesterritory` | `dim_wilayah` |
| `stg_specialoffer` | `sales.specialoffer` | `dim_promosi` |
| `stg_shipmethod` | `purchasing.shipmethod` | `dim_metode_kirim` |
| `stg_currencyrate` | `sales.currencyrate` | `dim_mata_uang` |

## Urutan Load Data

Penjelasan detail tiap tahap dapat dilihat di [docs/urutan-load.md](urutan-load.md).

1. **`stg_*` (extract penuh, truncate tiap jalan)**
   * Tarik semua data mentah dari database operasional (`adventureworks`) ke tabel staging `stg_*` di database DW.
   * Bersihkan tabel staging (`TRUNCATE`) sebelum melakukan pemuatan data baru agar transformasi berikutnya berjalan di satu database DW tanpa membebani database sumber.

2. **`dim_tanggal` (skrip standar sponsor — dijalankan sekali sebelum DDL/ETL)**
   * Jalankan skrip standar `dim_tanggal_mysql.sql` dari sponsor langsung di database DW (`2010-01-01` s.d. `2015-12-31` + baris `-1`, total 2.192 baris).
   * Tabel ini tidak dibuat sendiri di Pentaho, tidak diubah strukturnya, dan tidak ikut di-`DROP` saat skrip DDL dijalankan ulang.

3. **`dim_produk` (proses SCD campuran Tipe 0, 1, dan 2)**
   * Jahit riwayat perubahan `biaya_standar` dan `harga_jual` dari tabel staging riwayat produk menggunakan metode SCD Tipe 2 (beserta fallback ke master produk).
   * Pastikan baris `-1` (`'Tidak diketahui'`) tersedia di `dim_produk`.

4. **`dim_reseller`, `dim_sales_person`, `dim_wilayah`, `dim_promosi`, `dim_metode_kirim`, `dim_mata_uang` (proses SCD Tipe 1)**
   * Muat semua dimensi pendukung menggunakan metode SCD Tipe 1 (timpa nilai terbaru bila terdapat pembaruan dari sumber).
   * Pastikan setiap dimensi memiliki baris dengan key `-1` (`'Tidak diketahui'`), termasuk baris default USD pada `dim_mata_uang`.

5. **`fact_penjualan_reseller` (lookup surrogate key ke dimensi + kalkulasi measure)**
   * Filter pesanan reseller (`OnlineOrderFlag = 0`), konversi `OrderDate` dan `ShipDate` menjadi `tanggal_pesan_key` dan `tanggal_kirim_key` (`YYYYMMDD`, fallback `-1` jika `ShipDate` NULL).
   * Lakukan lookup surrogate key ke seluruh dimensi (khusus `dim_produk`, cocokkan `produk_id` beserta rentang tanggal `berlaku_mulai` s.d. `berlaku_sampai`).
   * Hitung seluruh measure (`nilai_penjualan`, `biaya_standar_produk`, `harga_jual_standar`, `laba_kotor_reseller`, `laba_kotor_perusahaan`).

6. **Rekonsiliasi & Validasi Data**
   * Verifikasi jumlah baris `fact_penjualan_reseller` (60.919 baris detail pesanan reseller), kecocokan total `nilai_penjualan` terhadap sumber, dan pastikan tidak ada foreign key yang bernilai `NULL` atau `0`.
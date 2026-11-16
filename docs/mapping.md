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
| average_rate | DECIMAL(15,4) | `currencyrate.AverageRate` | langsung | 1 (Baris USD) | 
| end_of_day_rate | DECIMAL(15,4) | `currencyrate.EndOfDayRate` | langsung | 1 (Baris USD) | 

## Target: fact_penjualan_reseller (grain: 1 baris = 1 produk dalam 1 pesanan reseller)

Sumber utama: `sales.salesorderheader`, `sales.salesorderdetail`

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL | 
| ----- | ----- | ----- | ----- | ----- | 
| fakta_penjualan_key | BIGINT PK | \- | surrogate key dari DW | \- | 
| tanggal_pesan_key | INT FK | `OrderDate` | `DATE(OrderDate)` ke format YYYYMMDD | \- | 
| tanggal_kirim_key | INT FK | `ShipDate` | `DATE(ShipDate)` ke format YYYYMMDD | \-1 | 
| tanggal_jatuh_tempo_key | INT FK | `DueDate` | `DATE(DueDate)` ke format YYYYMMDD | \- | 
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

## Urutan Load Data

1. **`stg_*` (extract penuh, truncate tiap jalan)**
   * Tarik semua informasi data mentah dari database operasional ke area staging.
   * Bersihkan tabel staging terlebih dahulu (truncate) sebelum melakukan pemuatan data baru.
   * Isi area staging dengan data terbaru agar proses transformasi tidak membebani kinerja database utama.

2. **`dim_tanggal`**
   * Bangun pondasi dimensi waktu dengan mengeksekusi skrip bawaan sponsor secara langsung di database Data Warehouse.
   * Cetak seluruh hari di kalender dengan rentang tahun 2010 hingga 2015.
   * Sisipkan baris dengan ID "-1" untuk menangani data transaksi yang tanggalnya kosong.

3. **`dim_produk` (proses SCD tipe 2)**
   * Proses dimensi produk ini lebih awal karena logika riwayatnya cukup rumit.
   * Jahit riwayat perubahan harga dan biaya menggunakan metode SCD tipe 2.
   * Gabungkan master produk dan tabel riwayatnya agar sistem bisa membedakan harga pada tahun transaksi yang berbeda.

4. **`dim_reseller, dim_sales_person, dim_wilayah, dim_promosi, dim_metode_kirim, dim_mata_uang` (proses SCD tipe 1)**
   * Muat semua dimensi pendukung lainnya menggunakan metode SCD tipe 1.
   * Timpa data lama secara langsung jika terdapat pembaruan informasi dari sumber operasional.
   * Pastikan setiap tabel dimensi memiliki baris ID "-1" sebagai penampung data yang tidak terdefinisi.

5. **`fact_penjualan_reseller` (lookup surrogate key ke dimensi + kalkulasi perhitungan measure)**
   * Jadikan proses pemuatan tabel fakta ini sebagai muara akhir alur ETL.
   * Konversi semua ID transaksi lama menjadi Surrogate Key dengan mencocokkannya ke tabel dimensi.
   * Hitung metrik uang seperti total omzet, diskon, dan keuntungan secara otomatis di tahap ini.
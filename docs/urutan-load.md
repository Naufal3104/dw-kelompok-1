# docs/mapping.md

## Target: dim_tanggal (SCD: tipe 0)
Sumber utama: - (Dihasilkan secara otomatis (generate) di Pentaho)

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| tanggal_key  | INT  | -                  | Format YYYYMMDD | -           |
| tanggal_asli | DATE | -                  | Generate otomatis | -           |
| nama_hari    | VARCHAR | -               | Ambil dari tanggal_asli | -           |
| bulan        | INT  | -                  | Ekstrak bulan dari tanggal_asli | -   |
| nama_bulan   | VARCHAR | -               | Ambil dari bulan | -           |
| tahun        | INT  | -                  | Ekstrak tahun dari tanggal_asli | -   |
| kuartal      | INT  | -                  | Ekstrak kuartal dari tanggal_asli | - |

## Target: dim_produk (SCD: tipe 2)
Sumber utama: Production.Product p 
(Join ke ProductSubcategory psc, ProductCategory pc)

| Kolom target    | Tipe    | Tabel.kolom sumber          | Transformasi | Aturan NULL |
|-----------------|---------|-----------------------------|--------------|-------------|
| produk_key      | INT     | -                           | surrogate key dari DW | - |
| produk_id       | INT     | p.ProductID                 | langsung     | -1          |
| nama_produk     | VARCHAR | p.Name                      | langsung     | "Tidak ada" |
| nomor_produk    | VARCHAR | p.ProductNumber             | langsung     | "Tidak ada" |
| warna           | VARCHAR | p.Color                     | langsung     | "Tidak ada" |
| biaya_standar   | NUMERIC | p.StandardCost              | langsung     | 0           |
| subkategori     | VARCHAR | psc.Name                    | langsung     | "Tanpa subkategori" |
| kategori        | VARCHAR | pc.Name                     | langsung     | "Tanpa kategori" |

## Target: dim_reseller (SCD: tipe 1)
Sumber utama: Sales.Store s

| Kolom target    | Tipe    | Tabel.kolom sumber          | Transformasi | Aturan NULL |
|-----------------|---------|-----------------------------|--------------|-------------|
| reseller_key    | INT     | -                           | surrogate key dari DW | - |
| reseller_id     | INT     | s.BusinessEntityID          | langsung     | -1          |
| nama_reseller   | VARCHAR | s.Name                      | langsung     | "Tidak diketahui" |

## Target: dim_salesperson (SCD: tipe 1)
Sumber utama: Sales.SalesPerson sp 
(Join ke Person.Person p)

| Kolom target    | Tipe    | Tabel.kolom sumber          | Transformasi | Aturan NULL |
|-----------------|---------|-----------------------------|--------------|-------------|
| sales_key       | INT     | -                           | surrogate key dari DW | - |
| sales_id        | INT     | sp.BusinessEntityID         | langsung     | -1          |
| nama_lengkap    | VARCHAR | p.FirstName + ' ' + p.LastName | Gabungkan string | "Tidak diketahui" |

## Target: dim_wilayah (SCD: tipe 1)
Sumber utama: Sales.SalesTerritory t

| Kolom target    | Tipe    | Tabel.kolom sumber          | Transformasi | Aturan NULL |
|-----------------|---------|-----------------------------|--------------|-------------|
| wilayah_key     | INT     | -                           | surrogate key dari DW | - |
| wilayah_id      | INT     | t.TerritoryID               | langsung     | -1          |
| nama_wilayah    | VARCHAR | t.Name                      | langsung     | "Tidak diketahui" |
| grup_wilayah    | VARCHAR | t.Group                     | langsung     | "Tidak diketahui" |

## Target: fact_penjualan_reseller (grain: satu baris per item pada pesanan reseller)
Sumber utama: Sales.SalesOrderHeader soh 
(Join ke Sales.SalesOrderDetail sod. Filter: soh.OnlineOrderFlag = 0)

| Kolom target       | Tipe    | Tabel.kolom sumber                   | Transformasi | Aturan NULL |
|--------------------|---------|--------------------------------------|--------------|-------------|
| tanggal_pesan_key  | INT     | soh.OrderDate                        | Ubah ke format YYYYMMDD | -1 |
| tanggal_kirim_key  | INT     | soh.ShipDate                         | Ubah ke format YYYYMMDD | -1 |
| produk_key         | INT     | sod.ProductID                        | Lookup ke dim_produk (berlaku saat tanggal_pesan) | -1 |
| reseller_key       | INT     | soh.CustomerID (relasi ke Store)     | Lookup ke dim_reseller | -1 |
| sales_key          | INT     | soh.SalesPersonID                    | Lookup ke dim_salesperson | -1 |
| wilayah_key        | INT     | soh.TerritoryID                      | Lookup ke dim_wilayah | -1 |
| nomor_pesanan      | VARCHAR | soh.SalesOrderNumber                 | Langsung (degenerate dimension) | "Tidak ada" |
| jumlah_unit        | INT     | sod.OrderQty                         | Langsung     | 0 |
| nilai_penjualan    | NUMERIC | OrderQty, UnitPrice, UnitPriceDiscount | orderqty × unitprice × (1 - unitpricediscount) | 0 |
| nilai_diskon       | NUMERIC | OrderQty, UnitPrice, UnitPriceDiscount | orderqty × unitprice × unitpricediscount | 0 |
| biaya_standar_total| NUMERIC | OrderQty, Lookup ke dim_produk       | orderqty × dim_produk.biaya_standar | 0 |
| lama_kirim_hari    | INT     | soh.ShipDate, soh.OrderDate          | shipdate - orderdate dalam satuan hari | NULL |

## Urutan load
1. Ekstrak data sumber ke tabel staging.
2. Bersihkan dan standarkan data (tangani NULL, ubah kode ke teks, seragamkan format tanggal).
3. Isi `dim_tanggal` secara otomatis (generate rows).
4. Muat tabel dimensi lain sambil memproses aturan SCD (`dim_wilayah`, `dim_produk`, `dim_reseller`, `dim_salesperson`).
5. Cari dan mapping *surrogate key* untuk setiap baris fakta menggunakan pencocokan (*lookup*) dari tabel-tabel dimensi.
6. Muat hasil akhir ke dalam tabel fakta (`fact_penjualan_reseller`).
7. Rekonsiliasi jumlah baris dan total agregat (misalnya total `nilai_penjualan`) antara DW dan sumber.
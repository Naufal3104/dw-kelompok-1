# Profil Data Sumber - Penjualan Reseller

## Hasil Profil Data (Data Aktual)

### Ringkasan Data Sumber

| Metrik | Nilai |
|--------|-------|
| Total pesanan reseller | 3.806 |
| Total baris detail (calon baris fakta) | 60.919 |
| Rentang tanggal | 31 Mei 2011 - 1 Mei 2014 (1.066 hari) |
| Total reseller | 701 |
| Total sales person | 17 |
| Total kategori | 4 |
| Total produk | 504 |
| Total reseller | 701 |
| Total salesperson | 17 |
| Total wilayah | 10 |
| Pesanan tanpa sales person | 0 (0%) |

### Distribusi Pesanan Reseller per Tahun

| Tahun | Jumlah Pesanan | Total Nilai Penjualan |
|-------|----------------|----------------------|
| 2011 | 406 | $9.886.951,62 |
| 2012 | 1.172 | $30.614.087,24 |
| 2013 | 1.598 | $37.106.886,93 |
| 2014 | 630 | $13.167.521,19 |

## Query Profil Data

### 1. Jumlah Pesanan Reseller vs Online dan Rentang Tanggal

```sql
SELECT 
    onlineorderflag,
    CASE WHEN onlineorderflag = 1 THEN 'Online' ELSE 'Reseller' END AS tipe_penjualan,
    COUNT(*) AS jumlah_pesanan,
    MIN(orderdate) AS tanggal_awal,
    MAX(orderdate) AS tanggal_akhir,
    DATEDIFF(MAX(orderdate), MIN(orderdate)) AS rentang_hari
FROM sales_salesorderheader
GROUP BY onlineorderflag;
```

### 2. Pesanan Reseller tanpa Sales Person

```sql
SELECT 
    COUNT(*) AS total_pesanan_reseller,
    SUM(CASE WHEN salespersonid IS NULL THEN 1 ELSE 0 END) AS tanpa_sales_person,
    ROUND(SUM(CASE WHEN salespersonid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS persen_tanpa_sales
FROM sales_salesorderheader
WHERE onlineorderflag = 0;
```

### 3. Jumlah Detail Pesanan (Calon Baris Fakta)

```sql
SELECT 
    COUNT(*) AS total_baris_detail
FROM sales_salesorderheader h
JOIN sales_salesorderdetail d ON d.salesorderid = h.salesorderid
WHERE h.onlineorderflag = 0;
```

### 4. Distribusi Pesanan per Tahun

```sql
SELECT 
    YEAR(orderdate) AS tahun,
    COUNT(*) AS jumlah_pesanan,
    SUM(totaldue) AS total_nilai_penjualan
FROM sales_salesorderheader
WHERE onlineorderflag = 0
GROUP BY YEAR(orderdate)
ORDER BY tahun;
```

### 5. Jumlah Produk dan Kategori

```sql
SELECT 
    pc.name AS kategori,
    COUNT(DISTINCT p.productid) AS jumlah_produk
FROM production_product p
LEFT JOIN production_productsubcategory psc ON psc.productsubcategoryid = p.productsubcategoryid
LEFT JOIN production_productcategory pc ON pc.productcategoryid = psc.productcategoryid
GROUP BY pc.name
ORDER BY jumlah_produk DESC;
```

### 6. Jumlah Reseller

```sql
SELECT COUNT(*) AS total_reseller FROM sales_store;
```

### 7. Jumlah Sales Person

```sql
SELECT COUNT(*) AS total_sales_person FROM sales_salesperson;
```

### 8. Jumlah Wilayah

```sql
SELECT COUNT(*) AS total_wilayah FROM sales_salesterritory;
```

### 9. Cek NULL di Kolom Penting

```sql
SELECT 
    'SalesOrderHeader' AS tabel,
    COUNT(*) AS total_baris,
    SUM(CASE WHEN customerid IS NULL THEN 1 ELSE 0 END) AS customerid_null,
    SUM(CASE WHEN salespersonid IS NULL THEN 1 ELSE 0 END) AS salespersonid_null,
    SUM(CASE WHEN territoryid IS NULL THEN 1 ELSE 0 END) AS territoryid_null,
    SUM(CASE WHEN shipmethodid IS NULL THEN 1 ELSE 0 END) AS shipmethodid_null
FROM sales_salesorderheader
WHERE onlineorderflag = 0;
```

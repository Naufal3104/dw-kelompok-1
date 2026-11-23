USE db_warehouse;


SELECT 'sumber' AS tahap, COUNT(*) AS jumlah_baris,
       SUM(ROUND(CAST(d.LineTotal AS DECIMAL(19,4)), 2)) AS total_penjualan
FROM adventureworks2.sales_salesorderdetail d
JOIN adventureworks2.sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
WHERE h.OnlineOrderFlag = 0
UNION ALL
SELECT 'staging', COUNT(*), SUM(ROUND(d.linetotal, 2))
FROM stg_salesorderdetail d
JOIN stg_salesorderheader h ON h.salesorderid = d.salesorderid
WHERE h.onlineorderflag = 0
UNION ALL
SELECT 'fakta', COUNT(*), SUM(nilai_penjualan)
FROM fact_penjualan_reseller;


SELECT SUM(tanggal_pesan_key = -1) AS tanggal_pesan_tidak_diketahui,
       SUM(tanggal_kirim_key = -1) AS tanggal_kirim_tidak_diketahui,
       SUM(produk_key        = -1) AS produk_tidak_diketahui,
       SUM(reseller_key      = -1) AS reseller_tidak_diketahui,
       SUM(sales_person_key  = -1) AS sales_person_tidak_diketahui,
       SUM(wilayah_key       = -1) AS wilayah_tidak_diketahui,
       SUM(promosi_key       = -1) AS promosi_tidak_diketahui,
       SUM(metode_kirim_key  = -1) AS metode_kirim_tidak_diketahui,
       SUM(mata_uang_key     = -1) AS mata_uang_tidak_diketahui,
       COUNT(*)                    AS total_baris
FROM fact_penjualan_reseller;


SELECT (SELECT MIN(DATE(TIMESTAMPADD(SECOND, UNIX_TIMESTAMP(OrderDate), '1970-01-01 08:00:00'))) FROM adventureworks2.sales_salesorderheader WHERE OnlineOrderFlag = 0) AS awal_sumber,
       (SELECT MIN(DATE(orderdate)) FROM stg_salesorderheader WHERE onlineorderflag = 0)                  AS awal_staging,
       (SELECT MIN(t.tanggal) FROM fact_penjualan_reseller f
          JOIN dim_tanggal t ON t.tanggal_key = f.tanggal_pesan_key WHERE f.tanggal_pesan_key <> -1)      AS awal_fakta,
       (SELECT MAX(DATE(TIMESTAMPADD(SECOND, UNIX_TIMESTAMP(OrderDate), '1970-01-01 08:00:00'))) FROM adventureworks2.sales_salesorderheader WHERE OnlineOrderFlag = 0) AS akhir_sumber,
       (SELECT MAX(t.tanggal) FROM fact_penjualan_reseller f
          JOIN dim_tanggal t ON t.tanggal_key = f.tanggal_pesan_key WHERE f.tanggal_pesan_key <> -1)      AS akhir_fakta;

SELECT s.tgl, s.jumlah AS jumlah_sumber, COALESCE(g.jumlah, 0) AS jumlah_staging
FROM (SELECT DATE(TIMESTAMPADD(SECOND, UNIX_TIMESTAMP(OrderDate), '1970-01-01 08:00:00')) AS tgl, COUNT(*) AS jumlah
      FROM adventureworks2.sales_salesorderheader GROUP BY DATE(TIMESTAMPADD(SECOND, UNIX_TIMESTAMP(OrderDate), '1970-01-01 08:00:00'))) s
LEFT JOIN (SELECT DATE(orderdate) AS tgl, COUNT(*) AS jumlah
           FROM stg_salesorderheader GROUP BY DATE(orderdate)) g ON g.tgl = s.tgl
WHERE COALESCE(g.jumlah, 0) <> s.jumlah
LIMIT 20;


SELECT produk_id, berlaku_mulai, COUNT(*) AS jumlah
FROM dim_produk
GROUP BY produk_id, berlaku_mulai
HAVING COUNT(*) > 1;


SELECT produk_id, SUM(is_current) AS versi_aktif
FROM dim_produk
WHERE produk_key <> -1
GROUP BY produk_id
HAVING SUM(is_current) <> 1;


SELECT 'dim_produk' AS tabel, COUNT(*) AS jumlah FROM dim_produk
UNION ALL SELECT 'dim_reseller',     COUNT(*) FROM dim_reseller
UNION ALL SELECT 'dim_sales_person', COUNT(*) FROM dim_sales_person
UNION ALL SELECT 'dim_wilayah',      COUNT(*) FROM dim_wilayah
UNION ALL SELECT 'dim_promosi',      COUNT(*) FROM dim_promosi
UNION ALL SELECT 'dim_metode_kirim', COUNT(*) FROM dim_metode_kirim
UNION ALL SELECT 'dim_mata_uang',    COUNT(*) FROM dim_mata_uang
UNION ALL SELECT 'fact_penjualan_reseller', COUNT(*) FROM fact_penjualan_reseller;

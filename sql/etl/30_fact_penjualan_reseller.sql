-- =====================================================================
--  30_fact_penjualan_reseller.sql  |  MariaDB 10.11 (kompatibel MySQL)  |  database DW
--  Grain: 1 baris = 1 produk dalam 1 pesanan reseller.
--  Filter: onlineorderflag = 0 (reseller). Lampiran memakai = 1 (online).
--
--  Semua lookup memakai LEFT JOIN + COALESCE(key, -1), padanan step
--  "Database lookup" dengan default -1 di Pentaho. JOIN biasa dilarang
--  karena baris tanpa pasangan hilang diam-diam dan rekonsiliasi gagal.
--
--  dim_produk dicari berdasarkan produk_id DAN rentang berlaku
--  (versi SCD 2 yang berlaku pada tanggal pesan).
--  Pesanan dengan currencyrateid NULL (USD) diarahkan ke baris USD
--  di dim_mata_uang (currency_rate_id = 0), lihat 26_dim_mata_uang.sql.
--
--  Measure (docs/mapping.md), dibulatkan 2 desimal per baris sesuai
--  tipe kolom fakta DECIMAL(12,2):
--    nilai_penjualan       = LineTotal (USD)
--    biaya_standar_produk  = biaya_standar versi berlaku x OrderQty
--    harga_jual_standar    = harga_jual versi berlaku x OrderQty
--    laba_kotor_reseller   = harga_jual_standar - nilai_penjualan
--    laba_kotor_perusahaan = nilai_penjualan - biaya_standar_produk
--
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO fact_penjualan_reseller (
    tanggal_pesan_key, tanggal_kirim_key, produk_key, reseller_key, sales_person_key,
    wilayah_key, promosi_key, metode_kirim_key, mata_uang_key,
    sales_order_id, sales_order_number,
    jumlah_unit, harga_satuan, nilai_penjualan,
    biaya_standar_produk, harga_jual_standar,
    laba_kotor_reseller, laba_kotor_perusahaan)
SELECT x.tanggal_pesan_key, x.tanggal_kirim_key, x.produk_key, x.reseller_key, x.sales_person_key,
       x.wilayah_key, x.promosi_key, x.metode_kirim_key, x.mata_uang_key,
       x.sales_order_id, x.sales_order_number,
       x.jumlah_unit, x.harga_satuan, x.nilai,
       x.biaya, x.harga_standar,
       x.harga_standar - x.nilai,
       x.nilai - x.biaya
FROM (
    SELECT COALESCE(tp.tanggal_key, -1)         AS tanggal_pesan_key,
           COALESCE(tk.tanggal_key, -1)         AS tanggal_kirim_key,
           COALESCE(dp.produk_key, -1)          AS produk_key,
           COALESCE(dr.reseller_key, -1)        AS reseller_key,
           COALESCE(ds.sales_person_key, -1)    AS sales_person_key,
           COALESCE(dw.wilayah_key, -1)         AS wilayah_key,
           COALESCE(dpr.promosi_key, -1)        AS promosi_key,
           COALESCE(dm.metode_kirim_key, -1)    AS metode_kirim_key,
           COALESCE(mu.mata_uang_key, -1)       AS mata_uang_key,
           h.salesorderid                       AS sales_order_id,
           COALESCE(h.salesordernumber, 'N/A')  AS sales_order_number,
           d.orderqty                           AS jumlah_unit,
           d.unitprice                          AS harga_satuan,
           ROUND(d.linetotal, 2)                                AS nilai,
           ROUND(COALESCE(dp.biaya_standar, 0) * d.orderqty, 2) AS biaya,
           ROUND(COALESCE(dp.harga_jual,    0) * d.orderqty, 2) AS harga_standar
    FROM stg_salesorderdetail d
    JOIN stg_salesorderheader h   ON h.salesorderid = d.salesorderid
    LEFT JOIN stg_customer c      ON c.customerid   = h.customerid
    LEFT JOIN dim_tanggal tp      ON tp.tanggal     = DATE(h.orderdate)
    LEFT JOIN dim_tanggal tk      ON tk.tanggal     = DATE(h.shipdate)
    LEFT JOIN dim_produk dp       ON dp.produk_id   = d.productid
                                 AND DATE(h.orderdate) BETWEEN dp.berlaku_mulai AND dp.berlaku_sampai
    LEFT JOIN dim_reseller dr     ON dr.reseller_id      = c.storeid
    LEFT JOIN dim_sales_person ds ON ds.sales_person_id  = h.salespersonid
    LEFT JOIN dim_wilayah dw      ON dw.wilayah_id       = h.territoryid
    LEFT JOIN dim_promosi dpr     ON dpr.promosi_id      = d.specialofferid
    LEFT JOIN dim_metode_kirim dm ON dm.metode_kirim_id  = h.shipmethodid
    LEFT JOIN dim_mata_uang mu    ON mu.currency_rate_id = COALESCE(h.currencyrateid, 0)
    WHERE h.onlineorderflag = 0
) x;

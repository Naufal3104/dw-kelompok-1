-- =====================================================================
--  20_dim_produk.sql  |  MariaDB 10.11 (kompatibel MySQL)  |  SCD tipe 2 dari riwayat biaya
--  Diadaptasi dari lampiran pekan 12, disesuaikan dengan dim_produk
--  kelompok 1 (sql/ddl.sql) dan docs/mapping.md.
--
--  * Satu baris per periode biaya (production_productcosthistory).
--  * Versi pertama berlaku sejak 1900-01-01 agar pesanan paling awal
--    tetap menemukan versi produk.
--  * Versi berakhir sehari sebelum versi berikutnya mulai.
--    Versi terakhir berlaku sampai 9999-12-31 dan is_current = TRUE.
--  * Produk tanpa riwayat biaya: satu versi dengan biaya/harga dari
--    stg_product (fallback, sesuai mapping).
--  * harga_jual diambil dari riwayat harga jual yang berlaku pada
--    tanggal mulai versi biaya, fallback ke stg_product.listprice.
--  * SCD 0: nomor_produk. SCD 1: nama, warna, subkategori, kategori.
--
--  Constraint UNIQUE (produk_id, berlaku_mulai) dari ddl.sql akan
--  menolak data ganda jika node ini tidak sengaja jalan berkali-kali.
--
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO dim_produk (produk_id, nama_produk, nomor_produk, warna, subkategori, kategori,
                        biaya_standar, harga_jual, berlaku_mulai, berlaku_sampai, is_current)
SELECT p.productid,
       p.name,
       p.productnumber,
       COALESCE(p.color, 'Tidak ada'),
       COALESCE(ps.name, 'Tanpa kategori'),
       COALESCE(pc.name, 'Tanpa kategori'),
       COALESCE(ch.standardcost, p.standardcost),
       COALESCE(lp.listprice, p.listprice),
       CASE WHEN ROW_NUMBER() OVER (PARTITION BY p.productid ORDER BY ch.startdate) = 1
            THEN DATE '1900-01-01'
            ELSE DATE(ch.startdate)
       END,
       COALESCE(DATE(LEAD(ch.startdate) OVER (PARTITION BY p.productid ORDER BY ch.startdate))
                - INTERVAL 1 DAY,
                DATE '9999-12-31'),
       LEAD(ch.startdate) OVER (PARTITION BY p.productid ORDER BY ch.startdate) IS NULL
FROM stg_product p
LEFT JOIN stg_productsubcategory ps ON ps.productsubcategoryid = p.productsubcategoryid
LEFT JOIN stg_productcategory    pc ON pc.productcategoryid    = ps.productcategoryid
LEFT JOIN stg_productcosthistory ch ON ch.productid            = p.productid
LEFT JOIN stg_productlistpricehistory lp
       ON lp.productid  = p.productid
      AND lp.startdate <= ch.startdate
      AND (lp.enddate IS NULL OR lp.enddate >= ch.startdate);

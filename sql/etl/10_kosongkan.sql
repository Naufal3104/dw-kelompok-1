-- =====================================================================
--  10_kosongkan.sql  |  MySQL  |  database DW (db_warehouse)
--  Langkah pertama workflow. Membuat workflow aman dijalankan berulang.
--
--  Urutan wajib:
--  1. Fakta dulu (karena punya FK ke dimensi).
--  2. Dimensi, KECUALI baris key -1 "Tidak diketahui" dari ddl.sql.
--     Pakai DELETE, bukan TRUNCATE: TRUNCATE ditolak untuk tabel yang
--     dirujuk FK dan akan ikut menghapus baris -1.
--  3. Staging dengan TRUNCATE (tanpa constraint, lebih cepat).
--  dim_tanggal TIDAK disentuh (tabel standar sponsor).
--
--  Node n8n: MySQL DW, Execute Query, Settings > Execute Once = ON.
-- =====================================================================

-- 1. Fakta
DELETE FROM fact_penjualan_reseller;

-- 2. Dimensi, baris -1 dipertahankan
DELETE FROM dim_produk       WHERE produk_key       <> -1;
DELETE FROM dim_reseller     WHERE reseller_key     <> -1;
DELETE FROM dim_sales_person WHERE sales_person_key <> -1;
DELETE FROM dim_wilayah      WHERE wilayah_key      <> -1;
DELETE FROM dim_promosi      WHERE promosi_key      <> -1;
DELETE FROM dim_metode_kirim WHERE metode_kirim_key <> -1;
DELETE FROM dim_mata_uang    WHERE mata_uang_key    <> -1;

-- 3. Staging
TRUNCATE TABLE stg_salesorderheader;
TRUNCATE TABLE stg_salesorderdetail;
TRUNCATE TABLE stg_product;
TRUNCATE TABLE stg_productsubcategory;
TRUNCATE TABLE stg_productcategory;
TRUNCATE TABLE stg_productcosthistory;
TRUNCATE TABLE stg_productlistpricehistory;
TRUNCATE TABLE stg_store;
TRUNCATE TABLE stg_customer;
TRUNCATE TABLE stg_salesperson;
TRUNCATE TABLE stg_person;
TRUNCATE TABLE stg_salesterritory;
TRUNCATE TABLE stg_specialoffer;
TRUNCATE TABLE stg_shipmethod;
TRUNCATE TABLE stg_currencyrate;

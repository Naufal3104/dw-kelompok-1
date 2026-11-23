-- =====================================================================
--  41_cek_staging_vs_sumber.sql  |  MySQL  |  jalankan di DBX
--  Bukti tugas "Jumlah baris setiap tabel staging sama dengan sumber".
--  Kolom 'cocok' harus 'YA' untuk ke-15 tabel.
-- =====================================================================

SELECT tabel, sumber, staging, IF(sumber = staging, 'YA', 'TIDAK') AS cocok
FROM (
    SELECT 'stg_salesorderheader' AS tabel,
           (SELECT COUNT(*) FROM adventureworks2.sales_salesorderheader) AS sumber,
           (SELECT COUNT(*) FROM db_warehouse.stg_salesorderheader)     AS staging
    UNION ALL SELECT 'stg_salesorderdetail',
           (SELECT COUNT(*) FROM adventureworks2.sales_salesorderdetail),
           (SELECT COUNT(*) FROM db_warehouse.stg_salesorderdetail)
    UNION ALL SELECT 'stg_product',
           (SELECT COUNT(*) FROM adventureworks2.production_product),
           (SELECT COUNT(*) FROM db_warehouse.stg_product)
    UNION ALL SELECT 'stg_productsubcategory',
           (SELECT COUNT(*) FROM adventureworks2.production_productsubcategory),
           (SELECT COUNT(*) FROM db_warehouse.stg_productsubcategory)
    UNION ALL SELECT 'stg_productcategory',
           (SELECT COUNT(*) FROM adventureworks2.production_productcategory),
           (SELECT COUNT(*) FROM db_warehouse.stg_productcategory)
    UNION ALL SELECT 'stg_productcosthistory',
           (SELECT COUNT(*) FROM adventureworks2.production_productcosthistory),
           (SELECT COUNT(*) FROM db_warehouse.stg_productcosthistory)
    UNION ALL SELECT 'stg_productlistpricehistory',
           (SELECT COUNT(*) FROM adventureworks2.production_productlistpricehistory),
           (SELECT COUNT(*) FROM db_warehouse.stg_productlistpricehistory)
    UNION ALL SELECT 'stg_store',
           (SELECT COUNT(*) FROM adventureworks2.sales_store),
           (SELECT COUNT(*) FROM db_warehouse.stg_store)
    UNION ALL SELECT 'stg_customer',
           (SELECT COUNT(*) FROM adventureworks2.sales_customer),
           (SELECT COUNT(*) FROM db_warehouse.stg_customer)
    UNION ALL SELECT 'stg_salesperson',
           (SELECT COUNT(*) FROM adventureworks2.sales_salesperson),
           (SELECT COUNT(*) FROM db_warehouse.stg_salesperson)
    UNION ALL SELECT 'stg_person',
           (SELECT COUNT(*) FROM adventureworks2.person_person),
           (SELECT COUNT(*) FROM db_warehouse.stg_person)
    UNION ALL SELECT 'stg_salesterritory',
           (SELECT COUNT(*) FROM adventureworks2.sales_salesterritory),
           (SELECT COUNT(*) FROM db_warehouse.stg_salesterritory)
    UNION ALL SELECT 'stg_specialoffer',
           (SELECT COUNT(*) FROM adventureworks2.sales_specialoffer),
           (SELECT COUNT(*) FROM db_warehouse.stg_specialoffer)
    UNION ALL SELECT 'stg_shipmethod',
           (SELECT COUNT(*) FROM adventureworks2.purchasing_shipmethod),
           (SELECT COUNT(*) FROM db_warehouse.stg_shipmethod)
    UNION ALL SELECT 'stg_currencyrate',
           (SELECT COUNT(*) FROM adventureworks2.sales_currencyrate),
           (SELECT COUNT(*) FROM db_warehouse.stg_currencyrate)
) t;

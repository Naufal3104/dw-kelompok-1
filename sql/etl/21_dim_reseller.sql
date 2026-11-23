-- =====================================================================
--  21_dim_reseller.sql  |  MySQL  |  SCD tipe 1
--  Sumber: stg_store (kolom Demographics berisi XML StoreSurvey).
--  reseller_id = BusinessEntityID toko = sales_customer.StoreID.
--
--  ExtractValue memakai '//Elemen' supaya tidak terganggu namespace
--  xmlns pada elemen <StoreSurvey>. Nilai kosong dijadikan NULL lalu
--  diberi default sesuai docs/mapping.md.
--
--  Kode BusinessType mengikuti AdventureWorksDW:
--  BM = Value Added Reseller, BS = Specialty Bike Shop, OS = Warehouse.
--  Cek dulu dengan:  SELECT DISTINCT ExtractValue(demographics,'//BusinessType') FROM stg_store;
--
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO dim_reseller (reseller_id, nama_reseller, tipe_bisnis,
                          penjualan_tahunan, jumlah_karyawan, tahun_buka)
SELECT x.businessentityid,
       x.name,
       CASE x.kode_bisnis
            WHEN 'BM' THEN 'Value Added Reseller'
            WHEN 'BS' THEN 'Specialty Bike Shop'
            WHEN 'OS' THEN 'Warehouse'
            ELSE COALESCE(x.kode_bisnis, 'Tidak diketahui')
       END,
       COALESCE(CAST(x.penjualan AS DECIMAL(15,2)), 0),
       COALESCE(CAST(x.karyawan  AS SIGNED), 0),
       COALESCE(CAST(x.tahun     AS SIGNED), -1)
FROM (
    SELECT s.businessentityid,
           s.name,
           NULLIF(TRIM(ExtractValue(s.demographics, '//BusinessType')),    '') AS kode_bisnis,
           NULLIF(TRIM(ExtractValue(s.demographics, '//AnnualSales')),     '') AS penjualan,
           NULLIF(TRIM(ExtractValue(s.demographics, '//NumberEmployees')), '') AS karyawan,
           NULLIF(TRIM(ExtractValue(s.demographics, '//YearOpened')),      '') AS tahun
    FROM stg_store s
) x;

-- =====================================================================
--  22_dim_sales_person.sql  |  MySQL  |  SCD tipe 1
--  Sumber: stg_salesperson + stg_person (nama lengkap).
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO dim_sales_person (sales_person_id, nama_lengkap, komisi_persen, kuota_penjualan)
SELECT sp.businessentityid,
       COALESCE(CONCAT(pe.firstname, ' ', pe.lastname), 'Tidak diketahui'),
       COALESCE(sp.commissionpct, 0),
       COALESCE(sp.salesquota, 0)
FROM stg_salesperson sp
LEFT JOIN stg_person pe ON pe.businessentityid = sp.businessentityid;

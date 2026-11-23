-- =====================================================================
--  23_dim_wilayah.sql  |  MySQL  |  SCD tipe 1
--  Sumber: stg_salesterritory.
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO dim_wilayah (wilayah_id, nama_wilayah, kode_negara, grup)
SELECT t.territoryid,
       COALESCE(t.name, 'Tidak diketahui'),
       COALESCE(t.countryregioncode, 'N/A'),
       COALESCE(t.`group`, 'Tidak diketahui')
FROM stg_salesterritory t;

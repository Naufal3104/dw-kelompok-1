-- =====================================================================
--  24_dim_promosi.sql  |  MySQL  |  SCD tipe 1
--  Sumber: stg_specialoffer.
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO dim_promosi (promosi_id, deskripsi, jenis, kategori, persentase_diskon, mulai, selesai)
SELECT so.specialofferid,
       COALESCE(so.description, 'Tidak ada promosi'),
       COALESCE(so.type, 'N/A'),
       COALESCE(so.category, 'N/A'),
       COALESCE(so.discountpct, 0),
       COALESCE(DATE(so.startdate), DATE '1900-01-01'),
       COALESCE(DATE(so.enddate),   DATE '9999-12-31')
FROM stg_specialoffer so;

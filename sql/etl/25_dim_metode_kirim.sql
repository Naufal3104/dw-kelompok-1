-- =====================================================================
--  25_dim_metode_kirim.sql  |  MySQL  |  SCD tipe 1
--  Sumber: stg_shipmethod.
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO dim_metode_kirim (metode_kirim_id, nama_metode, biaya_dasar, tarif)
SELECT sm.shipmethodid,
       COALESCE(sm.name, 'Tidak diketahui'),
       COALESCE(sm.shipbase, 0),
       COALESCE(sm.shiprate, 0)
FROM stg_shipmethod sm;

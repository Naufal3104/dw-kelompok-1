-- =====================================================================
--  26_dim_mata_uang.sql  |  MySQL  |  SCD tipe 1
--  Sumber: stg_currencyrate, ditambah satu baris transaksi USD.
--
--  Pesanan dengan CurrencyRateID NULL adalah transaksi USD tanpa
--  konversi. Pesanan itu diarahkan ke baris USD (bukan ke -1), sesuai
--  docs/mapping.md. Baris USD memakai currency_rate_id = 0 supaya:
--    - tidak bentrok dengan baris -1 "Tidak diketahui",
--    - tetap dijaga constraint UNIQUE (NULL tidak dijaga UNIQUE,
--      sehingga baris USD bisa ganda tanpa ketahuan).
--  Fakta mencarinya dengan COALESCE(currencyrateid, 0).
--
--  Kedua perintah boleh satu node. Jika node menolak multi-statement,
--  pecah menjadi dua node berurutan.
--  Node n8n: MySQL DW, Execute Query, Execute Once = ON.
-- =====================================================================

INSERT INTO dim_mata_uang (currency_rate_id, kode_asal, kode_tujuan,
                           tanggal_kurs, average_rate, end_of_day_rate)
VALUES (0, 'USD', 'USD', DATE '1900-01-01', 1, 1);

INSERT INTO dim_mata_uang (currency_rate_id, kode_asal, kode_tujuan,
                           tanggal_kurs, average_rate, end_of_day_rate)
SELECT cr.currencyrateid,
       COALESCE(cr.fromcurrencycode, 'USD'),
       COALESCE(cr.tocurrencycode, 'USD'),
       COALESCE(DATE(cr.currencyratedate), DATE '1900-01-01'),
       COALESCE(cr.averagerate, 1),
       COALESCE(cr.endofdayrate, 1)
FROM stg_currencyrate cr;

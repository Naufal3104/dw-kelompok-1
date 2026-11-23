# Catatan Perbandingan: ELT n8n + SQL vs ETL Pentaho

Kelompok      : 1
Proses bisnis : Penjualan Reseller

---

## Pekan 13

**Jalur n8n: memindahkan data, lalu mengolahnya dengan SQL**


| No | Aspek | n8n + SQL | Pentaho |
|----|-------|-----------|---------|
| 1 | Keterbacaan logika | Seluruh transformasi tertulis di file `.sql` dan bisa dibaca dari atas ke bawah | Logika tersebar di banyak step dan harus dibuka satu per satu |
| 2 | Kolaborasi lewat Git | Perubahan skrip bisa dibandingkan baris per baris dengan `git diff` | File `.ktr`/`.kjb` berupa XML panjang yang sulit di-review |
| 3 | Lookup dimensi | Cukup `LEFT JOIN ... COALESCE(key, -1)` di `30_fact_penjualan_reseller.sql` | Perlu step *Database lookup* untuk setiap dimensi |
| 4 | Pengujian | Query bisa langsung dijalankan dan dicek di DBeaver / DBX | Harus menjalankan transformasi atau job |
| 5 | Beban perangkat | n8n berjalan ringan di Docker | Spoon berat dijalankan |
| 6 | Tempat pemrosesan | Join dan agregasi dikerjakan oleh MariaDB | Data ditarik ke memori aplikasi ETL |

### Yang lebih sulit dengan SQL

| No | Aspek | n8n + SQL | Pentaho |
|----|-------|-----------|---------|
| 1 | Tabel staging | 15 tabel `stg_*` ditulis manual di `00_staging_ddl.sql` | Tabel target bisa dibuat otomatis |
| 2 | Tipe data dan zona waktu | Tanggal diubah ke teks dengan `DATE_FORMAT` dan dikunci ke UTC+8, desimal diubah dengan `CAST(... AS CHAR)` agar tidak bergeser atau dibulatkan oleh JavaScript | Tipe data ditangani secara bawaan |
| 3 | Tabel besar | `salesorderheader` dan `salesorderdetail` dibaca per 5000 baris dengan node *Loop Over Items* | Aliran baris diatur otomatis |
| 4 | SCD tipe 2 | Rentang `berlaku_mulai`/`berlaku_sampai` dan `is_current` dihitung manual dengan `ROW_NUMBER()` dan `LEAD()` (`20_dim_produk.sql`) | Tersedia step *Dimension lookup/update* |
| 5 | Kesalahan JOIN | `JOIN` biasa bisa menghilangkan baris tanpa error, jadi wajib dicek dengan `40_rekonsiliasi.sql` | Baris yang gagal lookup lebih mudah terlihat |

### Kesimpulan pekan 13

SQL lebih mudah dibaca, di-review, dan dikerjakan bersama. Namun banyak hal yang di Pentaho sudah otomatis (pembuatan tabel, tipe data, batch, SCD 2) harus ditulis dan uji sendiri, sehingga rekonsiliasi menjadi langkah wajib di jalur SQL.

---

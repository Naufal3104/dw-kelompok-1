# Laporan Progres Pekan 13
Kelompok      : 1
Proses bisnis : Penjualan Reseller
Status        : Hijau

## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Pasang n8n di VPS dengan versi yang dikunci (2.44.7) dan zona waktu UTC | ✓ Selesai | [etl/docker-compose.yml](../etl/docker-compose.yml) (`ac49775`) |
| Skrip DDL staging dan query ekstrak dari `adventureworks2` (tabel besar dibaca per batch 5000 baris) | ✓ Selesai | [sql/etl/00_staging_ddl.sql](../sql/etl/00_staging_ddl.sql), [sql/etl/01_ekstrak_mysql.sql](../sql/etl/01_ekstrak_mysql.sql) (`218fd57`, `ca0e367`) |
| Workflow n8n ELT Penjualan Reseller (kosongkan, ekstrak ke staging, dimensi, fakta) dan ekspor ke repositori | ✓ Selesai | [etl/Kelompok 1 - ELT Penjualan Reseller (versi B).json](../etl/Kelompok%201%20-%20ELT%20Penjualan%20Reseller%20(versi%20B).json) (`5ddae4b`) |
| Transformasi SQL 7 dimensi (`20`–`26`) dan fakta `fact_penjualan_reseller` (`30`), termasuk langkah kosongkan agar aman dijalankan berulang (`10`) | ✓ Selesai | [sql/etl/](../sql/etl/) (`a45bd45`) |
| Bukti SCD tipe 2 pada `dim_produk` | ✓ Selesai | [docs/bukti scd tipe 2.png](../docs/bukti%20scd%20tipe%202.png) (`f877cd7`) |
| Rekonsiliasi sumber, staging, dan fakta (jumlah baris dan total penjualan) serta bukti workflow dijalankan 2x | ✓ Selesai | [sql/etl/40_rekonsiliasi.sql](../sql/etl/40_rekonsiliasi.sql), [docs/Bukti Rekonsiliasi.png](../docs/Bukti%20Rekonsiliasi.png), [docs/Bukti Dijalankan 2x.jpg](../docs/Bukti%20Dijalankan%202x.jpg) (`315dfaf`, `96c56b0`) |
| Cek jumlah baris 15 tabel staging sama dengan sumber dan uji zona waktu | ✓ Selesai | [sql/etl/41_cek_staging_vs_sumber.sql](../sql/etl/41_cek_staging_vs_sumber.sql), [docs/uji-zona-waktu.png](../docs/uji-zona-waktu.png) (`a7c33f9`) |
| Catatan perbandingan n8n + SQL dengan Pentaho | ✓ Selesai | [docs/perbandingan-n8n-vs-pentaho.md](../docs/perbandingan-n8n-vs-pentaho.md) (`dafe0f7`) |
| Laporan progres pekan 13 | ✓ Selesai | [laporan/pekan-13.md](pekan-13.md) |

## 2. Kendala pengerjaan
| Kendala | Penanganan |
|---------|------------|
| Bingung di setup dan pembuatan workspace n8n | Setelah benar benar memahami proses yang diperlukan dan dibantu dengan anggota tim yang mengerti sehingga mempermudah dan berhasil |

## 3. Kendala tim

## 4. Keputusan yang butuh persetujuan sponsor

## 5. Rencana pekan depan
| Target | Penanggung jawab |
|--------|-----------------|
| `olap/schema.xml` sesuai tabel desain cube pekan 10 (`docs/desain-cube.md`), tanpa elemen merah di Schema Workbench | OLAP Developer |
| Dimensi Waktu didefinisikan di tingkat Schema dan dipakai cube lewat `DimensionUsage` | OLAP Developer |
| Minimal satu calculated member (misalnya margin persen atau harga rata-rata) | OLAP Developer |
| Minimal 5 query MDX di `olap/query.mdx`, setiap query diberi nomor pertanyaan bisnis yang dijawabnya | Data Modeler |
| Bukti MDX sama dengan SQL: tangkapan layar hasil MDX dan hasil SQL pembanding untuk setiap query | ETL/ELT Developer, Dashboard Developer |
| Laporan pekan 14 untuk Steering Review, termasuk pertanyaan bisnis yang belum bisa dijawab cube | Project Manager |

## 6. Kontribusi anggota
| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Ragil Hidayatulloh | Project Manager | Koordinasi tim, merapikan lokasi skrip rekonsiliasi, catatan perbandingan `docs/perbandingan-n8n-vs-pentaho.md`, dan menyusun `laporan/pekan-13.md` | `perbandingan n8n vs pentaho - pekan 13` & `laporan pekan 13` |
| Flaody Nayaka Zedha Priyambudi | Data Modeler | Skrip transformasi 7 dimensi dan fakta (`sql/etl/10`–`30`) serta bukti SCD tipe 2 `dim_produk` | `transformasi dimensi dan fakta sql` & `bukti scd tipe 2` |
| Jonatan Risa Siswanto | ETL/ELT Developer | Pemasangan n8n (`etl/docker-compose.yml`), DDL staging, query ekstrak, dan ekspor workflow n8n | `docker-compose n8n` & `staging & ekstrak` & `ekspor workflow n8n` |
| Raka Hanasta Syahrafi | OLAP Developer | Menjalankan skrip rekonsiliasi sumber, staging, dan fakta beserta bukti workflow dijalankan 2x | `Rekonsiliasi 2x` |
| Achmad Naufal Ferdiansyah | Dashboard Developer | Cek jumlah baris staging vs sumber dan uji zona waktu | `uji zona waktu` |

---

## Lampiran

### Link Repositori
`https://github.com/Naufal3104/dw-kelompok-1`

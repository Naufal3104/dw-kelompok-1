# Laporan Progres Pekan 12
Kelompok      : 1
Proses bisnis : Penjualan Reseller
Status        : Hijau

## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Pasang `dim_tanggal` standar v1.0 dan simpan hasil query pemeriksaan | ✓ Selesai | [docs/dim_tanggal.md](../docs/dim_tanggal.md), [Tes1.jpeg](../docs/Tes1.jpeg), [Tes2.jpeg](../docs/Tes2.jpeg), [Tes3.jpeg](../docs/Tes3.jpeg) (`efff075`) |
| Tulis `sql/ddl.sql` (7 dimensi + fakta, baris `-1`, FK constraint, idempoten 2x jalan) | ✓ Selesai | [sql/ddl.sql](../sql/ddl.sql) (`ad66380`) |
| Uji constraint (FK, CHECK, PK) dan simpan tangkapan layar pesan error | ✓ Selesai | [docs/uji-constraint.md](../docs/uji-constraint.md), [Hasil Uji Constraint 1.png](../docs/Hasil%20Uji%20Constraint%201.png), [2.png](../docs/Hasil%20Uji%20Constraint%202.png), [3.1.png](../docs/Hasil%20Uji%20Constraint%203.1.png), [3.2.png](../docs/Hasil%20Uji%20Constraint%203.2.png) (`407cc02`) |
| Kamus data seluruh tabel DW termasuk penjelasan `dim_tanggal` | ✓ Selesai | [docs/kamus-data.md](../docs/kamus-data.md) (`8b6fae9`) |
| ERD hasil reverse engineering dari database DW dan perbandingan dengan Star Schema v2 | ✓ Selesai | [docs/ER Diagram Hasil Reverse Enginering.png](../docs/ER%20Diagram%20Hasil%20Reverse%20Enginering.png), [docs/star-schema-v2.png](../docs/star-schema-v2.png) (`42ab2e4`) |
| Daftar tabel staging di dokumen mapping serta sinkronisasi cube dan urutan load | ✓ Selesai | [docs/mapping.md](../docs/mapping.md), [docs/desain-cube.md](../docs/desain-cube.md), [docs/urutan-load.md](../docs/urutan-load.md) (`0372150`) |
| Jalur n8n: buat dan jalankan skrip DDL staging (`sql/00_staging_ddl.sql`) | ✓ Selesai | [sql/00_staging_ddl.sql](../sql/00_staging_ddl.sql) (`ad66380`) |
| Laporan progres pekan 12 beserta permintaan perubahan jalur n8n (`CR-01`) | ✓ Selesai | [laporan/pekan-12.md](pekan-12.md) |

## 2. Kendala pengerjaan
**-**

## 3. Kendala tim
Belum ada kendala tim. Pembagian tugas berjalan dengan baik, komunikasi lancar, dan seluruh anggota aktif melakukan commit progres ke repositori.

## 4. Keputusan yang butuh persetujuan sponsor
Sesuai kesepakatan dengan sponsor untuk penggunaan jalur n8n (ELT), berikut catatan permintaan perubahan desain yang diajukan oleh Kelompok 1:

## Permintaan Perubahan Desain (CR-01)
Kelompok      : 1 (Penjualan Reseller)
Tanggal       : 16 November 2026
Yang diubah   : pipeline load data dari ETL (Pentaho Data Integration) menjadi ELT menggunakan n8n + DDL tabel staging manual (`sql/00_staging_ddl.sql`).
Alasan        : Pentaho PDI terasa berat saat dijalankan dan tidak mendukung kolaborasi tim secara langsung, sedangkan n8n lebih ringan dan mendukung kolaborasi tim secara real-time, serta memungkinkan transformasi SQL yang transparan dan eksplisit langsung di database DW (`db_warehouse`).
Dampak        : 
- Bagian ETL/ELT : Pembuatan 15 tabel staging (`stg_*`) dimajukan ke Pekan 11 melalui `sql/00_staging_ddl.sql` dan didokumentasikan tipe datanya di `docs/kamus-data.md` karena n8n tidak men-generate tabel staging otomatis seperti Pentaho. Selanjutnya seluruh alur ELT—mulai dari ekstraksi `adventureworks2` ke `stg_*`, transformasi SCD dimensi, hingga load `fact_penjualan_reseller` di `db_warehouse` dieksekusi dan diorkestrasi langsung di dalam workflow **n8n** (menggunakan node MySQL/SQL dan node transformasi n8n).
- Bagian Cube    : Tidak mengubah struktur dimensi, hierarki, maupun measure pada rancangan cube (`docs/desain-cube.md`).
Keputusan     : 

## 5. Rencana pekan depan
| Target | Penanggung jawab |
|--------|-----------------|
| Skrip DDL data warehouse di `sql/ddl.sql` | ETL/ELT Developer |
| Surrogate key, foreign key, dan index terpasang | ETL/ELT Developer |
| `dim_tanggal` standar terpasang dan dijelaskan di kamus data | Data Modeler |
| Baris `"Tidak diketahui"` di setiap dimensi | ETL/ELT Developer |
| Kamus data untuk setiap tabel | Data Modeler

## 6. Kontribusi anggota
| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Ragil Hidayatulloh | Project Manager | Koordinasi tim, sinkronisasi `docs/desain-cube.md`, `docs/mapping.md`, `docs/urutan-load.md`, dan menyusun `laporan/pekan-12.md` | `Perbaikan Minor biar sinkron` & `laporan pekan 12` |
| Flaody Nayaka Zedha Priyambudi | Data Modeler | Verifikasi `dim_tanggal` (`docs/dim_tanggal.md`, `Tes1.jpeg`–`Tes3.jpeg`) dan penyusunan kamus data `docs/kamus-data.md` | `uji dim_tanggal` & `kamus data` |
| Jonatan Risa Siswanto | ETL/ELT Developer | Implementasi `sql/ddl.sql` dan penyesuaian DDL staging `sql/00_staging_ddl.sql` | `Menambahkan ddl + stagging` |
| Raka Hanasta Syahrafi | OLAP Developer | Screenshot ERD dari DBX hasil reverse engineering database DW dan dibandingkan kesesuaian dengan Star Schema v2 | `ERD Hasil Reverse Enginering` |
| Achmad Naufal Ferdiansyah | Dashboard Developer | Pelaksanaan 3 uji constraint (FK, CHECK, PK) beserta dokumentasi dan tangkapan layar error | `uji constraint` |

---

## Lampiran

### Link Repositori
`https://github.com/Naufal3104/dw-kelompok-1`

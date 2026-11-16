# Laporan Progres Pekan 11
Kelompok      : 1
Proses bisnis : Penjualan Reseller
Status        : Kuning

## 1. Target dan capaian

| Target pekan ini | Status | Bukti |
|------------------|--------|-------|
| Star schema versi 2 diperbaiki sesuai catatan sponsor | ✓ Selesai | `docs/star-schema.md`, `docs/star-schema-v2.png` |
| `dim_tanggal` standar dipakai apa adanya, `dim_produk` mengikuti struktur standar | ✓ Selesai | `docs/star-schema.md`, `docs/mapping.md` bagian 2 |
| Source-to-target mapping lengkap semua kolom dimensi dan fakta | ✓ Selesai | `docs/mapping.md` |
| Strategi SCD tiap dimensi, minimal satu dimensi tipe 2 | ✓ Selesai | `docs/scd.md`, `docs/mapping.md` bagian 4 |
| Urutan load dari staging sampai fakta | ✓ Selesai | `docs/urutan-load.md`, `docs/mapping.md` bagian 6 |
| Desain cube dengan minimal satu calculated member | ✓ Selesai | `docs/cube.md` |
| Wireframe dashboard dengan nomor pertanyaan bisnis | ✓ Selesai | `docs/wireframe-dashboard.png` |
| Uji Pentaho: koneksi ke database sumber dan satu Table Input | ✓ Selesai | `docs/uji pentaho.png` |
| Laporan pekan 11 | ✓ Selesai | `laporan/pekan-11.md` |


## 2. Kendala pengerjaan

### Teknis

**-**

### Solusi yang akan dilakukan

**-**

## 3. Kendala tim

**-**

## 4. Keputusan yang butuh persetujuan sponsor

**-**

## 5. Rencana pekan depan

| Target | Penanggung jawab |
|--------|-----------------|
| Finalisasi desain cube ke `docs/cube.md` dan pemetaan Mondrian | OLAP Developer |
| Wireframe dashboard dua halaman bernomor P1 sampai P7 | Dashboard Developer |
| Update diagram star schema v2 | Data Modeler |
| DDL 9 tabel DW, 8 baris `-1` (satu per dimensi), dan tabel `stg_*` | Data Modeler |
| Bangun job Pentaho untuk seluruh dimensi | ETL Developer |
| Load fakta, hitung measure, dan rekonsiliasi | ETL Developer |
| Minta skrip `dim_tanggal` dan grant `dw_kelompok_1` | Project Manager |
| Review silang mapping sebelum implementasi | Project Manager |

## 6. Kontribusi anggota

| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Ragil Hidayatulloh | Project Manager | Koordinasi pekan 11, menyusun laporan progres, dan Source-to-target mapping lengkap | `laporan dan mapping` |
| Flaody Nayaka Zedha Priyambudi | Data Modeler | Star schema v2 dan strategi SCD | `update star schema v2 & scd` |
| Jonatan Risa Siswanto | ETL Developer | Membuat urutan load dan Uji Pentaho, koneksi ke `adventureworks2`, uji Table Input, profil data sumber | `urutan load data` |
| Raka Hanasta Syahrafi | OLAP Developer | Analisis ketersediaan measure dan desain cube | `desain cube` |
| Achmad Naufal Ferdiansyah | Dashboard Developer | Membuat wireframe dashboard | `Wireframe Dashboard` & `Redesigning dashboard wireframe` & `wireframe mockup` |

---

## Lampiran

### Link Repositori
`https://github.com/Naufal3104/dw-kelompok-1`
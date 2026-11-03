# Piagam Proyek Data Warehouse
Kelompok      : 1
Proses bisnis : Penjualan Reseller
Sponsor       : Mohamad Irwan Afandi, ST, M.Sc.

## 1. Latar belakang
Manajemen Adventure Works membutuhkan sistem analisis untuk memahami kinerja penjualan melalui saluran reseller (toko-toko yang menjual produk Adventure Works). Saat ini, data penjualan reseller tersebar di berbagai tabel operasional dengan struktur ternormalisasi, sehingga sulit untuk melakukan analisis cepat dan mendalam. Manajemen ingin mengetahui produk mana yang paling laris, reseller mana yang memberikan kontribusi terbesar, kinerja sales person per wilayah, dan efektivitas promosi yang dijalankan.

## 2. Tujuan dan pertanyaan bisnis
Membangun data warehouse yang dapat menjawab minimal 5 pertanyaan bisnis berikut:

| Pertanyaan bisnis | Fakta (ukuran) | Dimensi (sudut pandang) |
|---|---|---|
| Produk kategori apa yang penjualannya paling tinggi per kuartal? | Nilai penjualan | Produk (kategori), Tanggal (kuartal) |
| Reseller mana yang memberikan kontribusi penjualan terbesar per tahun? | Nilai penjualan, jumlah unit | Reseller, Tanggal (tahun) |
| Bagaimana kinerja sales person per wilayah dalam 12 bulan terakhir? | Nilai penjualan, jumlah pesanan | Sales Person, Wilayah, Tanggal |
| Promosi mana yang paling efektif dalam meningkatkan penjualan reseller? | Nilai penjualan, nilai diskon, jumlah unit | Promosi, Produk, Tanggal |
| Bagaimana tren penjualan reseller per bulan dibandingkan tahun sebelumnya? | Nilai penjualan | Tanggal (bulan, tahun), Reseller |

## 3. Ruang lingkup
**Masuk lingkup:**
- Proses bisnis: Penjualan Reseller (sales.salesorderheader dengan onlineorderflag = false)
- Rentang tahun data: Seluruh data historis yang tersedia di database Adventure Works
- Tabel sumber utama:
  - sales.salesorderheader (header pesanan reseller)
  - sales.salesorderdetail (detail pesanan)
  - sales.store (data reseller/toko)
  - sales.salesperson (data tenaga penjual)
  - sales.salesterritory (wilayah penjualan)
  - production.product (produk)
  - production.productsubcategory & productcategory (kategori produk)
  - sales.specialoffer (promosi)

**Di luar lingkup:**
- Penjualan online (onlineorderflag = true)
- Proses pembelian, produksi, dan persediaan
- Analisis profit margin detail (biaya produksi)

## 4. Tim dan peran
| Ragil Hidayatulloh | 23082010014 | Team Leader |
| Flaody Nayaka Zedha Priyambudi | 23082010104 | Data Modeler |
| Jonatan Risa Siswanto | 23082010128 | ETL Developer |
| Raka Hanasta Syahrafi | 23082010199 | OLAP Developer |
| Achmad Naufal Ferdiansyah | 23082010145 | Dashboard Developer |


## 5. Lingkungan teknis
- **Sumber:** MySQL (adventureworks2)
- **Target:** MySQL (dw_kelompok_1)
- **ETL:** Pentaho Data Integration CE
- **OLAP:** Mondrian
- **Dashboard:** Chart.js

## 6. Risiko awal
| Risiko | Dampak | Rencana penanganan |
|--------|--------|-------------------|
| Database tidak sinkron antar anggota kelompok | Tinggi - perbedaan data menyebabkan hasil analisis tidak konsisten | Menggunakan VPS untuk database agar semua anggota mengakses database yang sama |
| Sulit untuk track update dan kesalahan progress mingguan | Sedang - progress tidak terdokumentasi dengan baik | Menerapkan aturan untuk pesan commit dan staging progress yang rapi dan informatif |
| Pentaho tidak kompatibel dengan versi Java | Tinggi - ETL tidak bisa dibangun | Gunakan versi Java yang direkomendasikan (Java 8 atau 11), uji instalasi di pekan 10 |
| Kolom salespersonid banyak NULL pada pesanan reseller | Sedang - analisis per sales person tidak lengkap | Siapkan baris "Tidak diketahui" di dim_sales_person, dokumentasikan proporsi NULL di profil data |

## 7. Kriteria sukses
1. Total nilai penjualan di data warehouse sama dengan hasil query langsung ke database sumber
2. Dashboard dapat menjawab 5 pertanyaan bisnis yang ditetapkan
3. ETL dapat dijalankan ulang tanpa menghasilkan data ganda
4. Semua anggota memiliki kontribusi tercatat di repositori Git

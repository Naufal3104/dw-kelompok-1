# Desain Cube - Penjualan Reseller

---

## 1. Ketersediaan Data untuk Measure

Semua measure dihitung di ETL dan disimpan sebagai kolom di `fact_penjualan_reseller`, sehingga cube hanya melakukan agregasi.

| Measure | Sumber Data | Transformasi di ETL | Status |
|---------|-------------|---------------------|--------|
| Nilai Penjualan | `sales_salesorderdetail.LineTotal` | Langsung (USD, tanpa konversi kurs ulang) | ✅ Ada |
| Jumlah Unit | `sales_salesorderdetail.OrderQty` | Langsung | ✅ Ada |
| Harga Satuan | `sales_salesorderdetail.UnitPrice` | Langsung (nilai per unit saat transaksi; diagregasi `AVG` di cube) | ✅ Ada |
| Biaya Standar Produk | `production_productcosthistory.StandardCost` (historis) | `StandardCost` yang berlaku saat `OrderDate` × `OrderQty` | ✅ Ada |
| Harga Jual Standar | `production_productlistpricehistory.ListPrice` (historis) | `ListPrice` yang berlaku saat `OrderDate` × `OrderQty` | ✅ Ada |
| Laba Kotor Reseller | Kolom fakta di atas | `harga_jual_standar − nilai_penjualan` | ✅ Ada |
| Laba Kotor Perusahaan | Kolom fakta di atas | `nilai_penjualan − biaya_standar_produk` | ✅ Ada |
| Jumlah Pesanan | `sales_salesorderheader.SalesOrderID` | Disimpan sebagai degenerate dimension `sales_order_id` | ✅ Ada |

Aturan riwayat harga dan biaya (SCD tipe 2 pada `dim_produk`): ambil baris `*_history` dengan `StartDate <= OrderDate < COALESCE(EndDate, '9999-12-31')`. Jika tidak ada, pakai nilai `production_product` saat ini sebagai fallback (64 baris, 0,1%).

---

## 2. Dokumen Desain Cube

| Elemen | Desain Penjualan Reseller | Asal di DW |
|--------|---------------------------|------------|
| **Nama Cube** | **Penjualan Reseller** | Tabel fakta: `fact_penjualan_reseller` |
| **Dimensi** | | |
| **1. Dimensi Waktu** | Hierarki 1 (Kalender): `Tahun (tahun) > Semester (semester) > Kuartal (kuartal) > Bulan (bulan / nama_bulan) > Tanggal (tanggal)`<br>Hierarki 2 (Mingguan ISO): `Tahun (tahun) > Minggu (minggu_dalam_tahun) > Tanggal (tanggal)`<br>Atribut: `tanggal_dalam_bulan`, `hari_dalam_minggu`, `nama_hari`, `is_akhir_pekan` | `dim_tanggal` (FK utama: `tanggal_pesan_key`; FK role-playing kedua di fakta: `tanggal_kirim_key`) |
| **2. Dimensi Produk** | Hierarki: `Kategori > Subkategori > Produk`<br>Atribut: nomor_produk, warna, biaya_standar, harga_jual | `dim_produk` (FK: `produk_key`) |
| **3. Dimensi Reseller** | Hierarki: `Tipe Bisnis > Reseller`<br>Atribut: penjualan_tahunan, jumlah_karyawan, tahun_buka | `dim_reseller` (FK: `reseller_key`) |
| **4. Dimensi Sales Person** | Level: `Sales Person` (`nama_lengkap`)<br>Atribut: komisi_persen, kuota_penjualan | `dim_sales_person` (FK: `sales_person_key`) |
| **5. Dimensi Wilayah** | Hierarki: `Grup > Negara (kode_negara) > Wilayah` | `dim_wilayah` (FK: `wilayah_key`) |
| **6. Dimensi Promosi** | Hierarki 1: `Kategori Promo > Promosi`<br>Hierarki 2: `Jenis Promo > Promosi`<br>Atribut: persentase_diskon | `dim_promosi` (FK: `promosi_key`) |
| **7. Dimensi Metode Kirim** | Level: `Metode Kirim` (`nama_metode`)<br>Atribut: biaya_dasar, tarif | `dim_metode_kirim` (FK: `metode_kirim_key`) |
| **8. Dimensi Mata Uang** | Level: `Mata Uang` (`kode_tujuan`)<br>Atribut: kode_asal, average_rate, end_of_day_rate | `dim_mata_uang` (FK: `mata_uang_key`) |
| **Measure** | | |
| Nilai Penjualan | SUM | `fact_penjualan_reseller.nilai_penjualan` |
| Jumlah Unit | SUM | `fact_penjualan_reseller.jumlah_unit` |
| Harga Satuan | AVG | `fact_penjualan_reseller.harga_satuan` |
| Biaya Standar Produk | SUM | `fact_penjualan_reseller.biaya_standar_produk` |
| Harga Jual Standar | SUM | `fact_penjualan_reseller.harga_jual_standar` |
| Laba Kotor Reseller | SUM | `fact_penjualan_reseller.laba_kotor_reseller` |
| Laba Kotor Perusahaan | SUM | `fact_penjualan_reseller.laba_kotor_perusahaan` |
| Jumlah Pesanan | DISTINCT COUNT | `fact_penjualan_reseller.sales_order_id` |
| **Calculated Member** | | |
| **1. Margin Reseller %** | `[Laba Kotor Reseller] / [Harga Jual Standar]`<br>(sama dengan `[Laba Kotor Reseller] / ([Nilai Penjualan] + [Laba Kotor Reseller])`) | Persentase keuntungan reseller dari harga jual ke konsumen. Format `0.00%` |
| **2. Margin Perusahaan %** | `[Laba Kotor Perusahaan] / [Nilai Penjualan]` | Persentase keuntungan perusahaan dari omzet. Format `0.00%` |
| **3. Selisih Harga Reseller %** | `([Harga Jual Standar] - [Nilai Penjualan]) / [Harga Jual Standar]` | Persentase selisih/potongan harga jual reseller terhadap harga jual standar (`ListPrice`). Format `0.00%` |
| **4. Rata-rata Nilai Order** | `[Nilai Penjualan] / [Jumlah Pesanan]` | Rata-rata omzet per pesanan. Format `#,##0.00` |

Catatan desain:
- Dimensi waktu utama pada cube terhubung lewat `tanggal_pesan_key`, sedangkan `tanggal_kirim_key` tersedia di `fact_penjualan_reseller` sebagai FK *role-playing* kedua untuk kebutuhan analisis waktu pengiriman. Kolom `tanggal_jatuh_tempo_key` tidak digunakan pada Star Schema v2.
- `dim_tanggal` memakai struktur standar sponsor apa adanya tanpa mengubah maupun menambah kolom (12 kolom, 2.192 baris: `2010-01-01` s.d. `2015-12-31` dan baris `-1` pada `1900-01-01`). Ke-12 kolom standar (`tanggal_key`, `tanggal`, `tahun`, `semester`, `kuartal`, `bulan`, `nama_bulan`, `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`, `nama_hari`, `is_akhir_pekan`) sudah mencukupi seluruh hierarki dan atribut waktu cube. Jika di kemudian hari dibutuhkan atribut kalender tambahan (misalnya penanda hari libur nasional), atribut tersebut diletakkan di tabel tambahan terpisah (mis. `dim_tanggal_libur`) yang terhubung lewat `tanggal_key`.
- Persentase memakai `formatString` Mondrian, jadi rumus tidak dikali 100.
- Setiap dimensi punya baris `*_key = -1` ("Tidak diketahui"/"Tidak ada"), sehingga semua baris fakta tetap masuk agregasi.

---

## 3. Pertanyaan yang Dijawab Cube

Laba reseller dan laba perusahaan **per produk**, **per tanggal**, **per hari**, **per minggu**, **per bulan**, **per kuartal**, dan **per tahun**. Semuanya tersedia dari hierarki Dimensi Waktu dan Dimensi Produk tanpa SQL tambahan.

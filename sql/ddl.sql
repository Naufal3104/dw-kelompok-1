-- ddl.sql  |  MySQL 8.0+  |  Kelompok 1 - Penjualan Reseller (Star Schema v2)
-- Jalankan SETELAH dim_tanggal standar terpasang.
-- Catatan: dim_tanggal dipasang terpisah dengan skrip standar sponsor dan tidak ikut dihapus.

-- 1. Hapus dengan urutan terbalik: fakta dulu, lalu dimensi
DROP TABLE IF EXISTS fact_penjualan_reseller;
DROP TABLE IF EXISTS dim_produk;
DROP TABLE IF EXISTS dim_reseller;
DROP TABLE IF EXISTS dim_sales_person;
DROP TABLE IF EXISTS dim_wilayah;
DROP TABLE IF EXISTS dim_promosi;
DROP TABLE IF EXISTS dim_metode_kirim;
DROP TABLE IF EXISTS dim_mata_uang;

-- 2. Dimensi
CREATE TABLE dim_produk (
    produk_key      INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    produk_id       INT           NOT NULL,
    nama_produk     VARCHAR(50)   NOT NULL,
    nomor_produk    VARCHAR(25)   NOT NULL,
    warna           VARCHAR(15)   NOT NULL,
    subkategori     VARCHAR(50)   NOT NULL,
    kategori        VARCHAR(50)   NOT NULL,
    biaya_standar   DECIMAL(12,4) NOT NULL,
    harga_jual      DECIMAL(12,4) NOT NULL,
    berlaku_mulai   DATE          NOT NULL,
    berlaku_sampai  DATE          NOT NULL,
    is_current      BOOLEAN       NOT NULL,
    CONSTRAINT uq_produk_versi UNIQUE (produk_id, berlaku_mulai)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE dim_reseller (
    reseller_key      INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    reseller_id       INT           NOT NULL UNIQUE,
    nama_reseller     VARCHAR(100)  NOT NULL,
    tipe_bisnis       VARCHAR(50)   NOT NULL,
    penjualan_tahunan DECIMAL(15,2) NOT NULL,
    jumlah_karyawan   INT           NOT NULL,
    tahun_buka        INT           NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE dim_sales_person (
    sales_person_key INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sales_person_id  INT           NOT NULL UNIQUE,
    nama_lengkap     VARCHAR(100)  NOT NULL,
    komisi_persen    DECIMAL(10,4) NOT NULL,
    kuota_penjualan  DECIMAL(15,2) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE dim_wilayah (
    wilayah_key  INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    wilayah_id   INT         NOT NULL UNIQUE,
    nama_wilayah VARCHAR(50) NOT NULL,
    kode_negara  VARCHAR(3)  NOT NULL,
    grup         VARCHAR(50) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE dim_promosi (
    promosi_key       INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    promosi_id        INT           NOT NULL UNIQUE,
    deskripsi         VARCHAR(255)  NOT NULL,
    jenis             VARCHAR(50)   NOT NULL,
    kategori          VARCHAR(50)   NOT NULL,
    persentase_diskon DECIMAL(10,4) NOT NULL,
    mulai             DATE          NOT NULL,
    selesai           DATE          NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE dim_metode_kirim (
    metode_kirim_key INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    metode_kirim_id  INT           NOT NULL UNIQUE,
    nama_metode      VARCHAR(50)   NOT NULL,
    biaya_dasar      DECIMAL(10,4) NOT NULL,
    tarif            DECIMAL(10,4) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE dim_mata_uang (
    mata_uang_key    INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    currency_rate_id INT           UNIQUE,
    kode_asal        VARCHAR(3)    NOT NULL,
    kode_tujuan      VARCHAR(3)    NOT NULL,
    tanggal_kurs     DATE          NOT NULL,
    average_rate     DECIMAL(10,4) NOT NULL,
    end_of_day_rate  DECIMAL(10,4) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3. Baris "Tidak diketahui" (key -1) di setiap dimensi
INSERT INTO dim_produk (produk_key, produk_id, nama_produk, nomor_produk, warna, subkategori, kategori,
                        biaya_standar, harga_jual, berlaku_mulai, berlaku_sampai, is_current)
VALUES (-1, -1, 'Tidak diketahui', '-', 'Tidak ada', 'Tidak diketahui', 'Tidak diketahui',
        0, 0, '1900-01-01', '9999-12-31', TRUE);

INSERT INTO dim_reseller (reseller_key, reseller_id, nama_reseller, tipe_bisnis,
                          penjualan_tahunan, jumlah_karyawan, tahun_buka)
VALUES (-1, -1, 'Tidak diketahui', 'Tidak diketahui', 0, 0, -1);

INSERT INTO dim_sales_person (sales_person_key, sales_person_id, nama_lengkap, komisi_persen, kuota_penjualan)
VALUES (-1, -1, 'Tidak diketahui', 0, 0);

INSERT INTO dim_wilayah (wilayah_key, wilayah_id, nama_wilayah, kode_negara, grup)
VALUES (-1, -1, 'Tidak diketahui', 'N/A', 'Tidak diketahui');

INSERT INTO dim_promosi (promosi_key, promosi_id, deskripsi, jenis, kategori, persentase_diskon, mulai, selesai)
VALUES (-1, -1, 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui', 0, '1900-01-01', '9999-12-31');

INSERT INTO dim_metode_kirim (metode_kirim_key, metode_kirim_id, nama_metode, biaya_dasar, tarif)
VALUES (-1, -1, 'Tidak diketahui', 0, 0);

INSERT INTO dim_mata_uang (mata_uang_key, currency_rate_id, kode_asal, kode_tujuan,
                           tanggal_kurs, average_rate, end_of_day_rate)
VALUES (-1, -1, 'N/A', 'N/A', '1900-01-01', 1, 1);

-- 4. Fakta. Di MySQL 8, REFERENCES yang ditulis di samping kolom DIABAIKAN.
--    Foreign key wajib ditulis sebagai CONSTRAINT di bawah.
CREATE TABLE fact_penjualan_reseller (
    fakta_penjualan_key   BIGINT        NOT NULL AUTO_INCREMENT,
    tanggal_pesan_key     INT           NOT NULL,
    tanggal_kirim_key     INT           NOT NULL,
    produk_key            INT           NOT NULL,
    reseller_key          INT           NOT NULL,
    sales_person_key      INT           NOT NULL,
    wilayah_key           INT           NOT NULL,
    promosi_key           INT           NOT NULL,
    metode_kirim_key      INT           NOT NULL,
    mata_uang_key         INT           NOT NULL,
    sales_order_id        INT           NOT NULL,   -- degenerate dimension
    sales_order_number    VARCHAR(25)   NOT NULL,   -- degenerate dimension
    jumlah_unit           INT           NOT NULL,
    harga_satuan          DECIMAL(12,4) NOT NULL,
    nilai_penjualan       DECIMAL(12,2) NOT NULL,
    biaya_standar_produk  DECIMAL(12,2) NOT NULL,
    harga_jual_standar    DECIMAL(12,2) NOT NULL,
    laba_kotor_reseller   DECIMAL(12,2) NOT NULL,
    laba_kotor_perusahaan DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (fakta_penjualan_key),
    CONSTRAINT ck_fpr_unit        CHECK (jumlah_unit > 0),
    CONSTRAINT fk_fpr_tgl_pesan   FOREIGN KEY (tanggal_pesan_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fpr_tgl_kirim   FOREIGN KEY (tanggal_kirim_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fpr_produk      FOREIGN KEY (produk_key)        REFERENCES dim_produk (produk_key),
    CONSTRAINT fk_fpr_reseller    FOREIGN KEY (reseller_key)      REFERENCES dim_reseller (reseller_key),
    CONSTRAINT fk_fpr_sales       FOREIGN KEY (sales_person_key)  REFERENCES dim_sales_person (sales_person_key),
    CONSTRAINT fk_fpr_wilayah     FOREIGN KEY (wilayah_key)       REFERENCES dim_wilayah (wilayah_key),
    CONSTRAINT fk_fpr_promosi     FOREIGN KEY (promosi_key)       REFERENCES dim_promosi (promosi_key),
    CONSTRAINT fk_fpr_metode      FOREIGN KEY (metode_kirim_key)  REFERENCES dim_metode_kirim (metode_kirim_key),
    CONSTRAINT fk_fpr_mata_uang   FOREIGN KEY (mata_uang_key)     REFERENCES dim_mata_uang (mata_uang_key)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 5. Index: MySQL otomatis membuat index untuk setiap foreign key.

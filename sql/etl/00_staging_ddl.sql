-- =====================================================================
--  00_staging_ddl.sql  |  MariaDB 10.11 (kompatibel MySQL)  |  Kelompok 1 - Penjualan Reseller
--  Membuat 15 tabel staging di database DW (db_warehouse).
--  Disesuaikan dengan Star Schema v2 (docs/star-schema-v2.png) & docs/mapping.md.
--  Tanpa constraint agar proses ekstraksi mentah dari sumber berjalan cepat;
--  TRUNCATE setiap kali ETL/ELT dijalankan sebelum pengisian ulang.
--  Kolom tanggal bertipe DATETIME agar menampung nilai sumber apa adanya.
-- =====================================================================

DROP TABLE IF EXISTS stg_salesorderheader, stg_salesorderdetail,
  stg_product, stg_productsubcategory, stg_productcategory,
  stg_productcosthistory, stg_productlistpricehistory,
  stg_store, stg_customer, stg_salesperson, stg_person,
  stg_salesterritory, stg_specialoffer, stg_shipmethod, stg_currencyrate;

CREATE TABLE stg_salesorderheader (
  salesorderid      INT,
  salesordernumber  VARCHAR(25),
  orderdate         DATETIME,
  duedate           DATETIME,
  shipdate          DATETIME NULL,
  onlineorderflag   TINYINT(1),
  customerid        INT,
  salespersonid     INT NULL,
  territoryid       INT NULL,
  shipmethodid      INT,
  currencyrateid    INT NULL,
  subtotal          DECIMAL(19,4),
  taxamt            DECIMAL(19,4),
  freight           DECIMAL(19,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_salesorderdetail (
  salesorderid       INT,
  salesorderdetailid INT,
  productid          INT,
  specialofferid     INT,
  orderqty           INT,
  unitprice          DECIMAL(19,4),
  unitpricediscount  DECIMAL(19,4),
  linetotal          DECIMAL(19,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_product (
  productid            INT,
  name                 VARCHAR(50),
  productnumber        VARCHAR(25),
  color                VARCHAR(15) NULL,
  productsubcategoryid INT NULL,
  standardcost         DECIMAL(19,4),
  listprice            DECIMAL(19,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_productsubcategory (
  productsubcategoryid INT,
  productcategoryid    INT,
  name                 VARCHAR(50)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_productcategory (
  productcategoryid INT,
  name              VARCHAR(50)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_productcosthistory (
  productid    INT,
  startdate    DATETIME,
  enddate      DATETIME NULL,
  standardcost DECIMAL(19,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_productlistpricehistory (
  productid INT,
  startdate DATETIME,
  enddate   DATETIME NULL,
  listprice DECIMAL(19,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_store (
  businessentityid INT,
  name             VARCHAR(100),
  salespersonid    INT NULL,
  demographics     TEXT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_customer (
  customerid  INT,
  personid    INT NULL,
  storeid     INT NULL,
  territoryid INT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_salesperson (
  businessentityid INT,
  territoryid      INT NULL,
  salesquota       DECIMAL(19,4) NULL,
  bonus            DECIMAL(19,4),
  commissionpct    DECIMAL(10,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_person (
  businessentityid INT,
  firstname        VARCHAR(50),
  middlename       VARCHAR(50) NULL,
  lastname         VARCHAR(50)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_salesterritory (
  territoryid       INT,
  name              VARCHAR(50),
  countryregioncode VARCHAR(3),
  `group`           VARCHAR(50)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_specialoffer (
  specialofferid INT,
  description    VARCHAR(255),
  type           VARCHAR(50),
  category       VARCHAR(50),
  discountpct    DECIMAL(10,4),
  startdate      DATETIME,
  enddate        DATETIME
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_shipmethod (
  shipmethodid INT,
  name         VARCHAR(50),
  shipbase     DECIMAL(19,4),
  shiprate     DECIMAL(19,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE stg_currencyrate (
  currencyrateid   INT,
  currencyratedate DATETIME,
  fromcurrencycode VARCHAR(3),
  tocurrencycode   VARCHAR(3),
  averagerate      DECIMAL(19,4),
  endofdayrate     DECIMAL(19,4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Index kecil agar langkah transformasi/join antar staging di database DW lebih cepat
CREATE INDEX ix_stg_soh   ON stg_salesorderheader (salesorderid);
CREATE INDEX ix_stg_sod   ON stg_salesorderdetail (salesorderid);
CREATE INDEX ix_stg_pch   ON stg_productcosthistory (productid);
CREATE INDEX ix_stg_plh   ON stg_productlistpricehistory (productid);
CREATE INDEX ix_stg_cust  ON stg_customer (customerid);
CREATE INDEX ix_stg_store ON stg_store (businessentityid);
CREATE INDEX ix_stg_curr  ON stg_currencyrate (currencyrateid);

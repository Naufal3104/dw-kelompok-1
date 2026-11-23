-- =====================================================================
--  01_ekstrak_mysql.sql  |  query untuk node MySQL SUMBER di n8n
--  Kelompok 1 - Penjualan Reseller
--  Dijalankan di database SUMBER (adventureworks2, MariaDB 10.11 di VPS,
--  koneksi DBX "Hermes"). Diuji 23 Nov 2026: semua query valid.
--  Pengganti 01_ekstrak_postgresql.sql di lampiran pekan 12.
--
--  Aturan:
--  * Nama kolom hasil SELECT (alias huruf kecil) sama dengan kolom stg_*,
--    agar node MySQL "Insert" bisa memetakan kolom secara otomatis.
--  * Semua kolom tanggal diubah menjadi TEKS dengan DATE_FORMAT agar
--    tidak bergeser karena zona waktu (padanan TO_CHAR di lampiran).
--  * Angka desimal diubah menjadi teks dengan CAST(... AS CHAR)
--    agar tidak dibulatkan oleh JavaScript (padanan ::text).
--  * Tabel besar (salesorderheader, salesorderdetail) dibaca per batch
--    5000 baris. {{ $json.offset }} diisi oleh node Loop Over Items.
--
--  Penanda "-- [nama]" dibaca oleh tools/buat_workflow.py. Jangan dihapus.
-- =====================================================================

-- ---------- tabel besar: dibaca per batch 5000 baris ----------

-- [jumlah_tabel_besar]
-- Versi B (tools/buat_workflow.py): satu query untuk kedua tabel besar.
-- Nama kolom = nama tabel staging, dipakai node Code untuk membuat batch.
-- Diuji di Hermes 23 Nov 2026: 31465 dan 121317 baris.
SELECT (SELECT COUNT(*) FROM sales_salesorderheader) AS stg_salesorderheader,
       (SELECT COUNT(*) FROM sales_salesorderdetail) AS stg_salesorderdetail;

-- [jumlah_stg_salesorderheader]
SELECT COUNT(*) AS jumlah FROM sales_salesorderheader;

-- [stg_salesorderheader]
SELECT SalesOrderID                                       AS salesorderid,
       SalesOrderNumber                                   AS salesordernumber,
       -- OrderDate bertipe TIMESTAMP: tampilannya ikut zona waktu SESI.
       -- Server Hermes memakai CST (UTC+8). Jika sesi n8n memakai UTC,
       -- 2011-05-31 02:30 menjadi 2011-05-30 18:30 (bergeser sehari).
       -- UNIX_TIMESTAMP tidak bergantung zona sesi, lalu dikunci ke UTC+8.
       DATE_FORMAT(TIMESTAMPADD(SECOND, UNIX_TIMESTAMP(OrderDate), '1970-01-01 08:00:00'),
                   '%Y-%m-%d %H:%i:%s')               AS orderdate,
       DATE_FORMAT(DueDate,   '%Y-%m-%d %H:%i:%s')        AS duedate,
       DATE_FORMAT(ShipDate,  '%Y-%m-%d %H:%i:%s')        AS shipdate,
       OnlineOrderFlag                                    AS onlineorderflag,
       CustomerID                                         AS customerid,
       SalesPersonID                                      AS salespersonid,
       TerritoryID                                        AS territoryid,
       ShipMethodID                                       AS shipmethodid,
       CurrencyRateID                                     AS currencyrateid,
       CAST(SubTotal AS CHAR)                             AS subtotal,
       CAST(TaxAmt   AS CHAR)                             AS taxamt,
       CAST(Freight  AS CHAR)                             AS freight
FROM sales_salesorderheader
ORDER BY SalesOrderID
LIMIT 5000 OFFSET {{ $json.offset }};

-- [jumlah_stg_salesorderdetail]
SELECT COUNT(*) AS jumlah FROM sales_salesorderdetail;

-- [stg_salesorderdetail]
SELECT SalesOrderID                      AS salesorderid,
       SalesOrderDetailID                AS salesorderdetailid,
       ProductID                         AS productid,
       SpecialOfferID                    AS specialofferid,
       OrderQty                          AS orderqty,
       CAST(UnitPrice         AS CHAR)   AS unitprice,
       CAST(UnitPriceDiscount AS CHAR)   AS unitpricediscount,
       CAST(LineTotal         AS CHAR)   AS linetotal
FROM sales_salesorderdetail
ORDER BY SalesOrderDetailID
LIMIT 5000 OFFSET {{ $json.offset }};

-- ---------- tabel kecil: cukup sekali baca (Execute Once) ----------

-- [stg_product]
SELECT ProductID                    AS productid,
       Name                         AS name,
       ProductNumber                AS productnumber,
       Color                        AS color,
       ProductSubcategoryID         AS productsubcategoryid,
       CAST(StandardCost AS CHAR)   AS standardcost,
       CAST(ListPrice    AS CHAR)   AS listprice
FROM production_product;

-- [stg_productsubcategory]
SELECT ProductSubcategoryID AS productsubcategoryid,
       ProductCategoryID    AS productcategoryid,
       Name                 AS name
FROM production_productsubcategory;

-- [stg_productcategory]
SELECT ProductCategoryID AS productcategoryid,
       Name              AS name
FROM production_productcategory;

-- [stg_productcosthistory]
SELECT ProductID                                    AS productid,
       DATE_FORMAT(StartDate, '%Y-%m-%d %H:%i:%s')  AS startdate,
       DATE_FORMAT(EndDate,   '%Y-%m-%d %H:%i:%s')  AS enddate,
       CAST(StandardCost AS CHAR)                   AS standardcost
FROM production_productcosthistory;

-- [stg_productlistpricehistory]
SELECT ProductID                                    AS productid,
       DATE_FORMAT(StartDate, '%Y-%m-%d %H:%i:%s')  AS startdate,
       DATE_FORMAT(EndDate,   '%Y-%m-%d %H:%i:%s')  AS enddate,
       CAST(ListPrice AS CHAR)                      AS listprice
FROM production_productlistpricehistory;

-- [stg_store]
SELECT BusinessEntityID AS businessentityid,
       Name             AS name,
       SalesPersonID    AS salespersonid,
       Demographics     AS demographics
FROM sales_store;

-- [stg_customer]
SELECT CustomerID  AS customerid,
       PersonID    AS personid,
       StoreID     AS storeid,
       TerritoryID AS territoryid
FROM sales_customer;

-- [stg_salesperson]
SELECT BusinessEntityID             AS businessentityid,
       TerritoryID                  AS territoryid,
       CAST(SalesQuota    AS CHAR)  AS salesquota,
       CAST(Bonus         AS CHAR)  AS bonus,
       CAST(CommissionPct AS CHAR)  AS commissionpct
FROM sales_salesperson;

-- [stg_person]
SELECT BusinessEntityID AS businessentityid,
       FirstName        AS firstname,
       MiddleName       AS middlename,
       LastName         AS lastname
FROM person_person;

-- [stg_salesterritory]
SELECT TerritoryID       AS territoryid,
       Name              AS name,
       CountryRegionCode AS countryregioncode,
       `Group`           AS `group`
FROM sales_salesterritory;

-- [stg_specialoffer]
SELECT SpecialOfferID                               AS specialofferid,
       Description                                  AS description,
       Type                                         AS type,
       Category                                     AS category,
       CAST(DiscountPct AS CHAR)                    AS discountpct,
       DATE_FORMAT(StartDate, '%Y-%m-%d %H:%i:%s')  AS startdate,
       DATE_FORMAT(EndDate,   '%Y-%m-%d %H:%i:%s')  AS enddate
FROM sales_specialoffer;

-- [stg_shipmethod]
SELECT ShipMethodID           AS shipmethodid,
       Name                   AS name,
       CAST(ShipBase AS CHAR) AS shipbase,
       CAST(ShipRate AS CHAR) AS shiprate
FROM purchasing_shipmethod;

-- [stg_currencyrate]
SELECT CurrencyRateID                                      AS currencyrateid,
       DATE_FORMAT(CurrencyRateDate, '%Y-%m-%d %H:%i:%s')  AS currencyratedate,
       FromCurrencyCode                                    AS fromcurrencycode,
       ToCurrencyCode                                      AS tocurrencycode,
       CAST(AverageRate  AS CHAR)                          AS averagerate,
       CAST(EndOfDayRate AS CHAR)                          AS endofdayrate
FROM sales_currencyrate;

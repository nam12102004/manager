-- SQL script Nhân đôi toàn bộ số lượng Khách hàng, Nhà cung cấp, Sản phẩm hiện tại

BEGIN;

-- 1. Nhân đôi Nhà cung cấp (Suppliers)
INSERT INTO "Suppliers" ("Code", "Name", "ContactName", "PhonesJson", "Email", "AddressesJson", "Region", "Debt", "CreditLimit", "BankAccount", "TaxNumber", "Notes", "CreatedAt", "UpdatedAt")
SELECT 
  'NCC_DB_' || s."Id",
  s."Name" || ' (Chi nhánh 2)',
  s."ContactName",
  s."PhonesJson",
  'cn2_' || COALESCE(s."Email", 'ncc@example.com'),
  s."AddressesJson",
  COALESCE(s."Region", CASE (s."Id" % 5) WHEN 1 THEN 'Miền Bắc' WHEN 2 THEN 'Miền Nam' WHEN 3 THEN 'Miền Trung' WHEN 4 THEN 'TP. Hồ Chí Minh' ELSE 'Hà Nội' END),
  s."Debt",
  s."CreditLimit",
  s."BankAccount",
  s."TaxNumber",
  s."Notes",
  NOW(),
  NOW()
FROM "Suppliers" s;

-- 2. Nhân đôi Khách hàng (Customers)
INSERT INTO "Customers" ("Code", "Name", "ContactName", "PhonesJson", "Email", "AddressesJson", "Region", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
SELECT 
  'KH_DB_' || c."Id",
  c."Name" || ' (Cơ sở 2)',
  c."ContactName",
  c."PhonesJson",
  'cs2_' || COALESCE(c."Email", 'khachhang@example.com'),
  c."AddressesJson",
  COALESCE(c."Region", CASE (c."Id" % 5) WHEN 1 THEN 'Miền Bắc' WHEN 2 THEN 'Miền Nam' WHEN 3 THEN 'Miền Trung' WHEN 4 THEN 'TP. Hồ Chí Minh' ELSE 'Hà Nội' END),
  c."Debt",
  c."CreditLimit",
  c."Notes",
  NOW(),
  NOW()
FROM "Customers" c;

-- 3. Nhân đôi Sản phẩm (Products)
INSERT INTO "Products" ("Sku", "Name", "Category", "Uom", "Barcode", "SupplierId", "UnitCost", "WholesalePrice", "RetailPrice", "StockWarehouse1", "StockWarehouse2", "StockWarehouse3", "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt")
SELECT 
  'SP_DB_' || p."Id",
  p."Name" || ' (Mới / Loại 2)',
  p."Category",
  p."Uom",
  COALESCE(p."Barcode", '893000000000') || '2',
  p."SupplierId",
  p."UnitCost",
  p."WholesalePrice",
  p."RetailPrice",
  p."StockWarehouse1",
  p."StockWarehouse2",
  p."StockWarehouse3",
  p."TotalStock",
  p."ReorderPoint",
  NOW(),
  NOW()
FROM "Products" p;

COMMIT;

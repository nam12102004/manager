-- ============================================================================
-- PHẦN A: BẢNG PRODUCT UNITS & ĐƠN VỊ TÍNH QUY ĐỔI (TRÁNH LỖI 500)
-- ============================================================================
CREATE TABLE IF NOT EXISTS "ProductUnits" (
    "Id" SERIAL PRIMARY KEY,
    "ProductId" INTEGER NOT NULL REFERENCES "Products"("Id") ON DELETE CASCADE,
    "UnitName" VARCHAR(50) NOT NULL,
    "ConversionRate" NUMERIC(18,4) NOT NULL DEFAULT 1,
    "IsBaseUnit" BOOLEAN NOT NULL DEFAULT FALSE,
    "Barcode" VARCHAR(100),
    "RetailPrice" NUMERIC(18,2) NOT NULL DEFAULT 0,
    "WholesalePrice" NUMERIC(18,2) NOT NULL DEFAULT 0,
    "CanSell" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS "IX_ProductUnits_ProductId_UnitName" ON "ProductUnits" ("ProductId", "UnitName");
CREATE INDEX IF NOT EXISTS "IX_ProductUnits_ProductId" ON "ProductUnits" ("ProductId");

-- Thêm các cột đơn vị vào phiếu xuất & phiếu nhập
ALTER TABLE "ExportVoucherItems" ADD COLUMN IF NOT EXISTS "UnitName" VARCHAR(50);
ALTER TABLE "ExportVoucherItems" ADD COLUMN IF NOT EXISTS "ConversionRate" NUMERIC(18,4) NOT NULL DEFAULT 1;
ALTER TABLE "ExportVoucherItems" ADD COLUMN IF NOT EXISTS "BaseQuantity" NUMERIC(18,3) NOT NULL DEFAULT 0;

ALTER TABLE "ImportVoucherItems" ADD COLUMN IF NOT EXISTS "UnitName" VARCHAR(50);
ALTER TABLE "ImportVoucherItems" ADD COLUMN IF NOT EXISTS "ConversionRate" NUMERIC(18,4) NOT NULL DEFAULT 1;
ALTER TABLE "ImportVoucherItems" ADD COLUMN IF NOT EXISTS "BaseQuantity" NUMERIC(18,3) NOT NULL DEFAULT 0;

-- Backfill dữ liệu mặc định cho voucher items
UPDATE "ExportVoucherItems" SET "BaseQuantity" = "Quantity", "ConversionRate" = 1 WHERE "BaseQuantity" = 0 OR "BaseQuantity" IS NULL;
UPDATE "ImportVoucherItems" SET "BaseQuantity" = "Quantity", "ConversionRate" = 1 WHERE "BaseQuantity" = 0 OR "BaseQuantity" IS NULL;

-- Backfill đơn vị cơ sở cho các sản phẩm hiện có
INSERT INTO "ProductUnits" ("ProductId", "UnitName", "ConversionRate", "IsBaseUnit", "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt")
SELECT p."Id", COALESCE(NULLIF(TRIM(p."Uom"), ''), 'Cái'), 1.0000, TRUE, COALESCE(p."RetailPrice", 0), COALESCE(p."WholesalePrice", 0), TRUE, CURRENT_TIMESTAMP
FROM "Products" p
WHERE NOT EXISTS (
    SELECT 1 FROM "ProductUnits" pu WHERE pu."ProductId" = p."Id" AND pu."IsBaseUnit" = TRUE
);

-- ============================================================================
-- PHẦN B: CÔNG NỢ TÁCH RIÊNG THEO TỪNG KHO
-- ============================================================================
CREATE TABLE IF NOT EXISTS "CustomerWarehouseDebts" (
    "Id" BIGSERIAL PRIMARY KEY,
    "CustomerId" INTEGER NOT NULL REFERENCES "Customers"("Id") ON DELETE CASCADE,
    "Warehouse" VARCHAR(50) NOT NULL,
    "Debt" NUMERIC(18,2) NOT NULL DEFAULT 0,
    "UpdatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UQ_CustomerWarehouseDebt" UNIQUE ("CustomerId", "Warehouse")
);

CREATE TABLE IF NOT EXISTS "SupplierWarehouseDebts" (
    "Id" BIGSERIAL PRIMARY KEY,
    "SupplierId" INTEGER NOT NULL REFERENCES "Suppliers"("Id") ON DELETE CASCADE,
    "Warehouse" VARCHAR(50) NOT NULL,
    "Debt" NUMERIC(18,2) NOT NULL DEFAULT 0,
    "UpdatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UQ_SupplierWarehouseDebt" UNIQUE ("SupplierId", "Warehouse")
);

ALTER TABLE "CustomerDebtHistories" ADD COLUMN IF NOT EXISTS "Warehouse" VARCHAR(50) NOT NULL DEFAULT 'warehouse1';
ALTER TABLE "SupplierDebtHistories" ADD COLUMN IF NOT EXISTS "Warehouse" VARCHAR(50) NOT NULL DEFAULT 'warehouse1';

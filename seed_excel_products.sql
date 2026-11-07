-- seed_excel_products.sql
-- Tự động sinh bởi import-excel-products.js vào lúc 2026-11-07T06:15:03.583Z
-- Cập nhật Kho 1, Kho 2, Nhà cung cấp và Sản phẩm theo yêu cầu.

BEGIN;

-- 1. Đảm bảo Kho 1 và Kho 2 có trong Cấu hình (Owners)
DO $$
DECLARE
    cur_info text;
    new_info jsonb;
BEGIN
    SELECT "Info" INTO cur_info FROM "Owners" WHERE "Id" = 1;
    IF cur_info IS NULL THEN
        INSERT INTO "Owners" ("Id", "Info", "CreatedAt", "UpdatedAt")
        VALUES (1, '{"storeName":"KHO HÀNG & PHÂN PHỐI TỔNG HỢP","warehouses":[{"id":"warehouse1","name":"Kho 1","shortName":"Kho 1","color":"primary"},{"id":"warehouse2","name":"Kho 2","shortName":"Kho 2","color":"info"}]}', NOW(), NOW());
    ELSE
        BEGIN
            new_info := cur_info::jsonb;
        EXCEPTION WHEN OTHERS THEN
            new_info := jsonb_build_object('storeName', cur_info);
        END;
        new_info := jsonb_set(new_info, '{warehouses}', '[{"id":"warehouse1","name":"Kho 1","shortName":"Kho 1","color":"primary"},{"id":"warehouse2","name":"Kho 2","shortName":"Kho 2","color":"info"}]'::jsonb);
        UPDATE "Owners" SET "Info" = new_info::text, "UpdatedAt" = NOW() WHERE "Id" = 1;
    END IF;
END $$;

-- 2. Chèn Nhà cung cấp
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('HH', 'Hoàng Hà', 0, 0, 'Nhập từ Sheet "H.HÀ"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('NICE', 'Nice', 0, 0, 'Nhập từ Sheet "NICE"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('TAKAO', 'Takao', 0, 0, 'Nhập từ Sheet "TAKAO"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('VT', 'Vĩnh Thắng', 0, 0, 'Nhập từ Sheet "VĨNH THẮNG"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('DMAX', 'Dmax + Mira', 0, 0, 'Nhập từ Sheet "DMAX+MIRA"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('RA', 'Royal + Ấn Độ', 0, 0, 'Nhập từ Sheet "ROYAL+ẤN"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('TOKO', 'Toko', 0, 0, 'Nhập từ Sheet "TOKO,"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();
INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('AMY', 'Á Mỹ', 0, 0, 'Nhập từ Sheet "Á Mỹ"', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();

-- 3. Chèn Sản phẩm và Đơn vị tính cơ bản

-- >>> Hãng: Hoàng Hà (HH) - Tổng 216 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP10,104'))
       OR "Sku" = 'HH001'
    ORDER BY CASE WHEN "Sku" = 'HH001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH001',
            "Name" = 'LP10,104',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 289,
            "StockWarehouse2" = 0,
            "TotalStock" = 289,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH001', 'LP10,104', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            289, 0, 0,
            289, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP10,112'))
       OR "Sku" = 'HH002'
    ORDER BY CASE WHEN "Sku" = 'HH002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH002',
            "Name" = 'LP10,112',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 267,
            "StockWarehouse2" = 0,
            "TotalStock" = 267,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH002', 'LP10,112', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            267, 0, 0,
            267, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP10,113'))
       OR "Sku" = 'HH003'
    ORDER BY CASE WHEN "Sku" = 'HH003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH003',
            "Name" = 'LP10,113',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 218,
            "StockWarehouse2" = 0,
            "TotalStock" = 218,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH003', 'LP10,113', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            218, 0, 0,
            218, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP10,114'))
       OR "Sku" = 'HH004'
    ORDER BY CASE WHEN "Sku" = 'HH004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH004',
            "Name" = 'LP10,114',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 110,
            "StockWarehouse2" = 0,
            "TotalStock" = 110,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH004', 'LP10,114', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            110, 0, 0,
            110, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18,112 -A2'))
       OR "Sku" = 'HH005'
    ORDER BY CASE WHEN "Sku" = 'HH005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH005',
            "Name" = 'LP18,112 -A2',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 302,
            "StockWarehouse2" = 0,
            "TotalStock" = 302,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH005', 'LP18,112 -A2', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            302, 0, 0,
            302, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18,113 - A2'))
       OR "Sku" = 'HH006'
    ORDER BY CASE WHEN "Sku" = 'HH006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH006',
            "Name" = 'LP18,113 - A2',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH006', 'LP18,113 - A2', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18,114 -A2'))
       OR "Sku" = 'HH007'
    ORDER BY CASE WHEN "Sku" = 'HH007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH007',
            "Name" = 'LP18,114 -A2',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH007', 'LP18,114 -A2', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18,112 A1'))
       OR "Sku" = 'HH008'
    ORDER BY CASE WHEN "Sku" = 'HH008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH008',
            "Name" = 'LP18,112 A1',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 120,
            "StockWarehouse2" = 0,
            "TotalStock" = 120,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH008', 'LP18,112 A1', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            120, 0, 0,
            120, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18,113 A1'))
       OR "Sku" = 'HH009'
    ORDER BY CASE WHEN "Sku" = 'HH009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH009',
            "Name" = 'LP18,113 A1',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 80,
            "StockWarehouse2" = 0,
            "TotalStock" = 80,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH009', 'LP18,113 A1', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            80, 0, 0,
            80, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18,114 A1'))
       OR "Sku" = 'HH010'
    ORDER BY CASE WHEN "Sku" = 'HH010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH010',
            "Name" = 'LP18,114 A1',
            "Category" = 'GẠCH 1 MÉT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 158,
            "StockWarehouse2" = 0,
            "TotalStock" = 158,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH010', 'LP18,114 A1', 'GẠCH 1 MÉT', 'Hộp', supp_id,
            0, 0, 0,
            158, 0, 0,
            158, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8001'))
       OR "Sku" = 'HH011'
    ORDER BY CASE WHEN "Sku" = 'HH011' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH011',
            "Name" = 'LX8001',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 17,
            "StockWarehouse2" = 0,
            "TotalStock" = 17,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH011', 'LX8001', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            17, 0, 0,
            17, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8002'))
       OR "Sku" = 'HH012'
    ORDER BY CASE WHEN "Sku" = 'HH012' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH012',
            "Name" = 'LX8002',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 73,
            "StockWarehouse2" = 0,
            "TotalStock" = 73,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH012', 'LX8002', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            73, 0, 0,
            73, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8002 a2'))
       OR "Sku" = 'HH013'
    ORDER BY CASE WHEN "Sku" = 'HH013' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH013',
            "Name" = 'LX8002 a2',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 301,
            "StockWarehouse2" = 0,
            "TotalStock" = 301,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH013', 'LX8002 a2', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            301, 0, 0,
            301, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8003'))
       OR "Sku" = 'HH014'
    ORDER BY CASE WHEN "Sku" = 'HH014' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH014',
            "Name" = 'LX8003',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 12,
            "StockWarehouse2" = 0,
            "TotalStock" = 12,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH014', 'LX8003', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            12, 0, 0,
            12, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8004'))
       OR "Sku" = 'HH015'
    ORDER BY CASE WHEN "Sku" = 'HH015' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH015',
            "Name" = 'LX8004',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 14,
            "StockWarehouse2" = 0,
            "TotalStock" = 14,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH015', 'LX8004', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            14, 0, 0,
            14, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8005'))
       OR "Sku" = 'HH016'
    ORDER BY CASE WHEN "Sku" = 'HH016' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH016',
            "Name" = 'LX8005',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 31,
            "StockWarehouse2" = 0,
            "TotalStock" = 31,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH016', 'LX8005', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            31, 0, 0,
            31, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8005- A2'))
       OR "Sku" = 'HH017'
    ORDER BY CASE WHEN "Sku" = 'HH017' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH017',
            "Name" = 'LX8005- A2',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 140,
            "StockWarehouse2" = 0,
            "TotalStock" = 140,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH017', 'LX8005- A2', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            140, 0, 0,
            140, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8009'))
       OR "Sku" = 'HH018'
    ORDER BY CASE WHEN "Sku" = 'HH018' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH018',
            "Name" = 'LX8009',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 19,
            "StockWarehouse2" = 0,
            "TotalStock" = 19,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH018', 'LX8009', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            19, 0, 0,
            19, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8009 - A2'))
       OR "Sku" = 'HH019'
    ORDER BY CASE WHEN "Sku" = 'HH019' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH019',
            "Name" = 'LX8009 - A2',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 59,
            "StockWarehouse2" = 0,
            "TotalStock" = 59,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH019', 'LX8009 - A2', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            59, 0, 0,
            59, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8010'))
       OR "Sku" = 'HH020'
    ORDER BY CASE WHEN "Sku" = 'HH020' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH020',
            "Name" = 'LX8010',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 9,
            "StockWarehouse2" = 0,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH020', 'LX8010', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            9, 0, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8012'))
       OR "Sku" = 'HH021'
    ORDER BY CASE WHEN "Sku" = 'HH021' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH021',
            "Name" = 'LX8012',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 9,
            "StockWarehouse2" = 0,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH021', 'LX8012', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            9, 0, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8014'))
       OR "Sku" = 'HH022'
    ORDER BY CASE WHEN "Sku" = 'HH022' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH022',
            "Name" = 'LX8014',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 14,
            "StockWarehouse2" = 0,
            "TotalStock" = 14,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH022', 'LX8014', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            14, 0, 0,
            14, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8014 -A2'))
       OR "Sku" = 'HH023'
    ORDER BY CASE WHEN "Sku" = 'HH023' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH023',
            "Name" = 'LX8014 -A2',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 13,
            "StockWarehouse2" = 0,
            "TotalStock" = 13,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH023', 'LX8014 -A2', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            13, 0, 0,
            13, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8016'))
       OR "Sku" = 'HH024'
    ORDER BY CASE WHEN "Sku" = 'HH024' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH024',
            "Name" = 'LX8016',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 37,
            "StockWarehouse2" = 0,
            "TotalStock" = 37,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH024', 'LX8016', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            37, 0, 0,
            37, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8016 - A2'))
       OR "Sku" = 'HH025'
    ORDER BY CASE WHEN "Sku" = 'HH025' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH025',
            "Name" = 'LX8016 - A2',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 8,
            "StockWarehouse2" = 0,
            "TotalStock" = 8,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH025', 'LX8016 - A2', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            8, 0, 0,
            8, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8017'))
       OR "Sku" = 'HH026'
    ORDER BY CASE WHEN "Sku" = 'HH026' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH026',
            "Name" = 'LX8017',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 206,
            "StockWarehouse2" = 0,
            "TotalStock" = 206,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH026', 'LX8017', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            206, 0, 0,
            206, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX8017 a2'))
       OR "Sku" = 'HH027'
    ORDER BY CASE WHEN "Sku" = 'HH027' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH027',
            "Name" = 'LX8017 a2',
            "Category" = 'GẠCH 80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 37,
            "StockWarehouse2" = 0,
            "TotalStock" = 37,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH027', 'LX8017 a2', 'GẠCH 80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            37, 0, 0,
            37, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18101'))
       OR "Sku" = 'HH028'
    ORDER BY CASE WHEN "Sku" = 'HH028' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH028',
            "Name" = 'LP18101',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 194,
            "StockWarehouse2" = 0,
            "TotalStock" = 194,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH028', 'LP18101', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            194, 0, 0,
            194, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18101 A2'))
       OR "Sku" = 'HH029'
    ORDER BY CASE WHEN "Sku" = 'HH029' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH029',
            "Name" = 'LP18101 A2',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH029', 'LP18101 A2', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18102'))
       OR "Sku" = 'HH030'
    ORDER BY CASE WHEN "Sku" = 'HH030' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH030',
            "Name" = 'LP18102',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 44,
            "StockWarehouse2" = 0,
            "TotalStock" = 44,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH030', 'LP18102', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            44, 0, 0,
            44, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18102 A2'))
       OR "Sku" = 'HH031'
    ORDER BY CASE WHEN "Sku" = 'HH031' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH031',
            "Name" = 'LP18102 A2',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 20,
            "StockWarehouse2" = 0,
            "TotalStock" = 20,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH031', 'LP18102 A2', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            20, 0, 0,
            20, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18103'))
       OR "Sku" = 'HH032'
    ORDER BY CASE WHEN "Sku" = 'HH032' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH032',
            "Name" = 'LP18103',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 123,
            "StockWarehouse2" = 0,
            "TotalStock" = 123,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH032', 'LP18103', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            123, 0, 0,
            123, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18103 A2'))
       OR "Sku" = 'HH033'
    ORDER BY CASE WHEN "Sku" = 'HH033' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH033',
            "Name" = 'LP18103 A2',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 109,
            "StockWarehouse2" = 0,
            "TotalStock" = 109,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH033', 'LP18103 A2', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            109, 0, 0,
            109, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18104'))
       OR "Sku" = 'HH034'
    ORDER BY CASE WHEN "Sku" = 'HH034' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH034',
            "Name" = 'LP18104',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 74,
            "StockWarehouse2" = 0,
            "TotalStock" = 74,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH034', 'LP18104', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            74, 0, 0,
            74, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18104 A2'))
       OR "Sku" = 'HH035'
    ORDER BY CASE WHEN "Sku" = 'HH035' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH035',
            "Name" = 'LP18104 A2',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 29,
            "StockWarehouse2" = 0,
            "TotalStock" = 29,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH035', 'LP18104 A2', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            29, 0, 0,
            29, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18.8018 A1'))
       OR "Sku" = 'HH036'
    ORDER BY CASE WHEN "Sku" = 'HH036' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH036',
            "Name" = 'LP18.8018 A1',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 56,
            "StockWarehouse2" = 0,
            "TotalStock" = 56,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH036', 'LP18.8018 A1', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            56, 0, 0,
            56, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18.8016 A1'))
       OR "Sku" = 'HH037'
    ORDER BY CASE WHEN "Sku" = 'HH037' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH037',
            "Name" = 'LP18.8016 A1',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 107,
            "StockWarehouse2" = 0,
            "TotalStock" = 107,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH037', 'LP18.8016 A1', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            107, 0, 0,
            107, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18.8003 A1'))
       OR "Sku" = 'HH038'
    ORDER BY CASE WHEN "Sku" = 'HH038' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH038',
            "Name" = 'LP18.8003 A1',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH038', 'LP18.8003 A1', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18.8003 A2'))
       OR "Sku" = 'HH039'
    ORDER BY CASE WHEN "Sku" = 'HH039' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH039',
            "Name" = 'LP18.8003 A2',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 175,
            "StockWarehouse2" = 0,
            "TotalStock" = 175,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH039', 'LP18.8003 A2', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            175, 0, 0,
            175, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP18.8021 A1'))
       OR "Sku" = 'HH040'
    ORDER BY CASE WHEN "Sku" = 'HH040' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH040',
            "Name" = 'LP18.8021 A1',
            "Category" = '80*80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 63,
            "StockWarehouse2" = 0,
            "TotalStock" = 63,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH040', 'LP18.8021 A1', '80*80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            63, 0, 0,
            63, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6001'))
       OR "Sku" = 'HH041'
    ORDER BY CASE WHEN "Sku" = 'HH041' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH041',
            "Name" = 'LX6001',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 69,
            "StockWarehouse2" = 0,
            "TotalStock" = 69,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH041', 'LX6001', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            69, 0, 0,
            69, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6007'))
       OR "Sku" = 'HH042'
    ORDER BY CASE WHEN "Sku" = 'HH042' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH042',
            "Name" = 'LX6007',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 27,
            "StockWarehouse2" = 0,
            "TotalStock" = 27,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH042', 'LX6007', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            27, 0, 0,
            27, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6602'))
       OR "Sku" = 'HH043'
    ORDER BY CASE WHEN "Sku" = 'HH043' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH043',
            "Name" = 'LX6602',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 4,
            "StockWarehouse2" = 0,
            "TotalStock" = 4,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH043', 'LX6602', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            4, 0, 0,
            4, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6609'))
       OR "Sku" = 'HH044'
    ORDER BY CASE WHEN "Sku" = 'HH044' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH044',
            "Name" = 'LX6609',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 380,
            "StockWarehouse2" = 0,
            "TotalStock" = 380,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH044', 'LX6609', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            380, 0, 0,
            380, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6610'))
       OR "Sku" = 'HH045'
    ORDER BY CASE WHEN "Sku" = 'HH045' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH045',
            "Name" = 'LX6610',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 5,
            "StockWarehouse2" = 0,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH045', 'LX6610', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            5, 0, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6614'))
       OR "Sku" = 'HH046'
    ORDER BY CASE WHEN "Sku" = 'HH046' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH046',
            "Name" = 'LX6614',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 9,
            "StockWarehouse2" = 0,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH046', 'LX6614', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            9, 0, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6614 A2'))
       OR "Sku" = 'HH047'
    ORDER BY CASE WHEN "Sku" = 'HH047' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH047',
            "Name" = 'LX6614 A2',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 36,
            "StockWarehouse2" = 0,
            "TotalStock" = 36,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH047', 'LX6614 A2', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            36, 0, 0,
            36, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6616'))
       OR "Sku" = 'HH048'
    ORDER BY CASE WHEN "Sku" = 'HH048' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH048',
            "Name" = 'LX6616',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 6,
            "StockWarehouse2" = 0,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH048', 'LX6616', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            6, 0, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6617'))
       OR "Sku" = 'HH049'
    ORDER BY CASE WHEN "Sku" = 'HH049' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH049',
            "Name" = 'LX6617',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 139,
            "StockWarehouse2" = 0,
            "TotalStock" = 139,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH049', 'LX6617', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            139, 0, 0,
            139, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6618'))
       OR "Sku" = 'HH050'
    ORDER BY CASE WHEN "Sku" = 'HH050' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH050',
            "Name" = 'LX6618',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 63,
            "StockWarehouse2" = 0,
            "TotalStock" = 63,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH050', 'LX6618', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            63, 0, 0,
            63, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6621'))
       OR "Sku" = 'HH051'
    ORDER BY CASE WHEN "Sku" = 'HH051' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH051',
            "Name" = 'LX6621',
            "Category" = 'GẠCH 60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 35,
            "StockWarehouse2" = 0,
            "TotalStock" = 35,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH051', 'LX6621', 'GẠCH 60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            35, 0, 0,
            35, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96101'))
       OR "Sku" = 'HH052'
    ORDER BY CASE WHEN "Sku" = 'HH052' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH052',
            "Name" = 'LP96101',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 17,
            "StockWarehouse2" = 0,
            "TotalStock" = 17,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH052', 'LP96101', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            17, 0, 0,
            17, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96102'))
       OR "Sku" = 'HH053'
    ORDER BY CASE WHEN "Sku" = 'HH053' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH053',
            "Name" = 'LP96102',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 21,
            "StockWarehouse2" = 0,
            "TotalStock" = 21,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH053', 'LP96102', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            21, 0, 0,
            21, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96102 A2'))
       OR "Sku" = 'HH054'
    ORDER BY CASE WHEN "Sku" = 'HH054' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH054',
            "Name" = 'LP96102 A2',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 15,
            "StockWarehouse2" = 0,
            "TotalStock" = 15,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH054', 'LP96102 A2', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            15, 0, 0,
            15, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96103'))
       OR "Sku" = 'HH055'
    ORDER BY CASE WHEN "Sku" = 'HH055' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH055',
            "Name" = 'LP96103',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 69,
            "StockWarehouse2" = 0,
            "TotalStock" = 69,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH055', 'LP96103', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            69, 0, 0,
            69, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96103 A2'))
       OR "Sku" = 'HH056'
    ORDER BY CASE WHEN "Sku" = 'HH056' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH056',
            "Name" = 'LP96103 A2',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH056', 'LP96103 A2', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96104'))
       OR "Sku" = 'HH057'
    ORDER BY CASE WHEN "Sku" = 'HH057' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH057',
            "Name" = 'LP96104',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 10,
            "StockWarehouse2" = 0,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH057', 'LP96104', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            10, 0, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96-6603'))
       OR "Sku" = 'HH058'
    ORDER BY CASE WHEN "Sku" = 'HH058' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH058',
            "Name" = 'LP96-6603',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 42,
            "StockWarehouse2" = 0,
            "TotalStock" = 42,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH058', 'LP96-6603', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            42, 0, 0,
            42, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP96-6603 A2'))
       OR "Sku" = 'HH059'
    ORDER BY CASE WHEN "Sku" = 'HH059' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH059',
            "Name" = 'LP96-6603 A2',
            "Category" = '60*60-ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH059', 'LP96-6603 A2', '60*60-ECO', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6105'))
       OR "Sku" = 'HH060'
    ORDER BY CASE WHEN "Sku" = 'HH060' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH060',
            "Name" = 'LXC6105',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 140,
            "StockWarehouse2" = 0,
            "TotalStock" = 140,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH060', 'LXC6105', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            140, 0, 0,
            140, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6110 H4'))
       OR "Sku" = 'HH061'
    ORDER BY CASE WHEN "Sku" = 'HH061' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH061',
            "Name" = 'LXC6110 H4',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 175,
            "StockWarehouse2" = 0,
            "TotalStock" = 175,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH061', 'LXC6110 H4', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            175, 0, 0,
            175, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6112-h11'))
       OR "Sku" = 'HH062'
    ORDER BY CASE WHEN "Sku" = 'HH062' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH062',
            "Name" = 'LXC6112-h11',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 317,
            "StockWarehouse2" = 0,
            "TotalStock" = 317,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH062', 'LXC6112-h11', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            317, 0, 0,
            317, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6114'))
       OR "Sku" = 'HH063'
    ORDER BY CASE WHEN "Sku" = 'HH063' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH063',
            "Name" = 'LXC6114',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 45,
            "StockWarehouse2" = 0,
            "TotalStock" = 45,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH063', 'LXC6114', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            45, 0, 0,
            45, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6115'))
       OR "Sku" = 'HH064'
    ORDER BY CASE WHEN "Sku" = 'HH064' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH064',
            "Name" = 'LXC6115',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 34,
            "StockWarehouse2" = 0,
            "TotalStock" = 34,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH064', 'LXC6115', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            34, 0, 0,
            34, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6116'))
       OR "Sku" = 'HH065'
    ORDER BY CASE WHEN "Sku" = 'HH065' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH065',
            "Name" = 'LXC6116',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 175,
            "StockWarehouse2" = 0,
            "TotalStock" = 175,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH065', 'LXC6116', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            175, 0, 0,
            175, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6117'))
       OR "Sku" = 'HH066'
    ORDER BY CASE WHEN "Sku" = 'HH066' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH066',
            "Name" = 'LXC6117',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 2,
            "StockWarehouse2" = 0,
            "TotalStock" = 2,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH066', 'LXC6117', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            2, 0, 0,
            2, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6118'))
       OR "Sku" = 'HH067'
    ORDER BY CASE WHEN "Sku" = 'HH067' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH067',
            "Name" = 'LXC6118',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH067', 'LXC6118', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXC6119'))
       OR "Sku" = 'HH068'
    ORDER BY CASE WHEN "Sku" = 'HH068' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH068',
            "Name" = 'LXC6119',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 4,
            "StockWarehouse2" = 0,
            "TotalStock" = 4,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH068', 'LXC6119', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            4, 0, 0,
            4, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV4850'))
       OR "Sku" = 'HH069'
    ORDER BY CASE WHEN "Sku" = 'HH069' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH069',
            "Name" = 'LV4850',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 6,
            "StockWarehouse2" = 0,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH069', 'LV4850', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            6, 0, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV4850 A2'))
       OR "Sku" = 'HH070'
    ORDER BY CASE WHEN "Sku" = 'HH070' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH070',
            "Name" = 'LV4850 A2',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH070', 'LV4850 A2', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV48000 A2'))
       OR "Sku" = 'HH071'
    ORDER BY CASE WHEN "Sku" = 'HH071' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH071',
            "Name" = 'LV48000 A2',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 175,
            "StockWarehouse2" = 0,
            "TotalStock" = 175,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH071', 'LV48000 A2', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            175, 0, 0,
            175, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV4851'))
       OR "Sku" = 'HH072'
    ORDER BY CASE WHEN "Sku" = 'HH072' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH072',
            "Name" = 'LV4851',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 17,
            "StockWarehouse2" = 0,
            "TotalStock" = 17,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH072', 'LV4851', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            17, 0, 0,
            17, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX4861'))
       OR "Sku" = 'HH073'
    ORDER BY CASE WHEN "Sku" = 'HH073' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH073',
            "Name" = 'LX4861',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 57,
            "StockWarehouse2" = 0,
            "TotalStock" = 57,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH073', 'LX4861', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            57, 0, 0,
            57, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX4862'))
       OR "Sku" = 'HH074'
    ORDER BY CASE WHEN "Sku" = 'HH074' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH074',
            "Name" = 'LX4862',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 622,
            "StockWarehouse2" = 0,
            "TotalStock" = 622,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH074', 'LX4862', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            622, 0, 0,
            622, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX4863'))
       OR "Sku" = 'HH075'
    ORDER BY CASE WHEN "Sku" = 'HH075' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH075',
            "Name" = 'LX4863',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 158,
            "StockWarehouse2" = 0,
            "TotalStock" = 158,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH075', 'LX4863', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            158, 0, 0,
            158, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX4865'))
       OR "Sku" = 'HH076'
    ORDER BY CASE WHEN "Sku" = 'HH076' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH076',
            "Name" = 'LX4865',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 116,
            "StockWarehouse2" = 0,
            "TotalStock" = 116,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH076', 'LX4865', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            116, 0, 0,
            116, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX4864- ĐIỂM'))
       OR "Sku" = 'HH077'
    ORDER BY CASE WHEN "Sku" = 'HH077' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH077',
            "Name" = 'LX4864- ĐIỂM',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 115,
            "StockWarehouse2" = 0,
            "TotalStock" = 115,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH077', 'LX4864- ĐIỂM', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            115, 0, 0,
            115, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX4867'))
       OR "Sku" = 'HH078'
    ORDER BY CASE WHEN "Sku" = 'HH078' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH078',
            "Name" = 'LX4867',
            "Category" = '40*80 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 32,
            "StockWarehouse2" = 0,
            "TotalStock" = 32,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH078', 'LX4867', '40*80 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            32, 0, 0,
            32, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.150'))
       OR "Sku" = 'HH079'
    ORDER BY CASE WHEN "Sku" = 'HH079' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH079',
            "Name" = 'LP948.150',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 43,
            "StockWarehouse2" = 0,
            "TotalStock" = 43,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH079', 'LP948.150', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            43, 0, 0,
            43, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.150- ĐIỂM'))
       OR "Sku" = 'HH080'
    ORDER BY CASE WHEN "Sku" = 'HH080' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH080',
            "Name" = 'LP948.150- ĐIỂM',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 20,
            "StockWarehouse2" = 0,
            "TotalStock" = 20,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH080', 'LP948.150- ĐIỂM', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            20, 0, 0,
            20, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.154'))
       OR "Sku" = 'HH081'
    ORDER BY CASE WHEN "Sku" = 'HH081' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH081',
            "Name" = 'LP948.154',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 8,
            "StockWarehouse2" = 0,
            "TotalStock" = 8,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH081', 'LP948.154', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            8, 0, 0,
            8, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.155'))
       OR "Sku" = 'HH082'
    ORDER BY CASE WHEN "Sku" = 'HH082' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH082',
            "Name" = 'LP948.155',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 46,
            "StockWarehouse2" = 0,
            "TotalStock" = 46,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH082', 'LP948.155', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            46, 0, 0,
            46, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.154- ĐIỂM'))
       OR "Sku" = 'HH083'
    ORDER BY CASE WHEN "Sku" = 'HH083' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH083',
            "Name" = 'LP948.154- ĐIỂM',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH083', 'LP948.154- ĐIỂM', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.156'))
       OR "Sku" = 'HH084'
    ORDER BY CASE WHEN "Sku" = 'HH084' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH084',
            "Name" = 'LP948.156',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 110,
            "StockWarehouse2" = 0,
            "TotalStock" = 110,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH084', 'LP948.156', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            110, 0, 0,
            110, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.157'))
       OR "Sku" = 'HH085'
    ORDER BY CASE WHEN "Sku" = 'HH085' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH085',
            "Name" = 'LP948.157',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 37,
            "StockWarehouse2" = 0,
            "TotalStock" = 37,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH085', 'LP948.157', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            37, 0, 0,
            37, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP948.156-ĐIỂM'))
       OR "Sku" = 'HH086'
    ORDER BY CASE WHEN "Sku" = 'HH086' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH086',
            "Name" = 'LP948.156-ĐIỂM',
            "Category" = '40/80 ECO',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 38,
            "StockWarehouse2" = 0,
            "TotalStock" = 38,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH086', 'LP948.156-ĐIỂM', '40/80 ECO', 'Hộp', supp_id,
            0, 0, 0,
            38, 0, 0,
            38, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3601'))
       OR "Sku" = 'HH087'
    ORDER BY CASE WHEN "Sku" = 'HH087' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH087',
            "Name" = 'LXP3601',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 28,
            "StockWarehouse2" = 0,
            "TotalStock" = 28,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH087', 'LXP3601', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            28, 0, 0,
            28, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3601-ĐIỂM a2'))
       OR "Sku" = 'HH088'
    ORDER BY CASE WHEN "Sku" = 'HH088' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH088',
            "Name" = 'LXP3601-ĐIỂM a2',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 62,
            "StockWarehouse2" = 0,
            "TotalStock" = 62,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH088', 'LXP3601-ĐIỂM a2', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            62, 0, 0,
            62, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3602'))
       OR "Sku" = 'HH089'
    ORDER BY CASE WHEN "Sku" = 'HH089' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH089',
            "Name" = 'LXP3602',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 4,
            "StockWarehouse2" = 0,
            "TotalStock" = 4,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH089', 'LXP3602', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            4, 0, 0,
            4, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3603'))
       OR "Sku" = 'HH090'
    ORDER BY CASE WHEN "Sku" = 'HH090' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH090',
            "Name" = 'LXP3603',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 13,
            "StockWarehouse2" = 0,
            "TotalStock" = 13,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH090', 'LXP3603', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            13, 0, 0,
            13, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3602-ĐIỂM'))
       OR "Sku" = 'HH091'
    ORDER BY CASE WHEN "Sku" = 'HH091' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH091',
            "Name" = 'LXP3602-ĐIỂM',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 14,
            "StockWarehouse2" = 0,
            "TotalStock" = 14,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH091', 'LXP3602-ĐIỂM', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            14, 0, 0,
            14, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3606'))
       OR "Sku" = 'HH092'
    ORDER BY CASE WHEN "Sku" = 'HH092' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH092',
            "Name" = 'LXP3606',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 35,
            "StockWarehouse2" = 0,
            "TotalStock" = 35,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH092', 'LXP3606', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            35, 0, 0,
            35, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3607'))
       OR "Sku" = 'HH093'
    ORDER BY CASE WHEN "Sku" = 'HH093' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH093',
            "Name" = 'LXP3607',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 79,
            "StockWarehouse2" = 0,
            "TotalStock" = 79,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH093', 'LXP3607', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            79, 0, 0,
            79, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP3606-ĐIỂM'))
       OR "Sku" = 'HH094'
    ORDER BY CASE WHEN "Sku" = 'HH094' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH094',
            "Name" = 'LXP3606-ĐIỂM',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 41,
            "StockWarehouse2" = 0,
            "TotalStock" = 41,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH094', 'LXP3606-ĐIỂM', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            41, 0, 0,
            41, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP936.131-KHÓI TRẮNG'))
       OR "Sku" = 'HH095'
    ORDER BY CASE WHEN "Sku" = 'HH095' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH095',
            "Name" = 'LP936.131-KHÓI TRẮNG',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 6,
            "StockWarehouse2" = 0,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH095', 'LP936.131-KHÓI TRẮNG', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            6, 0, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP936.132'))
       OR "Sku" = 'HH096'
    ORDER BY CASE WHEN "Sku" = 'HH096' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH096',
            "Name" = 'LP936.132',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 25,
            "StockWarehouse2" = 0,
            "TotalStock" = 25,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH096', 'LP936.132', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            25, 0, 0,
            25, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP936.133'))
       OR "Sku" = 'HH097'
    ORDER BY CASE WHEN "Sku" = 'HH097' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH097',
            "Name" = 'LP936.133',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH097', 'LP936.133', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP936.132-ĐIỂM'))
       OR "Sku" = 'HH098'
    ORDER BY CASE WHEN "Sku" = 'HH098' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH098',
            "Name" = 'LP936.132-ĐIỂM',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH098', 'LP936.132-ĐIỂM', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP936.134'))
       OR "Sku" = 'HH099'
    ORDER BY CASE WHEN "Sku" = 'HH099' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH099',
            "Name" = 'LP936.134',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 4,
            "StockWarehouse2" = 0,
            "TotalStock" = 4,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH099', 'LP936.134', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            4, 0, 0,
            4, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP936.135'))
       OR "Sku" = 'HH100'
    ORDER BY CASE WHEN "Sku" = 'HH100' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH100',
            "Name" = 'LP936.135',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 76,
            "StockWarehouse2" = 0,
            "TotalStock" = 76,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH100', 'LP936.135', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            76, 0, 0,
            76, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP936.134-ĐIỂM'))
       OR "Sku" = 'HH101'
    ORDER BY CASE WHEN "Sku" = 'HH101' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH101',
            "Name" = 'LP936.134-ĐIỂM',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 41,
            "StockWarehouse2" = 0,
            "TotalStock" = 41,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH101', 'LP936.134-ĐIỂM', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            41, 0, 0,
            41, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV3600'))
       OR "Sku" = 'HH102'
    ORDER BY CASE WHEN "Sku" = 'HH102' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH102',
            "Name" = 'LV3600',
            "Category" = '30*60 ĐƠN MẦU',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 530,
            "StockWarehouse2" = 0,
            "TotalStock" = 530,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH102', 'LV3600', '30*60 ĐƠN MẦU', 'Hộp', supp_id,
            0, 0, 0,
            530, 0, 0,
            530, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX36000'))
       OR "Sku" = 'HH103'
    ORDER BY CASE WHEN "Sku" = 'HH103' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH103',
            "Name" = 'LX36000',
            "Category" = '30*60 ĐƠN MẦU',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 689,
            "StockWarehouse2" = 0,
            "TotalStock" = 689,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH103', 'LX36000', '30*60 ĐƠN MẦU', 'Hộp', supp_id,
            0, 0, 0,
            689, 0, 0,
            689, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX36601'))
       OR "Sku" = 'HH104'
    ORDER BY CASE WHEN "Sku" = 'HH104' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH104',
            "Name" = 'LX36601',
            "Category" = '30*60 ĐƠN MẦU',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 497,
            "StockWarehouse2" = 0,
            "TotalStock" = 497,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH104', 'LX36601', '30*60 ĐƠN MẦU', 'Hộp', supp_id,
            0, 0, 0,
            497, 0, 0,
            497, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV3652--h13'))
       OR "Sku" = 'HH105'
    ORDER BY CASE WHEN "Sku" = 'HH105' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH105',
            "Name" = 'LV3652--h13',
            "Category" = '30*60 ĐƠN MẦU',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 491,
            "StockWarehouse2" = 0,
            "TotalStock" = 491,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH105', 'LV3652--h13', '30*60 ĐƠN MẦU', 'Hộp', supp_id,
            0, 0, 0,
            491, 0, 0,
            491, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV3658'))
       OR "Sku" = 'HH106'
    ORDER BY CASE WHEN "Sku" = 'HH106' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH106',
            "Name" = 'LV3658',
            "Category" = '30*60 ĐƠN MẦU',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 98,
            "StockWarehouse2" = 0,
            "TotalStock" = 98,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH106', 'LV3658', '30*60 ĐƠN MẦU', 'Hộp', supp_id,
            0, 0, 0,
            98, 0, 0,
            98, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LV3650'))
       OR "Sku" = 'HH107'
    ORDER BY CASE WHEN "Sku" = 'HH107' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH107',
            "Name" = 'LV3650',
            "Category" = '30*60 ĐƠN MẦU',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 61,
            "StockWarehouse2" = 0,
            "TotalStock" = 61,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH107', 'LV3650', '30*60 ĐƠN MẦU', 'Hộp', supp_id,
            0, 0, 0,
            61, 0, 0,
            61, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3601-T'))
       OR "Sku" = 'HH108'
    ORDER BY CASE WHEN "Sku" = 'HH108' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH108',
            "Name" = 'LX3601-T',
            "Category" = '30*60 TRANG TRÍ BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 6,
            "StockWarehouse2" = 0,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH108', 'LX3601-T', '30*60 TRANG TRÍ BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            6, 0, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3602-T'))
       OR "Sku" = 'HH109'
    ORDER BY CASE WHEN "Sku" = 'HH109' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH109',
            "Name" = 'LX3602-T',
            "Category" = '30*60 TRANG TRÍ BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 43,
            "StockWarehouse2" = 0,
            "TotalStock" = 43,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH109', 'LX3602-T', '30*60 TRANG TRÍ BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            43, 0, 0,
            43, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3603-T'))
       OR "Sku" = 'HH110'
    ORDER BY CASE WHEN "Sku" = 'HH110' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH110',
            "Name" = 'LX3603-T',
            "Category" = '30*60 TRANG TRÍ BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 74,
            "StockWarehouse2" = 0,
            "TotalStock" = 74,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH110', 'LX3603-T', '30*60 TRANG TRÍ BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            74, 0, 0,
            74, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3604-T'))
       OR "Sku" = 'HH111'
    ORDER BY CASE WHEN "Sku" = 'HH111' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH111',
            "Name" = 'LX3604-T',
            "Category" = '30*60 TRANG TRÍ BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 16,
            "StockWarehouse2" = 0,
            "TotalStock" = 16,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH111', 'LX3604-T', '30*60 TRANG TRÍ BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            16, 0, 0,
            16, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK3605T'))
       OR "Sku" = 'HH112'
    ORDER BY CASE WHEN "Sku" = 'HH112' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH112',
            "Name" = 'LXK3605T',
            "Category" = '30*60 TRANG TRI ĐỊNH HÌNH',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 72,
            "StockWarehouse2" = 0,
            "TotalStock" = 72,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH112', 'LXK3605T', '30*60 TRANG TRI ĐỊNH HÌNH', 'Hộp', supp_id,
            0, 0, 0,
            72, 0, 0,
            72, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK3606T'))
       OR "Sku" = 'HH113'
    ORDER BY CASE WHEN "Sku" = 'HH113' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH113',
            "Name" = 'LXK3606T',
            "Category" = '30*60 TRANG TRI ĐỊNH HÌNH',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 108,
            "StockWarehouse2" = 0,
            "TotalStock" = 108,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH113', 'LXK3606T', '30*60 TRANG TRI ĐỊNH HÌNH', 'Hộp', supp_id,
            0, 0, 0,
            108, 0, 0,
            108, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK3607T'))
       OR "Sku" = 'HH114'
    ORDER BY CASE WHEN "Sku" = 'HH114' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH114',
            "Name" = 'LXK3607T',
            "Category" = '30*60 TRANG TRI ĐỊNH HÌNH',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 115,
            "StockWarehouse2" = 0,
            "TotalStock" = 115,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH114', 'LXK3607T', '30*60 TRANG TRI ĐỊNH HÌNH', 'Hộp', supp_id,
            0, 0, 0,
            115, 0, 0,
            115, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK3608T'))
       OR "Sku" = 'HH115'
    ORDER BY CASE WHEN "Sku" = 'HH115' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH115',
            "Name" = 'LXK3608T',
            "Category" = '30*60 TRANG TRI ĐỊNH HÌNH',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 119,
            "StockWarehouse2" = 0,
            "TotalStock" = 119,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH115', 'LXK3608T', '30*60 TRANG TRI ĐỊNH HÌNH', 'Hộp', supp_id,
            0, 0, 0,
            119, 0, 0,
            119, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3634'))
       OR "Sku" = 'HH116'
    ORDER BY CASE WHEN "Sku" = 'HH116' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH116',
            "Name" = 'LX3634',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 82,
            "StockWarehouse2" = 0,
            "TotalStock" = 82,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH116', 'LX3634', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            82, 0, 0,
            82, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3635'))
       OR "Sku" = 'HH117'
    ORDER BY CASE WHEN "Sku" = 'HH117' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH117',
            "Name" = 'LX3635',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 31,
            "StockWarehouse2" = 0,
            "TotalStock" = 31,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH117', 'LX3635', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            31, 0, 0,
            31, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3634-ĐIỂM'))
       OR "Sku" = 'HH118'
    ORDER BY CASE WHEN "Sku" = 'HH118' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH118',
            "Name" = 'LX3634-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 31,
            "StockWarehouse2" = 0,
            "TotalStock" = 31,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH118', 'LX3634-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            31, 0, 0,
            31, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3636'))
       OR "Sku" = 'HH119'
    ORDER BY CASE WHEN "Sku" = 'HH119' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH119',
            "Name" = 'LX3636',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 249,
            "StockWarehouse2" = 0,
            "TotalStock" = 249,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH119', 'LX3636', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            249, 0, 0,
            249, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3637'))
       OR "Sku" = 'HH120'
    ORDER BY CASE WHEN "Sku" = 'HH120' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH120',
            "Name" = 'LX3637',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 146,
            "StockWarehouse2" = 0,
            "TotalStock" = 146,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH120', 'LX3637', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            146, 0, 0,
            146, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3636-ĐIỂM'))
       OR "Sku" = 'HH121'
    ORDER BY CASE WHEN "Sku" = 'HH121' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH121',
            "Name" = 'LX3636-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 81,
            "StockWarehouse2" = 0,
            "TotalStock" = 81,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH121', 'LX3636-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            81, 0, 0,
            81, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3638'))
       OR "Sku" = 'HH122'
    ORDER BY CASE WHEN "Sku" = 'HH122' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH122',
            "Name" = 'LX3638',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH122', 'LX3638', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3639'))
       OR "Sku" = 'HH123'
    ORDER BY CASE WHEN "Sku" = 'HH123' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH123',
            "Name" = 'LX3639',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH123', 'LX3639', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3638-ĐIỂM'))
       OR "Sku" = 'HH124'
    ORDER BY CASE WHEN "Sku" = 'HH124' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH124',
            "Name" = 'LX3638-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 24,
            "StockWarehouse2" = 0,
            "TotalStock" = 24,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH124', 'LX3638-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            24, 0, 0,
            24, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3658'))
       OR "Sku" = 'HH125'
    ORDER BY CASE WHEN "Sku" = 'HH125' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH125',
            "Name" = 'LX3658',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 14,
            "StockWarehouse2" = 0,
            "TotalStock" = 14,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH125', 'LX3658', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            14, 0, 0,
            14, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3659'))
       OR "Sku" = 'HH126'
    ORDER BY CASE WHEN "Sku" = 'HH126' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH126',
            "Name" = 'LX3659',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 48,
            "StockWarehouse2" = 0,
            "TotalStock" = 48,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH126', 'LX3659', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            48, 0, 0,
            48, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3658 -ĐIỂM'))
       OR "Sku" = 'HH127'
    ORDER BY CASE WHEN "Sku" = 'HH127' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH127',
            "Name" = 'LX3658 -ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 7,
            "StockWarehouse2" = 0,
            "TotalStock" = 7,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH127', 'LX3658 -ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            7, 0, 0,
            7, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3662'))
       OR "Sku" = 'HH128'
    ORDER BY CASE WHEN "Sku" = 'HH128' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH128',
            "Name" = 'LX3662',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 168,
            "StockWarehouse2" = 0,
            "TotalStock" = 168,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH128', 'LX3662', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            168, 0, 0,
            168, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3663'))
       OR "Sku" = 'HH129'
    ORDER BY CASE WHEN "Sku" = 'HH129' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH129',
            "Name" = 'LX3663',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 73,
            "StockWarehouse2" = 0,
            "TotalStock" = 73,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH129', 'LX3663', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            73, 0, 0,
            73, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3662-ĐIỂM'))
       OR "Sku" = 'HH130'
    ORDER BY CASE WHEN "Sku" = 'HH130' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH130',
            "Name" = 'LX3662-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 29,
            "StockWarehouse2" = 0,
            "TotalStock" = 29,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH130', 'LX3662-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            29, 0, 0,
            29, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3664'))
       OR "Sku" = 'HH131'
    ORDER BY CASE WHEN "Sku" = 'HH131' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH131',
            "Name" = 'LX3664',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 62,
            "StockWarehouse2" = 0,
            "TotalStock" = 62,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH131', 'LX3664', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            62, 0, 0,
            62, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3665'))
       OR "Sku" = 'HH132'
    ORDER BY CASE WHEN "Sku" = 'HH132' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH132',
            "Name" = 'LX3665',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 44,
            "StockWarehouse2" = 0,
            "TotalStock" = 44,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH132', 'LX3665', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            44, 0, 0,
            44, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3664-ĐIỂM'))
       OR "Sku" = 'HH133'
    ORDER BY CASE WHEN "Sku" = 'HH133' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH133',
            "Name" = 'LX3664-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 42,
            "StockWarehouse2" = 0,
            "TotalStock" = 42,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH133', 'LX3664-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            42, 0, 0,
            42, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3666'))
       OR "Sku" = 'HH134'
    ORDER BY CASE WHEN "Sku" = 'HH134' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH134',
            "Name" = 'LX3666',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 182,
            "StockWarehouse2" = 0,
            "TotalStock" = 182,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH134', 'LX3666', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            182, 0, 0,
            182, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3667'))
       OR "Sku" = 'HH135'
    ORDER BY CASE WHEN "Sku" = 'HH135' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH135',
            "Name" = 'LX3667',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 131,
            "StockWarehouse2" = 0,
            "TotalStock" = 131,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH135', 'LX3667', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            131, 0, 0,
            131, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3666-ĐIỂM'))
       OR "Sku" = 'HH136'
    ORDER BY CASE WHEN "Sku" = 'HH136' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH136',
            "Name" = 'LX3666-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 41,
            "StockWarehouse2" = 0,
            "TotalStock" = 41,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH136', 'LX3666-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            41, 0, 0,
            41, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3668'))
       OR "Sku" = 'HH137'
    ORDER BY CASE WHEN "Sku" = 'HH137' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH137',
            "Name" = 'LX3668',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 46,
            "StockWarehouse2" = 0,
            "TotalStock" = 46,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH137', 'LX3668', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            46, 0, 0,
            46, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3669'))
       OR "Sku" = 'HH138'
    ORDER BY CASE WHEN "Sku" = 'HH138' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH138',
            "Name" = 'LX3669',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 27,
            "StockWarehouse2" = 0,
            "TotalStock" = 27,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH138', 'LX3669', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            27, 0, 0,
            27, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3668-ĐIỂM'))
       OR "Sku" = 'HH139'
    ORDER BY CASE WHEN "Sku" = 'HH139' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH139',
            "Name" = 'LX3668-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 13,
            "StockWarehouse2" = 0,
            "TotalStock" = 13,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH139', 'LX3668-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            13, 0, 0,
            13, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXM3670'))
       OR "Sku" = 'HH140'
    ORDER BY CASE WHEN "Sku" = 'HH140' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH140',
            "Name" = 'LXM3670',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 187,
            "StockWarehouse2" = 0,
            "TotalStock" = 187,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH140', 'LXM3670', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            187, 0, 0,
            187, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXM3671'))
       OR "Sku" = 'HH141'
    ORDER BY CASE WHEN "Sku" = 'HH141' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH141',
            "Name" = 'LXM3671',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 93,
            "StockWarehouse2" = 0,
            "TotalStock" = 93,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH141', 'LXM3671', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            93, 0, 0,
            93, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXM3670-ĐIỂM'))
       OR "Sku" = 'HH142'
    ORDER BY CASE WHEN "Sku" = 'HH142' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH142',
            "Name" = 'LXM3670-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 60,
            "StockWarehouse2" = 0,
            "TotalStock" = 60,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH142', 'LXM3670-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            60, 0, 0,
            60, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXM3672'))
       OR "Sku" = 'HH143'
    ORDER BY CASE WHEN "Sku" = 'HH143' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH143',
            "Name" = 'LXM3672',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 172,
            "StockWarehouse2" = 0,
            "TotalStock" = 172,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH143', 'LXM3672', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            172, 0, 0,
            172, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXM3673'))
       OR "Sku" = 'HH144'
    ORDER BY CASE WHEN "Sku" = 'HH144' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH144',
            "Name" = 'LXM3673',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 178,
            "StockWarehouse2" = 0,
            "TotalStock" = 178,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH144', 'LXM3673', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            178, 0, 0,
            178, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXM3672-ĐIỂM'))
       OR "Sku" = 'HH145'
    ORDER BY CASE WHEN "Sku" = 'HH145' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH145',
            "Name" = 'LXM3672-ĐIỂM',
            "Category" = 'ỐP BỘ 30*60 C',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 21,
            "StockWarehouse2" = 0,
            "TotalStock" = 21,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH145', 'LXM3672-ĐIỂM', 'ỐP BỘ 30*60 C', 'Hộp', supp_id,
            0, 0, 0,
            21, 0, 0,
            21, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3686'))
       OR "Sku" = 'HH146'
    ORDER BY CASE WHEN "Sku" = 'HH146' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH146',
            "Name" = 'LX3686',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 324,
            "StockWarehouse2" = 0,
            "TotalStock" = 324,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH146', 'LX3686', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            324, 0, 0,
            324, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3687'))
       OR "Sku" = 'HH147'
    ORDER BY CASE WHEN "Sku" = 'HH147' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH147',
            "Name" = 'LX3687',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 179,
            "StockWarehouse2" = 0,
            "TotalStock" = 179,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH147', 'LX3687', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            179, 0, 0,
            179, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3686 ĐIỂM'))
       OR "Sku" = 'HH148'
    ORDER BY CASE WHEN "Sku" = 'HH148' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH148',
            "Name" = 'LX3686 ĐIỂM',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 38,
            "StockWarehouse2" = 0,
            "TotalStock" = 38,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH148', 'LX3686 ĐIỂM', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            38, 0, 0,
            38, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3688'))
       OR "Sku" = 'HH149'
    ORDER BY CASE WHEN "Sku" = 'HH149' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH149',
            "Name" = 'LX3688',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 212,
            "StockWarehouse2" = 0,
            "TotalStock" = 212,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH149', 'LX3688', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            212, 0, 0,
            212, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3689'))
       OR "Sku" = 'HH150'
    ORDER BY CASE WHEN "Sku" = 'HH150' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH150',
            "Name" = 'LX3689',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 197,
            "StockWarehouse2" = 0,
            "TotalStock" = 197,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH150', 'LX3689', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            197, 0, 0,
            197, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3688 ĐIỂM'))
       OR "Sku" = 'HH151'
    ORDER BY CASE WHEN "Sku" = 'HH151' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH151',
            "Name" = 'LX3688 ĐIỂM',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 43,
            "StockWarehouse2" = 0,
            "TotalStock" = 43,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH151', 'LX3688 ĐIỂM', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            43, 0, 0,
            43, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3690'))
       OR "Sku" = 'HH152'
    ORDER BY CASE WHEN "Sku" = 'HH152' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH152',
            "Name" = 'LX3690',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 322,
            "StockWarehouse2" = 0,
            "TotalStock" = 322,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH152', 'LX3690', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            322, 0, 0,
            322, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3691'))
       OR "Sku" = 'HH153'
    ORDER BY CASE WHEN "Sku" = 'HH153' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH153',
            "Name" = 'LX3691',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 189,
            "StockWarehouse2" = 0,
            "TotalStock" = 189,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH153', 'LX3691', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            189, 0, 0,
            189, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3690 ĐIỂM'))
       OR "Sku" = 'HH154'
    ORDER BY CASE WHEN "Sku" = 'HH154' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH154',
            "Name" = 'LX3690 ĐIỂM',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 37,
            "StockWarehouse2" = 0,
            "TotalStock" = 37,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH154', 'LX3690 ĐIỂM', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            37, 0, 0,
            37, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3617'))
       OR "Sku" = 'HH155'
    ORDER BY CASE WHEN "Sku" = 'HH155' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH155',
            "Name" = 'LX3617',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 21,
            "StockWarehouse2" = 0,
            "TotalStock" = 21,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH155', 'LX3617', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            21, 0, 0,
            21, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3629'))
       OR "Sku" = 'HH156'
    ORDER BY CASE WHEN "Sku" = 'HH156' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH156',
            "Name" = 'LX3629',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 245,
            "StockWarehouse2" = 0,
            "TotalStock" = 245,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH156', 'LX3629', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            245, 0, 0,
            245, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3622'))
       OR "Sku" = 'HH157'
    ORDER BY CASE WHEN "Sku" = 'HH157' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH157',
            "Name" = 'LX3622',
            "Category" = 'ỐP MỚI',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 29,
            "StockWarehouse2" = 0,
            "TotalStock" = 29,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH157', 'LX3622', 'ỐP MỚI', 'Hộp', supp_id,
            0, 0, 0,
            29, 0, 0,
            29, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX335'))
       OR "Sku" = 'HH158'
    ORDER BY CASE WHEN "Sku" = 'HH158' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH158',
            "Name" = 'LX335',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 70,
            "StockWarehouse2" = 0,
            "TotalStock" = 70,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH158', 'LX335', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            70, 0, 0,
            70, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LK303'))
       OR "Sku" = 'HH159'
    ORDER BY CASE WHEN "Sku" = 'HH159' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH159',
            "Name" = 'LK303',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 122,
            "StockWarehouse2" = 0,
            "TotalStock" = 122,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH159', 'LK303', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            122, 0, 0,
            122, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3802'))
       OR "Sku" = 'HH160'
    ORDER BY CASE WHEN "Sku" = 'HH160' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH160',
            "Name" = 'LX3802',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 56,
            "StockWarehouse2" = 0,
            "TotalStock" = 56,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH160', 'LX3802', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            56, 0, 0,
            56, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXP303'))
       OR "Sku" = 'HH161'
    ORDER BY CASE WHEN "Sku" = 'HH161' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH161',
            "Name" = 'LXP303',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 50,
            "StockWarehouse2" = 0,
            "TotalStock" = 50,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH161', 'LXP303', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            50, 0, 0,
            50, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX337'))
       OR "Sku" = 'HH162'
    ORDER BY CASE WHEN "Sku" = 'HH162' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH162',
            "Name" = 'LX337',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 170,
            "StockWarehouse2" = 0,
            "TotalStock" = 170,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH162', 'LX337', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            170, 0, 0,
            170, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX367'))
       OR "Sku" = 'HH163'
    ORDER BY CASE WHEN "Sku" = 'HH163' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH163',
            "Name" = 'LX367',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH163', 'LX367', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX369'))
       OR "Sku" = 'HH164'
    ORDER BY CASE WHEN "Sku" = 'HH164' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH164',
            "Name" = 'LX369',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 24,
            "StockWarehouse2" = 0,
            "TotalStock" = 24,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH164', 'LX369', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            24, 0, 0,
            24, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX3133'))
       OR "Sku" = 'HH165'
    ORDER BY CASE WHEN "Sku" = 'HH165' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH165',
            "Name" = 'LX3133',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 18,
            "StockWarehouse2" = 0,
            "TotalStock" = 18,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH165', 'LX3133', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            18, 0, 0,
            18, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LK305-h1'))
       OR "Sku" = 'HH166'
    ORDER BY CASE WHEN "Sku" = 'HH166' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH166',
            "Name" = 'LK305-h1',
            "Category" = '30*30 CT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 5,
            "StockWarehouse2" = 0,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH166', 'LK305-h1', '30*30 CT', 'Hộp', supp_id,
            0, 0, 0,
            5, 0, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5516'))
       OR "Sku" = 'HH167'
    ORDER BY CASE WHEN "Sku" = 'HH167' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH167',
            "Name" = 'LX5516',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 218,
            "StockWarehouse2" = 0,
            "TotalStock" = 218,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH167', 'LX5516', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            218, 0, 0,
            218, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5516 A2'))
       OR "Sku" = 'HH168'
    ORDER BY CASE WHEN "Sku" = 'HH168' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH168',
            "Name" = 'LX5516 A2',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 110,
            "StockWarehouse2" = 0,
            "TotalStock" = 110,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH168', 'LX5516 A2', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            110, 0, 0,
            110, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5521'))
       OR "Sku" = 'HH169'
    ORDER BY CASE WHEN "Sku" = 'HH169' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH169',
            "Name" = 'LX5521',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 52,
            "StockWarehouse2" = 0,
            "TotalStock" = 52,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH169', 'LX5521', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            52, 0, 0,
            52, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5524'))
       OR "Sku" = 'HH170'
    ORDER BY CASE WHEN "Sku" = 'HH170' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH170',
            "Name" = 'LX5524',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 602,
            "StockWarehouse2" = 0,
            "TotalStock" = 602,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH170', 'LX5524', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            602, 0, 0,
            602, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5524 A2'))
       OR "Sku" = 'HH171'
    ORDER BY CASE WHEN "Sku" = 'HH171' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH171',
            "Name" = 'LX5524 A2',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 128,
            "StockWarehouse2" = 0,
            "TotalStock" = 128,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH171', 'LX5524 A2', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            128, 0, 0,
            128, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5525'))
       OR "Sku" = 'HH172'
    ORDER BY CASE WHEN "Sku" = 'HH172' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH172',
            "Name" = 'LX5525',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 59,
            "StockWarehouse2" = 0,
            "TotalStock" = 59,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH172', 'LX5525', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            59, 0, 0,
            59, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5525 A2'))
       OR "Sku" = 'HH173'
    ORDER BY CASE WHEN "Sku" = 'HH173' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH173',
            "Name" = 'LX5525 A2',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 942,
            "StockWarehouse2" = 0,
            "TotalStock" = 942,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH173', 'LX5525 A2', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            942, 0, 0,
            942, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX5527'))
       OR "Sku" = 'HH174'
    ORDER BY CASE WHEN "Sku" = 'HH174' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH174',
            "Name" = 'LX5527',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 127,
            "StockWarehouse2" = 0,
            "TotalStock" = 127,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH174', 'LX5527', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            127, 0, 0,
            127, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('NH5601'))
       OR "Sku" = 'HH175'
    ORDER BY CASE WHEN "Sku" = 'HH175' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH175',
            "Name" = 'NH5601',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 141,
            "StockWarehouse2" = 0,
            "TotalStock" = 141,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH175', 'NH5601', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            141, 0, 0,
            141, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('NH5602'))
       OR "Sku" = 'HH176'
    ORDER BY CASE WHEN "Sku" = 'HH176' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH176',
            "Name" = 'NH5602',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 123,
            "StockWarehouse2" = 0,
            "TotalStock" = 123,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH176', 'NH5602', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            123, 0, 0,
            123, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('NH5603'))
       OR "Sku" = 'HH177'
    ORDER BY CASE WHEN "Sku" = 'HH177' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH177',
            "Name" = 'NH5603',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 482,
            "StockWarehouse2" = 0,
            "TotalStock" = 482,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH177', 'NH5603', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            482, 0, 0,
            482, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('NH5604'))
       OR "Sku" = 'HH178'
    ORDER BY CASE WHEN "Sku" = 'HH178' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH178',
            "Name" = 'NH5604',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 614,
            "StockWarehouse2" = 0,
            "TotalStock" = 614,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH178', 'NH5604', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            614, 0, 0,
            614, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('NH5604 A2'))
       OR "Sku" = 'HH179'
    ORDER BY CASE WHEN "Sku" = 'HH179' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH179',
            "Name" = 'NH5604 A2',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH179', 'NH5604 A2', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('NH5605'))
       OR "Sku" = 'HH180'
    ORDER BY CASE WHEN "Sku" = 'HH180' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH180',
            "Name" = 'NH5605',
            "Category" = '50 *50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 271,
            "StockWarehouse2" = 0,
            "TotalStock" = 271,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH180', 'NH5605', '50 *50 SV', 'Hộp', supp_id,
            0, 0, 0,
            271, 0, 0,
            271, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('HXK-503 A1'))
       OR "Sku" = 'HH181'
    ORDER BY CASE WHEN "Sku" = 'HH181' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH181',
            "Name" = 'HXK-503 A1',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 28,
            "StockWarehouse2" = 0,
            "TotalStock" = 28,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH181', 'HXK-503 A1', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            28, 0, 0,
            28, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('HXK-503 B'))
       OR "Sku" = 'HH182'
    ORDER BY CASE WHEN "Sku" = 'HH182' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH182',
            "Name" = 'HXK-503 B',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH182', 'HXK-503 B', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('HM5028-MÁT'))
       OR "Sku" = 'HH183'
    ORDER BY CASE WHEN "Sku" = 'HH183' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH183',
            "Name" = 'HM5028-MÁT',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 270,
            "StockWarehouse2" = 0,
            "TotalStock" = 270,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH183', 'HM5028-MÁT', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            270, 0, 0,
            270, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('HM5028- MÁT B'))
       OR "Sku" = 'HH184'
    ORDER BY CASE WHEN "Sku" = 'HH184' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH184',
            "Name" = 'HM5028- MÁT B',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 11,
            "StockWarehouse2" = 0,
            "TotalStock" = 11,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH184', 'HM5028- MÁT B', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            11, 0, 0,
            11, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('HUS 5018-SUGAR'))
       OR "Sku" = 'HH185'
    ORDER BY CASE WHEN "Sku" = 'HH185' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH185',
            "Name" = 'HUS 5018-SUGAR',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 5,
            "StockWarehouse2" = 0,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH185', 'HUS 5018-SUGAR', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            5, 0, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('HG5407 A2'))
       OR "Sku" = 'HH186'
    ORDER BY CASE WHEN "Sku" = 'HH186' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH186',
            "Name" = 'HG5407 A2',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 7,
            "StockWarehouse2" = 0,
            "TotalStock" = 7,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH186', 'HG5407 A2', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            7, 0, 0,
            7, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('HS514 A1'))
       OR "Sku" = 'HH187'
    ORDER BY CASE WHEN "Sku" = 'HH187' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH187',
            "Name" = 'HS514 A1',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 2,
            "StockWarehouse2" = 0,
            "TotalStock" = 2,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH187', 'HS514 A1', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            2, 0, 0,
            2, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6905'))
       OR "Sku" = 'HH188'
    ORDER BY CASE WHEN "Sku" = 'HH188' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH188',
            "Name" = 'LX6905',
            "Category" = '60*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 5,
            "StockWarehouse2" = 0,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH188', 'LX6905', '60*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            5, 0, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXV6801'))
       OR "Sku" = 'HH189'
    ORDER BY CASE WHEN "Sku" = 'HH189' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH189',
            "Name" = 'LXV6801',
            "Category" = '60*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 1,
            "StockWarehouse2" = 0,
            "TotalStock" = 1,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH189', 'LXV6801', '60*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            1, 0, 0,
            1, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXV6802'))
       OR "Sku" = 'HH190'
    ORDER BY CASE WHEN "Sku" = 'HH190' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH190',
            "Name" = 'LXV6802',
            "Category" = '60*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 252,
            "StockWarehouse2" = 0,
            "TotalStock" = 252,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH190', 'LXV6802', '60*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            252, 0, 0,
            252, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXV6806'))
       OR "Sku" = 'HH191'
    ORDER BY CASE WHEN "Sku" = 'HH191' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH191',
            "Name" = 'LXV6806',
            "Category" = '60*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 97,
            "StockWarehouse2" = 0,
            "TotalStock" = 97,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH191', 'LXV6806', '60*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            97, 0, 0,
            97, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX6903'))
       OR "Sku" = 'HH192'
    ORDER BY CASE WHEN "Sku" = 'HH192' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH192',
            "Name" = 'LX6903',
            "Category" = '60*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 90,
            "StockWarehouse2" = 0,
            "TotalStock" = 90,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH192', 'LX6903', '60*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            90, 0, 0,
            90, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX46001'))
       OR "Sku" = 'HH193'
    ORDER BY CASE WHEN "Sku" = 'HH193' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH193',
            "Name" = 'LX46001',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 285,
            "StockWarehouse2" = 0,
            "TotalStock" = 285,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH193', 'LX46001', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            285, 0, 0,
            285, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LX46002'))
       OR "Sku" = 'HH194'
    ORDER BY CASE WHEN "Sku" = 'HH194' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH194',
            "Name" = 'LX46002',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 506,
            "StockWarehouse2" = 0,
            "TotalStock" = 506,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH194', 'LX46002', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            506, 0, 0,
            506, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK46050'))
       OR "Sku" = 'HH195'
    ORDER BY CASE WHEN "Sku" = 'HH195' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH195',
            "Name" = 'LXK46050',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 54,
            "StockWarehouse2" = 0,
            "TotalStock" = 54,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH195', 'LXK46050', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            54, 0, 0,
            54, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK46051'))
       OR "Sku" = 'HH196'
    ORDER BY CASE WHEN "Sku" = 'HH196' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH196',
            "Name" = 'LXK46051',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 43,
            "StockWarehouse2" = 0,
            "TotalStock" = 43,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH196', 'LXK46051', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            43, 0, 0,
            43, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK46052'))
       OR "Sku" = 'HH197'
    ORDER BY CASE WHEN "Sku" = 'HH197' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH197',
            "Name" = 'LXK46052',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 25,
            "StockWarehouse2" = 0,
            "TotalStock" = 25,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH197', 'LXK46052', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            25, 0, 0,
            25, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LXK46054'))
       OR "Sku" = 'HH198'
    ORDER BY CASE WHEN "Sku" = 'HH198' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH198',
            "Name" = 'LXK46054',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 474,
            "StockWarehouse2" = 0,
            "TotalStock" = 474,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH198', 'LXK46054', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            474, 0, 0,
            474, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LH46004'))
       OR "Sku" = 'HH199'
    ORDER BY CASE WHEN "Sku" = 'HH199' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH199',
            "Name" = 'LH46004',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 64,
            "StockWarehouse2" = 0,
            "TotalStock" = 64,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH199', 'LH46004', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            64, 0, 0,
            64, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LH46005'))
       OR "Sku" = 'HH200'
    ORDER BY CASE WHEN "Sku" = 'HH200' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH200',
            "Name" = 'LH46005',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 212,
            "StockWarehouse2" = 0,
            "TotalStock" = 212,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH200', 'LH46005', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            212, 0, 0,
            212, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LH46006'))
       OR "Sku" = 'HH201'
    ORDER BY CASE WHEN "Sku" = 'HH201' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH201',
            "Name" = 'LH46006',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 85,
            "StockWarehouse2" = 0,
            "TotalStock" = 85,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH201', 'LH46006', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            85, 0, 0,
            85, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LHK46055'))
       OR "Sku" = 'HH202'
    ORDER BY CASE WHEN "Sku" = 'HH202' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH202',
            "Name" = 'LHK46055',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 84,
            "StockWarehouse2" = 0,
            "TotalStock" = 84,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH202', 'LHK46055', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            84, 0, 0,
            84, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LHK46056'))
       OR "Sku" = 'HH203'
    ORDER BY CASE WHEN "Sku" = 'HH203' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH203',
            "Name" = 'LHK46056',
            "Category" = '40*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 164,
            "StockWarehouse2" = 0,
            "TotalStock" = 164,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH203', 'LHK46056', '40*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            164, 0, 0,
            164, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP 46-120'))
       OR "Sku" = 'HH204'
    ORDER BY CASE WHEN "Sku" = 'HH204' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH204',
            "Name" = 'LP 46-120',
            "Category" = '40*60 dầy 12m',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 240,
            "StockWarehouse2" = 0,
            "TotalStock" = 240,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH204', 'LP 46-120', '40*60 dầy 12m', 'Hộp', supp_id,
            0, 0, 0,
            240, 0, 0,
            240, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP 46-121'))
       OR "Sku" = 'HH205'
    ORDER BY CASE WHEN "Sku" = 'HH205' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH205',
            "Name" = 'LP 46-121',
            "Category" = '40*60 dầy 12m',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 192,
            "StockWarehouse2" = 0,
            "TotalStock" = 192,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH205', 'LP 46-121', '40*60 dầy 12m', 'Hộp', supp_id,
            0, 0, 0,
            192, 0, 0,
            192, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP 46-122'))
       OR "Sku" = 'HH206'
    ORDER BY CASE WHEN "Sku" = 'HH206' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH206',
            "Name" = 'LP 46-122',
            "Category" = '40*60 dầy 12m',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 240,
            "StockWarehouse2" = 0,
            "TotalStock" = 240,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH206', 'LP 46-122', '40*60 dầy 12m', 'Hộp', supp_id,
            0, 0, 0,
            240, 0, 0,
            240, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LP 46-123'))
       OR "Sku" = 'HH207'
    ORDER BY CASE WHEN "Sku" = 'HH207' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH207',
            "Name" = 'LP 46-123',
            "Category" = '40*60 dầy 12m',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 192,
            "StockWarehouse2" = 0,
            "TotalStock" = 192,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH207', 'LP 46-123', '40*60 dầy 12m', 'Hộp', supp_id,
            0, 0, 0,
            192, 0, 0,
            192, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX412'))
       OR "Sku" = 'HH208'
    ORDER BY CASE WHEN "Sku" = 'HH208' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH208',
            "Name" = 'PLX412',
            "Category" = '40*40',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 87,
            "StockWarehouse2" = 0,
            "TotalStock" = 87,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH208', 'PLX412', '40*40', 'Hộp', supp_id,
            0, 0, 0,
            87, 0, 0,
            87, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX413'))
       OR "Sku" = 'HH209'
    ORDER BY CASE WHEN "Sku" = 'HH209' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH209',
            "Name" = 'PLX413',
            "Category" = '40*40',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 206,
            "StockWarehouse2" = 0,
            "TotalStock" = 206,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH209', 'PLX413', '40*40', 'Hộp', supp_id,
            0, 0, 0,
            206, 0, 0,
            206, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX415'))
       OR "Sku" = 'HH210'
    ORDER BY CASE WHEN "Sku" = 'HH210' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH210',
            "Name" = 'PLX415',
            "Category" = '40*40',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 187,
            "StockWarehouse2" = 0,
            "TotalStock" = 187,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH210', 'PLX415', '40*40', 'Hộp', supp_id,
            0, 0, 0,
            187, 0, 0,
            187, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX5011'))
       OR "Sku" = 'HH211'
    ORDER BY CASE WHEN "Sku" = 'HH211' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH211',
            "Name" = 'PLX5011',
            "Category" = '50*50 BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 124,
            "StockWarehouse2" = 0,
            "TotalStock" = 124,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH211', 'PLX5011', '50*50 BS', 'Hộp', supp_id,
            0, 0, 0,
            124, 0, 0,
            124, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX5012'))
       OR "Sku" = 'HH212'
    ORDER BY CASE WHEN "Sku" = 'HH212' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH212',
            "Name" = 'PLX5012',
            "Category" = '50*50 BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 363,
            "StockWarehouse2" = 0,
            "TotalStock" = 363,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH212', 'PLX5012', '50*50 BS', 'Hộp', supp_id,
            0, 0, 0,
            363, 0, 0,
            363, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX5013'))
       OR "Sku" = 'HH213'
    ORDER BY CASE WHEN "Sku" = 'HH213' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH213',
            "Name" = 'PLX5013',
            "Category" = '50*50 BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 253,
            "StockWarehouse2" = 0,
            "TotalStock" = 253,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH213', 'PLX5013', '50*50 BS', 'Hộp', supp_id,
            0, 0, 0,
            253, 0, 0,
            253, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX5014'))
       OR "Sku" = 'HH214'
    ORDER BY CASE WHEN "Sku" = 'HH214' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH214',
            "Name" = 'PLX5014',
            "Category" = '50*50 BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 166,
            "StockWarehouse2" = 0,
            "TotalStock" = 166,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH214', 'PLX5014', '50*50 BS', 'Hộp', supp_id,
            0, 0, 0,
            166, 0, 0,
            166, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX5015'))
       OR "Sku" = 'HH215'
    ORDER BY CASE WHEN "Sku" = 'HH215' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH215',
            "Name" = 'PLX5015',
            "Category" = '50*50 BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 197,
            "StockWarehouse2" = 0,
            "TotalStock" = 197,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH215', 'PLX5015', '50*50 BS', 'Hộp', supp_id,
            0, 0, 0,
            197, 0, 0,
            197, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'HH';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('PLX5015 A2'))
       OR "Sku" = 'HH216'
    ORDER BY CASE WHEN "Sku" = 'HH216' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'HH216',
            "Name" = 'PLX5015 A2',
            "Category" = '50*50 BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 192,
            "StockWarehouse2" = 0,
            "TotalStock" = 192,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'HH216', 'PLX5015 A2', '50*50 BS', 'Hộp', supp_id,
            0, 0, 0,
            192, 0, 0,
            192, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

-- >>> Hãng: Nice (NICE) - Tổng 108 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('036-6002 Nhạt'))
       OR "Sku" = 'NICE001'
    ORDER BY CASE WHEN "Sku" = 'NICE001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE001',
            "Name" = '036-6002 Nhạt',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 182,
            "StockWarehouse2" = 0,
            "TotalStock" = 182,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE001', '036-6002 Nhạt', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            182, 0, 0,
            182, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('036-6003 nhạt'))
       OR "Sku" = 'NICE002'
    ORDER BY CASE WHEN "Sku" = 'NICE002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE002',
            "Name" = '036-6003 nhạt',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 53,
            "StockWarehouse2" = 0,
            "TotalStock" = 53,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE002', '036-6003 nhạt', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            53, 0, 0,
            53, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('036-601-kem vàng'))
       OR "Sku" = 'NICE003'
    ORDER BY CASE WHEN "Sku" = 'NICE003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE003',
            "Name" = '036-601-kem vàng',
            "Category" = '30*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 16,
            "StockWarehouse2" = 0,
            "TotalStock" = 16,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE003', '036-601-kem vàng', '30*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            16, 0, 0,
            16, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6000- Trắng tinh-53(30.12.23)'))
       OR "Sku" = 'NICE004'
    ORDER BY CASE WHEN "Sku" = 'NICE004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE004',
            "Name" = '48-6000- Trắng tinh-53(30.12.23)',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 6,
            "StockWarehouse2" = 0,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE004', '48-6000- Trắng tinh-53(30.12.23)', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            6, 0, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6001-Nhạt'))
       OR "Sku" = 'NICE005'
    ORDER BY CASE WHEN "Sku" = 'NICE005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE005',
            "Name" = '48-6001-Nhạt',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 104,
            "StockWarehouse2" = 0,
            "TotalStock" = 104,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE005', '48-6001-Nhạt', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            104, 0, 0,
            104, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6001-Đậm'))
       OR "Sku" = 'NICE006'
    ORDER BY CASE WHEN "Sku" = 'NICE006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE006',
            "Name" = '48-6001-Đậm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 29,
            "StockWarehouse2" = 0,
            "TotalStock" = 29,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE006', '48-6001-Đậm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            29, 0, 0,
            29, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6001-Điểm'))
       OR "Sku" = 'NICE007'
    ORDER BY CASE WHEN "Sku" = 'NICE007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE007',
            "Name" = '48-6001-Điểm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 38,
            "StockWarehouse2" = 0,
            "TotalStock" = 38,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE007', '48-6001-Điểm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            38, 0, 0,
            38, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6002-Khói'))
       OR "Sku" = 'NICE008'
    ORDER BY CASE WHEN "Sku" = 'NICE008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE008',
            "Name" = '48-6002-Khói',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 71,
            "StockWarehouse2" = 0,
            "TotalStock" = 71,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE008', '48-6002-Khói', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            71, 0, 0,
            71, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6002-Điểm'))
       OR "Sku" = 'NICE009'
    ORDER BY CASE WHEN "Sku" = 'NICE009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE009',
            "Name" = '48-6002-Điểm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 4,
            "StockWarehouse2" = 0,
            "TotalStock" = 4,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE009', '48-6002-Điểm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            4, 0, 0,
            4, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6003-Vân'))
       OR "Sku" = 'NICE010'
    ORDER BY CASE WHEN "Sku" = 'NICE010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE010',
            "Name" = '48-6003-Vân',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 90,
            "StockWarehouse2" = 0,
            "TotalStock" = 90,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE010', '48-6003-Vân', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            90, 0, 0,
            90, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6003-Điểm'))
       OR "Sku" = 'NICE011'
    ORDER BY CASE WHEN "Sku" = 'NICE011' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE011',
            "Name" = '48-6003-Điểm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 19,
            "StockWarehouse2" = 0,
            "TotalStock" = 19,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE011', '48-6003-Điểm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            19, 0, 0,
            19, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6007-Nhạt'))
       OR "Sku" = 'NICE012'
    ORDER BY CASE WHEN "Sku" = 'NICE012' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE012',
            "Name" = '48-6007-Nhạt',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 162,
            "StockWarehouse2" = 0,
            "TotalStock" = 162,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE012', '48-6007-Nhạt', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            162, 0, 0,
            162, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6007-Đậm'))
       OR "Sku" = 'NICE013'
    ORDER BY CASE WHEN "Sku" = 'NICE013' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE013',
            "Name" = '48-6007-Đậm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 63,
            "StockWarehouse2" = 0,
            "TotalStock" = 63,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE013', '48-6007-Đậm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            63, 0, 0,
            63, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-6007-Điểm'))
       OR "Sku" = 'NICE014'
    ORDER BY CASE WHEN "Sku" = 'NICE014' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE014',
            "Name" = '48-6007-Điểm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 33,
            "StockWarehouse2" = 0,
            "TotalStock" = 33,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE014', '48-6007-Điểm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            33, 0, 0,
            33, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-5004-Nhạt'))
       OR "Sku" = 'NICE015'
    ORDER BY CASE WHEN "Sku" = 'NICE015' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE015',
            "Name" = '48-5004-Nhạt',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 70,
            "StockWarehouse2" = 0,
            "TotalStock" = 70,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE015', '48-5004-Nhạt', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            70, 0, 0,
            70, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-5004-Đậm'))
       OR "Sku" = 'NICE016'
    ORDER BY CASE WHEN "Sku" = 'NICE016' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE016',
            "Name" = '48-5004-Đậm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 48,
            "StockWarehouse2" = 0,
            "TotalStock" = 48,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE016', '48-5004-Đậm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            48, 0, 0,
            48, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-5004-Điểm'))
       OR "Sku" = 'NICE017'
    ORDER BY CASE WHEN "Sku" = 'NICE017' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE017',
            "Name" = '48-5004-Điểm',
            "Category" = '40*80 BỘ BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 9,
            "StockWarehouse2" = 0,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE017', '48-5004-Điểm', '40*80 BỘ BS', 'Hộp', supp_id,
            0, 0, 0,
            9, 0, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-01 GO'))
       OR "Sku" = 'NICE018'
    ORDER BY CASE WHEN "Sku" = 'NICE018' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE018',
            "Name" = '48-01 GO',
            "Category" = '40*80 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 41,
            "StockWarehouse2" = 0,
            "TotalStock" = 41,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE018', '48-01 GO', '40*80 SV', 'Hộp', supp_id,
            0, 0, 0,
            41, 0, 0,
            41, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48-02 GO'))
       OR "Sku" = 'NICE019'
    ORDER BY CASE WHEN "Sku" = 'NICE019' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE019',
            "Name" = '48-02 GO',
            "Category" = '40*80 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 32,
            "StockWarehouse2" = 0,
            "TotalStock" = 32,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE019', '48-02 GO', '40*80 SV', 'Hộp', supp_id,
            0, 0, 0,
            32, 0, 0,
            32, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1001'))
       OR "Sku" = 'NICE020'
    ORDER BY CASE WHEN "Sku" = 'NICE020' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE020',
            "Name" = '5-1001',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE020', '5-1001', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1002'))
       OR "Sku" = 'NICE021'
    ORDER BY CASE WHEN "Sku" = 'NICE021' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE021',
            "Name" = '5-1002',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE021', '5-1002', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1004'))
       OR "Sku" = 'NICE022'
    ORDER BY CASE WHEN "Sku" = 'NICE022' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE022',
            "Name" = '5-1004',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 561,
            "StockWarehouse2" = 0,
            "TotalStock" = 561,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE022', '5-1004', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            561, 0, 0,
            561, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1012'))
       OR "Sku" = 'NICE023'
    ORDER BY CASE WHEN "Sku" = 'NICE023' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE023',
            "Name" = '5-1012',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 3.0000000000001137,
            "StockWarehouse2" = 0,
            "TotalStock" = 3.0000000000001137,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE023', '5-1012', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            3.0000000000001137, 0, 0,
            3.0000000000001137, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1501'))
       OR "Sku" = 'NICE024'
    ORDER BY CASE WHEN "Sku" = 'NICE024' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE024',
            "Name" = '5-1501',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 6,
            "StockWarehouse2" = 0,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE024', '5-1501', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            6, 0, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1013'))
       OR "Sku" = 'NICE025'
    ORDER BY CASE WHEN "Sku" = 'NICE025' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE025',
            "Name" = '5-1013',
            "Category" = '50*50 LÁT NỀN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 3,
            "StockWarehouse2" = 0,
            "TotalStock" = 3,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE025', '5-1013', '50*50 LÁT NỀN', 'Hộp', supp_id,
            0, 0, 0,
            3, 0, 0,
            3, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1601'))
       OR "Sku" = 'NICE026'
    ORDER BY CASE WHEN "Sku" = 'NICE026' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE026',
            "Name" = '5-1601',
            "Category" = '50*50 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 22,
            "StockWarehouse2" = 0,
            "TotalStock" = 22,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE026', '5-1601', '50*50 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            22, 0, 0,
            22, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1602'))
       OR "Sku" = 'NICE027'
    ORDER BY CASE WHEN "Sku" = 'NICE027' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE027',
            "Name" = '5-1602',
            "Category" = '50*50 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 167,
            "StockWarehouse2" = 0,
            "TotalStock" = 167,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE027', '5-1602', '50*50 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            167, 0, 0,
            167, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1603'))
       OR "Sku" = 'NICE028'
    ORDER BY CASE WHEN "Sku" = 'NICE028' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE028',
            "Name" = '5-1603',
            "Category" = '50*50 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 204,
            "StockWarehouse2" = 0,
            "TotalStock" = 204,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE028', '5-1603', '50*50 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            204, 0, 0,
            204, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1323'))
       OR "Sku" = 'NICE029'
    ORDER BY CASE WHEN "Sku" = 'NICE029' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE029',
            "Name" = '5-1323',
            "Category" = '50*50 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 65,
            "StockWarehouse2" = 0,
            "TotalStock" = 65,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE029', '5-1323', '50*50 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            65, 0, 0,
            65, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1311'))
       OR "Sku" = 'NICE030'
    ORDER BY CASE WHEN "Sku" = 'NICE030' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE030',
            "Name" = '5-1311',
            "Category" = '50*50 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 47,
            "StockWarehouse2" = 0,
            "TotalStock" = 47,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE030', '5-1311', '50*50 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            47, 0, 0,
            47, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5-1312'))
       OR "Sku" = 'NICE031'
    ORDER BY CASE WHEN "Sku" = 'NICE031' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE031',
            "Name" = '5-1312',
            "Category" = '50*50 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 324,
            "StockWarehouse2" = 0,
            "TotalStock" = 324,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE031', '5-1312', '50*50 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            324, 0, 0,
            324, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1001'))
       OR "Sku" = 'NICE032'
    ORDER BY CASE WHEN "Sku" = 'NICE032' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE032',
            "Name" = '6-1001',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 263,
            "StockWarehouse2" = 0,
            "TotalStock" = 263,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE032', '6-1001', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            263, 0, 0,
            263, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1012'))
       OR "Sku" = 'NICE033'
    ORDER BY CASE WHEN "Sku" = 'NICE033' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE033',
            "Name" = '6-1012',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 408,
            "StockWarehouse2" = 0,
            "TotalStock" = 408,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE033', '6-1012', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            408, 0, 0,
            408, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1016'))
       OR "Sku" = 'NICE034'
    ORDER BY CASE WHEN "Sku" = 'NICE034' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE034',
            "Name" = '6-1016',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 15,
            "StockWarehouse2" = 0,
            "TotalStock" = 15,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE034', '6-1016', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            15, 0, 0,
            15, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1019'))
       OR "Sku" = 'NICE035'
    ORDER BY CASE WHEN "Sku" = 'NICE035' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE035',
            "Name" = '6-1019',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 14,
            "StockWarehouse2" = 0,
            "TotalStock" = 14,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE035', '6-1019', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            14, 0, 0,
            14, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1020'))
       OR "Sku" = 'NICE036'
    ORDER BY CASE WHEN "Sku" = 'NICE036' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE036',
            "Name" = '6-1020',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 42,
            "StockWarehouse2" = 0,
            "TotalStock" = 42,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE036', '6-1020', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            42, 0, 0,
            42, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1021'))
       OR "Sku" = 'NICE037'
    ORDER BY CASE WHEN "Sku" = 'NICE037' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE037',
            "Name" = '6-1021',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 12,
            "StockWarehouse2" = 0,
            "TotalStock" = 12,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE037', '6-1021', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            12, 0, 0,
            12, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1022'))
       OR "Sku" = 'NICE038'
    ORDER BY CASE WHEN "Sku" = 'NICE038' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE038',
            "Name" = '6-1022',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 25,
            "StockWarehouse2" = 0,
            "TotalStock" = 25,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE038', '6-1022', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            25, 0, 0,
            25, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1501- Gỗ mát'))
       OR "Sku" = 'NICE039'
    ORDER BY CASE WHEN "Sku" = 'NICE039' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE039',
            "Name" = '6-1501- Gỗ mát',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 97,
            "StockWarehouse2" = 0,
            "TotalStock" = 97,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE039', '6-1501- Gỗ mát', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            97, 0, 0,
            97, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1502- Gỗ mát'))
       OR "Sku" = 'NICE040'
    ORDER BY CASE WHEN "Sku" = 'NICE040' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE040',
            "Name" = '6-1502- Gỗ mát',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 36,
            "StockWarehouse2" = 0,
            "TotalStock" = 36,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE040', '6-1502- Gỗ mát', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            36, 0, 0,
            36, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1304-men đường'))
       OR "Sku" = 'NICE041'
    ORDER BY CASE WHEN "Sku" = 'NICE041' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE041',
            "Name" = '6-1304-men đường',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 62,
            "StockWarehouse2" = 0,
            "TotalStock" = 62,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE041', '6-1304-men đường', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            62, 0, 0,
            62, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-1013-đen vân'))
       OR "Sku" = 'NICE042'
    ORDER BY CASE WHEN "Sku" = 'NICE042' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE042',
            "Name" = '6-1013-đen vân',
            "Category" = '60*60 CERAMIC',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 79,
            "StockWarehouse2" = 0,
            "TotalStock" = 79,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE042', '6-1013-đen vân', '60*60 CERAMIC', 'Hộp', supp_id,
            0, 0, 0,
            79, 0, 0,
            79, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6001'))
       OR "Sku" = 'NICE043'
    ORDER BY CASE WHEN "Sku" = 'NICE043' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE043',
            "Name" = '6-6001',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE043', '6-6001', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6007'))
       OR "Sku" = 'NICE044'
    ORDER BY CASE WHEN "Sku" = 'NICE044' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE044',
            "Name" = '6-6007',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 263,
            "StockWarehouse2" = 0,
            "TotalStock" = 263,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE044', '6-6007', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            263, 0, 0,
            263, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6022'))
       OR "Sku" = 'NICE045'
    ORDER BY CASE WHEN "Sku" = 'NICE045' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE045',
            "Name" = '6-6022',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 300,
            "StockWarehouse2" = 0,
            "TotalStock" = 300,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE045', '6-6022', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            300, 0, 0,
            300, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6030'))
       OR "Sku" = 'NICE046'
    ORDER BY CASE WHEN "Sku" = 'NICE046' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE046',
            "Name" = '6-6030',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 33,
            "StockWarehouse2" = 0,
            "TotalStock" = 33,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE046', '6-6030', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            33, 0, 0,
            33, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6030 A2'))
       OR "Sku" = 'NICE047'
    ORDER BY CASE WHEN "Sku" = 'NICE047' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE047',
            "Name" = '6-6030 A2',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 36,
            "StockWarehouse2" = 0,
            "TotalStock" = 36,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE047', '6-6030 A2', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            36, 0, 0,
            36, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6031'))
       OR "Sku" = 'NICE048'
    ORDER BY CASE WHEN "Sku" = 'NICE048' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE048',
            "Name" = '6-6031',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 38,
            "StockWarehouse2" = 0,
            "TotalStock" = 38,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE048', '6-6031', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            38, 0, 0,
            38, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6031 A2'))
       OR "Sku" = 'NICE049'
    ORDER BY CASE WHEN "Sku" = 'NICE049' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE049',
            "Name" = '6-6031 A2',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 40,
            "StockWarehouse2" = 0,
            "TotalStock" = 40,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE049', '6-6031 A2', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            40, 0, 0,
            40, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6036'))
       OR "Sku" = 'NICE050'
    ORDER BY CASE WHEN "Sku" = 'NICE050' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE050',
            "Name" = '6-6036',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 124,
            "StockWarehouse2" = 0,
            "TotalStock" = 124,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE050', '6-6036', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            124, 0, 0,
            124, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6037'))
       OR "Sku" = 'NICE051'
    ORDER BY CASE WHEN "Sku" = 'NICE051' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE051',
            "Name" = '6-6037',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 21,
            "StockWarehouse2" = 0,
            "TotalStock" = 21,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE051', '6-6037', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            21, 0, 0,
            21, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6038'))
       OR "Sku" = 'NICE052'
    ORDER BY CASE WHEN "Sku" = 'NICE052' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE052',
            "Name" = '6-6038',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 116,
            "StockWarehouse2" = 0,
            "TotalStock" = 116,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE052', '6-6038', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            116, 0, 0,
            116, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6040'))
       OR "Sku" = 'NICE053'
    ORDER BY CASE WHEN "Sku" = 'NICE053' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE053',
            "Name" = '6-6040',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 118,
            "StockWarehouse2" = 0,
            "TotalStock" = 118,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE053', '6-6040', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            118, 0, 0,
            118, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6040 A2'))
       OR "Sku" = 'NICE054'
    ORDER BY CASE WHEN "Sku" = 'NICE054' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE054',
            "Name" = '6-6040 A2',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 11,
            "StockWarehouse2" = 0,
            "TotalStock" = 11,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE054', '6-6040 A2', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            11, 0, 0,
            11, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6041'))
       OR "Sku" = 'NICE055'
    ORDER BY CASE WHEN "Sku" = 'NICE055' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE055',
            "Name" = '6-6041',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 190,
            "StockWarehouse2" = 0,
            "TotalStock" = 190,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE055', '6-6041', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            190, 0, 0,
            190, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6042'))
       OR "Sku" = 'NICE056'
    ORDER BY CASE WHEN "Sku" = 'NICE056' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE056',
            "Name" = '6-6042',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 228,
            "StockWarehouse2" = 0,
            "TotalStock" = 228,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE056', '6-6042', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            228, 0, 0,
            228, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6042- A2'))
       OR "Sku" = 'NICE057'
    ORDER BY CASE WHEN "Sku" = 'NICE057' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE057',
            "Name" = '6-6042- A2',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 65,
            "StockWarehouse2" = 0,
            "TotalStock" = 65,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE057', '6-6042- A2', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            65, 0, 0,
            65, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6043'))
       OR "Sku" = 'NICE058'
    ORDER BY CASE WHEN "Sku" = 'NICE058' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE058',
            "Name" = '6-6043',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 82,
            "StockWarehouse2" = 0,
            "TotalStock" = 82,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE058', '6-6043', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            82, 0, 0,
            82, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6043- A2'))
       OR "Sku" = 'NICE059'
    ORDER BY CASE WHEN "Sku" = 'NICE059' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE059',
            "Name" = '6-6043- A2',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 110,
            "StockWarehouse2" = 0,
            "TotalStock" = 110,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE059', '6-6043- A2', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            110, 0, 0,
            110, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6045'))
       OR "Sku" = 'NICE060'
    ORDER BY CASE WHEN "Sku" = 'NICE060' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE060',
            "Name" = '6-6045',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 121,
            "StockWarehouse2" = 0,
            "TotalStock" = 121,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE060', '6-6045', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            121, 0, 0,
            121, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6100'))
       OR "Sku" = 'NICE061'
    ORDER BY CASE WHEN "Sku" = 'NICE061' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE061',
            "Name" = '6-6100',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 84,
            "StockWarehouse2" = 0,
            "TotalStock" = 84,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE061', '6-6100', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            84, 0, 0,
            84, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6200'))
       OR "Sku" = 'NICE062'
    ORDER BY CASE WHEN "Sku" = 'NICE062' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE062',
            "Name" = '6-6200',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 9,
            "StockWarehouse2" = 0,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE062', '6-6200', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            9, 0, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6400'))
       OR "Sku" = 'NICE063'
    ORDER BY CASE WHEN "Sku" = 'NICE063' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE063',
            "Name" = '6-6400',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 9,
            "StockWarehouse2" = 0,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE063', '6-6400', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            9, 0, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6400 A2'))
       OR "Sku" = 'NICE064'
    ORDER BY CASE WHEN "Sku" = 'NICE064' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE064',
            "Name" = '6-6400 A2',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 20,
            "StockWarehouse2" = 0,
            "TotalStock" = 20,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE064', '6-6400 A2', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            20, 0, 0,
            20, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('6-6400 A3'))
       OR "Sku" = 'NICE065'
    ORDER BY CASE WHEN "Sku" = 'NICE065' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE065',
            "Name" = '6-6400 A3',
            "Category" = '60*60 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 171,
            "StockWarehouse2" = 0,
            "TotalStock" = 171,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE065', '6-6400 A3', '60*60 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            171, 0, 0,
            171, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6003 A2'))
       OR "Sku" = 'NICE066'
    ORDER BY CASE WHEN "Sku" = 'NICE066' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE066',
            "Name" = '8-6003 A2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 10,
            "StockWarehouse2" = 0,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE066', '8-6003 A2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            10, 0, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6004'))
       OR "Sku" = 'NICE067'
    ORDER BY CASE WHEN "Sku" = 'NICE067' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE067',
            "Name" = '8-6004',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 116,
            "StockWarehouse2" = 0,
            "TotalStock" = 116,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE067', '8-6004', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            116, 0, 0,
            116, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6010'))
       OR "Sku" = 'NICE068'
    ORDER BY CASE WHEN "Sku" = 'NICE068' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE068',
            "Name" = '8-6010',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 12,
            "StockWarehouse2" = 0,
            "TotalStock" = 12,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE068', '8-6010', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            12, 0, 0,
            12, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6017'))
       OR "Sku" = 'NICE069'
    ORDER BY CASE WHEN "Sku" = 'NICE069' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE069',
            "Name" = '8-6017',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 8,
            "StockWarehouse2" = 0,
            "TotalStock" = 8,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE069', '8-6017', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            8, 0, 0,
            8, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6019'))
       OR "Sku" = 'NICE070'
    ORDER BY CASE WHEN "Sku" = 'NICE070' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE070',
            "Name" = '8-6019',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 26,
            "StockWarehouse2" = 0,
            "TotalStock" = 26,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE070', '8-6019', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            26, 0, 0,
            26, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6019 A2'))
       OR "Sku" = 'NICE071'
    ORDER BY CASE WHEN "Sku" = 'NICE071' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE071',
            "Name" = '8-6019 A2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 202,
            "StockWarehouse2" = 0,
            "TotalStock" = 202,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE071', '8-6019 A2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            202, 0, 0,
            202, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6021'))
       OR "Sku" = 'NICE072'
    ORDER BY CASE WHEN "Sku" = 'NICE072' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE072',
            "Name" = '8-6021',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 154,
            "StockWarehouse2" = 0,
            "TotalStock" = 154,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE072', '8-6021', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            154, 0, 0,
            154, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6029'))
       OR "Sku" = 'NICE073'
    ORDER BY CASE WHEN "Sku" = 'NICE073' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE073',
            "Name" = '8-6029',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 16,
            "StockWarehouse2" = 0,
            "TotalStock" = 16,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE073', '8-6029', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            16, 0, 0,
            16, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6031'))
       OR "Sku" = 'NICE074'
    ORDER BY CASE WHEN "Sku" = 'NICE074' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE074',
            "Name" = '8-6031',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 15,
            "StockWarehouse2" = 0,
            "TotalStock" = 15,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE074', '8-6031', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            15, 0, 0,
            15, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6032 A2'))
       OR "Sku" = 'NICE075'
    ORDER BY CASE WHEN "Sku" = 'NICE075' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE075',
            "Name" = '8-6032 A2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 53,
            "StockWarehouse2" = 0,
            "TotalStock" = 53,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE075', '8-6032 A2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            53, 0, 0,
            53, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6035'))
       OR "Sku" = 'NICE076'
    ORDER BY CASE WHEN "Sku" = 'NICE076' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE076',
            "Name" = '8-6035',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 27,
            "StockWarehouse2" = 0,
            "TotalStock" = 27,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE076', '8-6035', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            27, 0, 0,
            27, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6036'))
       OR "Sku" = 'NICE077'
    ORDER BY CASE WHEN "Sku" = 'NICE077' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE077',
            "Name" = '8-6036',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 177,
            "StockWarehouse2" = 0,
            "TotalStock" = 177,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE077', '8-6036', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            177, 0, 0,
            177, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6037'))
       OR "Sku" = 'NICE078'
    ORDER BY CASE WHEN "Sku" = 'NICE078' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE078',
            "Name" = '8-6037',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 22,
            "StockWarehouse2" = 0,
            "TotalStock" = 22,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE078', '8-6037', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            22, 0, 0,
            22, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6038'))
       OR "Sku" = 'NICE079'
    ORDER BY CASE WHEN "Sku" = 'NICE079' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE079',
            "Name" = '8-6038',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 6,
            "StockWarehouse2" = 0,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE079', '8-6038', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            6, 0, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6039'))
       OR "Sku" = 'NICE080'
    ORDER BY CASE WHEN "Sku" = 'NICE080' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE080',
            "Name" = '8-6039',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 11,
            "StockWarehouse2" = 0,
            "TotalStock" = 11,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE080', '8-6039', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            11, 0, 0,
            11, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6039 A2'))
       OR "Sku" = 'NICE081'
    ORDER BY CASE WHEN "Sku" = 'NICE081' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE081',
            "Name" = '8-6039 A2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 184,
            "StockWarehouse2" = 0,
            "TotalStock" = 184,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE081', '8-6039 A2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            184, 0, 0,
            184, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6040'))
       OR "Sku" = 'NICE082'
    ORDER BY CASE WHEN "Sku" = 'NICE082' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE082',
            "Name" = '8-6040',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 172,
            "StockWarehouse2" = 0,
            "TotalStock" = 172,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE082', '8-6040', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            172, 0, 0,
            172, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6041'))
       OR "Sku" = 'NICE083'
    ORDER BY CASE WHEN "Sku" = 'NICE083' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE083',
            "Name" = '8-6041',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 45,
            "StockWarehouse2" = 0,
            "TotalStock" = 45,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE083', '8-6041', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            45, 0, 0,
            45, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6042'))
       OR "Sku" = 'NICE084'
    ORDER BY CASE WHEN "Sku" = 'NICE084' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE084',
            "Name" = '8-6042',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 10,
            "StockWarehouse2" = 0,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE084', '8-6042', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            10, 0, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6043'))
       OR "Sku" = 'NICE085'
    ORDER BY CASE WHEN "Sku" = 'NICE085' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE085',
            "Name" = '8-6043',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 48,
            "StockWarehouse2" = 0,
            "TotalStock" = 48,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE085', '8-6043', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            48, 0, 0,
            48, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6045'))
       OR "Sku" = 'NICE086'
    ORDER BY CASE WHEN "Sku" = 'NICE086' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE086',
            "Name" = '8-6045',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 140,
            "StockWarehouse2" = 0,
            "TotalStock" = 140,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE086', '8-6045', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            140, 0, 0,
            140, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6045 a2'))
       OR "Sku" = 'NICE087'
    ORDER BY CASE WHEN "Sku" = 'NICE087' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE087',
            "Name" = '8-6045 a2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 173,
            "StockWarehouse2" = 0,
            "TotalStock" = 173,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE087', '8-6045 a2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            173, 0, 0,
            173, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6046 a2'))
       OR "Sku" = 'NICE088'
    ORDER BY CASE WHEN "Sku" = 'NICE088' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE088',
            "Name" = '8-6046 a2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 1116,
            "StockWarehouse2" = 0,
            "TotalStock" = 1116,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE088', '8-6046 a2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            1116, 0, 0,
            1116, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6047 A2'))
       OR "Sku" = 'NICE089'
    ORDER BY CASE WHEN "Sku" = 'NICE089' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE089',
            "Name" = '8-6047 A2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 218,
            "StockWarehouse2" = 0,
            "TotalStock" = 218,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE089', '8-6047 A2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            218, 0, 0,
            218, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-601-vt'))
       OR "Sku" = 'NICE090'
    ORDER BY CASE WHEN "Sku" = 'NICE090' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE090',
            "Name" = '8-601-vt',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 174,
            "StockWarehouse2" = 0,
            "TotalStock" = 174,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE090', '8-601-vt', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            174, 0, 0,
            174, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-602'))
       OR "Sku" = 'NICE091'
    ORDER BY CASE WHEN "Sku" = 'NICE091' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE091',
            "Name" = '8-602',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE091', '8-602', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6200'))
       OR "Sku" = 'NICE092'
    ORDER BY CASE WHEN "Sku" = 'NICE092' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE092',
            "Name" = '8-6200',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 159,
            "StockWarehouse2" = 0,
            "TotalStock" = 159,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE092', '8-6200', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            159, 0, 0,
            159, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('8-6200 A2'))
       OR "Sku" = 'NICE093'
    ORDER BY CASE WHEN "Sku" = 'NICE093' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE093',
            "Name" = '8-6200 A2',
            "Category" = '80*80 BÁN SỨ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 126,
            "StockWarehouse2" = 0,
            "TotalStock" = 126,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE093', '8-6200 A2', '80*80 BÁN SỨ', 'Hộp', supp_id,
            0, 0, 0,
            126, 0, 0,
            126, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MN612.510 A1-mát-57(3.1.26)'))
       OR "Sku" = 'NICE094'
    ORDER BY CASE WHEN "Sku" = 'NICE094' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE094',
            "Name" = 'MN612.510 A1-mát-57(3.1.26)',
            "Category" = '60*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 87,
            "StockWarehouse2" = 0,
            "TotalStock" = 87,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE094', 'MN612.510 A1-mát-57(3.1.26)', '60*120', 'Hộp', supp_id,
            0, 0, 0,
            87, 0, 0,
            87, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MN612.616 A1-bóng-55(24.11.24)'))
       OR "Sku" = 'NICE095'
    ORDER BY CASE WHEN "Sku" = 'NICE095' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE095',
            "Name" = 'MN612.616 A1-bóng-55(24.11.24)',
            "Category" = '60*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 83,
            "StockWarehouse2" = 0,
            "TotalStock" = 83,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE095', 'MN612.616 A1-bóng-55(24.11.24)', '60*120', 'Hộp', supp_id,
            0, 0, 0,
            83, 0, 0,
            83, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MN612.618 A1-bóng-Đ58(3.3.26)'))
       OR "Sku" = 'NICE096'
    ORDER BY CASE WHEN "Sku" = 'NICE096' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE096',
            "Name" = 'MN612.618 A1-bóng-Đ58(3.3.26)',
            "Category" = '60*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 121,
            "StockWarehouse2" = 0,
            "TotalStock" = 121,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE096', 'MN612.618 A1-bóng-Đ58(3.3.26)', '60*120', 'Hộp', supp_id,
            0, 0, 0,
            121, 0, 0,
            121, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MN612.614-KHÓI'))
       OR "Sku" = 'NICE097'
    ORDER BY CASE WHEN "Sku" = 'NICE097' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE097',
            "Name" = 'MN612.614-KHÓI',
            "Category" = '60*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 96,
            "StockWarehouse2" = 0,
            "TotalStock" = 96,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE097', 'MN612.614-KHÓI', '60*120', 'Hộp', supp_id,
            0, 0, 0,
            96, 0, 0,
            96, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-645'))
       OR "Sku" = 'NICE098'
    ORDER BY CASE WHEN "Sku" = 'NICE098' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE098',
            "Name" = '11-645',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 446,
            "StockWarehouse2" = 0,
            "TotalStock" = 446,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE098', '11-645', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            446, 0, 0,
            446, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-645 A2-40H/K'))
       OR "Sku" = 'NICE099'
    ORDER BY CASE WHEN "Sku" = 'NICE099' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE099',
            "Name" = '11-645 A2-40H/K',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 281,
            "StockWarehouse2" = 0,
            "TotalStock" = 281,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE099', '11-645 A2-40H/K', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            281, 0, 0,
            281, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-602'))
       OR "Sku" = 'NICE100'
    ORDER BY CASE WHEN "Sku" = 'NICE100' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE100',
            "Name" = '11-602',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 279,
            "StockWarehouse2" = 0,
            "TotalStock" = 279,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE100', '11-602', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            279, 0, 0,
            279, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-602-D53(28.3.26) A2-43H/K'))
       OR "Sku" = 'NICE101'
    ORDER BY CASE WHEN "Sku" = 'NICE101' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE101',
            "Name" = '11-602-D53(28.3.26) A2-43H/K',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 286,
            "StockWarehouse2" = 0,
            "TotalStock" = 286,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE101', '11-602-D53(28.3.26) A2-43H/K', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            286, 0, 0,
            286, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-646-VT-(đ53:16.3.26)'))
       OR "Sku" = 'NICE102'
    ORDER BY CASE WHEN "Sku" = 'NICE102' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE102',
            "Name" = '11-646-VT-(đ53:16.3.26)',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 265,
            "StockWarehouse2" = 0,
            "TotalStock" = 265,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE102', '11-646-VT-(đ53:16.3.26)', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            265, 0, 0,
            265, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-646-VT-(đ55:16.3.26) A2(40h/k)'))
       OR "Sku" = 'NICE103'
    ORDER BY CASE WHEN "Sku" = 'NICE103' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE103',
            "Name" = '11-646-VT-(đ55:16.3.26) A2(40h/k)',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 729,
            "StockWarehouse2" = 0,
            "TotalStock" = 729,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE103', '11-646-VT-(đ55:16.3.26) A2(40h/k)', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            729, 0, 0,
            729, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-601-đ52(43h/k)-7.4.26'))
       OR "Sku" = 'NICE104'
    ORDER BY CASE WHEN "Sku" = 'NICE104' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE104',
            "Name" = '11-601-đ52(43h/k)-7.4.26',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 431,
            "StockWarehouse2" = 0,
            "TotalStock" = 431,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE104', '11-601-đ52(43h/k)-7.4.26', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            431, 0, 0,
            431, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11-601-đ55(40h/k)-12.3.26 A2-40H/K'))
       OR "Sku" = 'NICE105'
    ORDER BY CASE WHEN "Sku" = 'NICE105' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE105',
            "Name" = '11-601-đ55(40h/k)-12.3.26 A2-40H/K',
            "Category" = '100*100',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 426,
            "StockWarehouse2" = 0,
            "TotalStock" = 426,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE105', '11-601-đ55(40h/k)-12.3.26 A2-40H/K', '100*100', 'Hộp', supp_id,
            0, 0, 0,
            426, 0, 0,
            426, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('46512-01-DẦY 12mm'))
       OR "Sku" = 'NICE106'
    ORDER BY CASE WHEN "Sku" = 'NICE106' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE106',
            "Name" = '46512-01-DẦY 12mm',
            "Category" = '40*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 21,
            "StockWarehouse2" = 0,
            "TotalStock" = 21,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE106', '46512-01-DẦY 12mm', '40*60', 'Hộp', supp_id,
            0, 0, 0,
            21, 0, 0,
            21, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('46512-02DẦY 12mm'))
       OR "Sku" = 'NICE107'
    ORDER BY CASE WHEN "Sku" = 'NICE107' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE107',
            "Name" = '46512-02DẦY 12mm',
            "Category" = '40*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 132,
            "StockWarehouse2" = 0,
            "TotalStock" = 132,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE107', '46512-02DẦY 12mm', '40*60', 'Hộp', supp_id,
            0, 0, 0,
            132, 0, 0,
            132, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'NICE';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('46512-03DẦY 12mm'))
       OR "Sku" = 'NICE108'
    ORDER BY CASE WHEN "Sku" = 'NICE108' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'NICE108',
            "Name" = '46512-03DẦY 12mm',
            "Category" = '40*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 28,
            "StockWarehouse2" = 0,
            "TotalStock" = 28,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'NICE108', '46512-03DẦY 12mm', '40*60', 'Hộp', supp_id,
            0, 0, 0,
            28, 0, 0,
            28, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

-- >>> Hãng: Takao (TAKAO) - Tổng 92 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-665'))
       OR "Sku" = 'TAKAO001'
    ORDER BY CASE WHEN "Sku" = 'TAKAO001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO001',
            "Name" = '97-665',
            "Category" = '60*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 33,
            "TotalStock" = 33,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO001', '97-665', '60*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 33, 0,
            33, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-601'))
       OR "Sku" = 'TAKAO002'
    ORDER BY CASE WHEN "Sku" = 'TAKAO002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO002',
            "Name" = '97-601',
            "Category" = '60*60 bs',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 57,
            "TotalStock" = 57,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO002', '97-601', '60*60 bs', 'Hộp', supp_id,
            0, 0, 0,
            0, 57, 0,
            57, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-604'))
       OR "Sku" = 'TAKAO003'
    ORDER BY CASE WHEN "Sku" = 'TAKAO003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO003',
            "Name" = '97-604',
            "Category" = '60*60 bs',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 160,
            "TotalStock" = 160,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO003', '97-604', '60*60 bs', 'Hộp', supp_id,
            0, 0, 0,
            0, 160, 0,
            160, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-606'))
       OR "Sku" = 'TAKAO004'
    ORDER BY CASE WHEN "Sku" = 'TAKAO004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO004',
            "Name" = '97-606',
            "Category" = '60*60 bs',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 10,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO004', '97-606', '60*60 bs', 'Hộp', supp_id,
            0, 0, 0,
            0, 10, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-653'))
       OR "Sku" = 'TAKAO005'
    ORDER BY CASE WHEN "Sku" = 'TAKAO005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO005',
            "Name" = '97-653',
            "Category" = '60*60 bs',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 10,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO005', '97-653', '60*60 bs', 'Hộp', supp_id,
            0, 0, 0,
            0, 10, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-654'))
       OR "Sku" = 'TAKAO006'
    ORDER BY CASE WHEN "Sku" = 'TAKAO006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO006',
            "Name" = '97-654',
            "Category" = '60*60 bs',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 5,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO006', '97-654', '60*60 bs', 'Hộp', supp_id,
            0, 0, 0,
            0, 5, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-854'))
       OR "Sku" = 'TAKAO007'
    ORDER BY CASE WHEN "Sku" = 'TAKAO007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO007',
            "Name" = '97-854',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 13,
            "TotalStock" = 13,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO007', '97-854', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 13, 0,
            13, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-855'))
       OR "Sku" = 'TAKAO008'
    ORDER BY CASE WHEN "Sku" = 'TAKAO008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO008',
            "Name" = '97-855',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6.7,
            "TotalStock" = 6.7,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO008', '97-855', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 6.7, 0,
            6.7, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-101'))
       OR "Sku" = 'TAKAO009'
    ORDER BY CASE WHEN "Sku" = 'TAKAO009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO009',
            "Name" = '97-101',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 8,
            "TotalStock" = 8,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO009', '97-101', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 8, 0,
            8, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-104'))
       OR "Sku" = 'TAKAO010'
    ORDER BY CASE WHEN "Sku" = 'TAKAO010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO010',
            "Name" = '97-104',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 45,
            "TotalStock" = 45,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO010', '97-104', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 45, 0,
            45, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-105'))
       OR "Sku" = 'TAKAO011'
    ORDER BY CASE WHEN "Sku" = 'TAKAO011' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO011',
            "Name" = '97-105',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 17,
            "TotalStock" = 17,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO011', '97-105', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 17, 0,
            17, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('97-106'))
       OR "Sku" = 'TAKAO012'
    ORDER BY CASE WHEN "Sku" = 'TAKAO012' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO012',
            "Name" = '97-106',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 2,
            "TotalStock" = 2,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO012', '97-106', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 2, 0,
            2, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('13102'))
       OR "Sku" = 'TAKAO013'
    ORDER BY CASE WHEN "Sku" = 'TAKAO013' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO013',
            "Name" = '13102',
            "Category" = '30*60-BS (1h=8v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 253,
            "TotalStock" = 253,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO013', '13102', '30*60-BS (1h=8v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 253, 0,
            253, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('13103'))
       OR "Sku" = 'TAKAO014'
    ORDER BY CASE WHEN "Sku" = 'TAKAO014' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO014',
            "Name" = '13103',
            "Category" = '30*60-BS (1h=8v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 210,
            "TotalStock" = 210,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO014', '13103', '30*60-BS (1h=8v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 210, 0,
            210, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('13202-ĐIỂM'))
       OR "Sku" = 'TAKAO015'
    ORDER BY CASE WHEN "Sku" = 'TAKAO015' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO015',
            "Name" = '13202-ĐIỂM',
            "Category" = '30*60-BS (1h=8v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 65,
            "TotalStock" = 65,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO015', '13202-ĐIỂM', '30*60-BS (1h=8v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 65, 0,
            65, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('13106'))
       OR "Sku" = 'TAKAO016'
    ORDER BY CASE WHEN "Sku" = 'TAKAO016' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO016',
            "Name" = '13106',
            "Category" = '30*60-BS (1h=8v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 235.75,
            "TotalStock" = 235.75,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO016', '13106', '30*60-BS (1h=8v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 235.75, 0,
            235.75, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('13206 ĐIỂM'))
       OR "Sku" = 'TAKAO017'
    ORDER BY CASE WHEN "Sku" = 'TAKAO017' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO017',
            "Name" = '13206 ĐIỂM',
            "Category" = '30*60-BS (1h=8v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 52.5,
            "TotalStock" = 52.5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO017', '13206 ĐIỂM', '30*60-BS (1h=8v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 52.5, 0,
            52.5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('43500-Trắng tinh bs'))
       OR "Sku" = 'TAKAO018'
    ORDER BY CASE WHEN "Sku" = 'TAKAO018' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO018',
            "Name" = '43500-Trắng tinh bs',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 95,
            "TotalStock" = 95,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO018', '43500-Trắng tinh bs', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 95, 0,
            95, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('43600-điểm'))
       OR "Sku" = 'TAKAO019'
    ORDER BY CASE WHEN "Sku" = 'TAKAO019' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO019',
            "Name" = '43600-điểm',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO019', '43600-điểm', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73501-khói'))
       OR "Sku" = 'TAKAO020'
    ORDER BY CASE WHEN "Sku" = 'TAKAO020' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO020',
            "Name" = '73501-khói',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 424,
            "TotalStock" = 424,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO020', '73501-khói', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 424, 0,
            424, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73601-điểm'))
       OR "Sku" = 'TAKAO021'
    ORDER BY CASE WHEN "Sku" = 'TAKAO021' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO021',
            "Name" = '73601-điểm',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 32,
            "TotalStock" = 32,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO021', '73601-điểm', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 32, 0,
            32, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73506-nhạt'))
       OR "Sku" = 'TAKAO022'
    ORDER BY CASE WHEN "Sku" = 'TAKAO022' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO022',
            "Name" = '73506-nhạt',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 146,
            "TotalStock" = 146,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO022', '73506-nhạt', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 146, 0,
            146, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73507-đậm'))
       OR "Sku" = 'TAKAO023'
    ORDER BY CASE WHEN "Sku" = 'TAKAO023' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO023',
            "Name" = '73507-đậm',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 165,
            "TotalStock" = 165,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO023', '73507-đậm', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 165, 0,
            165, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73606-điểm'))
       OR "Sku" = 'TAKAO024'
    ORDER BY CASE WHEN "Sku" = 'TAKAO024' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO024',
            "Name" = '73606-điểm',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 35,
            "TotalStock" = 35,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO024', '73606-điểm', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 35, 0,
            35, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73502-nhạt'))
       OR "Sku" = 'TAKAO025'
    ORDER BY CASE WHEN "Sku" = 'TAKAO025' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO025',
            "Name" = '73502-nhạt',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 225,
            "TotalStock" = 225,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO025', '73502-nhạt', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 225, 0,
            225, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73503-đậm'))
       OR "Sku" = 'TAKAO026'
    ORDER BY CASE WHEN "Sku" = 'TAKAO026' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO026',
            "Name" = '73503-đậm',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 49,
            "TotalStock" = 49,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO026', '73503-đậm', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 49, 0,
            49, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('73602-điểm'))
       OR "Sku" = 'TAKAO027'
    ORDER BY CASE WHEN "Sku" = 'TAKAO027' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO027',
            "Name" = '73602-điểm',
            "Category" = '30*60 elit (1h =10 v)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 19,
            "TotalStock" = 19,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO027', '73602-điểm', '30*60 elit (1h =10 v)', 'Hộp', supp_id,
            0, 0, 0,
            0, 19, 0,
            19, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14101(1H=1.28)'))
       OR "Sku" = 'TAKAO028'
    ORDER BY CASE WHEN "Sku" = 'TAKAO028' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO028',
            "Name" = '14101(1H=1.28)',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 27,
            "TotalStock" = 27,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO028', '14101(1H=1.28)', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 27, 0,
            27, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14113-khói'))
       OR "Sku" = 'TAKAO029'
    ORDER BY CASE WHEN "Sku" = 'TAKAO029' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO029',
            "Name" = '14113-khói',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 58,
            "TotalStock" = 58,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO029', '14113-khói', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 58, 0,
            58, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14213-điểm'))
       OR "Sku" = 'TAKAO030'
    ORDER BY CASE WHEN "Sku" = 'TAKAO030' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO030',
            "Name" = '14213-điểm',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 18,
            "TotalStock" = 18,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO030', '14213-điểm', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 18, 0,
            18, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('74102'))
       OR "Sku" = 'TAKAO031'
    ORDER BY CASE WHEN "Sku" = 'TAKAO031' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO031',
            "Name" = '74102',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 110,
            "TotalStock" = 110,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO031', '74102', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 110, 0,
            110, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('74103'))
       OR "Sku" = 'TAKAO032'
    ORDER BY CASE WHEN "Sku" = 'TAKAO032' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO032',
            "Name" = '74103',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 122,
            "TotalStock" = 122,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO032', '74103', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 122, 0,
            122, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('74202-điểm'))
       OR "Sku" = 'TAKAO033'
    ORDER BY CASE WHEN "Sku" = 'TAKAO033' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO033',
            "Name" = '74202-điểm',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 59,
            "TotalStock" = 59,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO033', '74202-điểm', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 59, 0,
            59, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14109'))
       OR "Sku" = 'TAKAO034'
    ORDER BY CASE WHEN "Sku" = 'TAKAO034' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO034',
            "Name" = '14109',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 110,
            "TotalStock" = 110,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO034', '14109', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 110, 0,
            110, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14110'))
       OR "Sku" = 'TAKAO035'
    ORDER BY CASE WHEN "Sku" = 'TAKAO035' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO035',
            "Name" = '14110',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 20,
            "TotalStock" = 20,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO035', '14110', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 20, 0,
            20, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14209-điểm'))
       OR "Sku" = 'TAKAO036'
    ORDER BY CASE WHEN "Sku" = 'TAKAO036' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO036',
            "Name" = '14209-điểm',
            "Category" = '40*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 51,
            "TotalStock" = 51,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO036', '14209-điểm', '40*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 51, 0,
            51, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16901'))
       OR "Sku" = 'TAKAO037'
    ORDER BY CASE WHEN "Sku" = 'TAKAO037' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO037',
            "Name" = '16901',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 97,
            "TotalStock" = 97,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO037', '16901', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 97, 0,
            97, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16902'))
       OR "Sku" = 'TAKAO038'
    ORDER BY CASE WHEN "Sku" = 'TAKAO038' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO038',
            "Name" = '16902',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 53,
            "TotalStock" = 53,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO038', '16902', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 53, 0,
            53, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16906'))
       OR "Sku" = 'TAKAO039'
    ORDER BY CASE WHEN "Sku" = 'TAKAO039' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO039',
            "Name" = '16906',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 203,
            "TotalStock" = 203,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO039', '16906', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 203, 0,
            203, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16106 -K1'))
       OR "Sku" = 'TAKAO040'
    ORDER BY CASE WHEN "Sku" = 'TAKAO040' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO040',
            "Name" = '16106 -K1',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 10,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO040', '16106 -K1', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 10, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16911'))
       OR "Sku" = 'TAKAO041'
    ORDER BY CASE WHEN "Sku" = 'TAKAO041' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO041',
            "Name" = '16911',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 105,
            "TotalStock" = 105,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO041', '16911', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 105, 0,
            105, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16912'))
       OR "Sku" = 'TAKAO042'
    ORDER BY CASE WHEN "Sku" = 'TAKAO042' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO042',
            "Name" = '16912',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 156,
            "TotalStock" = 156,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO042', '16912', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 156, 0,
            156, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16913'))
       OR "Sku" = 'TAKAO043'
    ORDER BY CASE WHEN "Sku" = 'TAKAO043' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO043',
            "Name" = '16913',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 221,
            "TotalStock" = 221,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO043', '16913', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 221, 0,
            221, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16916'))
       OR "Sku" = 'TAKAO044'
    ORDER BY CASE WHEN "Sku" = 'TAKAO044' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO044',
            "Name" = '16916',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 283,
            "TotalStock" = 283,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO044', '16916', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 283, 0,
            283, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16917'))
       OR "Sku" = 'TAKAO045'
    ORDER BY CASE WHEN "Sku" = 'TAKAO045' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO045',
            "Name" = '16917',
            "Category" = '60*60-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 332,
            "TotalStock" = 332,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO045', '16917', '60*60-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 332, 0,
            332, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('16.126'))
       OR "Sku" = 'TAKAO046'
    ORDER BY CASE WHEN "Sku" = 'TAKAO046' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO046',
            "Name" = '16.126',
            "Category" = 'CẮT LÔ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 144,
            "TotalStock" = 144,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO046', '16.126', 'CẮT LÔ', 'Hộp', supp_id,
            0, 0, 0,
            0, 144, 0,
            144, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14602'))
       OR "Sku" = 'TAKAO047'
    ORDER BY CASE WHEN "Sku" = 'TAKAO047' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO047',
            "Name" = '14602',
            "Category" = '40*60-sv',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 160,
            "TotalStock" = 160,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO047', '14602', '40*60-sv', 'Hộp', supp_id,
            0, 0, 0,
            0, 160, 0,
            160, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('14603(1.44M2)'))
       OR "Sku" = 'TAKAO048'
    ORDER BY CASE WHEN "Sku" = 'TAKAO048' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO048',
            "Name" = '14603(1.44M2)',
            "Category" = '40*60-sv',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 11,
            "TotalStock" = 11,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO048', '14603(1.44M2)', '40*60-sv', 'Hộp', supp_id,
            0, 0, 0,
            0, 11, 0,
            11, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17001'))
       OR "Sku" = 'TAKAO049'
    ORDER BY CASE WHEN "Sku" = 'TAKAO049' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO049',
            "Name" = '17001',
            "Category" = '60 sân vườn(35kg)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 74,
            "TotalStock" = 74,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO049', '17001', '60 sân vườn(35kg)', 'Hộp', supp_id,
            0, 0, 0,
            0, 74, 0,
            74, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17006'))
       OR "Sku" = 'TAKAO050'
    ORDER BY CASE WHEN "Sku" = 'TAKAO050' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO050',
            "Name" = '17006',
            "Category" = '60 sân vườn(35kg)',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 105,
            "TotalStock" = 105,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO050', '17006', '60 sân vườn(35kg)', 'Hộp', supp_id,
            0, 0, 0,
            0, 105, 0,
            105, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17151'))
       OR "Sku" = 'TAKAO051'
    ORDER BY CASE WHEN "Sku" = 'TAKAO051' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO051',
            "Name" = '17151',
            "Category" = '60*60 Elit-Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 122,
            "TotalStock" = 122,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO051', '17151', '60*60 Elit-Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 122, 0,
            122, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17152'))
       OR "Sku" = 'TAKAO052'
    ORDER BY CASE WHEN "Sku" = 'TAKAO052' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO052',
            "Name" = '17152',
            "Category" = '60*60 Elit-Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 108,
            "TotalStock" = 108,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO052', '17152', '60*60 Elit-Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 108, 0,
            108, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17153'))
       OR "Sku" = 'TAKAO053'
    ORDER BY CASE WHEN "Sku" = 'TAKAO053' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO053',
            "Name" = '17153',
            "Category" = '60*60 Elit-Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 146,
            "TotalStock" = 146,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO053', '17153', '60*60 Elit-Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 146, 0,
            146, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17154'))
       OR "Sku" = 'TAKAO054'
    ORDER BY CASE WHEN "Sku" = 'TAKAO054' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO054',
            "Name" = '17154',
            "Category" = '60*60 Elit-Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 76,
            "TotalStock" = 76,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO054', '17154', '60*60 Elit-Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 76, 0,
            76, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17155'))
       OR "Sku" = 'TAKAO055'
    ORDER BY CASE WHEN "Sku" = 'TAKAO055' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO055',
            "Name" = '17155',
            "Category" = '60*60 Elit-Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 147,
            "TotalStock" = 147,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO055', '17155', '60*60 Elit-Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 147, 0,
            147, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('17156'))
       OR "Sku" = 'TAKAO056'
    ORDER BY CASE WHEN "Sku" = 'TAKAO056' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO056',
            "Name" = '17156',
            "Category" = '60*60 Elit-Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 136,
            "TotalStock" = 136,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO056', '17156', '60*60 Elit-Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 136, 0,
            136, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('76102'))
       OR "Sku" = 'TAKAO057'
    ORDER BY CASE WHEN "Sku" = 'TAKAO057' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO057',
            "Name" = '76102',
            "Category" = '60*60 Elite Ametyist',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 146,
            "TotalStock" = 146,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO057', '76102', '60*60 Elite Ametyist', 'Hộp', supp_id,
            0, 0, 0,
            0, 146, 0,
            146, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('76103'))
       OR "Sku" = 'TAKAO058'
    ORDER BY CASE WHEN "Sku" = 'TAKAO058' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO058',
            "Name" = '76103',
            "Category" = '60*60 Elite Ametyist',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 95,
            "TotalStock" = 95,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO058', '76103', '60*60 Elite Ametyist', 'Hộp', supp_id,
            0, 0, 0,
            0, 95, 0,
            95, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('76105'))
       OR "Sku" = 'TAKAO059'
    ORDER BY CASE WHEN "Sku" = 'TAKAO059' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO059',
            "Name" = '76105',
            "Category" = '60*60 Elite Ametyist',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 135,
            "TotalStock" = 135,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO059', '76105', '60*60 Elite Ametyist', 'Hộp', supp_id,
            0, 0, 0,
            0, 135, 0,
            135, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18901'))
       OR "Sku" = 'TAKAO060'
    ORDER BY CASE WHEN "Sku" = 'TAKAO060' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO060',
            "Name" = '18901',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 1,
            "TotalStock" = 1,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO060', '18901', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 1, 0,
            1, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18902'))
       OR "Sku" = 'TAKAO061'
    ORDER BY CASE WHEN "Sku" = 'TAKAO061' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO061',
            "Name" = '18902',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 36,
            "TotalStock" = 36,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO061', '18902', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 36, 0,
            36, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18906'))
       OR "Sku" = 'TAKAO062'
    ORDER BY CASE WHEN "Sku" = 'TAKAO062' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO062',
            "Name" = '18906',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 192,
            "TotalStock" = 192,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO062', '18906', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 192, 0,
            192, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18911'))
       OR "Sku" = 'TAKAO063'
    ORDER BY CASE WHEN "Sku" = 'TAKAO063' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO063',
            "Name" = '18911',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 48,
            "TotalStock" = 48,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO063', '18911', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 48, 0,
            48, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18912'))
       OR "Sku" = 'TAKAO064'
    ORDER BY CASE WHEN "Sku" = 'TAKAO064' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO064',
            "Name" = '18912',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 106,
            "TotalStock" = 106,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO064', '18912', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 106, 0,
            106, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18913'))
       OR "Sku" = 'TAKAO065'
    ORDER BY CASE WHEN "Sku" = 'TAKAO065' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO065',
            "Name" = '18913',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 179,
            "TotalStock" = 179,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO065', '18913', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 179, 0,
            179, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18916'))
       OR "Sku" = 'TAKAO066'
    ORDER BY CASE WHEN "Sku" = 'TAKAO066' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO066',
            "Name" = '18916',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 358.67,
            "TotalStock" = 358.67,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO066', '18916', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 358.67, 0,
            358.67, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18917'))
       OR "Sku" = 'TAKAO067'
    ORDER BY CASE WHEN "Sku" = 'TAKAO067' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO067',
            "Name" = '18917',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 364,
            "TotalStock" = 364,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO067', '18917', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 364, 0,
            364, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18126'))
       OR "Sku" = 'TAKAO068'
    ORDER BY CASE WHEN "Sku" = 'TAKAO068' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO068',
            "Name" = '18126',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO068', '18126', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48302'))
       OR "Sku" = 'TAKAO069'
    ORDER BY CASE WHEN "Sku" = 'TAKAO069' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO069',
            "Name" = '48302',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 59,
            "TotalStock" = 59,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO069', '48302', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 59, 0,
            59, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('48304'))
       OR "Sku" = 'TAKAO070'
    ORDER BY CASE WHEN "Sku" = 'TAKAO070' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO070',
            "Name" = '48304',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 69,
            "TotalStock" = 69,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO070', '48304', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 69, 0,
            69, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18402'))
       OR "Sku" = 'TAKAO071'
    ORDER BY CASE WHEN "Sku" = 'TAKAO071' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO071',
            "Name" = '18402',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 9,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO071', '18402', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 9, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('78001'))
       OR "Sku" = 'TAKAO072'
    ORDER BY CASE WHEN "Sku" = 'TAKAO072' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO072',
            "Name" = '78001',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 394,
            "TotalStock" = 394,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO072', '78001', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 394, 0,
            394, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('78002'))
       OR "Sku" = 'TAKAO073'
    ORDER BY CASE WHEN "Sku" = 'TAKAO073' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO073',
            "Name" = '78002',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 248,
            "TotalStock" = 248,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO073', '78002', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 248, 0,
            248, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('78003'))
       OR "Sku" = 'TAKAO074'
    ORDER BY CASE WHEN "Sku" = 'TAKAO074' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO074',
            "Name" = '78003',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 380,
            "TotalStock" = 380,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO074', '78003', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 380, 0,
            380, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('78008'))
       OR "Sku" = 'TAKAO075'
    ORDER BY CASE WHEN "Sku" = 'TAKAO075' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO075',
            "Name" = '78008',
            "Category" = '80*80-BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 342,
            "TotalStock" = 342,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO075', '78008', '80*80-BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 342, 0,
            342, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18701'))
       OR "Sku" = 'TAKAO076'
    ORDER BY CASE WHEN "Sku" = 'TAKAO076' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO076',
            "Name" = '18701',
            "Category" = '80*80 Elite Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 526,
            "TotalStock" = 526,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO076', '18701', '80*80 Elite Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 526, 0,
            526, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18704'))
       OR "Sku" = 'TAKAO077'
    ORDER BY CASE WHEN "Sku" = 'TAKAO077' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO077',
            "Name" = '18704',
            "Category" = '80*80 Elite Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 208,
            "TotalStock" = 208,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO077', '18704', '80*80 Elite Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 208, 0,
            208, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18706'))
       OR "Sku" = 'TAKAO078'
    ORDER BY CASE WHEN "Sku" = 'TAKAO078' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO078',
            "Name" = '18706',
            "Category" = '80*80 Elite Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 450,
            "TotalStock" = 450,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO078', '18706', '80*80 Elite Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 450, 0,
            450, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('18707'))
       OR "Sku" = 'TAKAO079'
    ORDER BY CASE WHEN "Sku" = 'TAKAO079' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO079',
            "Name" = '18707',
            "Category" = '80*80 Elite Crit',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 340,
            "TotalStock" = 340,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO079', '18707', '80*80 Elite Crit', 'Hộp', supp_id,
            0, 0, 0,
            0, 340, 0,
            340, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('78702'))
       OR "Sku" = 'TAKAO080'
    ORDER BY CASE WHEN "Sku" = 'TAKAO080' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO080',
            "Name" = '78702',
            "Category" = '80*80 Elite Amethist',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 105,
            "TotalStock" = 105,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO080', '78702', '80*80 Elite Amethist', 'Hộp', supp_id,
            0, 0, 0,
            0, 105, 0,
            105, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('78703'))
       OR "Sku" = 'TAKAO081'
    ORDER BY CASE WHEN "Sku" = 'TAKAO081' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO081',
            "Name" = '78703',
            "Category" = '80*80 Elite Amethist',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 406,
            "TotalStock" = 406,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO081', '78703', '80*80 Elite Amethist', 'Hộp', supp_id,
            0, 0, 0,
            0, 406, 0,
            406, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('78705'))
       OR "Sku" = 'TAKAO082'
    ORDER BY CASE WHEN "Sku" = 'TAKAO082' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO082',
            "Name" = '78705',
            "Category" = '80*80 Elite Amethist',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 243,
            "TotalStock" = 243,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO082', '78705', '80*80 Elite Amethist', 'Hộp', supp_id,
            0, 0, 0,
            0, 243, 0,
            243, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11101'))
       OR "Sku" = 'TAKAO083'
    ORDER BY CASE WHEN "Sku" = 'TAKAO083' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO083',
            "Name" = '11101',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 217,
            "TotalStock" = 217,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO083', '11101', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 217, 0,
            217, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11102'))
       OR "Sku" = 'TAKAO084'
    ORDER BY CASE WHEN "Sku" = 'TAKAO084' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO084',
            "Name" = '11102',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 262,
            "TotalStock" = 262,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO084', '11102', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 262, 0,
            262, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11103'))
       OR "Sku" = 'TAKAO085'
    ORDER BY CASE WHEN "Sku" = 'TAKAO085' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO085',
            "Name" = '11103',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 295.5,
            "TotalStock" = 295.5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO085', '11103', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 295.5, 0,
            295.5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11104'))
       OR "Sku" = 'TAKAO086'
    ORDER BY CASE WHEN "Sku" = 'TAKAO086' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO086',
            "Name" = '11104',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 235,
            "TotalStock" = 235,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO086', '11104', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 235, 0,
            235, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('11106'))
       OR "Sku" = 'TAKAO087'
    ORDER BY CASE WHEN "Sku" = 'TAKAO087' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO087',
            "Name" = '11106',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 54,
            "TotalStock" = 54,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO087', '11106', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 54, 0,
            54, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('71.101'))
       OR "Sku" = 'TAKAO088'
    ORDER BY CASE WHEN "Sku" = 'TAKAO088' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO088',
            "Name" = '71.101',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 221,
            "TotalStock" = 221,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO088', '71.101', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 221, 0,
            221, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('71102'))
       OR "Sku" = 'TAKAO089'
    ORDER BY CASE WHEN "Sku" = 'TAKAO089' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO089',
            "Name" = '71102',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 309,
            "TotalStock" = 309,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO089', '71102', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 309, 0,
            309, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('71103'))
       OR "Sku" = 'TAKAO090'
    ORDER BY CASE WHEN "Sku" = 'TAKAO090' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO090',
            "Name" = '71103',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 350,
            "TotalStock" = 350,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO090', '71103', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 350, 0,
            350, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('71105'))
       OR "Sku" = 'TAKAO091'
    ORDER BY CASE WHEN "Sku" = 'TAKAO091' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO091',
            "Name" = '71105',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 194,
            "TotalStock" = 194,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO091', '71105', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 194, 0,
            194, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TAKAO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('71108'))
       OR "Sku" = 'TAKAO092'
    ORDER BY CASE WHEN "Sku" = 'TAKAO092' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TAKAO092',
            "Name" = '71108',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 303,
            "TotalStock" = 303,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TAKAO092', '71108', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 303, 0,
            303, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

-- >>> Hãng: Vĩnh Thắng (VT) - Tổng 39 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FR5001'))
       OR "Sku" = 'VT001'
    ORDER BY CASE WHEN "Sku" = 'VT001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT001',
            "Name" = 'FR5001',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 235,
            "TotalStock" = 235,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT001', 'FR5001', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 235, 0,
            235, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FR5002'))
       OR "Sku" = 'VT002'
    ORDER BY CASE WHEN "Sku" = 'VT002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT002',
            "Name" = 'FR5002',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 255,
            "TotalStock" = 255,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT002', 'FR5002', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 255, 0,
            255, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FR5004'))
       OR "Sku" = 'VT003'
    ORDER BY CASE WHEN "Sku" = 'VT003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT003',
            "Name" = 'FR5004',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 217,
            "TotalStock" = 217,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT003', 'FR5004', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 217, 0,
            217, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FR5005'))
       OR "Sku" = 'VT004'
    ORDER BY CASE WHEN "Sku" = 'VT004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT004',
            "Name" = 'FR5005',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 249,
            "TotalStock" = 249,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT004', 'FR5005', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 249, 0,
            249, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FR5007'))
       OR "Sku" = 'VT005'
    ORDER BY CASE WHEN "Sku" = 'VT005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT005',
            "Name" = 'FR5007',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 229,
            "TotalStock" = 229,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT005', 'FR5007', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 229, 0,
            229, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FR5008'))
       OR "Sku" = 'VT006'
    ORDER BY CASE WHEN "Sku" = 'VT006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT006',
            "Name" = 'FR5008',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 379,
            "TotalStock" = 379,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT006', 'FR5008', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 379, 0,
            379, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FR5509'))
       OR "Sku" = 'VT007'
    ORDER BY CASE WHEN "Sku" = 'VT007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT007',
            "Name" = 'FR5509',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 120,
            "TotalStock" = 120,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT007', 'FR5509', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 120, 0,
            120, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3601-KHÓI'))
       OR "Sku" = 'VT008'
    ORDER BY CASE WHEN "Sku" = 'VT008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT008',
            "Name" = 'FB3601-KHÓI',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 421,
            "TotalStock" = 421,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT008', 'FB3601-KHÓI', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 421, 0,
            421, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3603-NHẠT'))
       OR "Sku" = 'VT009'
    ORDER BY CASE WHEN "Sku" = 'VT009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT009',
            "Name" = 'FB3603-NHẠT',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 309,
            "TotalStock" = 309,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT009', 'FB3603-NHẠT', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 309, 0,
            309, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3603-ĐẬM'))
       OR "Sku" = 'VT010'
    ORDER BY CASE WHEN "Sku" = 'VT010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT010',
            "Name" = 'FB3603-ĐẬM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 145,
            "TotalStock" = 145,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT010', 'FB3603-ĐẬM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 145, 0,
            145, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3603-ĐIỂM'))
       OR "Sku" = 'VT011'
    ORDER BY CASE WHEN "Sku" = 'VT011' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT011',
            "Name" = 'FB3603-ĐIỂM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 26.5,
            "TotalStock" = 26.5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT011', 'FB3603-ĐIỂM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 26.5, 0,
            26.5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3604-NHẠT'))
       OR "Sku" = 'VT012'
    ORDER BY CASE WHEN "Sku" = 'VT012' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT012',
            "Name" = 'FB3604-NHẠT',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 121,
            "TotalStock" = 121,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT012', 'FB3604-NHẠT', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 121, 0,
            121, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3604-ĐẬM'))
       OR "Sku" = 'VT013'
    ORDER BY CASE WHEN "Sku" = 'VT013' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT013',
            "Name" = 'FB3604-ĐẬM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 114,
            "TotalStock" = 114,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT013', 'FB3604-ĐẬM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 114, 0,
            114, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3604-ĐIỂM'))
       OR "Sku" = 'VT014'
    ORDER BY CASE WHEN "Sku" = 'VT014' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT014',
            "Name" = 'FB3604-ĐIỂM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 46,
            "TotalStock" = 46,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT014', 'FB3604-ĐIỂM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 46, 0,
            46, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3605-NHẠT'))
       OR "Sku" = 'VT015'
    ORDER BY CASE WHEN "Sku" = 'VT015' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT015',
            "Name" = 'FB3605-NHẠT',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 190,
            "TotalStock" = 190,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT015', 'FB3605-NHẠT', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 190, 0,
            190, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3605-ĐẬM'))
       OR "Sku" = 'VT016'
    ORDER BY CASE WHEN "Sku" = 'VT016' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT016',
            "Name" = 'FB3605-ĐẬM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 126,
            "TotalStock" = 126,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT016', 'FB3605-ĐẬM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 126, 0,
            126, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3605-ĐIỂM'))
       OR "Sku" = 'VT017'
    ORDER BY CASE WHEN "Sku" = 'VT017' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT017',
            "Name" = 'FB3605-ĐIỂM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 37,
            "TotalStock" = 37,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT017', 'FB3605-ĐIỂM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 37, 0,
            37, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3607-NHẠT'))
       OR "Sku" = 'VT018'
    ORDER BY CASE WHEN "Sku" = 'VT018' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT018',
            "Name" = 'FB3607-NHẠT',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 8,
            "TotalStock" = 8,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT018', 'FB3607-NHẠT', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 8, 0,
            8, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3607-ĐẬM'))
       OR "Sku" = 'VT019'
    ORDER BY CASE WHEN "Sku" = 'VT019' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT019',
            "Name" = 'FB3607-ĐẬM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT019', 'FB3607-ĐẬM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3607-ĐIỂM'))
       OR "Sku" = 'VT020'
    ORDER BY CASE WHEN "Sku" = 'VT020' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT020',
            "Name" = 'FB3607-ĐIỂM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 20,
            "TotalStock" = 20,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT020', 'FB3607-ĐIỂM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 20, 0,
            20, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3610-NHẠT'))
       OR "Sku" = 'VT021'
    ORDER BY CASE WHEN "Sku" = 'VT021' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT021',
            "Name" = 'FB3610-NHẠT',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 19,
            "TotalStock" = 19,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT021', 'FB3610-NHẠT', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 19, 0,
            19, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3610-ĐẬM'))
       OR "Sku" = 'VT022'
    ORDER BY CASE WHEN "Sku" = 'VT022' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT022',
            "Name" = 'FB3610-ĐẬM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 19.5,
            "TotalStock" = 19.5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT022', 'FB3610-ĐẬM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 19.5, 0,
            19.5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FB3610-ĐIỂM'))
       OR "Sku" = 'VT023'
    ORDER BY CASE WHEN "Sku" = 'VT023' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT023',
            "Name" = 'FB3610-ĐIỂM',
            "Category" = '50*50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 21.5,
            "TotalStock" = 21.5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT023', 'FB3610-ĐIỂM', '50*50 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 21.5, 0,
            21.5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM5801'))
       OR "Sku" = 'VT024'
    ORDER BY CASE WHEN "Sku" = 'VT024' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT024',
            "Name" = 'FM5801',
            "Category" = '50*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT024', 'FM5801', '50*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM5802'))
       OR "Sku" = 'VT025'
    ORDER BY CASE WHEN "Sku" = 'VT025' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT025',
            "Name" = 'FM5802',
            "Category" = '50*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 123,
            "TotalStock" = 123,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT025', 'FM5802', '50*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 123, 0,
            123, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM5803'))
       OR "Sku" = 'VT026'
    ORDER BY CASE WHEN "Sku" = 'VT026' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT026',
            "Name" = 'FM5803',
            "Category" = '50*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 5,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT026', 'FM5803', '50*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 5, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM4601'))
       OR "Sku" = 'VT027'
    ORDER BY CASE WHEN "Sku" = 'VT027' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT027',
            "Name" = 'FM4601',
            "Category" = '40*60 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 10,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT027', 'FM4601', '40*60 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            0, 10, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM4603'))
       OR "Sku" = 'VT028'
    ORDER BY CASE WHEN "Sku" = 'VT028' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT028',
            "Name" = 'FM4603',
            "Category" = '40*60 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 109,
            "TotalStock" = 109,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT028', 'FM4603', '40*60 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            0, 109, 0,
            109, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM4604'))
       OR "Sku" = 'VT029'
    ORDER BY CASE WHEN "Sku" = 'VT029' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT029',
            "Name" = 'FM4604',
            "Category" = '40*60 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 158,
            "TotalStock" = 158,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT029', 'FM4604', '40*60 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            0, 158, 0,
            158, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM4605'))
       OR "Sku" = 'VT030'
    ORDER BY CASE WHEN "Sku" = 'VT030' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT030',
            "Name" = 'FM4605',
            "Category" = '40*60 SÂN VƯỜN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 46,
            "TotalStock" = 46,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT030', 'FM4605', '40*60 SÂN VƯỜN', 'Hộp', supp_id,
            0, 0, 0,
            0, 46, 0,
            46, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FP46061'))
       OR "Sku" = 'VT031'
    ORDER BY CASE WHEN "Sku" = 'VT031' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT031',
            "Name" = 'FP46061',
            "Category" = '40*60 SÂN VƯỜN semi',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 331,
            "TotalStock" = 331,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT031', 'FP46061', '40*60 SÂN VƯỜN semi', 'Hộp', supp_id,
            0, 0, 0,
            0, 331, 0,
            331, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FP46062'))
       OR "Sku" = 'VT032'
    ORDER BY CASE WHEN "Sku" = 'VT032' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT032',
            "Name" = 'FP46062',
            "Category" = '40*60 SÂN VƯỜN semi',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 331,
            "TotalStock" = 331,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT032', 'FP46062', '40*60 SÂN VƯỜN semi', 'Hộp', supp_id,
            0, 0, 0,
            0, 331, 0,
            331, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FP46065'))
       OR "Sku" = 'VT033'
    ORDER BY CASE WHEN "Sku" = 'VT033' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT033',
            "Name" = 'FP46065',
            "Category" = '40*60 SÂN VƯỜN semi',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 331,
            "TotalStock" = 331,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT033', 'FP46065', '40*60 SÂN VƯỜN semi', 'Hộp', supp_id,
            0, 0, 0,
            0, 331, 0,
            331, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('F3305'))
       OR "Sku" = 'VT034'
    ORDER BY CASE WHEN "Sku" = 'VT034' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT034',
            "Name" = 'F3305',
            "Category" = '30*30 CHỐNG TRƠN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 65,
            "TotalStock" = 65,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT034', 'F3305', '30*30 CHỐNG TRƠN', 'Hộp', supp_id,
            0, 0, 0,
            0, 65, 0,
            65, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM3308'))
       OR "Sku" = 'VT035'
    ORDER BY CASE WHEN "Sku" = 'VT035' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT035',
            "Name" = 'FM3308',
            "Category" = '30*30 CHỐNG TRƠN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 216,
            "TotalStock" = 216,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT035', 'FM3308', '30*30 CHỐNG TRƠN', 'Hộp', supp_id,
            0, 0, 0,
            0, 216, 0,
            216, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('FM3310'))
       OR "Sku" = 'VT036'
    ORDER BY CASE WHEN "Sku" = 'VT036' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT036',
            "Name" = 'FM3310',
            "Category" = '30*30 CHỐNG TRƠN',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 126,
            "TotalStock" = 126,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT036', 'FM3310', '30*30 CHỐNG TRƠN', 'Hộp', supp_id,
            0, 0, 0,
            0, 126, 0,
            126, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('F6602'))
       OR "Sku" = 'VT037'
    ORDER BY CASE WHEN "Sku" = 'VT037' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT037',
            "Name" = 'F6602',
            "Category" = '60*60 hàng Ceramic',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 888,
            "TotalStock" = 888,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT037', 'F6602', '60*60 hàng Ceramic', 'Hộp', supp_id,
            0, 0, 0,
            0, 888, 0,
            888, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('F6616'))
       OR "Sku" = 'VT038'
    ORDER BY CASE WHEN "Sku" = 'VT038' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT038',
            "Name" = 'F6616',
            "Category" = '60*60 hàng Ceramic',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 125,
            "TotalStock" = 125,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT038', 'F6616', '60*60 hàng Ceramic', 'Hộp', supp_id,
            0, 0, 0,
            0, 125, 0,
            125, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'VT';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('F6604'))
       OR "Sku" = 'VT039'
    ORDER BY CASE WHEN "Sku" = 'VT039' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'VT039',
            "Name" = 'F6604',
            "Category" = '60*60 hàng Ceramic',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 358,
            "TotalStock" = 358,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'VT039', 'F6604', '60*60 hàng Ceramic', 'Hộp', supp_id,
            0, 0, 0,
            0, 358, 0,
            358, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

-- >>> Hãng: Dmax + Mira (DMAX) - Tổng 18 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA6601'))
       OR "Sku" = 'DMAX001'
    ORDER BY CASE WHEN "Sku" = 'DMAX001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX001',
            "Name" = 'DA6601',
            "Category" = '60*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 11,
            "TotalStock" = 11,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX001', 'DA6601', '60*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 11, 0,
            11, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA6602'))
       OR "Sku" = 'DMAX002'
    ORDER BY CASE WHEN "Sku" = 'DMAX002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX002',
            "Name" = 'DA6602',
            "Category" = '60*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 227,
            "TotalStock" = 227,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX002', 'DA6602', '60*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 227, 0,
            227, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA6603'))
       OR "Sku" = 'DMAX003'
    ORDER BY CASE WHEN "Sku" = 'DMAX003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX003',
            "Name" = 'DA6603',
            "Category" = '60*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX003', 'DA6603', '60*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA6604'))
       OR "Sku" = 'DMAX004'
    ORDER BY CASE WHEN "Sku" = 'DMAX004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX004',
            "Name" = 'DA6604',
            "Category" = '60*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 9,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX004', 'DA6604', '60*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 9, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA6606'))
       OR "Sku" = 'DMAX005'
    ORDER BY CASE WHEN "Sku" = 'DMAX005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX005',
            "Name" = 'DA6606',
            "Category" = '60*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 10,
            "TotalStock" = 10,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX005', 'DA6606', '60*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 10, 0,
            10, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA8801'))
       OR "Sku" = 'DMAX006'
    ORDER BY CASE WHEN "Sku" = 'DMAX006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX006',
            "Name" = 'DA8801',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 18,
            "TotalStock" = 18,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX006', 'DA8801', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 18, 0,
            18, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA8802'))
       OR "Sku" = 'DMAX007'
    ORDER BY CASE WHEN "Sku" = 'DMAX007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX007',
            "Name" = 'DA8802',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 69,
            "TotalStock" = 69,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX007', 'DA8802', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 69, 0,
            69, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA8803'))
       OR "Sku" = 'DMAX008'
    ORDER BY CASE WHEN "Sku" = 'DMAX008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX008',
            "Name" = 'DA8803',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 11,
            "TotalStock" = 11,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX008', 'DA8803', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 11, 0,
            11, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA8804'))
       OR "Sku" = 'DMAX009'
    ORDER BY CASE WHEN "Sku" = 'DMAX009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX009',
            "Name" = 'DA8804',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 97,
            "TotalStock" = 97,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX009', 'DA8804', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 97, 0,
            97, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA8806'))
       OR "Sku" = 'DMAX010'
    ORDER BY CASE WHEN "Sku" = 'DMAX010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX010',
            "Name" = 'DA8806',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX010', 'DA8806', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA61205'))
       OR "Sku" = 'DMAX011'
    ORDER BY CASE WHEN "Sku" = 'DMAX011' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX011',
            "Name" = 'DA61205',
            "Category" = '60*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 14,
            "TotalStock" = 14,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX011', 'DA61205', '60*120', 'Hộp', supp_id,
            0, 0, 0,
            0, 14, 0,
            14, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA1001'))
       OR "Sku" = 'DMAX012'
    ORDER BY CASE WHEN "Sku" = 'DMAX012' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX012',
            "Name" = 'DA1001',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 16,
            "TotalStock" = 16,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX012', 'DA1001', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 16, 0,
            16, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA1002'))
       OR "Sku" = 'DMAX013'
    ORDER BY CASE WHEN "Sku" = 'DMAX013' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX013',
            "Name" = 'DA1002',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 23,
            "TotalStock" = 23,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX013', 'DA1002', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 23, 0,
            23, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DA1004'))
       OR "Sku" = 'DMAX014'
    ORDER BY CASE WHEN "Sku" = 'DMAX014' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX014',
            "Name" = 'DA1004',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 23,
            "TotalStock" = 23,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX014', 'DA1004', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 23, 0,
            23, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MR12902'))
       OR "Sku" = 'DMAX015'
    ORDER BY CASE WHEN "Sku" = 'DMAX015' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX015',
            "Name" = 'MR12902',
            "Category" = '60*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 17,
            "TotalStock" = 17,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX015', 'MR12902', '60*120', 'Hộp', supp_id,
            0, 0, 0,
            0, 17, 0,
            17, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MR11034'))
       OR "Sku" = 'DMAX016'
    ORDER BY CASE WHEN "Sku" = 'DMAX016' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX016',
            "Name" = 'MR11034',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 20,
            "TotalStock" = 20,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX016', 'MR11034', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 20, 0,
            20, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MR11037'))
       OR "Sku" = 'DMAX017'
    ORDER BY CASE WHEN "Sku" = 'DMAX017' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX017',
            "Name" = 'MR11037',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 9,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX017', 'MR11037', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 9, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'DMAX';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('MR11039'))
       OR "Sku" = 'DMAX018'
    ORDER BY CASE WHEN "Sku" = 'DMAX018' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'DMAX018',
            "Name" = 'MR11039',
            "Category" = '1M*1M',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'DMAX018', 'MR11039', '1M*1M', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

-- >>> Hãng: Royal + Ấn Độ (RA) - Tổng 19 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DP514'))
       OR "Sku" = 'RA001'
    ORDER BY CASE WHEN "Sku" = 'RA001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA001',
            "Name" = 'DP514',
            "Category" = '50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 39,
            "StockWarehouse2" = 0,
            "TotalStock" = 39,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA001', 'DP514', '50 SV', 'Hộp', supp_id,
            0, 0, 0,
            39, 0, 0,
            39, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DP515'))
       OR "Sku" = 'RA002'
    ORDER BY CASE WHEN "Sku" = 'RA002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA002',
            "Name" = 'DP515',
            "Category" = '50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 426.33,
            "StockWarehouse2" = 0,
            "TotalStock" = 426.33,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA002', 'DP515', '50 SV', 'Hộp', supp_id,
            0, 0, 0,
            426.33, 0, 0,
            426.33, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('DP518'))
       OR "Sku" = 'RA003'
    ORDER BY CASE WHEN "Sku" = 'RA003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA003',
            "Name" = 'DP518',
            "Category" = '50 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 16,
            "StockWarehouse2" = 0,
            "TotalStock" = 16,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA003', 'DP518', '50 SV', 'Hộp', supp_id,
            0, 0, 0,
            16, 0, 0,
            16, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('BS3601-P'))
       OR "Sku" = 'RA004'
    ORDER BY CASE WHEN "Sku" = 'RA004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA004',
            "Name" = 'BS3601-P',
            "Category" = '30*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 3,
            "StockWarehouse2" = 0,
            "TotalStock" = 3,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA004', 'BS3601-P', '30*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            3, 0, 0,
            3, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('BS3605-DH'))
       OR "Sku" = 'RA005'
    ORDER BY CASE WHEN "Sku" = 'RA005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA005',
            "Name" = 'BS3605-DH',
            "Category" = '30*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 32,
            "StockWarehouse2" = 0,
            "TotalStock" = 32,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA005', 'BS3605-DH', '30*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            32, 0, 0,
            32, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('TP602'))
       OR "Sku" = 'RA006'
    ORDER BY CASE WHEN "Sku" = 'RA006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA006',
            "Name" = 'TP602',
            "Category" = '60*60 BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 44,
            "StockWarehouse2" = 0,
            "TotalStock" = 44,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA006', 'TP602', '60*60 BS', 'Hộp', supp_id,
            0, 0, 0,
            44, 0, 0,
            44, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LIMBER'))
       OR "Sku" = 'RA007'
    ORDER BY CASE WHEN "Sku" = 'RA007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA007',
            "Name" = 'LIMBER',
            "Category" = '20*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 3,
            "StockWarehouse2" = 0,
            "TotalStock" = 3,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA007', 'LIMBER', '20*120', 'Hộp', supp_id,
            0, 0, 0,
            3, 0, 0,
            3, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('CAFÉ'))
       OR "Sku" = 'RA008'
    ORDER BY CASE WHEN "Sku" = 'RA008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA008',
            "Name" = 'CAFÉ',
            "Category" = '20*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 55,
            "StockWarehouse2" = 0,
            "TotalStock" = 55,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA008', 'CAFÉ', '20*120', 'Hộp', supp_id,
            0, 0, 0,
            55, 0, 0,
            55, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('APRICOT'))
       OR "Sku" = 'RA009'
    ORDER BY CASE WHEN "Sku" = 'RA009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA009',
            "Name" = 'APRICOT',
            "Category" = '20*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 69,
            "StockWarehouse2" = 0,
            "TotalStock" = 69,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA009', 'APRICOT', '20*120', 'Hộp', supp_id,
            0, 0, 0,
            69, 0, 0,
            69, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('LIFE'))
       OR "Sku" = 'RA010'
    ORDER BY CASE WHEN "Sku" = 'RA010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA010',
            "Name" = 'LIFE',
            "Category" = '20*120',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 63,
            "StockWarehouse2" = 0,
            "TotalStock" = 63,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA010', 'LIFE', '20*120', 'Hộp', supp_id,
            0, 0, 0,
            63, 0, 0,
            63, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('1683'))
       OR "Sku" = 'RA011'
    ORDER BY CASE WHEN "Sku" = 'RA011' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA011',
            "Name" = '1683',
            "Category" = '30*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 55,
            "StockWarehouse2" = 0,
            "TotalStock" = 55,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA011', '1683', '30*60', 'Hộp', supp_id,
            0, 0, 0,
            55, 0, 0,
            55, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('1543'))
       OR "Sku" = 'RA012'
    ORDER BY CASE WHEN "Sku" = 'RA012' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA012',
            "Name" = '1543',
            "Category" = '30*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 16,
            "StockWarehouse2" = 0,
            "TotalStock" = 16,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA012', '1543', '30*60', 'Hộp', supp_id,
            0, 0, 0,
            16, 0, 0,
            16, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('1072'))
       OR "Sku" = 'RA013'
    ORDER BY CASE WHEN "Sku" = 'RA013' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA013',
            "Name" = '1072',
            "Category" = '30*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 34,
            "StockWarehouse2" = 0,
            "TotalStock" = 34,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA013', '1072', '30*60', 'Hộp', supp_id,
            0, 0, 0,
            34, 0, 0,
            34, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('1347'))
       OR "Sku" = 'RA014'
    ORDER BY CASE WHEN "Sku" = 'RA014' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA014',
            "Name" = '1347',
            "Category" = '30*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 4,
            "StockWarehouse2" = 0,
            "TotalStock" = 4,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA014', '1347', '30*60', 'Hộp', supp_id,
            0, 0, 0,
            4, 0, 0,
            4, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('Keo CK vỏ cam(bao 25kg)'))
       OR "Sku" = 'RA015'
    ORDER BY CASE WHEN "Sku" = 'RA015' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA015',
            "Name" = 'Keo CK vỏ cam(bao 25kg)',
            "Category" = 'PHỤ GIA',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA015', 'Keo CK vỏ cam(bao 25kg)', 'PHỤ GIA', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('KE 1MM'))
       OR "Sku" = 'RA016'
    ORDER BY CASE WHEN "Sku" = 'RA016' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA016',
            "Name" = 'KE 1MM',
            "Category" = 'PHỤ GIA',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 12,
            "StockWarehouse2" = 0,
            "TotalStock" = 12,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA016', 'KE 1MM', 'PHỤ GIA', 'Hộp', supp_id,
            0, 0, 0,
            12, 0, 0,
            12, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('KE 1,5 MM'))
       OR "Sku" = 'RA017'
    ORDER BY CASE WHEN "Sku" = 'RA017' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA017',
            "Name" = 'KE 1,5 MM',
            "Category" = 'PHỤ GIA',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 35,
            "StockWarehouse2" = 0,
            "TotalStock" = 35,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA017', 'KE 1,5 MM', 'PHỤ GIA', 'Hộp', supp_id,
            0, 0, 0,
            35, 0, 0,
            35, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('NÊM ĐỎ'))
       OR "Sku" = 'RA018'
    ORDER BY CASE WHEN "Sku" = 'RA018' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA018',
            "Name" = 'NÊM ĐỎ',
            "Category" = 'PHỤ GIA',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 31,
            "StockWarehouse2" = 0,
            "TotalStock" = 31,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA018', 'NÊM ĐỎ', 'PHỤ GIA', 'Hộp', supp_id,
            0, 0, 0,
            31, 0, 0,
            31, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'RA';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('keo 20 kg'))
       OR "Sku" = 'RA019'
    ORDER BY CASE WHEN "Sku" = 'RA019' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'RA019',
            "Name" = 'keo 20 kg',
            "Category" = 'PHỤ GIA',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 77,
            "StockWarehouse2" = 0,
            "TotalStock" = 77,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'RA019', 'keo 20 kg', 'PHỤ GIA', 'Hộp', supp_id,
            0, 0, 0,
            77, 0, 0,
            77, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

-- >>> Hãng: Toko (TOKO) - Tổng 45 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('3002'))
       OR "Sku" = 'TOKO001'
    ORDER BY CASE WHEN "Sku" = 'TOKO001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO001',
            "Name" = '3002',
            "Category" = '30*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 18,
            "TotalStock" = 18,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO001', '3002', '30*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 18, 0,
            18, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('3003'))
       OR "Sku" = 'TOKO002'
    ORDER BY CASE WHEN "Sku" = 'TOKO002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO002',
            "Name" = '3003',
            "Category" = '30*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 15,
            "TotalStock" = 15,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO002', '3003', '30*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 15, 0,
            15, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('3004'))
       OR "Sku" = 'TOKO003'
    ORDER BY CASE WHEN "Sku" = 'TOKO003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO003',
            "Name" = '3004',
            "Category" = '30*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 11,
            "TotalStock" = 11,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO003', '3004', '30*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 11, 0,
            11, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('3005'))
       OR "Sku" = 'TOKO004'
    ORDER BY CASE WHEN "Sku" = 'TOKO004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO004',
            "Name" = '3005',
            "Category" = '30*60 SV',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 9,
            "TotalStock" = 9,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO004', '3005', '30*60 SV', 'Hộp', supp_id,
            0, 0, 0,
            0, 9, 0,
            9, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5301'))
       OR "Sku" = 'TOKO005'
    ORDER BY CASE WHEN "Sku" = 'TOKO005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO005',
            "Name" = '5301',
            "Category" = '50*50 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 34,
            "TotalStock" = 34,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO005', '5301', '50*50 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 34, 0,
            34, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5302'))
       OR "Sku" = 'TOKO006'
    ORDER BY CASE WHEN "Sku" = 'TOKO006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO006',
            "Name" = '5302',
            "Category" = '50*50 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 5,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO006', '5302', '50*50 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 5, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5305'))
       OR "Sku" = 'TOKO007'
    ORDER BY CASE WHEN "Sku" = 'TOKO007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO007',
            "Name" = '5305',
            "Category" = '50*50 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 27,
            "TotalStock" = 27,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO007', '5305', '50*50 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 27, 0,
            27, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('5306'))
       OR "Sku" = 'TOKO008'
    ORDER BY CASE WHEN "Sku" = 'TOKO008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO008',
            "Name" = '5306',
            "Category" = '50*50 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 62,
            "TotalStock" = 62,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO008', '5306', '50*50 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 62, 0,
            62, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('46301-(8v/h)'))
       OR "Sku" = 'TOKO009'
    ORDER BY CASE WHEN "Sku" = 'TOKO009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO009',
            "Name" = '46301-(8v/h)',
            "Category" = '40*60 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 4,
            "TotalStock" = 4,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO009', '46301-(8v/h)', '40*60 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 4, 0,
            4, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('46302-(8v/h)'))
       OR "Sku" = 'TOKO010'
    ORDER BY CASE WHEN "Sku" = 'TOKO010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO010',
            "Name" = '46302-(8v/h)',
            "Category" = '40*60 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 39,
            "TotalStock" = 39,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO010', '46302-(8v/h)', '40*60 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 39, 0,
            39, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('46304-(6v/h)'))
       OR "Sku" = 'TOKO011'
    ORDER BY CASE WHEN "Sku" = 'TOKO011' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO011',
            "Name" = '46304-(6v/h)',
            "Category" = '40*60 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 17,
            "TotalStock" = 17,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO011', '46304-(6v/h)', '40*60 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 17, 0,
            17, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('46304- (8v/h)'))
       OR "Sku" = 'TOKO012'
    ORDER BY CASE WHEN "Sku" = 'TOKO012' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO012',
            "Name" = '46304- (8v/h)',
            "Category" = '40*60 SV BS',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO012', '46304- (8v/h)', '40*60 SV BS', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('632.005'))
       OR "Sku" = 'TOKO013'
    ORDER BY CASE WHEN "Sku" = 'TOKO013' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO013',
            "Name" = '632.005',
            "Category" = '50*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 60,
            "TotalStock" = 60,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO013', '632.005', '50*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 60, 0,
            60, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('632.009'))
       OR "Sku" = 'TOKO014'
    ORDER BY CASE WHEN "Sku" = 'TOKO014' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO014',
            "Name" = '632.009',
            "Category" = '50*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 18,
            "TotalStock" = 18,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO014', '632.009', '50*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 18, 0,
            18, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('632.602'))
       OR "Sku" = 'TOKO015'
    ORDER BY CASE WHEN "Sku" = 'TOKO015' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO015',
            "Name" = '632.602',
            "Category" = '50*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 8,
            "TotalStock" = 8,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO015', '632.602', '50*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 8, 0,
            8, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('632.603'))
       OR "Sku" = 'TOKO016'
    ORDER BY CASE WHEN "Sku" = 'TOKO016' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO016',
            "Name" = '632.603',
            "Category" = '50*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 164,
            "TotalStock" = 164,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO016', '632.603', '50*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 164, 0,
            164, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('632.604'))
       OR "Sku" = 'TOKO017'
    ORDER BY CASE WHEN "Sku" = 'TOKO017' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO017',
            "Name" = '632.604',
            "Category" = '50*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 203,
            "TotalStock" = 203,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO017', '632.604', '50*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 203, 0,
            203, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('632.605'))
       OR "Sku" = 'TOKO018'
    ORDER BY CASE WHEN "Sku" = 'TOKO018' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO018',
            "Name" = '632.605',
            "Category" = '50*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 175,
            "TotalStock" = 175,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO018', '632.605', '50*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 175, 0,
            175, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('632.608'))
       OR "Sku" = 'TOKO019'
    ORDER BY CASE WHEN "Sku" = 'TOKO019' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO019',
            "Name" = '632.608',
            "Category" = '50*60',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 42,
            "TotalStock" = 42,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO019', '632.608', '50*60', 'Hộp', supp_id,
            0, 0, 0,
            0, 42, 0,
            42, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832001'))
       OR "Sku" = 'TOKO020'
    ORDER BY CASE WHEN "Sku" = 'TOKO020' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO020',
            "Name" = '4832001',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 7,
            "TotalStock" = 7,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO020', '4832001', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 7, 0,
            7, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832002 Đ'))
       OR "Sku" = 'TOKO021'
    ORDER BY CASE WHEN "Sku" = 'TOKO021' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO021',
            "Name" = '4832002 Đ',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 2,
            "TotalStock" = 2,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO021', '4832002 Đ', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 2, 0,
            2, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832003'))
       OR "Sku" = 'TOKO022'
    ORDER BY CASE WHEN "Sku" = 'TOKO022' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO022',
            "Name" = '4832003',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO022', '4832003', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832004 Đ'))
       OR "Sku" = 'TOKO023'
    ORDER BY CASE WHEN "Sku" = 'TOKO023' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO023',
            "Name" = '4832004 Đ',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 45,
            "TotalStock" = 45,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO023', '4832004 Đ', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 45, 0,
            45, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832005'))
       OR "Sku" = 'TOKO024'
    ORDER BY CASE WHEN "Sku" = 'TOKO024' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO024',
            "Name" = '4832005',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 39,
            "TotalStock" = 39,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO024', '4832005', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 39, 0,
            39, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832005-A2'))
       OR "Sku" = 'TOKO025'
    ORDER BY CASE WHEN "Sku" = 'TOKO025' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO025',
            "Name" = '4832005-A2',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 5,
            "TotalStock" = 5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO025', '4832005-A2', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 5, 0,
            5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832006'))
       OR "Sku" = 'TOKO026'
    ORDER BY CASE WHEN "Sku" = 'TOKO026' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO026',
            "Name" = '4832006',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO026', '4832006', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832007 Đ'))
       OR "Sku" = 'TOKO027'
    ORDER BY CASE WHEN "Sku" = 'TOKO027' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO027',
            "Name" = '4832007 Đ',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 12,
            "TotalStock" = 12,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO027', '4832007 Đ', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 12, 0,
            12, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832009'))
       OR "Sku" = 'TOKO028'
    ORDER BY CASE WHEN "Sku" = 'TOKO028' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO028',
            "Name" = '4832009',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO028', '4832009', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832010 Đ'))
       OR "Sku" = 'TOKO029'
    ORDER BY CASE WHEN "Sku" = 'TOKO029' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO029',
            "Name" = '4832010 Đ',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 7,
            "TotalStock" = 7,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO029', '4832010 Đ', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 7, 0,
            7, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('4832011'))
       OR "Sku" = 'TOKO030'
    ORDER BY CASE WHEN "Sku" = 'TOKO030' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO030',
            "Name" = '4832011',
            "Category" = '40*80 BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 21,
            "TotalStock" = 21,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO030', '4832011', '40*80 BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 21, 0,
            21, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('832.001'))
       OR "Sku" = 'TOKO031'
    ORDER BY CASE WHEN "Sku" = 'TOKO031' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO031',
            "Name" = '832.001',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 48.0367,
            "TotalStock" = 48.0367,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO031', '832.001', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 48.0367, 0,
            48.0367, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('832.002'))
       OR "Sku" = 'TOKO032'
    ORDER BY CASE WHEN "Sku" = 'TOKO032' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO032',
            "Name" = '832.002',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 58,
            "TotalStock" = 58,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO032', '832.002', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 58, 0,
            58, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('832.003'))
       OR "Sku" = 'TOKO033'
    ORDER BY CASE WHEN "Sku" = 'TOKO033' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO033',
            "Name" = '832.003',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 33,
            "TotalStock" = 33,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO033', '832.003', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 33, 0,
            33, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('832.004'))
       OR "Sku" = 'TOKO034'
    ORDER BY CASE WHEN "Sku" = 'TOKO034' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO034',
            "Name" = '832.004',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 59,
            "TotalStock" = 59,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO034', '832.004', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 59, 0,
            59, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('832.005'))
       OR "Sku" = 'TOKO035'
    ORDER BY CASE WHEN "Sku" = 'TOKO035' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO035',
            "Name" = '832.005',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 121,
            "TotalStock" = 121,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO035', '832.005', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 121, 0,
            121, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('832.008'))
       OR "Sku" = 'TOKO036'
    ORDER BY CASE WHEN "Sku" = 'TOKO036' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO036',
            "Name" = '832.008',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 65,
            "TotalStock" = 65,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO036', '832.008', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 65, 0,
            65, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('832.014'))
       OR "Sku" = 'TOKO037'
    ORDER BY CASE WHEN "Sku" = 'TOKO037' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO037',
            "Name" = '832.014',
            "Category" = '80*80',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 30,
            "TotalStock" = 30,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO037', '832.014', '80*80', 'Hộp', supp_id,
            0, 0, 0,
            0, 30, 0,
            30, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336001'))
       OR "Sku" = 'TOKO038'
    ORDER BY CASE WHEN "Sku" = 'TOKO038' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO038',
            "Name" = '336001',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 18,
            "TotalStock" = 18,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO038', '336001', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 18, 0,
            18, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336002-Đ'))
       OR "Sku" = 'TOKO039'
    ORDER BY CASE WHEN "Sku" = 'TOKO039' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO039',
            "Name" = '336002-Đ',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 41,
            "TotalStock" = 41,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO039', '336002-Đ', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 41, 0,
            41, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336003'))
       OR "Sku" = 'TOKO040'
    ORDER BY CASE WHEN "Sku" = 'TOKO040' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO040',
            "Name" = '336003',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 33,
            "TotalStock" = 33,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO040', '336003', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 33, 0,
            33, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336004-Đ'))
       OR "Sku" = 'TOKO041'
    ORDER BY CASE WHEN "Sku" = 'TOKO041' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO041',
            "Name" = '336004-Đ',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 6,
            "TotalStock" = 6,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO041', '336004-Đ', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 6, 0,
            6, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336006'))
       OR "Sku" = 'TOKO042'
    ORDER BY CASE WHEN "Sku" = 'TOKO042' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO042',
            "Name" = '336006',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 66,
            "TotalStock" = 66,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO042', '336006', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 66, 0,
            66, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336007-Đ'))
       OR "Sku" = 'TOKO043'
    ORDER BY CASE WHEN "Sku" = 'TOKO043' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO043',
            "Name" = '336007-Đ',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 28,
            "TotalStock" = 28,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO043', '336007-Đ', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 28, 0,
            28, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336008'))
       OR "Sku" = 'TOKO044'
    ORDER BY CASE WHEN "Sku" = 'TOKO044' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO044',
            "Name" = '336008',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 12.5,
            "TotalStock" = 12.5,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO044', '336008', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 12.5, 0,
            12.5, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'TOKO';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('336011- A2'))
       OR "Sku" = 'TOKO045'
    ORDER BY CASE WHEN "Sku" = 'TOKO045' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'TOKO045',
            "Name" = '336011- A2',
            "Category" = '30*60-ỐP BỘ',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 7,
            "TotalStock" = 7,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'TOKO045', '336011- A2', '30*60-ỐP BỘ', 'Hộp', supp_id,
            0, 0, 0,
            0, 7, 0,
            7, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

-- >>> Hãng: Á Mỹ (AMY) - Tổng 10 SP
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM 5039'))
       OR "Sku" = 'AMY001'
    ORDER BY CASE WHEN "Sku" = 'AMY001' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY001',
            "Name" = 'AM 5039',
            "Category" = 'GẠCH 80 BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY001', 'AM 5039', 'GẠCH 80 BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM 6824'))
       OR "Sku" = 'AMY002'
    ORDER BY CASE WHEN "Sku" = 'AMY002' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY002',
            "Name" = 'AM 6824',
            "Category" = 'GẠCH 80 BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY002', 'AM 6824', 'GẠCH 80 BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM 6825'))
       OR "Sku" = 'AMY003'
    ORDER BY CASE WHEN "Sku" = 'AMY003' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY003',
            "Name" = 'AM 6825',
            "Category" = 'GẠCH 80 BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY003', 'AM 6825', 'GẠCH 80 BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM8049'))
       OR "Sku" = 'AMY004'
    ORDER BY CASE WHEN "Sku" = 'AMY004' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY004',
            "Name" = 'AM8049',
            "Category" = 'GẠCH 80 BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY004', 'AM8049', 'GẠCH 80 BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM5072'))
       OR "Sku" = 'AMY005'
    ORDER BY CASE WHEN "Sku" = 'AMY005' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY005',
            "Name" = 'AM5072',
            "Category" = 'GẠCH 80 BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY005', 'AM5072', 'GẠCH 80 BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM5060'))
       OR "Sku" = 'AMY006'
    ORDER BY CASE WHEN "Sku" = 'AMY006' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY006',
            "Name" = 'AM5060',
            "Category" = 'GẠCH 80 BÓNG',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY006', 'AM5060', 'GẠCH 80 BÓNG', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM 5069'))
       OR "Sku" = 'AMY007'
    ORDER BY CASE WHEN "Sku" = 'AMY007' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY007',
            "Name" = 'AM 5069',
            "Category" = 'GẠCH 80 MEN MÁT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY007', 'AM 5069', 'GẠCH 80 MEN MÁT', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM 3451'))
       OR "Sku" = 'AMY008'
    ORDER BY CASE WHEN "Sku" = 'AMY008' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY008',
            "Name" = 'AM 3451',
            "Category" = '40*80-MÁT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY008', 'AM 3451', '40*80-MÁT', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM 3061'))
       OR "Sku" = 'AMY009'
    ORDER BY CASE WHEN "Sku" = 'AMY009' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY009',
            "Name" = 'AM 3061',
            "Category" = '40*80-MÁT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY009', 'AM 3061', '40*80-MÁT', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;
DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = 'AMY';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('AM 3062'))
       OR "Sku" = 'AMY010'
    ORDER BY CASE WHEN "Sku" = 'AMY010' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = 'AMY010',
            "Name" = 'AM 3062',
            "Category" = '40*80-MÁT',
            "SupplierId" = supp_id,
            "StockWarehouse1" = 0,
            "StockWarehouse2" = 0,
            "TotalStock" = 0,
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            'AMY010', 'AM 3062', '40*80-MÁT', 'Hộp', supp_id,
            0, 0, 0,
            0, 0, 0,
            0, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;

COMMIT;

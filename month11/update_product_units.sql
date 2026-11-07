-- update_product_units.sql
-- Tự động sinh bởi month11/import-product-units.js vào lúc 2026-11-07T07:05:30.971Z
-- Nguồn quy đổi: TK_T10.2026.xlsx
-- Nghiệp vụ:
--   1. Xoá toàn bộ đơn vị tính cũ (ProductUnits) của sản phẩm khớp để tránh xung đột.
--   2. Thêm lại đơn vị tính mới:
--        + Với "1H = N viên ...": thêm Viên (x1, đơn vị gốc) + Hộp (xN), giữ Uom hiển thị chính = 'Hộp' (bỏ qua m2).
--        + Với đơn vị đơn (Túi, Hòm, Bao...): thêm đơn vị gốc (x1), cập nhật Uom = tên đơn vị.
--   3. Quy đổi tồn kho hiện tại về đơn vị cơ sở nhỏ nhất (Viên) một cách idempotent (an toàn khi chạy lại nhiều lần).

BEGIN;

-- Hàm phụ trợ quy đổi số lượng sang đơn vị gốc nhỏ nhất (làm tròn số nguyên Viên cho các số lẻ thập phân từ Hộp như 426.33 * 6 = 2558)
CREATE OR REPLACE FUNCTION pg_temp.scale_base_qty(val numeric, factor numeric)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    raw_val numeric;
    nearest_int numeric;
BEGIN
    IF factor IS NULL OR factor = 1 OR val = 0 THEN
        RETURN val;
    END IF;
    raw_val := val * factor;
    nearest_int := ROUND(raw_val, 0);
    IF ABS(raw_val - nearest_int) <= 0.11 THEN
        RETURN nearest_int;
    END IF;
    RETURN ROUND(raw_val, 3);
END;
$$;

-- Hàm cập nhật đơn vị tính cho từng sản phẩm đã tồn tại trong bảng Products
CREATE OR REPLACE FUNCTION pg_temp.apply_product_unit_spec(
    p_supplier_code text,
    p_sku text,
    p_name text,
    p_primary_uom text,
    p_base_uom text,
    p_conversion_rate numeric
) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
    v_supp_id int;
    v_prod_id int;
    v_old_primary_rate numeric;
    v_old_primary_retail numeric := 0;
    v_old_primary_wholesale numeric := 0;
    v_old_primary_barcode text := NULL;
    v_old_base_barcode text := NULL;
    v_max_old_rate numeric;
    v_scale_factor numeric := 1;
    v_wh1 numeric;
    v_wh2 numeric;
    v_wh3 numeric;
BEGIN
    SELECT s."Id" INTO v_supp_id
    FROM "Suppliers" s
    WHERE UPPER(BTRIM(s."Code")) = UPPER(BTRIM(p_supplier_code))
    LIMIT 1;

    -- Chỉ tìm các sản phẩm ĐÃ CÓ trong hệ thống
    SELECT p."Id" INTO v_prod_id
    FROM "Products" p
    WHERE (v_supp_id IS NOT NULL AND p."SupplierId" = v_supp_id AND UPPER(BTRIM(p."Name")) = UPPER(BTRIM(p_name)))
       OR (p_sku <> '' AND UPPER(BTRIM(p."Sku")) = UPPER(BTRIM(p_sku)))
    ORDER BY
       CASE WHEN v_supp_id IS NOT NULL AND p."SupplierId" = v_supp_id AND UPPER(BTRIM(p."Name")) = UPPER(BTRIM(p_name)) THEN 0 ELSE 1 END,
       p."Id" ASC
    LIMIT 1;

    IF v_prod_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Đọc thông tin đơn vị cũ trước khi xoá để bảo toàn giá/barcode (nếu có) và tính hệ số quy đổi tồn kho idempotent
    SELECT u."ConversionRate", u."RetailPrice", u."WholesalePrice", u."Barcode"
      INTO v_old_primary_rate, v_old_primary_retail, v_old_primary_wholesale, v_old_primary_barcode
    FROM "ProductUnits" u
    WHERE u."ProductId" = v_prod_id
      AND UPPER(BTRIM(u."UnitName")) = UPPER(BTRIM(p_primary_uom))
    LIMIT 1;

    SELECT u."Barcode"
      INTO v_old_base_barcode
    FROM "ProductUnits" u
    WHERE u."ProductId" = v_prod_id
      AND UPPER(BTRIM(u."UnitName")) = UPPER(BTRIM(p_base_uom))
    LIMIT 1;

    IF p_conversion_rate > 1 AND UPPER(BTRIM(p_base_uom)) <> UPPER(BTRIM(p_primary_uom)) THEN
        IF v_old_primary_rate IS NULL OR v_old_primary_rate <= 0 THEN
            v_old_primary_rate := 1;
        END IF;
        v_scale_factor := p_conversion_rate / v_old_primary_rate;
    ELSE
        SELECT MAX(u."ConversionRate") INTO v_max_old_rate
        FROM "ProductUnits" u
        WHERE u."ProductId" = v_prod_id;

        IF v_max_old_rate IS NOT NULL AND v_max_old_rate > 1 THEN
            v_scale_factor := 1.0 / v_max_old_rate;
        ELSE
            v_scale_factor := 1;
        END IF;
    END IF;

    -- Cập nhật tồn kho cơ sở & giá gốc trên bảng Products nếu hệ số cơ sở thay đổi
    IF ABS(v_scale_factor - 1) > 0.000001 THEN
        SELECT
            pg_temp.scale_base_qty(p."StockWarehouse1", v_scale_factor),
            pg_temp.scale_base_qty(p."StockWarehouse2", v_scale_factor),
            pg_temp.scale_base_qty(p."StockWarehouse3", v_scale_factor)
        INTO v_wh1, v_wh2, v_wh3
        FROM "Products" p
        WHERE p."Id" = v_prod_id;

        -- Nếu sản phẩm đã có giá lẻ / giá sỉ trên Products nhưng chưa lưu riêng trên đơn vị lớn thì giữ lại trên đơn vị lớn
        IF COALESCE(v_old_primary_retail, 0) = 0 THEN
            SELECT ROUND(p."RetailPrice" * COALESCE(v_old_primary_rate, 1), 2)
              INTO v_old_primary_retail
            FROM "Products" p WHERE p."Id" = v_prod_id;
        END IF;
        IF COALESCE(v_old_primary_wholesale, 0) = 0 THEN
            SELECT ROUND(p."WholesalePrice" * COALESCE(v_old_primary_rate, 1), 2)
              INTO v_old_primary_wholesale
            FROM "Products" p WHERE p."Id" = v_prod_id;
        END IF;

        UPDATE "Products"
        SET "StockWarehouse1" = v_wh1,
            "StockWarehouse2" = v_wh2,
            "StockWarehouse3" = v_wh3,
            "TotalStock"      = v_wh1 + v_wh2 + v_wh3,
            "UnitCost"        = CASE WHEN "UnitCost" <> 0 THEN ROUND("UnitCost" / v_scale_factor, 2) ELSE 0 END,
            "WholesalePrice"  = CASE WHEN "WholesalePrice" <> 0 THEN ROUND("WholesalePrice" / v_scale_factor, 2) ELSE 0 END,
            "RetailPrice"     = CASE WHEN "RetailPrice" <> 0 THEN ROUND("RetailPrice" / v_scale_factor, 2) ELSE 0 END,
            "Uom"             = p_primary_uom,
            "UpdatedAt"       = NOW()
        WHERE "Id" = v_prod_id;

        -- Đồng bộ bản ghi tồn kho đầu kỳ trong StockHistories để sổ kho khớp 100%
        UPDATE "StockHistories"
        SET "BeforeWarehouseStock" = pg_temp.scale_base_qty("BeforeWarehouseStock", v_scale_factor),
            "Delta"                = pg_temp.scale_base_qty("Delta", v_scale_factor),
            "AfterWarehouseStock"  = pg_temp.scale_base_qty("AfterWarehouseStock", v_scale_factor),
            "BeforeTotalStock"     = pg_temp.scale_base_qty("BeforeTotalStock", v_scale_factor),
            "AfterTotalStock"      = pg_temp.scale_base_qty("AfterTotalStock", v_scale_factor)
        WHERE "ProductId" = v_prod_id
          AND "SourceType" = 'init';
    ELSE
        UPDATE "Products"
        SET "Uom" = p_primary_uom,
            "UpdatedAt" = NOW()
        WHERE "Id" = v_prod_id;
    END IF;

    -- XOÁ ĐƠN VỊ CŨ TRƯỚC KHI THÊM LẠI ĐỂ TRÁNH XUNG ĐỘT
    DELETE FROM "ProductUnits" WHERE "ProductId" = v_prod_id;

    -- THÊM LẠI ĐƠN VỊ MỚI
    IF p_conversion_rate > 1 AND UPPER(BTRIM(p_base_uom)) <> UPPER(BTRIM(p_primary_uom)) THEN
        -- 1. Đơn vị nhỏ nhất (VD: Viên - ConversionRate = 1, IsBaseUnit = true)
        INSERT INTO "ProductUnits" (
            "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
            "Barcode", "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
        ) VALUES (
            v_prod_id, p_base_uom, 1, true,
            v_old_base_barcode, 0, 0, true, NOW()
        );

        -- 2. Đơn vị quy đổi lớn (VD: Hộp = N Viên - ConversionRate = N, IsBaseUnit = false)
        INSERT INTO "ProductUnits" (
            "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
            "Barcode", "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
        ) VALUES (
            v_prod_id, p_primary_uom, p_conversion_rate, false,
            v_old_primary_barcode, COALESCE(v_old_primary_retail, 0), COALESCE(v_old_primary_wholesale, 0), true, NOW()
        );
    ELSE
        -- Đơn vị đơn lẻ (VD: Túi, Hòm, Bao, Thùng, Can, Chai, Viên...)
        INSERT INTO "ProductUnits" (
            "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
            "Barcode", "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
        ) VALUES (
            v_prod_id, p_primary_uom, 1, true,
            COALESCE(v_old_primary_barcode, v_old_base_barcode),
            COALESCE(v_old_primary_retail, 0), COALESCE(v_old_primary_wholesale, 0), true, NOW()
        );
    END IF;

    RETURN TRUE;
END;
$$;

DO $$
BEGIN
    -- >>> Nhà cung cấp [HH] - 216 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH001', 'LP10,104', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH002', 'LP10,112', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH003', 'LP10,113', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH004', 'LP10,114', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH005', 'LP18,112 -A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH006', 'LP18,113 - A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH007', 'LP18,114 -A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH008', 'LP18,112 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH009', 'LP18,113 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH010', 'LP18,114 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH011', 'LX8001', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH012', 'LX8002', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH013', 'LX8002 a2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH014', 'LX8003', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH015', 'LX8004', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH016', 'LX8005', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH017', 'LX8005- A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH018', 'LX8009', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH019', 'LX8009 - A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH020', 'LX8010', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH021', 'LX8012', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH022', 'LX8014', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH023', 'LX8014 -A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH024', 'LX8016', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH025', 'LX8016 - A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH026', 'LX8017', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH027', 'LX8017 a2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH028', 'LP18101', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH029', 'LP18101 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH030', 'LP18102', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH031', 'LP18102 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH032', 'LP18103', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH033', 'LP18103 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH034', 'LP18104', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH035', 'LP18104 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH036', 'LP18.8018 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH037', 'LP18.8016 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH038', 'LP18.8003 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH039', 'LP18.8003 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH040', 'LP18.8021 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH041', 'LX6001', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH042', 'LX6007', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH043', 'LX6602', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH044', 'LX6609', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH045', 'LX6610', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH046', 'LX6614', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH047', 'LX6614 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH048', 'LX6616', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH049', 'LX6617', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH050', 'LX6618', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH051', 'LX6621', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH052', 'LP96101', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH053', 'LP96102', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH054', 'LP96102 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH055', 'LP96103', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH056', 'LP96103 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH057', 'LP96104', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH058', 'LP96-6603', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH059', 'LP96-6603 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH060', 'LXC6105', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH061', 'LXC6110 H4', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH062', 'LXC6112-h11', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH063', 'LXC6114', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH064', 'LXC6115', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH065', 'LXC6116', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH066', 'LXC6117', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH067', 'LXC6118', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH068', 'LXC6119', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH069', 'LV4850', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH070', 'LV4850 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH071', 'LV48000 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH072', 'LV4851', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH073', 'LX4861', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH074', 'LX4862', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH075', 'LX4863', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH076', 'LX4865', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH077', 'LX4864- ĐIỂM', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH078', 'LX4867', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH079', 'LP948.150', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH080', 'LP948.150- ĐIỂM', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH081', 'LP948.154', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH082', 'LP948.155', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH083', 'LP948.154- ĐIỂM', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH084', 'LP948.156', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH085', 'LP948.157', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH086', 'LP948.156-ĐIỂM', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH087', 'LXP3601', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH088', 'LXP3601-ĐIỂM a2', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH089', 'LXP3602', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH090', 'LXP3603', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH091', 'LXP3602-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH092', 'LXP3606', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH093', 'LXP3607', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH094', 'LXP3606-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH095', 'LP936.131-KHÓI TRẮNG', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH096', 'LP936.132', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH097', 'LP936.133', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH098', 'LP936.132-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH099', 'LP936.134', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH100', 'LP936.135', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH101', 'LP936.134-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH102', 'LV3600', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH103', 'LX36000', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH104', 'LX36601', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH105', 'LV3652--h13', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH106', 'LV3658', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH107', 'LV3650', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH108', 'LX3601-T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH109', 'LX3602-T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH110', 'LX3603-T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH111', 'LX3604-T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH112', 'LXK3605T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH113', 'LXK3606T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH114', 'LXK3607T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH115', 'LXK3608T', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH116', 'LX3634', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH117', 'LX3635', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH118', 'LX3634-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH119', 'LX3636', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH120', 'LX3637', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH121', 'LX3636-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH122', 'LX3638', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH123', 'LX3639', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH124', 'LX3638-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH125', 'LX3658', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH126', 'LX3659', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH127', 'LX3658 -ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH128', 'LX3662', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH129', 'LX3663', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH130', 'LX3662-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH131', 'LX3664', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH132', 'LX3665', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH133', 'LX3664-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH134', 'LX3666', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH135', 'LX3667', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH136', 'LX3666-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH137', 'LX3668', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH138', 'LX3669', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH139', 'LX3668-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH140', 'LXM3670', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH141', 'LXM3671', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH142', 'LXM3670-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH143', 'LXM3672', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH144', 'LXM3673', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH145', 'LXM3672-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH146', 'LX3686', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH147', 'LX3687', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH148', 'LX3686 ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH149', 'LX3688', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH150', 'LX3689', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH151', 'LX3688 ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH152', 'LX3690', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH153', 'LX3691', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH154', 'LX3690 ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH155', 'LX3617', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH156', 'LX3629', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH157', 'LX3622', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH158', 'LX335', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH159', 'LK303', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH160', 'LX3802', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH161', 'LXP303', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH162', 'LX337', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH163', 'LX367', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH164', 'LX369', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH165', 'LX3133', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH166', 'LK305-h1', 'Hộp', 'Viên', 16);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH167', 'LX5516', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH168', 'LX5516 A2', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH169', 'LX5521', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH170', 'LX5524', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH171', 'LX5524 A2', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH172', 'LX5525', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH173', 'LX5525 A2', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH174', 'LX5527', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH175', 'NH5601', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH176', 'NH5602', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH177', 'NH5603', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH178', 'NH5604', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH179', 'NH5604 A2', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH180', 'NH5605', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH181', 'HXK-503 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH182', 'HXK-503 B', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH183', 'HM5028-MÁT', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH184', 'HM5028- MÁT B', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH185', 'HUS 5018-SUGAR', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH186', 'HG5407 A2', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH187', 'HS514 A1', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH188', 'LX6905', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH189', 'LXV6801', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH190', 'LXV6802', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH191', 'LXV6806', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH192', 'LX6903', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH193', 'LX46001', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH194', 'LX46002', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH195', 'LXK46050', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH196', 'LXK46051', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH197', 'LXK46052', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH198', 'LXK46054', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH199', 'LH46004', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH200', 'LH46005', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH201', 'LH46006', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH202', 'LHK46055', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH203', 'LHK46056', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH204', 'LP 46-120', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH205', 'LP 46-121', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH206', 'LP 46-122', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH207', 'LP 46-123', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH208', 'PLX412', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH209', 'PLX413', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH210', 'PLX415', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH211', 'PLX5011', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH212', 'PLX5012', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH213', 'PLX5013', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH214', 'PLX5014', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH215', 'PLX5015', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('HH', 'HH216', 'PLX5015 A2', 'Hộp', 'Viên', 6);

    -- >>> Nhà cung cấp [NICE] - 108 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE001', '036-6002 Nhạt', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE002', '036-6003 nhạt', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE003', '036-601-kem vàng', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE004', '48-6000- Trắng tinh-53(30.12.23)', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE005', '48-6001-Nhạt', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE006', '48-6001-Đậm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE007', '48-6001-Điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE008', '48-6002-Khói', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE009', '48-6002-Điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE010', '48-6003-Vân', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE011', '48-6003-Điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE012', '48-6007-Nhạt', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE013', '48-6007-Đậm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE014', '48-6007-Điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE015', '48-5004-Nhạt', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE016', '48-5004-Đậm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE017', '48-5004-Điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE018', '48-01 GO', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE019', '48-02 GO', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE020', '5-1001', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE021', '5-1002', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE022', '5-1004', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE023', '5-1012', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE024', '5-1501', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE025', '5-1013', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE026', '5-1601', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE027', '5-1602', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE028', '5-1603', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE029', '5-1323', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE030', '5-1311', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE031', '5-1312', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE032', '6-1001', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE033', '6-1012', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE034', '6-1016', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE035', '6-1019', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE036', '6-1020', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE037', '6-1021', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE038', '6-1022', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE039', '6-1501- Gỗ mát', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE040', '6-1502- Gỗ mát', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE041', '6-1304-men đường', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE042', '6-1013-đen vân', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE043', '6-6001', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE044', '6-6007', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE045', '6-6022', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE046', '6-6030', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE047', '6-6030 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE048', '6-6031', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE049', '6-6031 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE050', '6-6036', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE051', '6-6037', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE052', '6-6038', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE053', '6-6040', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE054', '6-6040 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE055', '6-6041', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE056', '6-6042', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE057', '6-6042- A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE058', '6-6043', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE059', '6-6043- A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE060', '6-6045', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE061', '6-6100', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE062', '6-6200', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE063', '6-6400', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE064', '6-6400 A2', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE065', '6-6400 A3', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE066', '8-6003 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE067', '8-6004', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE068', '8-6010', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE069', '8-6017', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE070', '8-6019', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE071', '8-6019 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE072', '8-6021', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE073', '8-6029', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE074', '8-6031', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE075', '8-6032 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE076', '8-6035', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE077', '8-6036', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE078', '8-6037', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE079', '8-6038', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE080', '8-6039', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE081', '8-6039 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE082', '8-6040', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE083', '8-6041', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE084', '8-6042', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE085', '8-6043', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE086', '8-6045', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE087', '8-6045 a2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE088', '8-6046 a2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE089', '8-6047 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE090', '8-601-vt', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE091', '8-602', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE092', '8-6200', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE093', '8-6200 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE094', 'MN612.510 A1-mát-57(3.1.26)', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE095', 'MN612.616 A1-bóng-55(24.11.24)', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE096', 'MN612.618 A1-bóng-Đ58(3.3.26)', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE097', 'MN612.614-KHÓI', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE098', '11-645', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE099', '11-645 A2-40H/K', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE100', '11-602', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE101', '11-602-D53(28.3.26) A2-43H/K', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE102', '11-646-VT-(đ53:16.3.26)', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE103', '11-646-VT-(đ55:16.3.26) A2(40h/k)', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE104', '11-601-đ52(43h/k)-7.4.26', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE105', '11-601-đ55(40h/k)-12.3.26 A2-40H/K', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE106', '46512-01-DẦY 12mm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE107', '46512-02DẦY 12mm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', 'NICE108', '46512-03DẦY 12mm', 'Hộp', 'Viên', 6);

    -- >>> Nhà cung cấp [TAKAO] - 92 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO001', '97-665', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO002', '97-601', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO003', '97-604', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO004', '97-606', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO005', '97-653', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO006', '97-654', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO007', '97-854', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO008', '97-855', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO009', '97-101', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO010', '97-104', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO011', '97-105', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO012', '97-106', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO013', '13102', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO014', '13103', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO015', '13202-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO016', '13106', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO017', '13206 ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO018', '43500-Trắng tinh bs', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO019', '43600-điểm', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO020', '73501-khói', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO021', '73601-điểm', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO022', '73506-nhạt', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO023', '73507-đậm', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO024', '73606-điểm', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO025', '73502-nhạt', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO026', '73503-đậm', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO027', '73602-điểm', 'Hộp', 'Viên', 10);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO028', '14101(1H=1.28)', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO029', '14113-khói', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO030', '14213-điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO031', '74102', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO032', '74103', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO033', '74202-điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO034', '14109', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO035', '14110', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO036', '14209-điểm', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO037', '16901', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO038', '16902', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO039', '16906', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO040', '16106 -K1', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO041', '16911', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO042', '16912', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO043', '16913', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO044', '16916', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO045', '16917', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO046', '16.126', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO047', '14602', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO048', '14603(1.44M2)', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO049', '17001', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO050', '17006', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO051', '17151', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO052', '17152', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO053', '17153', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO054', '17154', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO055', '17155', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO056', '17156', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO057', '76102', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO058', '76103', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO059', '76105', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO060', '18901', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO061', '18902', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO062', '18906', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO063', '18911', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO064', '18912', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO065', '18913', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO066', '18916', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO067', '18917', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO068', '18126', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO069', '48302', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO070', '48304', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO071', '18402', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO072', '78001', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO073', '78002', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO074', '78003', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO075', '78008', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO076', '18701', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO077', '18704', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO078', '18706', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO079', '18707', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO080', '78702', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO081', '78703', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO082', '78705', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO083', '11101', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO084', '11102', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO085', '11103', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO086', '11104', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO087', '11106', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO088', '71.101', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO089', '71102', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO090', '71103', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO091', '71105', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', 'TAKAO092', '71108', 'Hộp', 'Viên', 2);

    -- >>> Nhà cung cấp [VT] - 39 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT001', 'FR5001', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT002', 'FR5002', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT003', 'FR5004', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT004', 'FR5005', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT005', 'FR5007', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT006', 'FR5008', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT007', 'FR5509', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT008', 'FB3601-KHÓI', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT009', 'FB3603-NHẠT', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT010', 'FB3603-ĐẬM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT011', 'FB3603-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT012', 'FB3604-NHẠT', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT013', 'FB3604-ĐẬM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT014', 'FB3604-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT015', 'FB3605-NHẠT', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT016', 'FB3605-ĐẬM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT017', 'FB3605-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT018', 'FB3607-NHẠT', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT019', 'FB3607-ĐẬM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT020', 'FB3607-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT021', 'FB3610-NHẠT', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT022', 'FB3610-ĐẬM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT023', 'FB3610-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT024', 'FM5801', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT025', 'FM5802', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT026', 'FM5803', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT027', 'FM4601', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT028', 'FM4603', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT029', 'FM4604', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT030', 'FM4605', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT031', 'FP46061', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT032', 'FP46062', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT033', 'FP46065', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT034', 'F3305', 'Hộp', 'Viên', 11);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT035', 'FM3308', 'Hộp', 'Viên', 11);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT036', 'FM3310', 'Hộp', 'Viên', 11);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT037', 'F6602', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT038', 'F6616', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('VT', 'VT039', 'F6604', 'Hộp', 'Viên', 4);

    -- >>> Nhà cung cấp [DMAX] - 18 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX001', 'DA6601', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX002', 'DA6602', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX003', 'DA6603', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX004', 'DA6604', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX005', 'DA6606', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX006', 'DA8801', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX007', 'DA8802', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX008', 'DA8803', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX009', 'DA8804', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX010', 'DA8806', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX011', 'DA61205', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX012', 'DA1001', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX013', 'DA1002', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX014', 'DA1004', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX015', 'MR12902', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX016', 'MR11034', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX017', 'MR11037', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('DMAX', 'DMAX018', 'MR11039', 'Hộp', 'Viên', 2);

    -- >>> Nhà cung cấp [RA] - 19 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA001', 'DP514', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA002', 'DP515', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA003', 'DP518', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA004', 'BS3601-P', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA005', 'BS3605-DH', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA006', 'TP602', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA007', 'LIMBER', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA008', 'CAFÉ', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA009', 'APRICOT', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA010', 'LIFE', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA011', '1683', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA012', '1543', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA013', '1072', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA014', '1347', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA015', 'Keo CK vỏ cam(bao 25kg)', 'Bao', 'Bao', 1);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA016', 'KE 1MM', 'Túi', 'Túi', 1);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA017', 'KE 1,5 MM', 'Túi', 'Túi', 1);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA018', 'NÊM ĐỎ', 'Túi', 'Túi', 1);
    PERFORM pg_temp.apply_product_unit_spec('RA', 'RA019', 'keo 20 kg', 'Bao', 'Bao', 1);

    -- >>> Nhà cung cấp [TOKO] - 45 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO001', '3002', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO002', '3003', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO003', '3004', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO004', '3005', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO005', '5301', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO006', '5302', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO007', '5305', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO008', '5306', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO009', '46301-(8v/h)', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO010', '46302-(8v/h)', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO011', '46304-(6v/h)', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO012', '46304- (8v/h)', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO013', '632.005', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO014', '632.009', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO015', '632.602', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO016', '632.603', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO017', '632.604', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO018', '632.605', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO019', '632.608', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO020', '4832001', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO021', '4832002 Đ', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO022', '4832003', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO023', '4832004 Đ', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO024', '4832005', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO025', '4832005-A2', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO026', '4832006', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO027', '4832007 Đ', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO028', '4832009', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO029', '4832010 Đ', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO030', '4832011', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO031', '832.001', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO032', '832.002', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO033', '832.003', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO034', '832.004', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO035', '832.005', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO036', '832.008', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO037', '832.014', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO038', '336001', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO039', '336002-Đ', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO040', '336003', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO041', '336004-Đ', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO042', '336006', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO043', '336007-Đ', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO044', '336008', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('TOKO', 'TOKO045', '336011- A2', 'Hộp', 'Viên', 8);

    -- >>> Nhà cung cấp [AMY] - 10 sản phẩm
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY001', 'AM 5039', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY002', 'AM 6824', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY003', 'AM 6825', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY004', 'AM8049', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY005', 'AM5072', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY006', 'AM5060', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY007', 'AM 5069', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY008', 'AM 3451', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY009', 'AM 3061', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('AMY', 'AMY010', 'AM 3062', 'Hộp', 'Viên', 4);

    -- >>> Các tên mã quy cách dự phòng trong bảng quy đổi (chỉ cập nhật nếu tồn tại tên tương ứng trong DB)
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP10,104 A1', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP10,112 A1', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP10,113 A1', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP10,114 A1', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP18,113 -A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8001 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8002 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8003 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8004 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8005 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8009 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8010 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8012 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8014 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8016 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX8017 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP18101 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP18102 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP18103 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP18104 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP18,8003 A1', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6001 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6007 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6602 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6609 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6610 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6614 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6616 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6617 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6618 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX6621 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP96101 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP96102 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP96103 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP96104 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP96-6603 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6105 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6110 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6112 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6114 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6115 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6116 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6117 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6118 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXC6119 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LV4850 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LV4851 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX4861 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX4862 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX4863 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX4865 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX4867 A1', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP948.150 A1', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP948.154 A1', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP948.155 A1', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP948.156 A1', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP948.157 A1', 'Hộp', 'Viên', 5);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXP3601 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXP3601-ĐIỂM', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXP3602 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXP3603 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXP3606 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LXP3607 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP936.132 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP936.133 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP936.134 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LP936.135 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LV3600 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX36000 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LX36601 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LV3652 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LV3658 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('HH', '', 'LV3650 A1', 'Hộp', 'Viên', 8);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '48-6000- Trắng tinh', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '5-1007', 'Hộp', 'Viên', 6);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '6-1501', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '6-1502', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '6-1304', 'Hộp', 'Viên', 4);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6004 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6021 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6037 VT', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6040 VT', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6040 VT A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6041 VT', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6041 VT A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6042 VT', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6042 A2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6043 VT', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6046 VT a2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6047 VT a2', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '8-6200 đen vân', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', 'MN612.510 A1-mát', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', 'MN612.616 A1-bóng', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', 'MN612.618 A1-bóng', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', 'MN612,614-khói', 'Hộp', 'Viên', 3);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '11-645 A2', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '11-60 A2', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '11-646-VT', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '11-646-VT A2', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '11-601-VT', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('NICE', '', '11-601-VT A2', 'Hộp', 'Viên', 2);
    PERFORM pg_temp.apply_product_unit_spec('TAKAO', '', '14603', 'Hộp', 'Viên', 6);

    -- Đồng bộ lại sequence cho bảng ProductUnits
    PERFORM setval(pg_get_serial_sequence('"ProductUnits"', 'Id'), COALESCE((SELECT MAX("Id") FROM "ProductUnits"), 1), true);
END $$;

COMMIT;

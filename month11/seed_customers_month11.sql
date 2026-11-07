--
-- SEED DỮ LIỆU KHÁCH HÀNG & CÔNG NỢ THÁNG 11 (SHEET BÁO CÁO)
-- Thời gian tạo: 2026-11-07T05:26:37.484Z
-- Tổng số khách hàng: 220
--
BEGIN;

-- Khách hàng: [KH.140722991] ch dương định - 549 Đặng Xuân Bảng - ĐT: 0824358882
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722991', 'ch dương định - 549 Đặng Xuân Bảng - ĐT: 0824358882', 'THÀNH PHỐ - HÀ NAM', '["0824358882"]', 71223000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 71223000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722991'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=71223000, Có ĐK=0)', 0, 71223000, 71223000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140722991'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3376111] CH Hùng Yến - 162 Trường Chinh - ĐT: 0915606525 - 0834926868
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3376111', 'CH Hùng Yến - 162 Trường Chinh - ĐT: 0915606525 - 0834926868', 'THÀNH PHỐ - HÀ NAM', '["0915606525","0834926868"]', 60250230, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 60250230, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3376111'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=60250230, Có ĐK=0)', 0, 60250230, 60250230, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3376111'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.41438931] CH Hoài tuyến - TP-  ĐT: 0919744131
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.41438931', 'CH Hoài tuyến - TP-  ĐT: 0919744131', 'THÀNH PHỐ - HÀ NAM', '["0919744131"]', 42413880, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 42413880, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.41438931'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=42413880, Có ĐK=0)', 0, 42413880, 42413880, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.41438931'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.42866499] CH Mai Dịu ( mới) - 563 Trường chinh  ĐT: 0943673739
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.42866499', 'CH Mai Dịu ( mới) - 563 Trường chinh  ĐT: 0943673739', 'THÀNH PHỐ - HÀ NAM', '["0943673739"]', 38539820, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 38539820, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.42866499'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=38539820, Có ĐK=0)', 0, 38539820, 38539820, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.42866499'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.137907868] CH Gia Khang - 279 Đặng Xuân Bảng
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137907868', 'CH Gia Khang - 279 Đặng Xuân Bảng', 'THÀNH PHỐ - HÀ NAM', NULL, 33011600, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 33011600, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137907868'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=33011600, Có ĐK=0)', 0, 33011600, 33011600, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.137907868'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723006] CH Phương Huê-0942637406-248 điện biên
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723006', 'CH Phương Huê-0942637406-248 điện biên', 'THÀNH PHỐ - HÀ NAM', '["0942637406"]', 31193760, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 31193760, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723006'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=31193760, Có ĐK=0)', 0, 31193760, 31193760, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723006'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.23863608] CH Tuấn Thoa - 32 Trần Đăng Ninh - ĐT:039 9191 519  - 0855933170 (vợ)-  0988500259
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.23863608', 'CH Tuấn Thoa - 32 Trần Đăng Ninh - ĐT:039 9191 519  - 0855933170 (vợ)-  0988500259', 'THÀNH PHỐ - HÀ NAM', '["0855933170","0988500259"]', 30880300, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 30880300, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.23863608'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=30880300, Có ĐK=0)', 0, 30880300, 30880300, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.23863608'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.9784236] CH Anh Dũng ( Đông A - mới) - 524 Đường Điện Biên 0912151839
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.9784236', 'CH Anh Dũng ( Đông A - mới) - 524 Đường Điện Biên 0912151839', 'THÀNH PHỐ - HÀ NAM', '["0912151839"]', 29924700, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 29924700, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.9784236'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=29924700, Có ĐK=0)', 0, 29924700, 29924700, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.9784236'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.90559075] CH Văn Thưởng - Trường Chinh -  ( mới)TP Nam Định ĐT: 0845154498
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.90559075', 'CH Văn Thưởng - Trường Chinh -  ( mới)TP Nam Định ĐT: 0845154498', 'THÀNH PHỐ - HÀ NAM', '["0845154498"]', 15769100, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 15769100, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.90559075'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=15769100, Có ĐK=0)', 0, 15769100, 15769100, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.90559075'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.5887766] CH Thắm Hoan - 164 Trường Chinh  - TP  ĐT: 03503 838 492
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.5887766', 'CH Thắm Hoan - 164 Trường Chinh  - TP  ĐT: 03503 838 492', 'THÀNH PHỐ - HÀ NAM', NULL, 15323800, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 15323800, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.5887766'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=15323800, Có ĐK=0)', 0, 15323800, 15323800, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.5887766'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.5328359] CH Tuấn Sinh - 679 Đường Trường Chinh - ĐT: 03503 641 345
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.5328359', 'CH Tuấn Sinh - 679 Đường Trường Chinh - ĐT: 03503 641 345', 'THÀNH PHỐ - HÀ NAM', NULL, 15317400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 15317400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.5328359'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=15317400, Có ĐK=0)', 0, 15317400, 15317400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.5328359'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.34886727] CH Quang An - Thôn lý nội - Xã Phú Phúc - HN - ĐT: 0972770591
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.34886727', 'CH Quang An - Thôn lý nội - Xã Phú Phúc - HN - ĐT: 0972770591', 'THÀNH PHỐ - HÀ NAM', '["0972770591"]', 15002200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 15002200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.34886727'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=15002200, Có ĐK=0)', 0, 15002200, 15002200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.34886727'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3364485] CH Thanh Điện - Đường Vũ Hữu Lợi - TP NĐ - ĐT: 0813882942
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3364485', 'CH Thanh Điện - Đường Vũ Hữu Lợi - TP NĐ - ĐT: 0813882942', 'THÀNH PHỐ - HÀ NAM', '["0813882942"]', 12811600, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 12811600, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3364485'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=12811600, Có ĐK=0)', 0, 12811600, 12811600, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3364485'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.7883862] CH huy dũng (đường hưng yên) - TP
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.7883862', 'CH huy dũng (đường hưng yên) - TP', 'THÀNH PHỐ - HÀ NAM', NULL, 12672560, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 12672560, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.7883862'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=12672560, Có ĐK=0)', 0, 12672560, 12672560, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.7883862'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.117607333] CH Phương Liên - Đường 52-  TP - ĐT: 0915606333
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.117607333', 'CH Phương Liên - Đường 52-  TP - ĐT: 0915606333', 'THÀNH PHỐ - HÀ NAM', '["0915606333"]', 11174000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 11174000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.117607333'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=11174000, Có ĐK=0)', 0, 11174000, 11174000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.117607333'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.72975864] CH Nam Huyền - Chợ Quắn - 0392388757
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.72975864', 'CH Nam Huyền - Chợ Quắn - 0392388757', 'THÀNH PHỐ - HÀ NAM', '["0392388757"]', 6337790, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 6337790, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.72975864'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=6337790, Có ĐK=0)', 0, 6337790, 6337790, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.72975864'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.69764735] CH Đức Linh - 259 Trường Chinh - ĐT: 0888 769 786
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.69764735', 'CH Đức Linh - 259 Trường Chinh - ĐT: 0888 769 786', 'THÀNH PHỐ - HÀ NAM', NULL, 5220900, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 5220900, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.69764735'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=5220900, Có ĐK=0)', 0, 5220900, 5220900, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.69764735'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723075] CH Thắng Hằng - Giải Phóng - TP Nam Định
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723075', 'CH Thắng Hằng - Giải Phóng - TP Nam Định', 'THÀNH PHỐ - HÀ NAM', NULL, 2656000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 2656000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723075'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=2656000, Có ĐK=0)', 0, 2656000, 2656000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723075'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3452748] CH Hòa an - 474 Trường Chinh -  TP Nam Định ĐT: 0912 715 919 - 3 600 565
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3452748', 'CH Hòa an - 474 Trường Chinh -  TP Nam Định ĐT: 0912 715 919 - 3 600 565', 'THÀNH PHỐ - HÀ NAM', NULL, 543000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 543000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3452748'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=543000, Có ĐK=0)', 0, 543000, 543000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3452748'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3519323] CH Quân Mùi - Quân Khu 3 - (TP) ĐT: 0836530350
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3519323', 'CH Quân Mùi - Quân Khu 3 - (TP) ĐT: 0836530350', 'THÀNH PHỐ - HÀ NAM', '["0836530350"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3519323'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723283] CH Toan Anh:633 Trần Huy Liệu-TP NĐ:0859420388
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723283', 'CH Toan Anh:633 Trần Huy Liệu-TP NĐ:0859420388', 'THÀNH PHỐ - HÀ NAM', '["0859420388"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723283'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3403619] CH Thắng Hoà - 60 Trường Chinh - TP Nam Định  ĐT: 03503 840 504
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3403619', 'CH Thắng Hoà - 60 Trường Chinh - TP Nam Định  ĐT: 03503 840 504', 'THÀNH PHỐ - HÀ NAM', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3403619'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.181] CH Niêm Chiến - Thôn 5 - Nam Lý
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.181', 'CH Niêm Chiến - Thôn 5 - Nam Lý', 'THÀNH PHỐ - HÀ NAM', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.181'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140260023] CH Hùng Phát-0941356333-chợ hoa mỹ tân,nam định
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140260023', 'CH Hùng Phát-0941356333-chợ hoa mỹ tân,nam định', 'THÀNH PHỐ - HÀ NAM', '["0941356333"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140260023'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140722973] CH TUẤN HOÀI-0949372910-đường 52m -Tp NĐ
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722973', 'CH TUẤN HOÀI-0949372910-đường 52m -Tp NĐ', 'THÀNH PHỐ - HÀ NAM', '["0949372910"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722973'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723139] CH Chiến Tuyết-0943232293-265 đặng xuân bảng
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723139', 'CH Chiến Tuyết-0943232293-265 đặng xuân bảng', 'THÀNH PHỐ - HÀ NAM', '["0943232293"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723139'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723161] CH Bích Hường
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723161', 'CH Bích Hường', 'THÀNH PHỐ - HÀ NAM', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723161'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3448342] CH Dũng Roma - Đô thị Hòa Vượng -TP Nam Định ĐT: 03503 500 670
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3448342', 'CH Dũng Roma - Đô thị Hòa Vượng -TP Nam Định ĐT: 03503 500 670', 'THÀNH PHỐ - HÀ NAM', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3448342'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3368596] CH Hoài Trang - Đường Giải Phóng - TP Nam Định ĐT: 03502241368 - - chị trang 0917761410
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3368596', 'CH Hoài Trang - Đường Giải Phóng - TP Nam Định ĐT: 03502241368 - - chị trang 0917761410', 'THÀNH PHỐ - HÀ NAM', '["0350224136","0917761410"]', -2345560, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -2345560, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3368596'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=2345560)', 0, -2345560, -2345560, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3368596'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.6253696] showroom Tân Phong - ĐT: 0943531966
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.6253696', 'showroom Tân Phong - ĐT: 0943531966', 'THÀNH PHỐ - HÀ NAM', '["0943531966"]', -21569520, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -21569520, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.6253696'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=21569520)', 0, -21569520, -21569520, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.6253696'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3376559] CH Thuỷ Vượng - 458 đường Vũ Hữu Lợi - Phường Cửa Nam - TP Nam Định ĐT: 3 859 671 - 0948 598 993
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3376559', 'CH Thuỷ Vượng - 458 đường Vũ Hữu Lợi - Phường Cửa Nam - TP Nam Định ĐT: 3 859 671 - 0948 598 993', 'THÀNH PHỐ - HÀ NAM', NULL, -14130040, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -14130040, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3376559'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=14130040)', 0, -14130040, -14130040, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3376559'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.999VHL] CH Gia Huy - 999 Vũ Hữu Lợi - ĐT: 0912659239
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.999VHL', 'CH Gia Huy - 999 Vũ Hữu Lợi - ĐT: 0912659239', 'THÀNH PHỐ - HÀ NAM', '["0912659239"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.999VHL'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.67284075] CH Phương Thay - Xuân Trường - ĐT: 0839940057 - 0984656830
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.67284075', 'CH Phương Thay - Xuân Trường - ĐT: 0839940057 - 0984656830', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0839940057","0984656830"]', 67464600, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 67464600, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.67284075'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=67464600, Có ĐK=0)', 0, 67464600, 67464600, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.67284075'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.23393822] CH Hiếu Loan - Xóm 4 - Xuân Vinh - Xuân trường - ĐT: 0343 554 856 - 0989743001
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.23393822', 'CH Hiếu Loan - Xóm 4 - Xuân Vinh - Xuân trường - ĐT: 0343 554 856 - 0989743001', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0989743001"]', 48066200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 48066200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.23393822'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=48066200, Có ĐK=0)', 0, 48066200, 48066200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.23393822'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3550155] CH Nghi Thoa - Thọ Nghiệp - Xuân Trường - ĐT: 03503 887 050 - 0974 558 327
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3550155', 'CH Nghi Thoa - Thọ Nghiệp - Xuân Trường - ĐT: 03503 887 050 - 0974 558 327', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 38108350, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 38108350, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3550155'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=38108350, Có ĐK=0)', 0, 38108350, 38108350, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3550155'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3690781] CH Lộc Hợi - Xuân Phương - Xuân Trường ĐT: 0917 843 199
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3690781', 'CH Lộc Hợi - Xuân Phương - Xuân Trường ĐT: 0917 843 199', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 34288900, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 34288900, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3690781'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=34288900, Có ĐK=0)', 0, 34288900, 34288900, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3690781'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3465956] CH Ngọc Căn - Nam Dương - Nam Trực ĐT: 0945009507 ( số mới)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3465956', 'CH Ngọc Căn - Nam Dương - Nam Trực ĐT: 0945009507 ( số mới)', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0945009507"]', 32092000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 32092000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3465956'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=32092000, Có ĐK=0)', 0, 32092000, 32092000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3465956'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH001] CH Xuân Đức-Xuân Trường-Xuân Đài
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH001', 'CH Xuân Đức-Xuân Trường-Xuân Đài', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 25345000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 25345000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH001'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=25345000, Có ĐK=0)', 0, 25345000, 25345000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH001'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3331768] CH Xuân Trường - Xã Việt Hùng - Quần Lạc -  Trực Ninh  - ĐT: 0857413669
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3331768', 'CH Xuân Trường - Xã Việt Hùng - Quần Lạc -  Trực Ninh  - ĐT: 0857413669', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0857413669"]', 22995200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 22995200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3331768'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=22995200, Có ĐK=0)', 0, 22995200, 22995200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3331768'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.5865310] CH Cẩn Thoa - Xuân trường
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.5865310', 'CH Cẩn Thoa - Xuân trường', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 22030000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 22030000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.5865310'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=22030000, Có ĐK=0)', 0, 22030000, 22030000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.5865310'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140722993] CH Đôn Loan-0368080222-
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722993', 'CH Đôn Loan-0368080222-', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0368080222"]', 20123600, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 20123600, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722993'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=20123600, Có ĐK=0)', 0, 20123600, 20123600, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140722993'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.137433398] CH Xuân Dương - Chợ giá - Nam TRực - ĐT: 0915411763 ( anh dương) - 02283883652
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137433398', 'CH Xuân Dương - Chợ giá - Nam TRực - ĐT: 0915411763 ( anh dương) - 02283883652', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0915411763","02283883652"]', 17925100, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 17925100, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137433398'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=17925100, Có ĐK=0)', 0, 17925100, 17925100, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.137433398'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3412943] CH Hồng Đệ - Chợ Đường - Liêm Hải Trực Ninh- ĐT: 0914 542 817
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3412943', 'CH Hồng Đệ - Chợ Đường - Liêm Hải Trực Ninh- ĐT: 0914 542 817', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 7120000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 7120000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3412943'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=7120000, Có ĐK=0)', 0, 7120000, 7120000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3412943'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.65576426] CH Đỗ Mười -  Xuân Trường
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.65576426', 'CH Đỗ Mười -  Xuân Trường', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 7003380, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 7003380, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.65576426'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=7003380, Có ĐK=0)', 0, 7003380, 7003380, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.65576426'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3715623] CH Tuyết Tuân - Đường đen - Trực Ninh -(TP) ĐT: 0125 594 8364 - (Gửi xe buýt tải số 36)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3715623', 'CH Tuyết Tuân - Đường đen - Trực Ninh -(TP) ĐT: 0125 594 8364 - (Gửi xe buýt tải số 36)', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 3517900, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 3517900, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3715623'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=3517900, Có ĐK=0)', 0, 3517900, 3517900, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3715623'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.62924176] CH Khánh Tụ-Cổ Lễ- 0348920427
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.62924176', 'CH Khánh Tụ-Cổ Lễ- 0348920427', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0348920427"]', 1440600, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 1440600, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.62924176'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=1440600, Có ĐK=0)', 0, 1440600, 1440600, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.62924176'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3500618] CH Quyết Thuý - trung Khanh - Nam Thái -Nam trực - ĐT: 0934608223
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3500618', 'CH Quyết Thuý - trung Khanh - Nam Thái -Nam trực - ĐT: 0934608223', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0934608223"]', 502750, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 502750, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3500618'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=502750, Có ĐK=0)', 0, 502750, 502750, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3500618'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723143] CH Vĩnh Nhàn-0966722629-Nam hoa-nam trực
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723143', 'CH Vĩnh Nhàn-0966722629-Nam hoa-nam trực', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0966722629"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723143'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3844799] CH Lại Hằng - Cổ Lễ - ĐT: 01234 610  880
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3844799', 'CH Lại Hằng - Cổ Lễ - ĐT: 01234 610  880', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3844799'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3462768] CH Cúc Bách - Cổ Lễ - ĐT: 0912 829  221
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3462768', 'CH Cúc Bách - Cổ Lễ - ĐT: 0912 829  221', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3462768'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.138240787] CH Thu Thủy  _cổ lễ , trực ninh - ĐT: 0976944119
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.138240787', 'CH Thu Thủy  _cổ lễ , trực ninh - ĐT: 0976944119', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0976944119"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.138240787'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3384840] CH Huê Vượng - Cổ Lễ  - ĐT: 0946525505 (chị huê)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3384840', 'CH Huê Vượng - Cổ Lễ  - ĐT: 0946525505 (chị huê)', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0946525505"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3384840'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3360958] CH Cao kỳ - Cầu vô tình - ĐT: 0916175899
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3360958', 'CH Cao kỳ - Cầu vô tình - ĐT: 0916175899', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0916175899"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3360958'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.41040638] CH Dương Cậy - Cổ Lễ 0944469969
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.41040638', 'CH Dương Cậy - Cổ Lễ 0944469969', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0944469969"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.41040638'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.14832134] CH Mãi Thu _Cổ Lễ_01278806880
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.14832134', 'CH Mãi Thu _Cổ Lễ_01278806880', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.14832134'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.6086674] CH Hiền Khiên - Cổ Lễ - ĐT: 0984 048 435
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.6086674', 'CH Hiền Khiên - Cổ Lễ - ĐT: 0984 048 435', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.6086674'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.37282227] CH Cúc Hậu - Cổ Lễ
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.37282227', 'CH Cúc Hậu - Cổ Lễ', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.37282227'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140722995] CH Ngọc Hồi - Xuân Phú - Xuân Trường - ĐT: 094 508 8618
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722995', 'CH Ngọc Hồi - Xuân Phú - Xuân Trường - ĐT: 094 508 8618', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722995'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.5172590] CH Công Định - ngã 3 ngặt kéo - Trực Ninh (TP) ĐT: 0844 889 111-0974 724 682-0
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.5172590', 'CH Công Định - ngã 3 ngặt kéo - Trực Ninh (TP) ĐT: 0844 889 111-0974 724 682-0', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.5172590'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.32102366] CH Hương Lý - Nam Trực - ĐT: 0918311892
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.32102366', 'CH Hương Lý - Nam Trực - ĐT: 0918311892', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0918311892"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.32102366'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140043142] CH Lâm Hiếu - Đồng Sơn - Nam Trực - ĐT: 0368258439
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140043142', 'CH Lâm Hiếu - Đồng Sơn - Nam Trực - ĐT: 0368258439', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0368258439"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140043142'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.4021272] Ch Tuấn Dũng - Đồng lư (qua cầu vòi) TP NĐ - ĐT: 01253564985
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.4021272', 'Ch Tuấn Dũng - Đồng lư (qua cầu vòi) TP NĐ - ĐT: 01253564985', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.4021272'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.132] CH Tiến Phượng - Nam Trực
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.132', 'CH Tiến Phượng - Nam Trực', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.132'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.4048306] CH Đức Tín - Xuân thượng - Xuân Trường ĐT: 01632 879 336
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.4048306', 'CH Đức Tín - Xuân thượng - Xuân Trường ĐT: 01632 879 336', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.4048306'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.7862806] CH Hưng Mai - Hành Thiện - Xuân Trường - ĐT: 0824349829
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.7862806', 'CH Hưng Mai - Hành Thiện - Xuân Trường - ĐT: 0824349829', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0824349829"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.7862806'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3611835] CH Thuận Thành - Xuân Trường (gần tượng đài Trường Chinh) - ĐT: 3 751 851 - DĐ: 0945 365 313
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3611835', 'CH Thuận Thành - Xuân Trường (gần tượng đài Trường Chinh) - ĐT: 3 751 851 - DĐ: 0945 365 313', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3611835'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.90958598] CH Xuyến Thưởng - Lạc Quần
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.90958598', 'CH Xuyến Thưởng - Lạc Quần', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.90958598'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.9042349] CH Khải Dung - Xuân Trường - ĐT: 0968572087
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.9042349', 'CH Khải Dung - Xuân Trường - ĐT: 0968572087', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0968572087"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.9042349'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.8101262] CH Đức Duy - Xuân Trường - ĐT: 02283 752 338
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.8101262', 'CH Đức Duy - Xuân Trường - ĐT: 02283 752 338', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.8101262'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3400351] CH Dũng Thủy - Hành Thiện - Xuân Trường ĐT: 0942 094 303
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3400351', 'CH Dũng Thủy - Hành Thiện - Xuân Trường ĐT: 0942 094 303', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3400351'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.HUONGDUONG] CH Hương dương -Xuân Thành - Xuân trường  ĐT 0915329232 - 0948 287 687
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.HUONGDUONG', 'CH Hương dương -Xuân Thành - Xuân trường  ĐT 0915329232 - 0948 287 687', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0915329232"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.HUONGDUONG'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.11988150] CH An Bình - Xuân Vinh 0912850773
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.11988150', 'CH An Bình - Xuân Vinh 0912850773', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0912850773"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.11988150'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.VIETQUANG] CH Việt Quang - Xuân Tiến - Xuân Trường - ĐT: 0914 483 143
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.VIETQUANG', 'CH Việt Quang - Xuân Tiến - Xuân Trường - ĐT: 0914 483 143', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.VIETQUANG'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.TANHA] CH Tấn Hà xóm 5 thôn đoài ngoại, xuân hòa, ĐT:0962960189-096637267CH Tấn Hà
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.TANHA', 'CH Tấn Hà xóm 5 thôn đoài ngoại, xuân hòa, ĐT:0962960189-096637267CH Tấn Hà', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', '["0962960189"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.TANHA'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3682710] Chinh Hoài - Xuân Tiến - Xuân Trường
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3682710', 'Chinh Hoài - Xuân Tiến - Xuân Trường', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3682710'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.MINHTAN] CH Minh Tân - Xuân Tiến - Xuân Trường ĐT: 0947 203 144 - 03503 762 578
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.MINHTAN', 'CH Minh Tân - Xuân Tiến - Xuân Trường ĐT: 0947 203 144 - 03503 762 578', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.MINHTAN'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.113] Quang Khải - Nam Trực
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.113', 'Quang Khải - Nam Trực', 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG', NULL, -109440, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -109440, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.113'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=109440)', 0, -109440, -109440, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.113'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.52870053] CH Tòng Lăng - Yên Trị - ý yên - ĐT: 0856626888 ( tòng) - 0828 268 999
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.52870053', 'CH Tòng Lăng - Yên Trị - ý yên - ĐT: 0856626888 ( tòng) - 0828 268 999', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0856626888"]', 236480660, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 236480660, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.52870053'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=236480660, Có ĐK=0)', 0, 236480660, 236480660, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.52870053'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.137751525] CH tuấn Bình - Đường 57A - Tân Lập - Yên Tiến - Ý Yên - ĐT: 0912740395
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137751525', 'CH tuấn Bình - Đường 57A - Tân Lập - Yên Tiến - Ý Yên - ĐT: 0912740395', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0912740395"]', 255158400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 255158400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137751525'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=255158400, Có ĐK=0)', 0, 255158400, 255158400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.137751525'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.6562372] CH Quang Phóng - Mỹ Hà - Mỹ Lộc -  ĐT: 0983656838
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.6562372', 'CH Quang Phóng - Mỹ Hà - Mỹ Lộc -  ĐT: 0983656838', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0983656838"]', 123137280, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 123137280, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.6562372'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=123137280, Có ĐK=0)', 0, 123137280, 123137280, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.6562372'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.56038565] CH Mạnh Thắng - 39 Trung Yên - Ý Yên -  ĐT: 0917786583
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.56038565', 'CH Mạnh Thắng - 39 Trung Yên - Ý Yên -  ĐT: 0917786583', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0917786583"]', 96112200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 96112200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.56038565'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=96112200, Có ĐK=0)', 0, 96112200, 96112200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.56038565'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.10414554] CH Trình Hoa - Ý Yên - ĐT: 0384260258 ( vợ) - 0355 006 452
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.10414554', 'CH Trình Hoa - Ý Yên - ĐT: 0384260258 ( vợ) - 0355 006 452', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0384260258"]', 44803260, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 44803260, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.10414554'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=44803260, Có ĐK=0)', 0, 44803260, 44803260, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.10414554'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.10905371] CH Hùng Liên -0975941137-phà đống cao -yy
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.10905371', 'CH Hùng Liên -0975941137-phà đống cao -yy', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0975941137"]', 37797000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 37797000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.10905371'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=37797000, Có ĐK=0)', 0, 37797000, 37797000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.10905371'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.137802102] CH Lan Lợi - Gôi - ĐT: 0942607282 ( gửi bến mới -  ĐT nhà xe: 0988122758 a. bình)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137802102', 'CH Lan Lợi - Gôi - ĐT: 0942607282 ( gửi bến mới -  ĐT nhà xe: 0988122758 a. bình)', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0942607282","0988122758"]', 21203200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 21203200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137802102'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=21203200, Có ĐK=0)', 0, 21203200, 21203200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.137802102'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.8573086] CH Kỳ Dung - Yên Đông - ý yên - ĐT: 0787487529
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.8573086', 'CH Kỳ Dung - Yên Đông - ý yên - ĐT: 0787487529', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0787487529"]', 29014000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 29014000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.8573086'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=29014000, Có ĐK=0)', 0, 29014000, 29014000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.8573086'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.65292959] CH Cường Ngân- Mỹ Lộc - ĐT: 0946890915
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.65292959', 'CH Cường Ngân- Mỹ Lộc - ĐT: 0946890915', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0946890915"]', 14624480, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 14624480, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.65292959'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=14624480, Có ĐK=0)', 0, 14624480, 14624480, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.65292959'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.97697445] CH Tân Phong - vụ Bản
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.97697445', 'CH Tân Phong - vụ Bản', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 20418050, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 20418050, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.97697445'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=20418050, Có ĐK=0)', 0, 20418050, 20418050, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.97697445'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723335] CH Xuân Thuyết:0869685526-lê xá-mỹ lộc -nđ
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723335', 'CH Xuân Thuyết:0869685526-lê xá-mỹ lộc -nđ', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0869685526"]', 17209400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 17209400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723335'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=17209400, Có ĐK=0)', 0, 17209400, 17209400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723335'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.250] CH Phương Nam
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.250', 'CH Phương Nam', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 15923000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 15923000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.250'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=15923000, Có ĐK=0)', 0, 15923000, 15923000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.250'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.000000] CH Dũng Linh - Mỹ Lộc
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.000000', 'CH Dũng Linh - Mỹ Lộc', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 13890000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 13890000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.000000'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=13890000, Có ĐK=0)', 0, 13890000, 13890000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.000000'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3599597] CH Oanh Chợ Sét - Mỹ Lộc - TP Nam Định  ĐT: 01275281760
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3599597', 'CH Oanh Chợ Sét - Mỹ Lộc - TP Nam Định  ĐT: 01275281760', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 12105800, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 12105800, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3599597'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=12105800, Có ĐK=0)', 0, 12105800, 12105800, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3599597'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.137565660] CH Hinh Sáu - Xóm Già - Kim Thái - Vụ Bản - ĐT: 0962046225
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137565660', 'CH Hinh Sáu - Xóm Già - Kim Thái - Vụ Bản - ĐT: 0962046225', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0962046225"]', 8896000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 8896000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137565660'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=8896000, Có ĐK=0)', 0, 8896000, 8896000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.137565660'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723142] CH Ngọc Quyên - chọ huyện yên Thọ - Yên thành - ý yên - ĐT: 0981767889
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723142', 'CH Ngọc Quyên - chọ huyện yên Thọ - Yên thành - ý yên - ĐT: 0981767889', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0981767889"]', 7923000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 7923000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723142'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=7923000, Có ĐK=0)', 0, 7923000, 7923000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723142'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.17761203] CH Phán - Gôi (Trường Huy) - ĐT: 0911006886
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.17761203', 'CH Phán - Gôi (Trường Huy) - ĐT: 0911006886', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0911006886"]', 6645790, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 6645790, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.17761203'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=6645790, Có ĐK=0)', 0, 6645790, 6645790, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.17761203'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3687845] CH Tứ Khuyên - Chợ Dần - Vụ Bản - ĐT: 0982 192 316 - 0985 598 319 ( chú tứ)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3687845', 'CH Tứ Khuyên - Chợ Dần - Vụ Bản - ĐT: 0982 192 316 - 0985 598 319 ( chú tứ)', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 5871500, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 5871500, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3687845'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=5871500, Có ĐK=0)', 0, 5871500, 5871500, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3687845'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723085] CH Vĩnh Tuy- chợ gạo -VB-NĐ
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723085', 'CH Vĩnh Tuy- chợ gạo -VB-NĐ', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 2871000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 2871000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723085'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=2871000, Có ĐK=0)', 0, 2871000, 2871000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723085'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.72599068] CH Sơn Hoàn - Mỹ Lộc - ĐT: 0943096194
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.72599068', 'CH Sơn Hoàn - Mỹ Lộc - ĐT: 0943096194', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0943096194"]', 2584000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 2584000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.72599068'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=2584000, Có ĐK=0)', 0, 2584000, 2584000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.72599068'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140722997] CH Phố Hà-0376615228-hợp hưng -vụ bản
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722997', 'CH Phố Hà-0376615228-hợp hưng -vụ bản', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0376615228"]', 2000000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 2000000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722997'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=2000000, Có ĐK=0)', 0, 2000000, 2000000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140722997'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140722998] CH Sơn Thảo-Làng hoàng mỹ lộc-0942125445
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722998', 'CH Sơn Thảo-Làng hoàng mỹ lộc-0942125445', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0942125445"]', 1163000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 1163000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722998'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=1163000, Có ĐK=0)', 0, 1163000, 1163000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140722998'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.119294013] CH thắm Giang - Yên Lợi - Ý Yên - ĐT: 0944631262
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.119294013', 'CH thắm Giang - Yên Lợi - Ý Yên - ĐT: 0944631262', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0944631262"]', 8442000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 8442000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.119294013'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=8442000, Có ĐK=0)', 0, 8442000, 8442000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.119294013'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.95531706] CH Ánh Tuyết (mới) - Chợ hầu  - Vụ Bản - ĐT: 0916 509 676
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.95531706', 'CH Ánh Tuyết (mới) - Chợ hầu  - Vụ Bản - ĐT: 0916 509 676', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 255000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 255000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.95531706'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=255000, Có ĐK=0)', 0, 255000, 255000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.95531706'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.200] CH Gia Huy - Núi Ngăm
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.200', 'CH Gia Huy - Núi Ngăm', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 136800, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 136800, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.200'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=136800, Có ĐK=0)', 0, 136800, 136800, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.200'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140521485] CH Đạt Huyền-0985928698-yên khang , ý yên ( Gửi xe Kiên bến nông nghiệp)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140521485', 'CH Đạt Huyền-0985928698-yên khang , ý yên ( Gửi xe Kiên bến nông nghiệp)', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0985928698"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140521485'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.77284452] CH Huy Kiên - Mỹ Lộc ( A.kiên tây sơn) - 0906050328
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.77284452', 'CH Huy Kiên - Mỹ Lộc ( A.kiên tây sơn) - 0906050328', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0906050328"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.77284452'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.45004204] CH Quảng Mận - Mỹ Hưng - Mỹ Lộc - ĐT: 0854014007
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.45004204', 'CH Quảng Mận - Mỹ Hưng - Mỹ Lộc - ĐT: 0854014007', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0854014007"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.45004204'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.137432566] CH Mạnh Thủy - Đặng Xá
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137432566', 'CH Mạnh Thủy - Đặng Xá', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137432566'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.63493156] cty huệ hải
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.63493156', 'cty huệ hải', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.63493156'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723338] CH Đại Việt - Mỹ Lộc - TP Nam Định
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723338', 'CH Đại Việt - Mỹ Lộc - TP Nam Định', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723338'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.80824483] CH Nam Thắng - Mỹ Lộc - ĐT: 0977555308
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.80824483', 'CH Nam Thắng - Mỹ Lộc - ĐT: 0977555308', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0977555308"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.80824483'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723159] CH Đăng Long-0852992413-mỹ lộc
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723159', 'CH Đăng Long-0852992413-mỹ lộc', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0852992413"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723159'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.31294206] CH Thanh Tùng - Mỹ Tiến - Mỹ Lộc - ĐT: 0912652078
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.31294206', 'CH Thanh Tùng - Mỹ Tiến - Mỹ Lộc - ĐT: 0912652078', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0912652078"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.31294206'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.130] CH Vĩ An - Ý Yên
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.130', 'CH Vĩ An - Ý Yên', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.130'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.20546284] CH Quyết Loan - Yên Trung - Ý Yên - ĐT: 0974691257
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.20546284', 'CH Quyết Loan - Yên Trung - Ý Yên - ĐT: 0974691257', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0974691257"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.20546284'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723279] CH Điện Lực:0869740989-0941750135 gần ch tòng lăng
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723279', 'CH Điện Lực:0869740989-0941750135 gần ch tòng lăng', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0869740989","0941750135"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723279'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.38712931] CH Dũng Hoa - ý yên - ĐT: 0989321791
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.38712931', 'CH Dũng Hoa - ý yên - ĐT: 0989321791', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0989321791"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.38712931'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3687919] CH Huy nhung ( hưng thịnh) - Chợ Gạo - Ý Yên - ĐT: 0988935132 - 2 245 630
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3687919', 'CH Huy nhung ( hưng thịnh) - Chợ Gạo - Ý Yên - ĐT: 0988935132 - 2 245 630', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0988935132"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3687919'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3323772] CH Xuân Thủy - Cầu Bo - Ý Yên ĐT: - 0912920078 -  0904 770 600 ( Gửi xe Hiếu Bằng bến mới)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3323772', 'CH Xuân Thủy - Cầu Bo - Ý Yên ĐT: - 0912920078 -  0904 770 600 ( Gửi xe Hiếu Bằng bến mới)', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0912920078"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3323772'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.136969364] CH Minh Tiến -  Phú Thôn - Tân khánh - Vụ Bản - ĐT: 0376407176
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.136969364', 'CH Minh Tiến -  Phú Thôn - Tân khánh - Vụ Bản - ĐT: 0376407176', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0376407176"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.136969364'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.137293980] CH Quốc Hiệu - Vụ Bản
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137293980', 'CH Quốc Hiệu - Vụ Bản', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137293980'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.8376302] CH Đăng Tâm - Cầu Bát Di - Vụ Bản - ĐT: 02283 996 854 - 0949 661 057
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.8376302', 'CH Đăng Tâm - Cầu Bát Di - Vụ Bản - ĐT: 02283 996 854 - 0949 661 057', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.8376302'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.6845616] CH Tiến Sơn -Chợ Gạo -vụ bản -0968076767
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.6845616', 'CH Tiến Sơn -Chợ Gạo -vụ bản -0968076767', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0968076767"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.6845616'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140338554] CH Phương Quyên-0976645622 yên minh ý yên
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140338554', 'CH Phương Quyên-0976645622 yên minh ý yên', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0976645622"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140338554'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.5683197] CH Phong Hằng - Minh Thuận - Vụ Bản - ĐT: 0978 287 579
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.5683197', 'CH Phong Hằng - Minh Thuận - Vụ Bản - ĐT: 0978 287 579', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.5683197'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3500354] CH Đại Đồng - Yên Chính - Ý Yên - ĐT: 0228 6 577 424 ( gửi xe hiếu bằng)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3500354', 'CH Đại Đồng - Yên Chính - Ý Yên - ĐT: 0228 6 577 424 ( gửi xe hiếu bằng)', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3500354'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3687958] CH Nhật Linh - Yên Lương - Ý Yên - ĐT: 0906 145 573
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3687958', 'CH Nhật Linh - Yên Lương - Ý Yên - ĐT: 0906 145 573', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3687958'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.136999893] CH Xuân Tới - Yên Hưng - ý Yên
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.136999893', 'CH Xuân Tới - Yên Hưng - ý Yên', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.136999893'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140722990] CH Tiến Lực-yên cường -yy 0368.013.997
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722990', 'CH Tiến Lực-yên cường -yy 0368.013.997', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722990'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.18617801] CH Tuấn Hiệp (Ngã tư chợ mụa)  - ý yên - ĐT 0988152739
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.18617801', 'CH Tuấn Hiệp (Ngã tư chợ mụa)  - ý yên - ĐT 0988152739', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0988152739"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.18617801'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3448907] CH Thọ Châu - Vụ Bản - ĐT: 0912 967 549 -0984377929( Gửi xe Viên Ngát - Bãi cơ khí nông nghiệp - ĐT xe: 0979 311 121
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3448907', 'CH Thọ Châu - Vụ Bản - ĐT: 0912 967 549 -0984377929( Gửi xe Viên Ngát - Bãi cơ khí nông nghiệp - ĐT xe: 0979 311 121', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0984377929"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3448907'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3687995] CH Xuân Dũng - Thị trấn Lâm - Ý Yên - ĐT: 0915 753 580
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3687995', 'CH Xuân Dũng - Thị trấn Lâm - Ý Yên - ĐT: 0915 753 580', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3687995'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.116591126] CH Hùng Thoa - Ý Yên ( Gần đống Cao)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.116591126', 'CH Hùng Thoa - Ý Yên ( Gần đống Cao)', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.116591126'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.42533450] CH Gia Huy - yên cường - Ý Yên - ĐT: 0972145566
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.42533450', 'CH Gia Huy - yên cường - Ý Yên - ĐT: 0972145566', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0972145566"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.42533450'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.131138937] CH Hạnh Nga -  ý yên ( gửi xe về Cầu Bo) - ĐT: 0367813445
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.131138937', 'CH Hạnh Nga -  ý yên ( gửi xe về Cầu Bo) - ĐT: 0367813445', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0367813445"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.131138937'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.91127414] CH Tài Hiền - Ý Yên
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.91127414', 'CH Tài Hiền - Ý Yên', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.91127414'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.136337371] CH Điện máy Phạm Hoàng - Cầu Ngăm - Minh Tân - Vụ Bản - ĐT: 0987229691
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.136337371', 'CH Điện máy Phạm Hoàng - Cầu Ngăm - Minh Tân - Vụ Bản - ĐT: 0987229691', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0987229691"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.136337371'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140722971] CH Xuân Đương - Xóm 8 - cao phương - liên bảo- Vụ Bản - ĐT: 0327252686
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140722971', 'CH Xuân Đương - Xóm 8 - cao phương - liên bảo- Vụ Bản - ĐT: 0327252686', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0327252686"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140722971'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.97574136] CH Hùng Nhàn - Hiển Khánh - Vụ Bản - ĐT: 0971 909 636
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.97574136', 'CH Hùng Nhàn - Hiển Khánh - Vụ Bản - ĐT: 0971 909 636', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.97574136'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.107091089] CH Hùng Thanh - Ý Yên - (mới)  ĐT: 0973482490
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.107091089', 'CH Hùng Thanh - Ý Yên - (mới)  ĐT: 0973482490', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0973482490"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.107091089'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.8441123] CH Cửu thắm - Vụ Bản (ngăm - 01685530079
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.8441123', 'CH Cửu thắm - Vụ Bản (ngăm - 01685530079', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.8441123'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.76899995] CH Tấn Tùng ( mới) - Cát Đằng -Ý Yên - 0944751066 ( Gửi xe Hiếu Bằng - Bến mới)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.76899995', 'CH Tấn Tùng ( mới) - Cát Đằng -Ý Yên - 0944751066 ( Gửi xe Hiếu Bằng - Bến mới)', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0944751066"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.76899995'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.102431473] CH Tình Hoa - Vụ Bản ĐT: 0388255966
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.102431473', 'CH Tình Hoa - Vụ Bản ĐT: 0388255966', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0388255966"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.102431473'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723121] CH Gia Hưng  - Chợ gạo - ĐT: 0948886730
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723121', 'CH Gia Hưng  - Chợ gạo - ĐT: 0948886730', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0948886730"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723121'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3441995] CH Ly Dần -  ( chồng) Vụ Bản ĐT: 0944808571 - 01674805756
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3441995', 'CH Ly Dần -  ( chồng) Vụ Bản ĐT: 0944808571 - 01674805756', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0944808571"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3441995'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.45026316] CH cô Lai  Đặng Xá - ĐT: 0812672543
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.45026316', 'CH cô Lai  Đặng Xá - ĐT: 0812672543', 'MỸ LỘC - Ý YÊN - VỤ BẢN', '["0812672543"]', -31480500, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -31480500, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.45026316'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=31480500)', 0, -31480500, -31480500, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.45026316'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3717075] CH Đức Vân - Ý Yên - ĐT: 0976 146 861
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3717075', 'CH Đức Vân - Ý Yên - ĐT: 0976 146 861', 'MỸ LỘC - Ý YÊN - VỤ BẢN', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3717075'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.6130387] CH Hoàng nguyệt - Thị trấn Ngô Đồng - Giao Thủy - ĐT: 0912 283 347 -
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.6130387', 'CH Hoàng nguyệt - Thị trấn Ngô Đồng - Giao Thủy - ĐT: 0912 283 347 -', 'GIAO THỦY', NULL, 153065000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 153065000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.6130387'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=153065000, Có ĐK=0)', 0, 153065000, 153065000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.6130387'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3345710] CH Việt Phượng -Giao Xuân - Giao Thủy ĐT: 0934 279 068
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3345710', 'CH Việt Phượng -Giao Xuân - Giao Thủy ĐT: 0934 279 068', 'GIAO THỦY', NULL, 131773530, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 131773530, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3345710'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=131773530, Có ĐK=0)', 0, 131773530, 131773530, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3345710'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3931347] CH Kim Thư - Giao Hải - ĐT: 0982 449 028
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3931347', 'CH Kim Thư - Giao Hải - ĐT: 0982 449 028', 'GIAO THỦY', NULL, 96787300, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 96787300, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3931347'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=96787300, Có ĐK=0)', 0, 96787300, 96787300, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3931347'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.70829994] Hải Trình - Hoành Sơn -Giao Thủy(0942820166)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.70829994', 'Hải Trình - Hoành Sơn -Giao Thủy(0942820166)', 'GIAO THỦY', '["0942820166"]', 92031000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 92031000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.70829994'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=92031000, Có ĐK=0)', 0, 92031000, 92031000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.70829994'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3404275] CH Hiển Tho - Giao Châu - Giao Thủy  ĐT: 03503 731 988  - 0988 418 257- DĐ: 0973 036 985
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3404275', 'CH Hiển Tho - Giao Châu - Giao Thủy  ĐT: 03503 731 988  - 0988 418 257- DĐ: 0973 036 985', 'GIAO THỦY', NULL, 61448080, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 61448080, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3404275'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=61448080, Có ĐK=0)', 0, 61448080, 61448080, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3404275'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3346129] CH Đức Cường - Hoành Sơn - Giao Thủy - ĐT: 01686630207 - 0944 654 423 ( Gửi xe buýt tải Đông A)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3346129', 'CH Đức Cường - Hoành Sơn - Giao Thủy - ĐT: 01686630207 - 0944 654 423 ( Gửi xe buýt tải Đông A)', 'GIAO THỦY', NULL, 49269100, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 49269100, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3346129'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=49269100, Có ĐK=0)', 0, 49269100, 49269100, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3346129'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3347232] CH Huân Thơm - Bạch Long - Giao Thủy - ĐT: 03503 893 058 - 0972 998 081 - 0979122009
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3347232', 'CH Huân Thơm - Bạch Long - Giao Thủy - ĐT: 03503 893 058 - 0972 998 081 - 0979122009', 'GIAO THỦY', '["0979122009"]', 42893400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 42893400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3347232'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=42893400, Có ĐK=0)', 0, 42893400, 42893400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3347232'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3907210] CH Minh Hương - Giao Thủy - ĐT: 0912850484
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3907210', 'CH Minh Hương - Giao Thủy - ĐT: 0912850484', 'GIAO THỦY', '["0912850484"]', 33833320, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 33833320, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3907210'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=33833320, Có ĐK=0)', 0, 33833320, 33833320, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3907210'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.9295947] Quang liên - Giao thủy -0987777879
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.9295947', 'Quang liên - Giao thủy -0987777879', 'GIAO THỦY', '["0987777879"]', 31490400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 31490400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.9295947'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=31490400, Có ĐK=0)', 0, 31490400, 31490400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.9295947'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3404169] CH Tú Thoan - Giao Yến - Giao thủy - ĐT: 0943714192
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3404169', 'CH Tú Thoan - Giao Yến - Giao thủy - ĐT: 0943714192', 'GIAO THỦY', '["0943714192"]', 30389400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 30389400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3404169'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=30389400, Có ĐK=0)', 0, 30389400, 30389400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3404169'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.9040428] CH Đức Thiện - Đại Đồng - Giao Thủy - ĐT: 0983 159 613
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.9040428', 'CH Đức Thiện - Đại Đồng - Giao Thủy - ĐT: 0983 159 613', 'GIAO THỦY', NULL, 29328100, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 29328100, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.9040428'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=29328100, Có ĐK=0)', 0, 29328100, 29328100, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.9040428'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.68104749] CH Quý Lan - chợ Bể - Giao Thủy - ĐT: 0836754357 ( vợ)- 0912284317
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.68104749', 'CH Quý Lan - chợ Bể - Giao Thủy - ĐT: 0836754357 ( vợ)- 0912284317', 'GIAO THỦY', '["0836754357","0912284317"]', 26764680, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 26764680, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.68104749'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=26764680, Có ĐK=0)', 0, 26764680, 26764680, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.68104749'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.4704934] CH Ngọc Tiện - Chợ Giao Thiện - Giao Thủy - ĐT:   0859167318 - 0846686701 (ĐT nhà xe 0913 117 101)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.4704934', 'CH Ngọc Tiện - Chợ Giao Thiện - Giao Thủy - ĐT:   0859167318 - 0846686701 (ĐT nhà xe 0913 117 101)', 'GIAO THỦY', '["0859167318","0846686701"]', 13680000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 13680000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.4704934'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=13680000, Có ĐK=0)', 0, 13680000, 13680000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.4704934'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.44432719] CH An Thuyên - Giao An - Giao Thủy - ĐT:  0981682998
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.44432719', 'CH An Thuyên - Giao An - Giao Thủy - ĐT:  0981682998', 'GIAO THỦY', '["0981682998"]', 9503400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 9503400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.44432719'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=9503400, Có ĐK=0)', 0, 9503400, 9503400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.44432719'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.106574051] CH Trần Độ - Giao Châu - Giao Thủy
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.106574051', 'CH Trần Độ - Giao Châu - Giao Thủy', 'GIAO THỦY', NULL, 1556200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 1556200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.106574051'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=1556200, Có ĐK=0)', 0, 1556200, 1556200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.106574051'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3404050] CH Xuân Bôn - Giao An - Giao Thủy - ĐT: 0988 837 476 - 03503 741 535
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3404050', 'CH Xuân Bôn - Giao An - Giao Thủy - ĐT: 0988 837 476 - 03503 741 535', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3404050'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.124244199] CH Quỳnh An - Xóm 6 - Giao Hương - Giao Thủy - ĐT: 0974 422 346
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.124244199', 'CH Quỳnh An - Xóm 6 - Giao Hương - Giao Thủy - ĐT: 0974 422 346', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.124244199'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.65675531] CH Chung Thủy - Giao Thủy - ĐT: 0969756935Gửi xe buýt tải Đông A - Ngã tư Hồng Thuận
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.65675531', 'CH Chung Thủy - Giao Thủy - ĐT: 0969756935Gửi xe buýt tải Đông A - Ngã tư Hồng Thuận', 'GIAO THỦY', '["0969756935"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.65675531'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.138324253] CH Trang Huynh - Bành Long - Giao Thủy
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.138324253', 'CH Trang Huynh - Bành Long - Giao Thủy', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.138324253'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3333321] CH Tỵ Liên - Giao Lạc - Giao Thủy
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3333321', 'CH Tỵ Liên - Giao Lạc - Giao Thủy', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3333321'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3404254] CH Thịnh Phát - Giao Thịnh - Giao Thủy - ĐT: 0979 654 994
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3404254', 'CH Thịnh Phát - Giao Thịnh - Giao Thủy - ĐT: 0979 654 994', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3404254'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.28336137] CH Minh Doanh - Quất Lâm - Giao Thủy - ĐT: 0966290636 ( Gửi xe bến trần hưng đạo - Xe số 12
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.28336137', 'CH Minh Doanh - Quất Lâm - Giao Thủy - ĐT: 0966290636 ( Gửi xe bến trần hưng đạo - Xe số 12', 'GIAO THỦY', '["0966290636"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.28336137'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3750495] CH Thành Hương - Giao Tiến - Giao Thủy: ĐT: 03503 895 620
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3750495', 'CH Thành Hương - Giao Tiến - Giao Thủy: ĐT: 03503 895 620', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3750495'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.10785822] CH Cẩn Liễu -  Giao Thanh _giao Thủy -ĐT: 01288 365 064
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.10785822', 'CH Cẩn Liễu -  Giao Thanh _giao Thủy -ĐT: 01288 365 064', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.10785822'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3393138] Chính Hiền - Giao Tân - Giao Thủy  ĐT: 0974 861 428
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3393138', 'Chính Hiền - Giao Tân - Giao Thủy  ĐT: 0974 861 428', 'GIAO THỦY', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3393138'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.105387748] CH Khoa Cương - Giao Tiến - Giao Thủy - ĐT: 0915878085
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.105387748', 'CH Khoa Cương - Giao Tiến - Giao Thủy - ĐT: 0915878085', 'GIAO THỦY', '["0915878085"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.105387748'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723249] CH Lạng Hạnh-Bình hoà -giao thuỷ-0907865384(đt bus 0917117101)
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723249', 'CH Lạng Hạnh-Bình hoà -giao thuỷ-0907865384(đt bus 0917117101)', 'GIAO THỦY', '["0907865384","0917117101"]', -76400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -76400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723249'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=76400)', 0, -76400, -76400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723249'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.138202764] CH Phúc Ân - Giao Yến - Giao Thủy - ĐT: 0973 334 568
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.138202764', 'CH Phúc Ân - Giao Yến - Giao Thủy - ĐT: 0973 334 568', 'GIAO THỦY', NULL, -143000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -143000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.138202764'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=143000)', 0, -143000, -143000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.138202764'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3364535] CH Đức Dĩnh - Hải Đông - Hải Hậu  ĐT:0972 685 775 - 03503875272
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3364535', 'CH Đức Dĩnh - Hải Đông - Hải Hậu  ĐT:0972 685 775 - 03503875272', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0350387527"]', 210813400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 210813400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3364535'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=210813400, Có ĐK=0)', 0, 210813400, 210813400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3364535'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.43571865] CH Hà Thuỷ - Ngã 3 Tam Thôn - ĐT: 0386447857
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.43571865', 'CH Hà Thuỷ - Ngã 3 Tam Thôn - ĐT: 0386447857', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0386447857"]', 156648300, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 156648300, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.43571865'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=156648300, Có ĐK=0)', 0, 156648300, 156648300, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.43571865'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3329059] CH Đức Hải ( Đình Huyền) - Nghĩa An - Nam Trực -   - ĐT: 0948598862
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3329059', 'CH Đức Hải ( Đình Huyền) - Nghĩa An - Nam Trực -   - ĐT: 0948598862', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0948598862"]', 105653000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 105653000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3329059'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=105653000, Có ĐK=0)', 0, 105653000, 105653000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3329059'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3324131] ch đức giang-đường đen -  Thượng Đồng, Đồng Sơn , Nam Trực - ĐT: 0962223488
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3324131', 'ch đức giang-đường đen -  Thượng Đồng, Đồng Sơn , Nam Trực - ĐT: 0962223488', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0962223488"]', 89552160, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 89552160, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3324131'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=89552160, Có ĐK=0)', 0, 89552160, 89552160, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3324131'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3401189] CH Thế Hải - Hải Cường - Hải Hậu
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3401189', 'CH Thế Hải - Hải Cường - Hải Hậu', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 76579800, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 76579800, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3401189'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=76579800, Có ĐK=0)', 0, 76579800, 76579800, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3401189'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.4917715] CH Tùng Sen - Hải Hậu - ĐT: 0913 199 135
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.4917715', 'CH Tùng Sen - Hải Hậu - ĐT: 0913 199 135', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 62986800, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 62986800, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.4917715'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=62986800, Có ĐK=0)', 0, 62986800, 62986800, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.4917715'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3400234] CH Ngọc Khang - Cầu Tùng Lâm - Hải Hậu gửi xe buýt số 36 - ĐT  0915878591 - 0989342978
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3400234', 'CH Ngọc Khang - Cầu Tùng Lâm - Hải Hậu gửi xe buýt số 36 - ĐT  0915878591 - 0989342978', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0915878591","0989342978"]', 57704200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 57704200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3400234'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=57704200, Có ĐK=0)', 0, 57704200, 57704200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3400234'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.18507547] CH Thuỷ Tùng - Nghĩa Hưng
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.18507547', 'CH Thuỷ Tùng - Nghĩa Hưng', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 51404240, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 51404240, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.18507547'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=51404240, Có ĐK=0)', 0, 51404240, 51404240, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.18507547'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.38623920] CH Tiến Sang - Nghĩa Lâm - Nghĩa Hưng - ĐT: 0976 583714 -
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.38623920', 'CH Tiến Sang - Nghĩa Lâm - Nghĩa Hưng - ĐT: 0976 583714 -', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 50507040, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 50507040, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.38623920'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=50507040, Có ĐK=0)', 0, 50507040, 50507040, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.38623920'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3400290] CH Đỉnh Thu - Hải Thịnh - Hải Hậu - ĐT: 0948 582 333 - 0944618233 ( vợ) - Gửi xe Liễu ở bến mới
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3400290', 'CH Đỉnh Thu - Hải Thịnh - Hải Hậu - ĐT: 0948 582 333 - 0944618233 ( vợ) - Gửi xe Liễu ở bến mới', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0944618233"]', 38192000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 38192000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3400290'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=38192000, Có ĐK=0)', 0, 38192000, 38192000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3400290'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.73813467] CH Thiệu Hường - Nghĩa Hưng - ĐT: 0948076996
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.73813467', 'CH Thiệu Hường - Nghĩa Hưng - ĐT: 0948076996', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0948076996"]', 37175300, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 37175300, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.73813467'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=37175300, Có ĐK=0)', 0, 37175300, 37175300, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.73813467'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH 12131415] CH Tỉnh Dung
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH 12131415', 'CH Tỉnh Dung', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 28560000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 28560000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH 12131415'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=28560000, Có ĐK=0)', 0, 28560000, 28560000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH 12131415'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.251] CH Cao Quỳnh
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.251', 'CH Cao Quỳnh', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 24260000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 24260000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.251'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=24260000, Có ĐK=0)', 0, 24260000, 24260000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.251'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723015] CH Hoàng Hải-0977419887-hải phong -hh
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723015', 'CH Hoàng Hải-0977419887-hải phong -hh', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0977419887"]', 21946800, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 21946800, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723015'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=21946800, Có ĐK=0)', 0, 21946800, 21946800, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723015'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.14222902] CH Đức Lương _ Hải Hậu _0948688480
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.14222902', 'CH Đức Lương _ Hải Hậu _0948688480', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0948688480"]', 19263800, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 19263800, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.14222902'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=19263800, Có ĐK=0)', 0, 19263800, 19263800, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.14222902'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.136867751] CH Tiên Hoa - km7 - Đường 55 - Nghĩa Hưng ĐT: 0912443022
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.136867751', 'CH Tiên Hoa - km7 - Đường 55 - Nghĩa Hưng ĐT: 0912443022', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0912443022"]', 11573480, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 11573480, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.136867751'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=11573480, Có ĐK=0)', 0, 11573480, 11573480, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.136867751'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.180] CH Đông Nhạn - Hải Hậu
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.180', 'CH Đông Nhạn - Hải Hậu', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 11472000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 11472000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.180'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=11472000, Có ĐK=0)', 0, 11472000, 11472000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.180'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.120034372] CH Trung Lan - Xóm Tân Phong - Hải Triều - Hải Hậu - ĐT: 0335134053
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.120034372', 'CH Trung Lan - Xóm Tân Phong - Hải Triều - Hải Hậu - ĐT: 0335134053', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0335134053"]', 11411400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 11411400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.120034372'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=11411400, Có ĐK=0)', 0, 11411400, 11411400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.120034372'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.23021393] CH Đoan Hằng - Trực thái - Hải hậu - ĐT: 0944874236
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.23021393', 'CH Đoan Hằng - Trực thái - Hải hậu - ĐT: 0944874236', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0944874236"]', 10796200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 10796200, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.23021393'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=10796200, Có ĐK=0)', 0, 10796200, 10796200, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.23021393'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3332008] CH Rồng Huế - Quỹ nhất - Nghĩa Hưng - 03503872111 - 0944571298 - 0912410633
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3332008', 'CH Rồng Huế - Quỹ nhất - Nghĩa Hưng - 03503872111 - 0944571298 - 0912410633', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0350387211","0944571298","0912410633"]', 10295000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 10295000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3332008'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=10295000, Có ĐK=0)', 0, 10295000, 10295000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3332008'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.90494765] CH Minh Ái - Xóm 8 - Hải Lộc - Hải Hậu  - ĐT: 0915068151
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.90494765', 'CH Minh Ái - Xóm 8 - Hải Lộc - Hải Hậu  - ĐT: 0915068151', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0915068151"]', 9881940, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 9881940, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.90494765'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=9881940, Có ĐK=0)', 0, 9881940, 9881940, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.90494765'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3403658] CH Hoà Nguyệt - Hải Lý - Hải Hậu - ĐT: 01696 366 037 (vợ) - 0977 557 103 - 03503 789 686 - 0000000000
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3403658', 'CH Hoà Nguyệt - Hải Lý - Hải Hậu - ĐT: 01696 366 037 (vợ) - 0977 557 103 - 03503 789 686 - 0000000000', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 9432190, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 9432190, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3403658'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=9432190, Có ĐK=0)', 0, 9432190, 9432190, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3403658'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.89361744] CH Mai Hương - Cầu An Lá - 0948 114 716
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.89361744', 'CH Mai Hương - Cầu An Lá - 0948 114 716', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 9169000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 9169000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.89361744'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=9169000, Có ĐK=0)', 0, 9169000, 9169000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.89361744'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3649076] CH Toản Hà - Hải Lạng - Nghĩa Hưng
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3649076', 'CH Toản Hà - Hải Lạng - Nghĩa Hưng', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 5599000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 5599000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3649076'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=5599000, Có ĐK=0)', 0, 5599000, 5599000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3649076'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.23847069] CH Tú Lĩnh - Hải Hậu - ĐT: 0329842485
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.23847069', 'CH Tú Lĩnh - Hải Hậu - ĐT: 0329842485', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0329842485"]', 4688960, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 4688960, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.23847069'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=4688960, Có ĐK=0)', 0, 4688960, 4688960, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.23847069'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.140723021] CH Vũ Oánh:-0912555776-chợ đền hải quang -h2
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723021', 'CH Vũ Oánh:-0912555776-chợ đền hải quang -h2', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0912555776"]', 3629000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 3629000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723021'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=3629000, Có ĐK=0)', 0, 3629000, 3629000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.140723021'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.150] CH Thịnh Kế -tt cồn -hh-nđ-0989432618
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.150', 'CH Thịnh Kế -tt cồn -hh-nđ-0989432618', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0989432618"]', 2074000, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 2074000, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.150'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=2074000, Có ĐK=0)', 0, 2074000, 2074000, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.150'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3403365] CH Thứ Nga - Hải Hậu - ĐT: 0914791095
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3403365', 'CH Thứ Nga - Hải Hậu - ĐT: 0914791095', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0914791095"]', 1657640, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 1657640, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3403365'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=1657640, Có ĐK=0)', 0, 1657640, 1657640, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3403365'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.5172976] CH Hoàng Phương - Liễu Đề - Nghĩa Hưng - 0915063239
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.5172976', 'CH Hoàng Phương - Liễu Đề - Nghĩa Hưng - 0915063239', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0915063239"]', 1054400, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 1054400, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.5172976'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=1054400, Có ĐK=0)', 0, 1054400, 1054400, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.5172976'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3716180] CH Khoan Nhật - Nghĩa Hùng - Nghĩa Hưng - ĐT: 03503 714 668
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3716180', 'CH Khoan Nhật - Nghĩa Hùng - Nghĩa Hưng - ĐT: 03503 714 668', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 921600, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 921600, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3716180'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=921600, Có ĐK=0)', 0, 921600, 921600, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3716180'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.4232934] CH Thêm Thùy - Hải Lạng - Nghĩa Hưng - ĐT: 0912675229
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.4232934', 'CH Thêm Thùy - Hải Lạng - Nghĩa Hưng - ĐT: 0912675229', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0912675229"]', 356250, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 356250, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.4232934'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=356250, Có ĐK=0)', 0, 356250, 356250, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.4232934'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

-- Khách hàng: [KH.3403607] CH Hiệp Thơm - Thị trấn Cồn - Hải Hậu- ĐT: 0972208139
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3403607', 'CH Hiệp Thơm - Thị trấn Cồn - Hải Hậu- ĐT: 0972208139', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0972208139"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3403607'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.72930264] CH Hoài Cương - Yên Định - Hải Hậu
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.72930264', 'CH Hoài Cương - Yên Định - Hải Hậu', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.72930264'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723223] CH Nghiêm Sâm:0338554888-liễu đề -nghĩa hưng
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723223', 'CH Nghiêm Sâm:0338554888-liễu đề -nghĩa hưng', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0338554888"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723223'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.122] CH Luyến Phượng - Trực Đại
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.122', 'CH Luyến Phượng - Trực Đại', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.122'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723199] CH Đức Thịnh-0989577804-cạnh ubnd xã đồng sơn -ngã 3 giao cù đi vào
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723199', 'CH Đức Thịnh-0989577804-cạnh ubnd xã đồng sơn -ngã 3 giao cù đi vào', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0989577804"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723199'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.4516015] CH Quản Lan - Chợ Chùa  ĐT: 0916 161 013
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.4516015', 'CH Quản Lan - Chợ Chùa  ĐT: 0916 161 013', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', NULL, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.4516015'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.137087332] CH Tiến Khích - Nam Thái - Nam Trực -  0948933650
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.137087332', 'CH Tiến Khích - Nam Thái - Nam Trực -  0948933650', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0948933650"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.137087332'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723328] CH Minh Khuê:0985815371-qua cầu trắng 100m bên tay phỉa cạnh cty giầy da-đi đường 21 chợ chùa
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723328', 'CH Minh Khuê:0985815371-qua cầu trắng 100m bên tay phỉa cạnh cty giầy da-đi đường 21 chợ chùa', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0985815371"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723328'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH111115555] CH Thái Hạnh - Nghĩa Thành - Nghĩa Hưng - ĐT: 0363668421
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH111115555', 'CH Thái Hạnh - Nghĩa Thành - Nghĩa Hưng - ĐT: 0363668421', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0363668421"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH111115555'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.TRONGANH] CH Trọng Anh - Xóm 3 - Nghĩa Thành - Nghĩa Hưng - ĐT: 0989993234 - 0398162642, gửi xe 34 Trần Hưng Đạo.
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.TRONGANH', 'CH Trọng Anh - Xóm 3 - Nghĩa Thành - Nghĩa Hưng - ĐT: 0989993234 - 0398162642, gửi xe 34 Trần Hưng Đạo.', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0989993234","0398162642"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.TRONGANH'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.55085086] CH Kha Hằng(Phạm Kha) - Hải Hậu - ĐT: 0854537045
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.55085086', 'CH Kha Hằng(Phạm Kha) - Hải Hậu - ĐT: 0854537045', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0854537045"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.55085086'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3400438] CH Duy Trực - Chợ Trâu - Hải Hậu 0944206519
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3400438', 'CH Duy Trực - Chợ Trâu - Hải Hậu 0944206519', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0944206519"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3400438'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.55916821] CH Huyền Linh - Hải Cường - Hải Hậu - ĐT: 0384902923 - 0984081942
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.55916821', 'CH Huyền Linh - Hải Cường - Hải Hậu - ĐT: 0384902923 - 0984081942', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0384902923","0984081942"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.55916821'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723300] CH Hoàng Hiệp(1) - Xóm 8 - Hải Vân - Hải Hậu - ĐT: 0828087890
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723300', 'CH Hoàng Hiệp(1) - Xóm 8 - Hải Vân - Hải Hậu - ĐT: 0828087890', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0828087890"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723300'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.140723306] CH Quân Huy:0929533333
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.140723306', 'CH Quân Huy:0929533333', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0929533333"]', 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', 0, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.140723306'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

-- Khách hàng: [KH.3330140] oanh Nhì -  Nghĩa Châu - Nghĩa Hưng ĐT: 03506 586 024 - 0966630937
INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")
VALUES ('KH.3330140', 'oanh Nhì -  Nghĩa Châu - Nghĩa Hưng ĐT: 03506 586 024 - 0966630937', 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)', '["0966630937"]', -8258840, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("Code") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Region" = EXCLUDED."Region",
    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")
SELECT "Id", 'warehouse1', -8258840, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = 'KH.3330140'
ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET
    "Debt" = EXCLUDED."Debt",
    "UpdatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")
SELECT "Id", 'warehouse1', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=0, Có ĐK=8258840)', 0, -8258840, -8258840, CURRENT_TIMESTAMP
FROM "Customers" WHERE "Code" = 'KH.3330140'
AND NOT EXISTS (
    SELECT 1 FROM "CustomerDebtHistories" 
    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = 'warehouse1'
);

COMMIT;

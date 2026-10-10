-- Script reset database nhưng GIỮ LẠI danh sách Người dùng (Users / Owners / LoginHistories)

BEGIN TRANSACTION;

-- Xóa dữ liệu các bảng nghiệp vụ theo thứ tự ràng buộc khóa ngoại (Foreign Keys)
TRUNCATE TABLE "StockHistories" CASCADE;
TRUNCATE TABLE "ExportVoucherItems" CASCADE;
TRUNCATE TABLE "ImportVoucherItems" CASCADE;
TRUNCATE TABLE "ExportVouchers" CASCADE;
TRUNCATE TABLE "ImportVouchers" CASCADE;
TRUNCATE TABLE "Payments" CASCADE;
TRUNCATE TABLE "Receipts" CASCADE;
TRUNCATE TABLE "CustomerDebtHistories" CASCADE;
TRUNCATE TABLE "SupplierDebtHistories" CASCADE;
TRUNCATE TABLE "AuditLogs" CASCADE;
TRUNCATE TABLE "Products" CASCADE;
TRUNCATE TABLE "Customers" CASCADE;
TRUNCATE TABLE "Suppliers" CASCADE;

COMMIT;

-- Các bảng được giữ nguyên hoàn toàn: "Users", "Owners", "LoginHistories".

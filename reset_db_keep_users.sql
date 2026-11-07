-- Script reset database nhưng GIỮ LẠI danh sách Người dùng (Users / Owners / LoginHistories)

BEGIN TRANSACTION;

-- Xóa toàn bộ dữ liệu nghiệp vụ và reset lại sequence (ID tự tăng) về 1
TRUNCATE TABLE 
    "StockHistories",
    "ExportVoucherItems",
    "ImportVoucherItems",
    "ExportVouchers",
    "ImportVouchers",
    "Payments",
    "Receipts",
    "CustomerDebtHistories",
    "SupplierDebtHistories",
    "CustomerWarehouseDebts",
    "SupplierWarehouseDebts",
    "ProductUnits",
    "Products",
    "Customers",
    "Suppliers",
    "Employees",
    "AuditLogs"
RESTART IDENTITY CASCADE;

COMMIT;

-- Các bảng được giữ nguyên hoàn toàn: "Users", "Owners", "LoginHistories".

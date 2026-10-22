-- =====================================================================
-- Script: seed_employees_and_assign_exports.sql
-- Mục đích:
--   1. Thêm 5 nhân viên bán hàng/kinh doanh (nếu chưa có)
--   2. Gán các phiếu xuất hiện có (ExportVouchers) cho 5 nhân viên theo
--      cơ chế xoay vòng (round-robin) đồng đều theo thứ tự thời gian
--   3. Cập nhật cả EmployeeId và EmployeeName trong bảng ExportVouchers
-- =====================================================================

SET client_encoding = 'UTF8';

BEGIN;

-- 1. Thêm 5 nhân viên mẫu nếu chưa tồn tại
INSERT INTO "Employees" ("Name", "Phone", "Notes", "CreatedAt")
SELECT emp.name, emp.phone, emp.notes, NOW()
FROM (VALUES
    ('Nguyễn Văn An', '0912345678', 'Nhân viên kinh doanh phụ trách Miền Nam'),
    ('Trần Thị Mai', '0923456789', 'Nhân viên bán hàng phụ trách Miền Bắc'),
    ('Lê Hoàng Nam', '0934567890', 'Nhân viên kinh doanh khu vực TP.HCM'),
    ('Phạm Quốc Dũng', '0945678901', 'Nhân viên bán hàng dự án & đại lý'),
    ('Hoàng Kim Oanh', '0956789012', 'Nhân viên kinh doanh kênh siêu thị & bán lẻ')
) AS emp(name, phone, notes)
WHERE NOT EXISTS (
    SELECT 1 FROM "Employees" e WHERE e."Name" = emp.name
);

-- 2. Phân bổ đều các phiếu xuất hiện có cho 5 nhân viên
WITH numbered_vouchers AS (
    SELECT 
        "Id",
        ROW_NUMBER() OVER (ORDER BY "Date" ASC, "Id" ASC) - 1 AS row_idx
    FROM "ExportVouchers"
),
emp_list AS (
    SELECT 
        "Id",
        "Name",
        ROW_NUMBER() OVER (ORDER BY "Id" ASC) - 1 AS emp_idx,
        COUNT(*) OVER () AS total_emps
    FROM "Employees"
    WHERE "Name" IN (
        'Nguyễn Văn An',
        'Trần Thị Mai',
        'Lê Hoàng Nam',
        'Phạm Quốc Dũng',
        'Hoàng Kim Oanh'
    )
),
assignments AS (
    SELECT 
        nv."Id" AS voucher_id,
        el."Id" AS emp_id,
        el."Name" AS emp_name
    FROM numbered_vouchers nv
    JOIN emp_list el ON (nv.row_idx % el.total_emps) = el.emp_idx
)
UPDATE "ExportVouchers" ev
SET 
    "EmployeeId" = a.emp_id,
    "EmployeeName" = a.emp_name
FROM assignments a
WHERE ev."Id" = a.voucher_id;

COMMIT;

-- 3. Hiển thị báo cáo thống kê sau khi gán
SELECT 
    e."Id" AS "Mã NV",
    e."Name" AS "Tên Nhân Viên",
    e."Phone" AS "Số Điện Thoại",
    COUNT(ev."Id") AS "Số Phiếu Xuất",
    COALESCE(SUM(ev."TotalSale"), 0) AS "Tổng Doanh Thu (VNĐ)"
FROM "Employees" e
LEFT JOIN "ExportVouchers" ev ON e."Id" = ev."EmployeeId"
GROUP BY e."Id", e."Name", e."Phone"
ORDER BY e."Id";

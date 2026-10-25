-- =====================================================================
-- Script: fix_missing_receipts_payments.sql
-- 1. Bổ sung Phiếu thu (Receipts) cho các Phiếu xuất có PaidAmount > 0 nhưng chưa có phiếu thu
-- 2. Bổ sung Phiếu chi (Payments) cho các Phiếu nhập có PaidAmount > 0 nhưng chưa có phiếu chi
-- 3. Bổ sung bản ghi 'init' công nợ ban đầu cho Customers và Suppliers
-- 4. Cập nhật lại Identity Sequence cho Receipts, Payments, CustomerDebtHistories, SupplierDebtHistories
-- =====================================================================

BEGIN;

-- 1. Bổ sung Phiếu thu cho ExportVouchers
INSERT INTO "Receipts" (
    "ReceiptNumber",
    "Date",
    "CustomerId",
    "SupplierId",
    "Amount",
    "Method",
    "RelatedVoucherType",
    "RelatedVoucherId",
    "Notes",
    "CreatedAt"
)
SELECT 
    'PT' || TO_CHAR(ev."Date", 'YYYYMMDD') || '-' || LPAD(ev."Id"::text, 6, '0'),
    ev."Date",
    ev."CustomerId",
    NULL,
    ev."PaidAmount",
    'cash',
    'export_voucher',
    ev."VoucherNumber",
    'Thu tiền bán hàng ngay theo phiếu xuất ' || ev."VoucherNumber",
    ev."Date"
FROM "ExportVouchers" ev
WHERE ev."PaidAmount" > 0
  AND ev."Status" != 'cancelled'
  AND NOT EXISTS (
    SELECT 1 FROM "Receipts" r 
    WHERE r."CustomerId" = ev."CustomerId" 
      AND r."RelatedVoucherId" = ev."VoucherNumber"
  );

-- 2. Bổ sung Phiếu chi cho ImportVouchers
INSERT INTO "Payments" (
    "PaymentNumber",
    "Date",
    "SupplierId",
    "CustomerId",
    "Amount",
    "Method",
    "Status",
    "CancelledAt",
    "RelatedVoucherType",
    "RelatedVoucherId",
    "Notes",
    "CreatedAt"
)
SELECT 
    'PC' || TO_CHAR(iv."Date", 'YYYYMMDD') || '-' || LPAD(iv."Id"::text, 6, '0'),
    iv."Date",
    iv."SupplierId",
    NULL,
    iv."PaidAmount",
    'bank_transfer',
    'completed',
    NULL,
    'import_voucher',
    iv."VoucherNumber",
    'Thanh toán tiền nhập hàng theo phiếu ' || iv."VoucherNumber",
    iv."Date"
FROM "ImportVouchers" iv
WHERE iv."PaidAmount" > 0
  AND iv."Status" != 'cancelled'
  AND NOT EXISTS (
    SELECT 1 FROM "Payments" p 
    WHERE p."SupplierId" = iv."SupplierId" 
      AND p."RelatedVoucherId" = iv."VoucherNumber"
  );

-- 3. Bổ sung bản ghi 'init' công nợ ban đầu cho Customers
INSERT INTO "CustomerDebtHistories" (
    "CustomerId",
    "SourceType",
    "ReferenceType",
    "ReferenceId",
    "Reason",
    "Note",
    "BeforeDebt",
    "Delta",
    "AfterDebt",
    "CreatedAt"
)
SELECT 
    c."Id",
    'init',
    NULL,
    'INIT-' || c."Code",
    'Khởi tạo công nợ ban đầu',
    'Số dư công nợ ban đầu khi tạo khách hàng',
    0,
    (c."Debt" - COALESCE(h.total_delta, 0)),
    (c."Debt" - COALESCE(h.total_delta, 0)),
    COALESCE(
        (SELECT MIN("Date") - INTERVAL '1 minute' FROM "ExportVouchers" WHERE "CustomerId" = c."Id"),
        c."CreatedAt" - INTERVAL '1 minute'
    )
FROM "Customers" c
LEFT JOIN (
    SELECT "CustomerId", SUM("Delta") AS total_delta
    FROM "CustomerDebtHistories"
    GROUP BY "CustomerId"
) h ON h."CustomerId" = c."Id"
WHERE (c."Debt" - COALESCE(h.total_delta, 0)) != 0;

-- 4. Bổ sung bản ghi 'init' công nợ ban đầu cho Suppliers
INSERT INTO "SupplierDebtHistories" (
    "SupplierId",
    "SourceType",
    "ReferenceType",
    "ReferenceId",
    "Reason",
    "Note",
    "BeforeDebt",
    "Delta",
    "AfterDebt",
    "CreatedAt"
)
SELECT 
    s."Id",
    'init',
    NULL,
    'INIT-' || s."Code",
    'Khởi tạo công nợ ban đầu',
    'Số dư công nợ ban đầu khi tạo nhà cung cấp',
    0,
    (s."Debt" - COALESCE(h.total_delta, 0)),
    (s."Debt" - COALESCE(h.total_delta, 0)),
    COALESCE(
        (SELECT MIN("Date") - INTERVAL '1 minute' FROM "ImportVouchers" WHERE "SupplierId" = s."Id"),
        s."CreatedAt" - INTERVAL '1 minute'
    )
FROM "Suppliers" s
LEFT JOIN (
    SELECT "SupplierId", SUM("Delta") AS total_delta
    FROM "SupplierDebtHistories"
    GROUP BY "SupplierId"
) h ON h."SupplierId" = s."Id"
WHERE (s."Debt" - COALESCE(h.total_delta, 0)) != 0;

-- 5. Cập nhật lại Identity Sequence cho tất cả các bảng
SELECT setval(pg_get_serial_sequence('"Receipts"', 'Id'), (SELECT COALESCE(MAX("Id"), 1) FROM "Receipts"));
SELECT setval(pg_get_serial_sequence('"Payments"', 'Id'), (SELECT COALESCE(MAX("Id"), 1) FROM "Payments"));
SELECT setval(pg_get_serial_sequence('"CustomerDebtHistories"', 'Id'), (SELECT COALESCE(MAX("Id"), 1) FROM "CustomerDebtHistories"));
SELECT setval(pg_get_serial_sequence('"SupplierDebtHistories"', 'Id'), (SELECT COALESCE(MAX("Id"), 1) FROM "SupplierDebtHistories"));

COMMIT;

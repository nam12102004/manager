// update-product-skus.js
// Script chỉnh sửa mã sản phẩm (SKU) theo quy tắc:
//   [Tên NCC viết tắt (nếu tên tiếng Việt, giữ nguyên nếu tên Latin/tiếng Anh)] + [STT]
//   Lưu ý: Dùng chữ cái Latin không dấu (không dùng các ký tự tiếng Việt như Đ, Ă, Â, Ê, Ô, Ơ, Ư...).
//
// Các chế độ chạy:
//   node update-product-skus.js --dry-run    (Xem trước bảng ánh xạ SKU cũ -> SKU mới, không ghi DB)
//   node update-product-skus.js --sql        (Chỉ xuất file SQL update_product_skus.sql)
//   node update-product-skus.js --direct-db  (Thực thi cập nhật trực tiếp vào PostgreSQL container debtmanager_db)
//   node update-product-skus.js --api        (Thực thi cập nhật qua Backend REST API localhost:5050)

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const API_BASE = process.env.API_BASE || 'http://localhost:5050/api';
const SQL_OUTPUT_PATH = path.join(__dirname, 'update_product_skus.sql');

// ============================================================================
// 1. BẢNG CẤU HÌNH TÊN VIẾT TẮT NHÀ CUNG CẤP (CHỮ CÁI LATIN KHÔNG DẤU)
// ============================================================================
// Có thể tùy chỉnh lại tiền tố (prefix), ký tự nối (separator) và độ dài STT (padLength) sau khi chốt:
const SKU_FORMAT_CONFIG = {
  separator: '',     // Có thể đổi thành '-' nếu muốn dạng HH-001 thay vì HH001
  padLength: 3,      // Số chữ số STT: 3 -> 001..216 (đổi thành 0 nếu muốn HH1, HH2...)
};

const SUPPLIER_ABBR_MAP = {
  'Hoàng Hà':      { abbr: 'HH',    supplierCode: 'HH',    note: 'Tên tiếng Việt -> viết tắt chữ cái đầu (Hoang Ha -> HH)' },
  'Nice':          { abbr: 'NICE',  supplierCode: 'NICE',  note: 'Tên tiếng Anh/Latin -> giữ nguyên' },
  'Takao':         { abbr: 'TAKAO', supplierCode: 'TAKAO', note: 'Tên Latin -> giữ nguyên' },
  'Vĩnh Thắng':    { abbr: 'VT',    supplierCode: 'VT',    note: 'Tên tiếng Việt -> viết tắt chữ cái đầu (Vinh Thang -> VT)' },
  'Dmax + Mira':   { abbr: 'DMAX',  supplierCode: 'DMAX',  note: 'Theo Suppliers.Code (Option B)' },
  'Royal + Ấn Độ': { abbr: 'RA',    supplierCode: 'RA',    note: 'Theo Suppliers.Code (Option B - Latin không dấu)' },
  'Toko':          { abbr: 'TOKO',  supplierCode: 'TOKO',  note: 'Tên Latin -> giữ nguyên' },
  'Á Mỹ':          { abbr: 'AMY',   supplierCode: 'AMY',   note: 'Theo Suppliers.Code (Option B - Latin không dấu)' },
};

// ============================================================================
// 2. HÀM CHUYỂN ĐỔI TIẾNG VIỆT CÓ DẤU -> CHỮ LATIN KHÔNG DẤU
// ============================================================================
function toLatinAscii(str) {
  if (!str) return '';
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Xóa toàn bộ dấu thanh & dấu mũ tiếng Việt (ă, â, ê, ô, ơ, ư)
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .replace(/[^a-zA-Z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function hasVietnameseChars(str) {
  return /[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]/.test(str);
}

/**
 * Tự động suy luận mã viết tắt Latin cho Nhà cung cấp bất kỳ nếu chưa có trong bảng cấu hình
 */
function resolveSupplierPrefix(supplierName) {
  const cleanName = (supplierName || '').trim();
  if (SUPPLIER_ABBR_MAP[cleanName]) {
    return SUPPLIER_ABBR_MAP[cleanName].abbr;
  }

  const latinWords = toLatinAscii(cleanName).toUpperCase().split(' ').filter(Boolean);
  if (latinWords.length === 0) return 'SP';

  // Nếu tên có tiếng Việt hoặc nhiều hơn 1 từ -> lấy chữ cái đầu của từng từ (VD: "Hoàng Hà" -> "HH", "Vĩnh Thắng" -> "VT")
  if (hasVietnameseChars(cleanName) || latinWords.length > 1) {
    return latinWords.map((w) => w[0]).join('');
  }

  // Nếu là 1 từ Latin đơn (VD: "Nice", "Takao", "Toko") -> giữ nguyên chữ in hoa
  return latinWords[0];
}

function formatSku(prefix, stt) {
  const numStr = SKU_FORMAT_CONFIG.padLength > 0
    ? String(stt).padStart(SKU_FORMAT_CONFIG.padLength, '0')
    : String(stt);
  return `${prefix}${SKU_FORMAT_CONFIG.separator}${numStr}`;
}

// ============================================================================
// 3. ĐỌC DỮ LIỆU HIỆN TẠI TỪ POSTGRESQL HOẶC API
// ============================================================================
function fetchProductsFromPostgres() {
  const sqlQuery = `
    SELECT p."Id", p."Sku", p."Name", p."SupplierId", COALESCE(s."Code", '') AS "SupplierCode", COALESCE(s."Name", '') AS "SupplierName"
    FROM "Products" p
    LEFT JOIN "Suppliers" s ON p."SupplierId" = s."Id"
    ORDER BY p."SupplierId" ASC NULLS LAST, p."Id" ASC;
  `;
  const cmd = `docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -t -A -F "|"`;
  const rawOut = execSync(cmd, {
    input: sqlQuery,
    encoding: 'utf8',
    stdio: ['pipe', 'pipe', 'pipe'],
  });

  const rows = [];
  for (const line of rawOut.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const [idStr, sku, name, supplierIdStr, supplierCode, supplierName] = trimmed.split('|');
    rows.push({
      id: parseInt(idStr, 10),
      oldSku: sku,
      name: name,
      supplierId: supplierIdStr ? parseInt(supplierIdStr, 10) : null,
      supplierCode: supplierCode,
      supplierName: supplierName,
    });
  }
  return rows;
}

// ============================================================================
// 4. TÍNH TOÁN MÃ SKU MỚI & SINH FILE SQL
// ============================================================================
function buildSkuUpdatePlan(products) {
  const countersByPrefix = new Map();
  const updates = [];

  for (const prod of products) {
    const prefix = resolveSupplierPrefix(prod.supplierName);
    const nextStt = (countersByPrefix.get(prefix) || 0) + 1;
    countersByPrefix.set(prefix, nextStt);

    const newSku = formatSku(prefix, nextStt);
    updates.push({
      ...prod,
      prefix,
      stt: nextStt,
      newSku,
    });
  }

  return updates;
}

function generateSqlScript(updates, outPath) {
  let sql = `-- update_product_skus.sql
-- Script cập nhật mã sản phẩm (SKU) theo cấu trúc: [Tên viết tắt NCC chữ Latin] + [STT]
-- Tự động sinh bởi update-product-skus.js
-- LƯU Ý: Giữ nguyên Products.Name (tên sản phẩm gốc), chỉ cập nhật cột Sku.

BEGIN;

-- Bước 1: Gán SKU tạm thời để tránh xung đột UNIQUE INDEX ("IX_Products_Sku") trong quá trình cập nhật hàng loạt
`;

  for (const item of updates) {
    sql += `UPDATE "Products" SET "Sku" = '__TMP_SKU_${item.id}__' WHERE "Id" = ${item.id};\n`;
  }

  sql += `\n-- Bước 2: Cập nhật SKU chính thức theo từng Nhà cung cấp và STT\n`;

  let currentSupplier = null;
  for (const item of updates) {
    if (item.supplierName !== currentSupplier) {
      currentSupplier = item.supplierName;
      sql += `\n-- >>> Nhà cung cấp: ${currentSupplier || 'Chưa phân loại'} (Prefix: ${item.prefix})\n`;
    }
    const escapedNewSku = item.newSku.replace(/'/g, "''");
    const commentOldSku = item.oldSku.replace(/\r?\n/g, ' ');
    sql += `UPDATE "Products" SET "Sku" = '${escapedNewSku}', "UpdatedAt" = NOW() WHERE "Id" = ${item.id}; -- Cũ: ${commentOldSku}\n`;
  }

  sql += `
-- Bước 3: Đồng bộ lại cột Sku lưu trữ trong bảng ImportVoucherItems (nếu có phiếu nhập)
UPDATE "ImportVoucherItems" ivi
SET "Sku" = p."Sku"
FROM "Products" p
WHERE ivi."ProductId" = p."Id" AND ivi."Sku" <> p."Sku";

COMMIT;
`;

  fs.writeFileSync(outPath, sql, 'utf8');
}

// ============================================================================
// 5. HÀM CHÍNH
// ============================================================================
async function main() {
  const isDryRun = process.argv.includes('--dry-run');
  const isSqlOnly = process.argv.includes('--sql');
  const isDirectDb = process.argv.includes('--direct-db');
  const isApi = process.argv.includes('--api');

  if (!isDryRun && !isSqlOnly && !isDirectDb && !isApi) {
    console.log('Vui lòng chọn một trong các chế độ chạy:');
    console.log('  node update-product-skus.js --dry-run    (Xem trước kết quả, không sửa DB)');
    console.log('  node update-product-skus.js --sql        (Xuất file update_product_skus.sql)');
    console.log('  node update-product-skus.js --direct-db  (Cập nhật trực tiếp vào DB qua Docker)');
    console.log('  node update-product-skus.js --api        (Cập nhật qua REST API)');
    return;
  }

  const products = fetchProductsFromPostgres();
  const updates = buildSkuUpdatePlan(products);

  console.log('=========================================================================');
  console.log('       THỐNG KÊ KẾ HOẠCH CẬP NHẬT MÃ SẢN PHẨM (SKU) THEO NCC + STT');
  console.log('=========================================================================');
  console.log(`Tổng số sản phẩm: ${updates.length}\n`);

  // Nhóm theo NCC để in báo cáo
  const grouped = new Map();
  for (const u of updates) {
    const key = u.supplierName || 'Khác';
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(u);
  }

  for (const [suppName, items] of grouped.entries()) {
    const first = items[0];
    const last = items[items.length - 1];
    console.log(
      `• ${suppName.padEnd(15)} | Viết tắt: ${first.prefix.padEnd(6)} | Số SP: ${String(items.length).padStart(3)} | Dải mã: ${first.newSku} -> ${last.newSku} (VD: "${first.oldSku}" -> "${first.newSku}")`
    );
  }

  if (isSqlOnly || isDirectDb) {
    generateSqlScript(updates, SQL_OUTPUT_PATH);
    console.log(`\n✓ Đã xuất file SQL tại: ${SQL_OUTPUT_PATH}`);
  }

  if (isDryRun || isSqlOnly) {
    console.log('\n[HOÀN TẤT CHẾ ĐỘ XEM TRƯỚC] Chưa có thay đổi nào được ghi vào Database.');
    return;
  }

  if (isDirectDb) {
    console.log('\nĐang thực thi cập nhật trực tiếp vào PostgreSQL container (debtmanager_db)...');
    const sqlContent = fs.readFileSync(SQL_OUTPUT_PATH, 'utf8');
    execSync('docker exec -i debtmanager_db psql -U postgres -d debtmanager_db', {
      input: sqlContent,
      stdio: ['pipe', 'inherit', 'inherit'],
    });
    console.log('✓ Hoàn tất cập nhật mã sản phẩm (SKU) trong Database!');
  }
}

main().catch((err) => {
  console.error('Lỗi:', err.message);
  process.exit(1);
});

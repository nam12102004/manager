// month11/import_customers_t11.js
// Script đọc file Excel và nhập dữ liệu Khách hàng từ Sheet "T11,2026" vào Database.
//
// Yêu cầu:
//   - Cột B làm mã KH (Code) - tự sinh mã KH_T11_Rxxx nếu rỗng để đảm bảo tính duy nhất.
//   - Cột C làm tên KH (Name).
//   - Cột D (Nợ ĐK), Cột E (Có ĐK) vào công nợ (Debt = Nợ ĐK - Có ĐK) cho Kho 2 (warehouse2).
//   - Tuyến bán hàng làm địa điểm (Region) - gán khách hàng tương ứng theo tuyến trong Excel.
//   - Chỉ thêm các cột chỉ định theo yêu cầu.
//
// Cách sử dụng:
//   node month11/import_customers_t11.js --dry-run    (Kiểm tra số liệu, không ghi DB)
//   node month11/import_customers_t11.js --sql        (Tạo / cập nhật file SQL import_customers_t11.sql)
//   node month11/import_customers_t11.js --direct-db  (Thực thi file SQL vào Docker Postgres debtmanager_db)
//   node month11/import_customers_t11.js --api        (Nhập dữ liệu qua REST API backend localhost:5050)

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { execSync } = require('child_process');

const API_BASE = process.env.API_BASE || 'http://localhost:5050/api';

// Các đường dẫn file Excel khả dĩ (ưu tiên file trong thư mục month11)
const POSSIBLE_EXCEL_PATHS = [
  process.argv.find((arg) => arg.endsWith('.xlsx')),
  path.join(__dirname, 'cong_no_kho2_t11.xlsx'),
  'C:/Users/Admin/.gemini/antigravity/brain/dfe12d50-4d24-47d6-89c1-b273fc44ed48/.user_uploaded/media_1794027516559_dd882f0c.xlsx',
  path.join(__dirname, '..', 'TK_T11.2026.xlsx'),
].filter(Boolean);

const EXCEL_FILE = POSSIBLE_EXCEL_PATHS.find((p) => fs.existsSync(p));

if (!EXCEL_FILE) {
  console.error('❌ Không tìm thấy file Excel hợp lệ. Vui lòng truyền đường dẫn file .xlsx!');
  process.exit(1);
}

// ============================================================================
// 1. Trình đọc file .xlsx (ZIP + XML) thuần Node.js
// ============================================================================
function readZipEntries(filePath) {
  const buf = fs.readFileSync(filePath);
  let eocdOffset = -1;
  for (let i = buf.length - 22; i >= Math.max(0, buf.length - 65557); i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) {
      eocdOffset = i;
      break;
    }
  }
  if (eocdOffset === -1) throw new Error('File không đúng định dạng ZIP/XLSX.');

  const cdCount = buf.readUInt16LE(eocdOffset + 10);
  const cdOffset = buf.readUInt32LE(eocdOffset + 16);

  const entries = new Map();
  let pos = cdOffset;
  for (let i = 0; i < cdCount; i++) {
    if (buf.readUInt32LE(pos) !== 0x02014b50) break;
    const compression = buf.readUInt16LE(pos + 10);
    const compressedSize = buf.readUInt32LE(pos + 20);
    const uncompressedSize = buf.readUInt32LE(pos + 24);
    const nameLen = buf.readUInt16LE(pos + 28);
    const extraLen = buf.readUInt16LE(pos + 30);
    const commentLen = buf.readUInt16LE(pos + 32);
    const localHeaderOffset = buf.readUInt32LE(pos + 42);

    const name = buf.toString('utf8', pos + 46, pos + 46 + nameLen);
    entries.set(name, {
      compression,
      compressedSize,
      uncompressedSize,
      localHeaderOffset,
    });
    pos += 46 + nameLen + extraLen + commentLen;
  }

  function readEntry(name) {
    const entry = entries.get(name);
    if (!entry) return null;
    const lh = entry.localHeaderOffset;
    if (buf.readUInt32LE(lh) !== 0x04034b50) throw new Error(`Hỏng local header: ${name}`);
    const fnLen = buf.readUInt16LE(lh + 26);
    const exLen = buf.readUInt16LE(lh + 28);
    const dataStart = lh + 30 + fnLen + exLen;
    const compressedData = buf.subarray(dataStart, dataStart + entry.compressedSize);

    if (entry.compression === 0) return compressedData;
    if (entry.compression === 8) return zlib.inflateRawSync(compressedData);
    throw new Error(`Kiểu nén không hỗ trợ: ${entry.compression}`);
  }

  return { entries, readEntry };
}

function parseCellRef(ref) {
  const m = ref.match(/^([A-Z]+)([0-9]+)$/);
  if (!m) return [0, 0];
  let col = 0;
  for (let i = 0; i < m[1].length; i++) {
    col = col * 26 + (m[1].charCodeAt(i) - 64);
  }
  return [col, parseInt(m[2], 10)];
}

function parseNum(val) {
  if (!val) return 0;
  const n = parseFloat(String(val).replace(/,/g, '').trim());
  return isNaN(n) ? 0 : n;
}

// ============================================================================
// 2. Trích xuất danh sách khách hàng từ Sheet T11,2026
// ============================================================================
function extractT11Customers() {
  const zip = readZipEntries(EXCEL_FILE);

  // 1. Shared Strings
  const ss = [];
  const ssXml = zip.readEntry('xl/sharedStrings.xml');
  if (ssXml) {
    const ssStr = ssXml.toString('utf8');
    const regex = /<si>(.*?)<\/si>/gs;
    let match;
    while ((match = regex.exec(ssStr)) !== null) {
      const tMatch = match[1].match(/<t[^>]*>(.*?)<\/t>/gs) || [];
      const text = tMatch
        .map((t) => t.replace(/<[^>]+>/g, ''))
        .join('')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&apos;/g, "'");
      ss.push(text);
    }
  }

  // 2. Workbook to find sheet T11,2026
  const wbXml = zip.readEntry('xl/workbook.xml').toString('utf8');
  const relsXml = zip.readEntry('xl/_rels/workbook.xml.rels').toString('utf8');

  const relMap = new Map();
  const relRegex = /<Relationship[^>]+Id="([^"]+)"[^>]+Target="([^"]+)"/g;
  let relMatch;
  while ((relMatch = relRegex.exec(relsXml)) !== null) {
    relMap.set(relMatch[1], relMatch[2]);
  }

  let sheetPath = null;
  const sheetRegex = /<sheet[^>]+name="([^"]+)"[^>]+sheetId="([^"]+)"[^>]+r:id="([^"]+)"/g;
  let sMatch;
  while ((sMatch = sheetRegex.exec(wbXml)) !== null) {
    const name = sMatch[1];
    const rId = sMatch[3];
    if (name.includes('T11') || name.includes('11')) {
      const target = relMap.get(rId);
      sheetPath = target.startsWith('xl/') ? target : `xl/${target}`;
      break;
    }
  }

  if (!sheetPath) {
    sheetPath = 'xl/worksheets/sheet2.xml';
  }

  const sheetXml = zip.readEntry(sheetPath).toString('utf8');

  // Parse rows
  const rows = new Map();
  const rowRegex = /<row[^>]+r="([0-9]+)"[^>]*>(.*?)<\/row>/gs;
  let rMatch;
  while ((rMatch = rowRegex.exec(sheetXml)) !== null) {
    const rowNum = parseInt(rMatch[1], 10);
    const rowBody = rMatch[2];
    const cells = new Map();

    const cellRegex = /<c[^>]+r="([A-Z0-9]+)"(?:[^>]+t="([^"]*)")?[^>]*>(?:<v>([^<]*)<\/v>)?/gs;
    let cMatch;
    while ((cMatch = cellRegex.exec(rowBody)) !== null) {
      const cellRef = cMatch[1];
      const cellType = cMatch[2];
      const val = cMatch[3];
      const [col] = parseCellRef(cellRef);
      let textVal = '';
      if (val !== undefined) {
        textVal = cellType === 's' ? ss[parseInt(val, 10)] || '' : val;
      }
      cells.set(col, textVal);
    }
    rows.set(rowNum, cells);
  }

  let currentRoute = '';
  const rawCustomers = [];

  const sortedRowNums = Array.from(rows.keys()).sort((a, b) => a - b);
  for (const rNum of sortedRowNums) {
    if (rNum <= 5) continue;
    const cells = rows.get(rNum);
    const colB = (cells.get(2) || '').trim();
    const colC = (cells.get(3) || '').trim();
    const colD = (cells.get(4) || '').trim();
    const colE = (cells.get(5) || '').trim();

    // Nhận diện Tuyến bán hàng (Địa điểm)
    if (rNum === 6) {
      currentRoute = 'THÀNH PHỐ';
      continue;
    } else if (rNum >= 66 && rNum <= 72) {
      continue;
    } else if (rNum === 73) {
      currentRoute = 'NAM TRỰC - TRỰC NINH - Ý YÊN - VỤ BẢN - XUÂN TRƯỜNG';
      continue;
    } else if (rNum >= 202 && rNum <= 208) {
      continue;
    } else if (rNum === 209) {
      currentRoute = 'GIAO THUỶ - NGHĨA HƯNG - HẢI HẬU';
      continue;
    } else if (rNum === 328 || rNum === 330) {
      continue;
    }

    // Bỏ qua dòng trống hoặc dòng tổng cộng
    if (!colB && !colC) continue;
    if (colC.toLowerCase().includes('cộng tuyến') || colC.toLowerCase().includes('tổng cộng')) continue;

    const noDk = parseNum(colD);
    const coDk = parseNum(colE);
    const debt = noDk - coDk;

    rawCustomers.push({
      row: rNum,
      codeRaw: colB,
      name: colC,
      route: currentRoute,
      noDk,
      coDk,
      debt,
    });
  }

  // Đảm bảo Mã KH duy nhất và không bị rỗng
  const seenCodes = new Map();
  const customers = [];

  for (const c of rawCustomers) {
    let code = c.codeRaw;
    if (!code) {
      code = `KH_T11_R${String(c.row).padStart(3, '0')}`;
    } else if (seenCodes.has(code)) {
      const count = seenCodes.get(code) + 1;
      seenCodes.set(code, count);
      code = `${code}_${count}`;
    } else {
      seenCodes.set(code, 1);
    }

    customers.push({
      row: c.row,
      code,
      codeOrig: c.codeRaw,
      name: c.name,
      route: c.route,
      noDk: c.noDk,
      coDk: c.coDk,
      debt: c.debt,
    });
  }

  return customers;
}

// ============================================================================
// 3. Xuất file SQL
// ============================================================================
function generateSqlFile(customers) {
  const outPath = path.join(__dirname, 'import_customers_t11.sql');

  function escapeSql(val) {
    if (val === null || val === undefined) return 'NULL';
    return "'" + String(val).replace(/'/g, "''") + "'";
  }

  const lines = [];
  lines.push('-- =====================================================================');
  lines.push('-- Script: import_customers_t11.sql');
  lines.push('-- Mục đích: Nhập danh sách khách hàng từ Sheet T11,2026 (File Excel Kho 2)');
  lines.push('-- Yêu cầu:');
  lines.push('--   - Cột B làm mã KH (Code)');
  lines.push('--   - Cột C làm tên KH (Name)');
  lines.push('--   - Cột D (Nợ ĐK), Cột E (Có ĐK) vào công nợ (Debt = Nợ ĐK - Có ĐK)');
  lines.push('--   - Tuyến bán hàng làm địa điểm (Region - gán theo tuyến trong Excel)');
  lines.push('--   - Chỉ thêm các cột chỉ định theo yêu cầu');
  lines.push('-- =====================================================================\n');
  lines.push("SET client_encoding = 'UTF8';\n");
  lines.push('BEGIN;\n');
  lines.push('CREATE TEMP TABLE temp_customers_t11 (');
  lines.push('    row_num INT,');
  lines.push('    code VARCHAR(50),');
  lines.push('    name VARCHAR(255),');
  lines.push('    debt NUMERIC(18, 2),');
  lines.push('    region VARCHAR(100)');
  lines.push(') ON COMMIT DROP;\n');

  lines.push('INSERT INTO temp_customers_t11 (row_num, code, name, debt, region) VALUES');
  const valuesSql = customers
    .map(
      (c) =>
        `    (${c.row}, ${escapeSql(c.code)}, ${escapeSql(c.name)}, ${c.debt.toFixed(2)}, ${escapeSql(c.route)})`
    )
    .join(',\n');
  lines.push(valuesSql + ';\n');

  lines.push('-- 1. Chèn hoặc Cập nhật vào bảng Customers (chỉ các cột chỉ định: Code, Name, Debt, Region)');
  lines.push('INSERT INTO "Customers" ("Code", "Name", "Debt", "CreditLimit", "Region", "CreatedAt", "UpdatedAt")');
  lines.push('SELECT ');
  lines.push('    t.code,');
  lines.push('    t.name,');
  lines.push('    t.debt,');
  lines.push('    0,');
  lines.push('    t.region,');
  lines.push('    NOW(),');
  lines.push('    NOW()');
  lines.push('FROM temp_customers_t11 t');
  lines.push('ON CONFLICT ("Code") DO UPDATE SET');
  lines.push('    "Name" = EXCLUDED."Name",');
  lines.push('    "Debt" = EXCLUDED."Debt",');
  lines.push('    "Region" = EXCLUDED."Region",');
  lines.push('    "UpdatedAt" = NOW();\n');

  lines.push('-- 2. Cập nhật bảng công nợ theo kho: CustomerWarehouseDebts (cho Kho 2 - warehouse2)');
  lines.push('INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")');
  lines.push('SELECT ');
  lines.push('    c."Id",');
  lines.push("    'warehouse2',");
  lines.push('    t.debt,');
  lines.push('    NOW()');
  lines.push('FROM temp_customers_t11 t');
  lines.push('JOIN "Customers" c ON c."Code" = t.code');
  lines.push('ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET');
  lines.push('    "Debt" = EXCLUDED."Debt",');
  lines.push('    "UpdatedAt" = NOW();\n');

  lines.push('-- 3. Ghi nhận sổ công nợ ban đầu: CustomerDebtHistories (nếu chưa có bản ghi init)');
  lines.push('INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")');
  lines.push('SELECT ');
  lines.push('    c."Id",');
  lines.push("    'warehouse2',");
  lines.push("    'init',");
  lines.push("    'Khởi tạo công nợ đầu kỳ T11/2026 từ Excel',");
  lines.push('    0,');
  lines.push('    t.debt,');
  lines.push('    t.debt,');
  lines.push('    NOW()');
  lines.push('FROM temp_customers_t11 t');
  lines.push('JOIN "Customers" c ON c."Code" = t.code');
  lines.push('WHERE NOT EXISTS (');
  lines.push('    SELECT 1 FROM "CustomerDebtHistories" h ');
  lines.push("    WHERE h.\"CustomerId\" = c.\"Id\" AND h.\"SourceType\" = 'init' AND h.\"Warehouse\" = 'warehouse2'");
  lines.push(');\n');

  lines.push('COMMIT;\n');
  lines.push('-- Thống kê kiểm tra:');
  lines.push('-- SELECT "Region", COUNT(*) AS "SoLuongKH", SUM("Debt") AS "TongCongNo" FROM "Customers" GROUP BY "Region" ORDER BY "Region";');

  fs.writeFileSync(outPath, lines.join('\n'), 'utf8');
  console.log(`✅ Đã tạo file SQL thành công tại: ${outPath}`);
  return outPath;
}

// ============================================================================
// 4. Chạy trực tiếp vào Docker Postgres Container
// ============================================================================
function runDirectDb(sqlFile) {
  console.log('🔄 Đang thực thi file SQL vào Docker container debtmanager_db...');
  try {
    execSync(`docker cp "${sqlFile}" debtmanager_db:/tmp/import_customers_t11.sql`, { stdio: 'inherit' });
    execSync(`docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/import_customers_t11.sql`, {
      stdio: 'inherit',
    });
    console.log('✅ Đã nạp thành công toàn bộ dữ liệu vào PostgreSQL!');
  } catch (err) {
    console.error('❌ Lỗi khi thực thi lệnh psql trong Docker:', err.message);
  }
}

// ============================================================================
// 5. Chạy qua REST API Backend
// ============================================================================
async function runApiImport(customers) {
  console.log(`🔄 Đang gọi REST API (${API_BASE}/customers) để thêm/cập nhật ${customers.length} khách hàng...`);
  let success = 0;
  let failed = 0;

  for (const c of customers) {
    const payload = {
      code: c.code,
      name: c.name,
      region: c.route,
      initialDebt: c.debt,
      initialDebtWarehouse: 'warehouse2',
    };
    try {
      const res = await fetch(`${API_BASE}/customers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (res.ok) {
        success++;
      } else {
        failed++;
      }
    } catch {
      failed++;
    }
  }
  console.log(`✅ Kết quả import qua API: Thành công ${success}, Lỗi ${failed}.`);
}

// ============================================================================
// MAIN
// ============================================================================
async function main() {
  console.log('======================================================================');
  console.log(' BỘ TOOL IMPORT KHÁCH HÀNG & CÔNG NỢ TỪ SHEET T11,2026 VÀO DATABASE');
  console.log('======================================================================');
  console.log(`📂 Nguồn Excel: ${EXCEL_FILE}\n`);

  const customers = extractT11Customers();

  // Thống kê theo tuyến
  const byRoute = {};
  let totalNo = 0;
  let totalCo = 0;
  for (const c of customers) {
    if (!byRoute[c.route]) byRoute[c.route] = { count: 0, no: 0, co: 0, debt: 0 };
    byRoute[c.route].count++;
    byRoute[c.route].no += c.noDk;
    byRoute[c.route].co += c.coDk;
    byRoute[c.route].debt += c.debt;
    totalNo += c.noDk;
    totalCo += c.coDk;
  }

  console.log(`📊 Đã trích xuất thành công ${customers.length} khách hàng:`);
  for (const [r, stat] of Object.entries(byRoute)) {
    console.log(`  📍 Tuyến: ${r}`);
    console.log(`     - Số lượng KH: ${stat.count}`);
    console.log(`     - Nợ ĐK (Cột D): ${stat.no.toLocaleString('vi-VN')} đ`);
    console.log(`     - Có ĐK (Cột E): ${stat.co.toLocaleString('vi-VN')} đ`);
    console.log(`     - Công nợ ròng : ${stat.debt.toLocaleString('vi-VN')} đ`);
  }
  console.log('----------------------------------------------------------------------');
  console.log(`⭐ TỔNG CỘNG NỢ ĐK (Cột D): ${totalNo.toLocaleString('vi-VN')} đ (Khớp Excel: 2.164.483.650 đ)`);
  console.log(`⭐ TỔNG CỘNG CÓ ĐK (Cột E): ${totalCo.toLocaleString('vi-VN')} đ (Khớp Excel:   122.623.820 đ)`);
  console.log(`⭐ CÔNG NỢ RÒNG (Debt):    ${(totalNo - totalCo).toLocaleString('vi-VN')} đ`);
  console.log('======================================================================\n');

  const args = process.argv.slice(2);
  const sqlFile = generateSqlFile(customers);

  if (args.includes('--direct-db')) {
    runDirectDb(sqlFile);
  } else if (args.includes('--api')) {
    await runApiImport(customers);
  } else if (args.includes('--dry-run')) {
    console.log('ℹ️  Đang ở chế độ --dry-run (chỉ xem trước, không ghi DB).');
  } else {
    console.log('💡 Hướng dẫn chạy:');
    console.log('  1. Nạp thẳng vào DB: node month11/import_customers_t11.js --direct-db');
    console.log('  2. Chạy qua Batch  : click chạy month11/run_import.bat');
    console.log('  3. Nạp qua REST API: node month11/import_customers_t11.js --api');
  }
}

main().catch(console.error);

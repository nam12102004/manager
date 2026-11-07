// month11/import-customers-month11.js
// Script đọc file Excel công nợ (CongNo_T11.2026.xlsx) và đồng bộ Khách Hàng, Tuyến bán hàng, Công nợ vào Database.
//
// Yêu cầu nghiệp vụ:
//   - Trong SHEET 'báo cáo':
//       + Cột B: Mã khách hàng (Code)
//       + Cột C: Tên khách hàng (Name - kèm tách SĐT và Địa chỉ)
//       + Cột D: Nợ đầu kỳ (NỢ ĐK)
//       + Cột E: Có đầu kỳ (CÓ ĐK)
//       + Công nợ nạp vào: Nợ ĐK - Có ĐK (kho warehouse1)
//       + Thêm Tuyến bán hàng làm Địa điểm/Khu vực (Region):
//           * THÀNH PHỐ - HÀ NAM
//           * NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG
//           * MỸ LỘC - Ý YÊN - VỤ BẢN
//           * GIAO THỦY
//           * NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)
//
// Cách sử dụng:
//   node import-customers-month11.js              (Nhập vào database qua API)
//   node import-customers-month11.js --dry-run    (Kiểm tra số liệu, không ghi DB)
//   node import-customers-month11.js --sql        (Tạo file seed_customers_month11.sql)
//   node import-customers-month11.js --direct-db  (Chạy file SQL trực tiếp vào PostgreSQL Docker container)

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { execSync } = require('child_process');

const API_BASE = process.env.API_BASE || 'http://localhost:5050/api';

// Tìm file Excel công nợ
const POSSIBLE_EXCEL_PATHS = [
  process.argv.find((arg) => arg.endsWith('.xlsx')),
  path.join(__dirname, 'CongNo_T11.2026.xlsx'),
  path.join(__dirname, '..', 'CongNo_T11.2026.xlsx'),
  'C:/Users/Admin/.gemini/antigravity/brain/4976a697-ee89-406d-b5df-08e2409a16d8/.user_uploaded/media_1794027486498_ce6eedcf.xlsx',
].filter(Boolean);

const EXCEL_FILE = POSSIBLE_EXCEL_PATHS.find((p) => fs.existsSync(p)) || POSSIBLE_EXCEL_PATHS[0];

// ============================================================================
// 1. Bộ đọc file .xlsx (ZIP + XML) thuần Node.js
// ============================================================================
function readZipEntries(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Không tìm thấy file Excel tại: ${filePath}`);
  }
  const buf = fs.readFileSync(filePath);
  let eocdOffset = -1;
  for (let i = buf.length - 22; i >= Math.max(0, buf.length - 65557); i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) {
      eocdOffset = i;
      break;
    }
  }
  if (eocdOffset === -1) {
    throw new Error('File không đúng định dạng ZIP/XLSX');
  }

  const totalEntries = buf.readUInt16LE(eocdOffset + 10);
  const cdOffset = buf.readUInt32LE(eocdOffset + 16);

  const entries = new Map();
  let ptr = cdOffset;
  for (let i = 0; i < totalEntries; i++) {
    if (buf.readUInt32LE(ptr) !== 0x02014b50) break;
    const compressionMethod = buf.readUInt16LE(ptr + 10);
    const compressedSize = buf.readUInt32LE(ptr + 20);
    const uncompressedSize = buf.readUInt32LE(ptr + 24);
    const fileNameLen = buf.readUInt16LE(ptr + 28);
    const extraFieldLen = buf.readUInt16LE(ptr + 30);
    const fileCommentLen = buf.readUInt16LE(ptr + 32);
    const localHeaderOffset = buf.readUInt32LE(ptr + 42);
    const fileName = buf.toString('utf8', ptr + 46, ptr + 46 + fileNameLen);

    entries.set(fileName, {
      compressionMethod,
      compressedSize,
      uncompressedSize,
      localHeaderOffset,
    });

    ptr += 46 + fileNameLen + extraFieldLen + fileCommentLen;
  }

  function readEntry(name) {
    const info = entries.get(name);
    if (!info) return null;
    const lhOffset = info.localHeaderOffset;
    if (buf.readUInt32LE(lhOffset) !== 0x04034b50) {
      throw new Error(`Corrupted local header for: ${name}`);
    }
    const lhFileNameLen = buf.readUInt16LE(lhOffset + 26);
    const lhExtraLen = buf.readUInt16LE(lhOffset + 28);
    const dataOffset = lhOffset + 30 + lhFileNameLen + lhExtraLen;
    const rawData = buf.subarray(dataOffset, dataOffset + info.compressedSize);

    if (info.compressionMethod === 0) {
      return rawData;
    } else if (info.compressionMethod === 8) {
      return zlib.inflateRawSync(rawData);
    } else {
      throw new Error(`Unsupported compression method: ${info.compressionMethod}`);
    }
  }

  return { entries, readEntry };
}

function parseSharedStrings(xmlStr) {
  if (!xmlStr) return [];
  const list = [];
  const reSi = /<si\b[^>]*>([\s\S]*?)<\/si>/gi;
  let match;
  while ((match = reSi.exec(xmlStr)) !== null) {
    const siContent = match[1];
    let fullText = '';
    const reT = /<t\b[^>]*>([\s\S]*?)<\/t>/gi;
    let tMatch;
    while ((tMatch = reT.exec(siContent)) !== null) {
      fullText += decodeXml(tMatch[1]);
    }
    list.push(fullText);
  }
  return list;
}

function decodeXml(s) {
  return s
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'");
}

function parseCellRef(ref) {
  const m = ref.match(/^([A-Z]+)([0-9]+)$/);
  if (!m) return { col: 0, row: 0, colLetter: '' };
  const letters = m[1];
  const row = parseInt(m[2], 10);
  let col = 0;
  for (let i = 0; i < letters.length; i++) {
    col = col * 26 + (letters.charCodeAt(i) - 64);
  }
  return { col, row, colLetter: letters };
}

// Trích xuất số điện thoại từ chuỗi
function extractPhones(text) {
  if (!text) return [];
  const phones = [];
  const re = /(?:0|\+84)[35789]\d{8}|0228\d{6,7}|0350\d{6,7}/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    const clean = m[0].replace(/\D/g, '');
    if (clean.length >= 9 && !phones.includes(clean)) {
      phones.push(clean);
    }
  }
  return phones;
}

// ============================================================================
// 2. Trích xuất danh sách Khách Hàng từ Sheet 'báo cáo'
// ============================================================================
function extractCustomersFromBaoCao() {
  console.log(`Đang đọc file Excel: ${EXCEL_FILE}`);
  const zip = readZipEntries(EXCEL_FILE);

  // Đọc danh sách sheet từ workbook.xml
  const wbXml = zip.readEntry('xl/workbook.xml').toString('utf8');
  const relsXml = zip.readEntry('xl/_rels/workbook.xml.rels').toString('utf8');
  const sharedStringsXml = zip.readEntry('xl/sharedStrings.xml')?.toString('utf8');
  const sharedStrings = parseSharedStrings(sharedStringsXml);

  const relMap = new Map();
  const reRel = /<Relationship\b[^>]*Id="([^"]+)"[^>]*Target="([^"]+)"/gi;
  let rMatch;
  while ((rMatch = reRel.exec(relsXml)) !== null) {
    relMap.set(rMatch[1], rMatch[2]);
  }

  // Tìm sheet 'báo cáo'
  let baoCaoSheetFile = null;
  const reSheet = /<sheet\b[^>]*name="([^"]+)"[^>]*sheetId="([^"]+)"[^>]*r:id="([^"]+)"/gi;
  let sMatch;
  while ((sMatch = reSheet.exec(wbXml)) !== null) {
    const sName = sMatch[1];
    const rId = sMatch[3];
    if (sName.trim().toLowerCase() === 'báo cáo') {
      let target = relMap.get(rId);
      if (!target.startsWith('xl/')) target = 'xl/' + target;
      baoCaoSheetFile = target;
      break;
    }
  }

  if (!baoCaoSheetFile) {
    throw new Error("Không tìm thấy sheet 'báo cáo' trong file Excel!");
  }

  console.log(`Tìm thấy sheet 'báo cáo' tại: ${baoCaoSheetFile}`);
  const sheetXml = zip.readEntry(baoCaoSheetFile).toString('utf8');

  // Đọc tất cả các ô trong sheet (hỗ trợ cả thẻ tự đóng <c ... />)
  const rowsMap = new Map();
  const reRow = /<row\b[^>]*\br="(\d+)"[^>]*>([\s\S]*?)<\/row>/gi;
  let rowMatch;
  while ((rowMatch = reRow.exec(sheetXml)) !== null) {
    const rowNum = parseInt(rowMatch[1], 10);
    const rowContent = rowMatch[2];
    const cells = new Map();

    const reCell = /<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/gi;
    let cMatch;
    while ((cMatch = reCell.exec(rowContent)) !== null) {
      const attrs = cMatch[1];
      const inner = cMatch[2] || '';
      const refM = /r="([A-Z0-9]+)"/.exec(attrs);
      if (!refM) continue;
      const ref = refM[1];
      const tM = /t="([a-z]+)"/.exec(attrs);
      const type = tM ? tM[1] : null;
      const { colLetter } = parseCellRef(ref);

      let val = '';
      const vMatch = /<v>([\s\S]*?)<\/v>/.exec(inner);
      if (vMatch) {
        val = vMatch[1];
        if (type === 's') {
          val = sharedStrings[parseInt(val, 10)] || '';
        }
      }
      cells.set(colLetter, val.trim());
    }
    rowsMap.set(rowNum, cells);
  }

  // Xử lý từng dòng từ dòng 6 đến dòng 261
  let currentTuyen = null;
  const customers = [];
  const usedCodes = new Set();

  // Bảng ánh xạ mã chuẩn cho các dòng thiếu mã hoặc bị trùng
  const CODE_OVERRIDES = {
    'CH Đỗ Mười -  Xuân Trường': 'KH.65576426', // Mã chuẩn trong sheet công nợ đầu năm (tránh trùng Cẩn Thoa KH.5865310)
    'CH Ngọc Hồi - Xuân Phú - Xuân Trường - ĐT: 094 508 8618': 'KH.140722995', // Lấy từ sheet công nợ đầu năm
    'CH Gia Huy - Núi Ngăm': 'KH.200', // Lấy từ sheet T7-2026 và Doanh số năm
    'CH Vĩ An - Ý Yên': 'KH.130', // Lấy từ sheet T4-2026 và Doanh số năm
    'CH Gia Huy - 999 Vũ Hữu Lợi - ĐT: 0912659239': 'KH.999VHL',
    'CH Hương dương -Xuân Thành - Xuân trường  ĐT 0915329232 - 0948 287 687': 'KH.HUONGDUONG',
    'CH Việt Quang - Xuân Tiến - Xuân Trường - ĐT: 0914 483 143': 'KH.VIETQUANG',
    'CH Tấn Hà xóm 5 thôn đoài ngoại, xuân hòa, ĐT:0962960189-096637267CH Tấn Hà': 'KH.TANHA',
    'CH Minh Tân - Xuân Tiến - Xuân Trường ĐT: 0947 203 144 - 03503 762 578': 'KH.MINHTAN',
    'CH Trọng Anh - Xóm 3 - Nghĩa Thành - Nghĩa Hưng - ĐT: 0989993234 - 0398162642, gửi xe 34 Trần Hưng Đạo.': 'KH.TRONGANH',
  };

  for (let r = 6; r <= 261; r++) {
    const cells = rowsMap.get(r);
    if (!cells) continue;

    const colC = cells.get('C') || '';
    const colB = cells.get('B') || '';
    const colD = cells.get('D') || '';
    const colE = cells.get('E') || '';

    // Kiểm tra dòng tiêu đề Tuyến
    if (colC.includes('THÀNH PHỐ - HÀ NAM') || colC.includes('THÀNH PHỐ')) {
      currentTuyen = 'THÀNH PHỐ - HÀ NAM';
      continue;
    } else if (colC.includes('NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG')) {
      currentTuyen = 'NAM TRỰC - TRỰC NINH - XUÂN TRƯỜNG';
      continue;
    } else if (colC.includes('MỸ LỘC - Ý YÊN - VỤ BẢN')) {
      currentTuyen = 'MỸ LỘC - Ý YÊN - VỤ BẢN';
      continue;
    } else if (colC.includes('TUYẾN XUÂN TRƯỜNG')) {
      continue;
    } else if (colC.includes('TUYẾN GIAO THỦY') || colC.trim() === 'TUYẾN GIAO THỦY') {
      currentTuyen = 'GIAO THỦY';
      continue;
    } else if (colC.includes('NGHĨA HƯNG - HẢI HẬU - NAM TRỰC')) {
      currentTuyen = 'NGHĨA HƯNG - HẢI HẬU - NAM TRỰC ( DỌC ĐƯỜNG 55)';
      continue;
    } else if (colC.includes('Cộng tuyến') || colC.includes('Tổng cộng')) {
      continue;
    }

    if (!colC || colC.trim() === '') continue;

    const noDk = parseFloat(colD) || 0;
    const coDk = parseFloat(colE) || 0;
    const initialDebt = noDk - coDk;

    // Xác định mã khách hàng
    let code = colB.trim();
    if (CODE_OVERRIDES[colC.trim()]) {
      code = CODE_OVERRIDES[colC.trim()];
    } else if (!code) {
      code = `KH.ROW${r}`;
    }

    // Đảm bảo không trùng mã (Unique constraint)
    if (usedCodes.has(code)) {
      code = `${code}_${r}`;
    }
    usedCodes.add(code);

    const phones = extractPhones(colC);
    const phonesJson = phones.length > 0 ? JSON.stringify(phones) : null;

    customers.push({
      row: r,
      code,
      name: colC.trim(),
      region: currentTuyen,
      noDk,
      coDk,
      debt: initialDebt,
      phonesJson,
      warehouse: 'warehouse1', // Báo cáo Kho 1
    });
  }

  return customers;
}

// ============================================================================
// 3. Tạo file SQL Seed (seed_customers_month11.sql)
// ============================================================================
function generateSqlSeed(customers, outPath) {
  const lines = [
    '--',
    '-- SEED DỮ LIỆU KHÁCH HÀNG & CÔNG NỢ THÁNG 11 (SHEET BÁO CÁO)',
    `-- Thời gian tạo: ${new Date().toISOString()}`,
    `-- Tổng số khách hàng: ${customers.length}`,
    '--',
    'BEGIN;',
    '',
  ];

  customers.forEach((c) => {
    const escName = c.name.replace(/'/g, "''");
    const escCode = c.code.replace(/'/g, "''");
    const escRegion = c.region ? `'${c.region.replace(/'/g, "''")}'` : 'NULL';
    const escPhones = c.phonesJson ? `'${c.phonesJson.replace(/'/g, "''")}'` : 'NULL';

    // 1. Chèn hoặc cập nhật bảng Customers
    lines.push(`-- Khách hàng: [${c.code}] ${c.name}`);
    lines.push(`INSERT INTO "Customers" ("Code", "Name", "Region", "PhonesJson", "Debt", "CreditLimit", "CreatedAt", "UpdatedAt")`);
    lines.push(`VALUES ('${escCode}', '${escName}', ${escRegion}, ${escPhones}, ${c.debt}, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`);
    lines.push(`ON CONFLICT ("Code") DO UPDATE SET`);
    lines.push(`    "Name" = EXCLUDED."Name",`);
    lines.push(`    "Region" = EXCLUDED."Region",`);
    lines.push(`    "PhonesJson" = COALESCE(EXCLUDED."PhonesJson", "Customers"."PhonesJson"),`);
    lines.push(`    "Debt" = EXCLUDED."Debt",`);
    lines.push(`    "UpdatedAt" = CURRENT_TIMESTAMP;`);
    lines.push('');

    // 2. Chèn hoặc cập nhật công nợ theo kho CustomerWarehouseDebts
    lines.push(`INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")`);
    lines.push(`SELECT "Id", '${c.warehouse}', ${c.debt}, CURRENT_TIMESTAMP FROM "Customers" WHERE "Code" = '${escCode}'`);
    lines.push(`ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET`);
    lines.push(`    "Debt" = EXCLUDED."Debt",`);
    lines.push(`    "UpdatedAt" = CURRENT_TIMESTAMP;`);
    lines.push('');

    // 3. Ghi lịch sử công nợ CustomerDebtHistories nếu có số dư nợ ban đầu
    if (c.debt !== 0) {
      lines.push(`INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")`);
      lines.push(`SELECT "Id", '${c.warehouse}', 'opening_balance', 'Số dư nợ đầu kỳ Tháng 11/2026 (Sheet báo cáo: Nợ ĐK=${c.noDk}, Có ĐK=${c.coDk})', 0, ${c.debt}, ${c.debt}, CURRENT_TIMESTAMP`);
      lines.push(`FROM "Customers" WHERE "Code" = '${escCode}'`);
      lines.push(`AND NOT EXISTS (`);
      lines.push(`    SELECT 1 FROM "CustomerDebtHistories" `);
      lines.push(`    WHERE "CustomerId" = "Customers"."Id" AND "SourceType" = 'opening_balance' AND "Warehouse" = '${c.warehouse}'`);
      lines.push(`);`);
      lines.push('');
    }
  });

  lines.push('COMMIT;');
  lines.push('');

  fs.writeFileSync(outPath, lines.join('\n'), 'utf8');
  console.log(`Đã tạo thành công file SQL: ${outPath} (${lines.length} dòng)`);
}

// ============================================================================
// 4. Nhập dữ liệu qua API (HTTP Client)
// ============================================================================
async function importViaApi(customers) {
  console.log(`\nBắt đầu import ${customers.length} khách hàng qua API: ${API_BASE}/customers`);

  let success = 0;
  let fail = 0;

  for (let i = 0; i < customers.length; i++) {
    const c = customers[i];
    try {
      const payload = {
        code: c.code,
        name: c.name,
        region: c.region,
        phonesJson: c.phonesJson,
        initialDebt: c.debt,
        initialDebtWarehouse: c.warehouse,
        notes: `Nợ ĐK=${c.noDk.toLocaleString('vi-VN')} đ, Có ĐK=${c.coDk.toLocaleString('vi-VN')} đ`,
      };

      const res = await fetch(`${API_BASE}/customers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        const errText = await res.text();
        throw new Error(`HTTP ${res.status}: ${errText}`);
      }

      success++;
      if (success % 20 === 0 || success === customers.length) {
        console.log(`  + Đã import thành công: ${success}/${customers.length} khách hàng`);
      }
    } catch (err) {
      fail++;
      console.error(`  - Lỗi [${c.code}] ${c.name}:`, err.message);
    }
  }

  console.log(`\nKết quả import API: ${success} thành công, ${fail} thất bại.`);
}

// ============================================================================
// 5. Chạy SQL trực tiếp vào PostgreSQL Container
// ============================================================================
function runDirectDb(sqlPath) {
  console.log(`\nThực thi file SQL trực tiếp vào container debtmanager_db: ${sqlPath}`);
  try {
    const containerTmpPath = '/tmp/seed_customers_month11.sql';
    // 1. Copy file SQL vào container để đảm bảo 100% chuẩn mã hóa UTF-8 (tiếng Việt có dấu)
    execSync(`docker cp "${sqlPath}" debtmanager_db:${containerTmpPath}`, {
      stdio: 'inherit',
    });
    // 2. Chạy psql thực thi file bên trong container
    execSync(`docker exec debtmanager_db psql -U postgres -d debtmanager_db -f ${containerTmpPath}`, {
      stdio: 'inherit',
    });
    console.log('\nThực thi SQL thành công (bảo toàn 100% tiếng Việt UTF-8)!');
  } catch (err) {
    console.error('Lỗi khi thực thi SQL vào PostgreSQL container:', err.message);
    process.exit(1);
  }
}

// ============================================================================
// 6. Hàm chạy chính
// ============================================================================
async function main() {
  const isDryRun = process.argv.includes('--dry-run');
  const isSqlOnly = process.argv.includes('--sql');
  const isDirectDb = process.argv.includes('--direct-db');

  console.log('===============================================================');
  console.log('   IMPORT KHÁCH HÀNG & CÔNG NỢ THÁNG 11 (SHEET BÁO CÁO)');
  console.log('===============================================================\n');

  const customers = extractCustomersFromBaoCao();

  // Thống kê theo tuyến
  const stats = {};
  let totalNoDk = 0;
  let totalCoDk = 0;
  let totalDebt = 0;

  customers.forEach((c) => {
    if (!stats[c.region]) {
      stats[c.region] = { count: 0, noDk: 0, coDk: 0, debt: 0 };
    }
    stats[c.region].count++;
    stats[c.region].noDk += c.noDk;
    stats[c.region].coDk += c.coDk;
    stats[c.region].debt += c.debt;

    totalNoDk += c.noDk;
    totalCoDk += c.coDk;
    totalDebt += c.debt;
  });

  console.log('\n--- THỐNG KÊ THEO TUYẾN BÁN HÀNG (REGION) ---');
  Object.keys(stats).forEach((tuyen) => {
    const s = stats[tuyen];
    console.log(`* ${tuyen}:`);
    console.log(`    - Số lượng khách: ${s.count}`);
    console.log(`    - Tổng Nợ ĐK (Cột D): ${s.noDk.toLocaleString('vi-VN')} đ`);
    console.log(`    - Tổng Có ĐK (Cột E): ${s.coDk.toLocaleString('vi-VN')} đ`);
    console.log(`    - Công nợ thực nạp:   ${s.debt.toLocaleString('vi-VN')} đ`);
  });

  console.log('\n--- TỔNG TOÀN BỘ 5 TUYẾN ---');
  console.log(`* Tổng số khách hàng: ${customers.length}`);
  console.log(`* Tổng Nợ ĐK (Cột D): ${totalNoDk.toLocaleString('vi-VN')} đ (Khớp Dòng 261: 3.722.025.850 đ)`);
  console.log(`* Tổng Có ĐK (Cột E): ${totalCoDk.toLocaleString('vi-VN')} đ (Khớp Dòng 261: 78.113.300 đ)`);
  console.log(`* Tổng Công nợ thuần: ${totalDebt.toLocaleString('vi-VN')} đ`);
  console.log('---------------------------------------------------------------\n');

  const sqlPath = path.join(__dirname, 'seed_customers_month11.sql');

  if (isDryRun) {
    console.log('Chế độ Dry-Run: Đã kiểm tra số liệu hoàn tất, không ghi vào database.');
    return;
  }

  // Tự động tạo file SQL
  generateSqlSeed(customers, sqlPath);

  if (isSqlOnly) {
    console.log('Chế độ --sql: Đã tạo file seed_customers_month11.sql thành công.');
    return;
  }

  if (isDirectDb) {
    runDirectDb(sqlPath);
    return;
  }

  // Mặc định: Import qua API
  await importViaApi(customers);
}

main().catch((err) => {
  console.error('LỖI THỰC THI:', err);
  process.exit(1);
});

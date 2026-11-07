// import-excel-products.js
// Script đọc file Excel (TK_T11.2026.xlsx) và đồng bộ Nhà cung cấp, Sản phẩm, Tồn kho theo từng kho vào Database.
//
// Yêu cầu:
//   - Sheet tab làm tên Nhà cung cấp, mã để tên viết tắt chữ cái Latin không dấu (HH, NICE, TAKAO, VT, DMAX, RA, TOKO, AMY).
//   - Cột A làm Loại sản phẩm (Category - kế thừa fill-down theo nhóm).
//   - Cột B làm Tên sản phẩm (Name), còn Mã sản phẩm (SKU) tự động sinh theo cấu trúc: [Mã viết tắt NCC] + [STT 3 chữ số] (VD: HH001, VT001, RA001...).
//   - Cột C làm Tồn kho hiện tại:
//       + Hoàng Hà, Nice, Royal + Ấn Độ  -> Kho 1 (warehouse1)
//       + Toko, Takao, Vĩnh Thắng, Dmax + Mira -> Kho 2 (warehouse2)
//       + Á Mỹ -> Tạm thời tồn kho = 0
//   - Tự động thêm Kho 1 và Kho 2 vào hệ thống nếu chưa có.
//
// Cách sử dụng:
//   node import-excel-products.js              (Nhập dữ liệu vào database qua API)
//   node import-excel-products.js --dry-run    (Chỉ kiểm tra và in thống kê số liệu, không ghi DB)
//   node import-excel-products.js --sql        (Tạo file seed_excel_products.sql để import trực tiếp qua SQL)
//   node import-excel-products.js --direct-db  (Thực thi file SQL trực tiếp vào PostgreSQL docker container)

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { execSync } = require('child_process');

const API_BASE = process.env.API_BASE || 'http://localhost:5050/api';

// Tìm file Excel theo các đường dẫn ưu tiên
const POSSIBLE_EXCEL_PATHS = [
  process.argv.find((arg) => arg.endsWith('.xlsx')),
  path.join(__dirname, 'TK_T11.2026.xlsx'),
  'C:/Users/Admin/.gemini/antigravity/brain/d5e2c8ab-5e72-44f6-ab70-2cf8faacb270/.user_uploaded/media_1794026804926_460a41fa.xlsx',
  path.join(__dirname, 'TK T10.2026.xlsx'),
].filter(Boolean);

const EXCEL_FILE = POSSIBLE_EXCEL_PATHS.find((p) => fs.existsSync(p)) || POSSIBLE_EXCEL_PATHS[0];

// Cấu hình Nhà cung cấp, mã viết tắt và Kho lưu trữ
const SUPPLIER_CONFIGS = [
  { sheet: 'H.HÀ', code: 'HH', name: 'Hoàng Hà', warehouse: 'warehouse1' },
  { sheet: 'NICE', code: 'NICE', name: 'Nice', warehouse: 'warehouse1' },
  { sheet: 'ROYAL+ẤN', code: 'RA', name: 'Royal + Ấn Độ', warehouse: 'warehouse1' },
  { sheet: 'TOKO,', code: 'TOKO', name: 'Toko', warehouse: 'warehouse2' },
  { sheet: 'TAKAO', code: 'TAKAO', name: 'Takao', warehouse: 'warehouse2' },
  { sheet: 'VĨNH THẮNG', code: 'VT', name: 'Vĩnh Thắng', warehouse: 'warehouse2' },
  { sheet: 'DMAX+MIRA', code: 'DMAX', name: 'Dmax + Mira', warehouse: 'warehouse2' },
  { sheet: 'Á Mỹ', code: 'AMY', name: 'Á Mỹ', warehouse: 'none' }, // Toàn bộ tồn kho = 0
];

const CONFIG_MAP = new Map(SUPPLIER_CONFIGS.map((c) => [c.sheet.toUpperCase(), c]));

// ============================================================================
// 1. Bộ đọc file .xlsx (ZIP + XML) thuần Node.js (không cần thêm npm library)
// ============================================================================
function readZipEntries(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Không tìm thấy file Excel tại đường dẫn: ${filePath}`);
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
    const fileNameLen = buf.readUInt16LE(ptr + 28);
    const extraLen = buf.readUInt16LE(ptr + 30);
    const commentLen = buf.readUInt16LE(ptr + 32);
    const localHeaderOffset = buf.readUInt32LE(ptr + 42);
    const fileName = buf.toString('utf8', ptr + 46, ptr + 46 + fileNameLen);

    const localFileNameLen = buf.readUInt16LE(localHeaderOffset + 26);
    const localExtraLen = buf.readUInt16LE(localHeaderOffset + 28);
    const dataStart = localHeaderOffset + 30 + localFileNameLen + localExtraLen;
    const compressedData = buf.subarray(dataStart, dataStart + compressedSize);

    let content;
    if (compressionMethod === 0) {
      content = compressedData;
    } else if (compressionMethod === 8) {
      content = zlib.inflateRawSync(compressedData);
    }
    if (content) {
      entries.set(fileName, content.toString('utf8'));
    }

    ptr += 46 + fileNameLen + extraLen + commentLen;
  }

  return entries;
}

function decodeXmlEntities(str) {
  if (!str) return '';
  return str
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(parseInt(dec, 10)))
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&');
}

function getAttr(tagStr, attrName) {
  const regex = new RegExp(`(?:^|\\s)${attrName}="([^"]*)"`);
  const match = tagStr.match(regex);
  return match ? decodeXmlEntities(match[1]) : null;
}

function normalizeText(str) {
  if (!str) return '';
  return str.replace(/\s+/g, ' ').trim();
}

function parseCellRef(ref) {
  const match = ref.match(/^([A-Z]+)(\d+)$/);
  if (!match) return { col: ref, row: 0 };
  return { col: match[1], row: parseInt(match[2], 10) };
}

// ============================================================================
// 2. Phân tích các sheet trong file Excel theo quy chuẩn người dùng yêu cầu
// ============================================================================
function parseExcelData(filePath) {
  const entries = readZipEntries(filePath);

  // 1. Shared Strings
  const sharedStrings = [];
  const ssXml = entries.get('xl/sharedStrings.xml') || '';
  for (const match of ssXml.matchAll(/<si\b[^>]*>([\s\S]*?)<\/si>/g)) {
    const siBody = match[1];
    let text = '';
    for (const tm of siBody.matchAll(/<t(?:\s[^>]*)?>([\s\S]*?)<\/t>/g)) {
      text += decodeXmlEntities(tm[1]);
    }
    sharedStrings.push(text);
  }

  // 2. Relationship Map
  const relsMap = new Map();
  const relsXml = entries.get('xl/_rels/workbook.xml.rels') || '';
  for (const match of relsXml.matchAll(/<Relationship\b([^>]*?)\/?>/g)) {
    const attrs = match[1];
    const id = getAttr(attrs, 'Id');
    const target = getAttr(attrs, 'Target');
    if (id && target) {
      relsMap.set(id, 'xl/' + target.replace(/^\/+/, ''));
    }
  }

  // 3. Sheets trong workbook.xml
  const wbXml = entries.get('xl/workbook.xml') || '';
  const parsedSheets = [];

  for (const match of wbXml.matchAll(/<sheet\b([^>]*?)\/?>/g)) {
    const attrs = match[1];
    const name = getAttr(attrs, 'name');
    const state = getAttr(attrs, 'state') || 'visible';
    const rId = getAttr(attrs, 'r:id');
    const targetPath = relsMap.get(rId);

    if (state === 'hidden' || state === 'veryHidden') {
      continue;
    }

    const config = CONFIG_MAP.get(name.toUpperCase());
    if (!config || !targetPath) {
      continue;
    }

    const wsXml = entries.get(targetPath) || '';
    const products = [];
    let currentCategory = '';
    let totalStockC = 0;

    for (const rowMatch of wsXml.matchAll(/<row\b([^>]*)>([\s\S]*?)<\/row>/g)) {
      const rowAttrs = rowMatch[1];
      const rowNum = parseInt(getAttr(rowAttrs, 'r') || '0', 10);
      if (rowNum <= 4) continue; // Dòng 1-4 là tiêu đề và tổng cộng

      const rowBody = rowMatch[2];
      const cells = {};

      for (const cellMatch of rowBody.matchAll(/<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)) {
        const cAttrs = cellMatch[1];
        const cBody = cellMatch[2] || '';
        const ref = getAttr(cAttrs, 'r') || '';
        const { col } = parseCellRef(ref);

        if (col !== 'A' && col !== 'B' && col !== 'C') continue;

        const cellType = getAttr(cAttrs, 't') || '';
        let val = '';

        if (cellType === 'inlineStr') {
          const isMatch = cBody.match(/<t(?:\s[^>]*)?>([\s\S]*?)<\/t>/);
          val = isMatch ? decodeXmlEntities(isMatch[1]) : '';
        } else {
          const vMatch = cBody.match(/<v>([\s\S]*?)<\/v>/);
          if (vMatch) {
            const rawVal = decodeXmlEntities(vMatch[1]);
            if (cellType === 's') {
              val = sharedStrings[parseInt(rawVal, 10)] ?? '';
            } else {
              val = rawVal;
            }
          }
        }

        const cleaned = normalizeText(val);
        if (cleaned !== '') {
          cells[col] = cleaned;
        }
      }

      // Cột A: Loại sản phẩm (kế thừa fill-down)
      if (cells.A) {
        currentCategory = cells.A;
      }

      // Cột B: Tên sản phẩm
      if (cells.B) {
        if (['TÊN SP', 'MÃ SP', 'TỔNG CỘNG', 'TỔNG TỒN'].includes(cells.B.toUpperCase())) {
          continue;
        }

        let prodName = cells.B;
        if (/^\d+\.\d{10,}$/.test(prodName)) {
          prodName = parseFloat(prodName).toString();
        }

        // Cột C: Tồn kho hiện tại
        let stockVal = 0;
        if (cells.C) {
          const parsed = parseFloat(cells.C);
          if (!isNaN(parsed)) {
            stockVal = parsed;
          }
        }
        totalStockC += stockVal;

        // Phân bổ tồn kho theo kho
        let stockWarehouse1 = 0;
        let stockWarehouse2 = 0;

        if (config.warehouse === 'warehouse1') {
          stockWarehouse1 = stockVal;
        } else if (config.warehouse === 'warehouse2') {
          stockWarehouse2 = stockVal;
        } else {
          // Á Mỹ: toàn bộ tồn kho để 0
          stockWarehouse1 = 0;
          stockWarehouse2 = 0;
        }

        const totalStock = stockWarehouse1 + stockWarehouse2;
        const stt = products.length + 1;
        const formattedSku = `${config.code}${String(stt).padStart(3, '0')}`;

        products.push({
          row: rowNum,
          sku: formattedSku,
          name: prodName,
          category: currentCategory || null,
          uom: 'Hộp',
          unitCost: 0,
          wholesalePrice: 0,
          retailPrice: 0,
          stockWarehouse1,
          stockWarehouse2,
          stockWarehouse3: 0,
          totalStock,
          rawStockC: stockVal,
        });
      }
    }

    parsedSheets.push({
      sheetName: name,
      supplierName: config.name,
      supplierCode: config.code,
      targetWarehouse: config.warehouse,
      products,
      totalStockC,
    });
  }

  return parsedSheets;
}

// ============================================================================
// 3. Tạo file SQL Seed trực tiếp
// ============================================================================
function generateSqlSeed(sheetsData, outFilePath) {
  let sql = `-- seed_excel_products.sql
-- Tự động sinh bởi import-excel-products.js vào lúc ${new Date().toISOString()}
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

`;

  // 2. Chèn / cập nhật Nhà cung cấp
  sql += `-- 2. Chèn Nhà cung cấp\n`;
  for (const s of sheetsData) {
    const escapedName = s.supplierName.replace(/'/g, "''");
    const escapedCode = s.supplierCode.replace(/'/g, "''");
    const notes = `Nhập từ Sheet "${s.sheetName}"`.replace(/'/g, "''");
    sql += `INSERT INTO "Suppliers" ("Code", "Name", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES ('${escapedCode}', '${escapedName}', 0, 0, '${notes}', NOW(), NOW())
ON CONFLICT ("Code") DO UPDATE SET "Name" = EXCLUDED."Name", "UpdatedAt" = NOW();\n`;
  }

  // 3. Chèn / cập nhật Sản phẩm & Đơn vị tính cơ bản
  sql += `\n-- 3. Chèn Sản phẩm và Đơn vị tính cơ bản\n`;
  for (const s of sheetsData) {
    sql += `\n-- >>> Hãng: ${s.supplierName} (${s.supplierCode}) - Tổng ${s.products.length} SP\n`;
    for (const p of s.products) {
      const escapedSku = p.sku.replace(/'/g, "''");
      const escapedName = p.name.replace(/'/g, "''");
      const escapedCat = p.category ? `'${p.category.replace(/'/g, "''")}'` : 'NULL';
      const escapedCode = s.supplierCode.replace(/'/g, "''");

      sql += `DO $$
DECLARE
    supp_id int;
    prod_id int;
BEGIN
    SELECT "Id" INTO supp_id FROM "Suppliers" WHERE "Code" = '${escapedCode}';

    -- Ưu tiên tìm SP đã có theo (SupplierId + Name) hoặc Sku để cập nhật trực tiếp không bị trùng bản ghi
    SELECT "Id" INTO prod_id FROM "Products"
    WHERE ("SupplierId" = supp_id AND UPPER("Name") = UPPER('${escapedName}'))
       OR "Sku" = '${escapedSku}'
    ORDER BY CASE WHEN "Sku" = '${escapedSku}' THEN 0 ELSE 1 END, "Id" ASC
    LIMIT 1;

    IF prod_id IS NOT NULL THEN
        UPDATE "Products" SET
            "Sku" = '${escapedSku}',
            "Name" = '${escapedName}',
            "Category" = ${escapedCat},
            "SupplierId" = supp_id,
            "StockWarehouse1" = ${p.stockWarehouse1},
            "StockWarehouse2" = ${p.stockWarehouse2},
            "TotalStock" = ${p.totalStock},
            "UpdatedAt" = NOW()
        WHERE "Id" = prod_id;
    ELSE
        INSERT INTO "Products" (
            "Sku", "Name", "Category", "Uom", "SupplierId",
            "UnitCost", "WholesalePrice", "RetailPrice",
            "StockWarehouse1", "StockWarehouse2", "StockWarehouse3",
            "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt"
        ) VALUES (
            '${escapedSku}', '${escapedName}', ${escapedCat}, 'Hộp', supp_id,
            0, 0, 0,
            ${p.stockWarehouse1}, ${p.stockWarehouse2}, 0,
            ${p.totalStock}, 0, NOW(), NOW()
        )
        RETURNING "Id" INTO prod_id;
    END IF;

    -- Đơn vị tính cơ bản (ProductUnits)
    INSERT INTO "ProductUnits" (
        "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
        "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
    ) VALUES (
        prod_id, 'Hộp', 1, true, 0, 0, true, NOW()
    )
    ON CONFLICT DO NOTHING;
END $$;\n`;
    }
  }

  sql += `\nCOMMIT;\n`;
  fs.writeFileSync(outFilePath, sql, 'utf8');
}

// ============================================================================
// 4. Gọi API trực tiếp
// ============================================================================
async function requestApi(apiPath, options = {}) {
  const url = `${API_BASE}${apiPath}`;
  const res = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`HTTP ${res.status} on ${apiPath}: ${errorText}`);
  }
  const json = await res.json();
  return json.data;
}

// ============================================================================
// 5. Hàm chính
// ============================================================================
async function main() {
  const isDryRun = process.argv.includes('--dry-run');
  const isSqlOnly = process.argv.includes('--sql');
  const isDirectDb = process.argv.includes('--direct-db');

  console.log('=========================================================================');
  console.log('      CÔNG CỤ IMPORT SẢN PHẨM & TỒN KHO THEO KHO TỪ FILE EXCEL');
  console.log('=========================================================================');
  console.log(`Đang đọc file: ${EXCEL_FILE}`);

  const sheetsData = parseExcelData(EXCEL_FILE);
  const totalProducts = sheetsData.reduce((sum, s) => sum + s.products.length, 0);

  let totalKho1Stock = 0;
  let totalKho2Stock = 0;
  let totalKho1Items = 0;
  let totalKho2Items = 0;
  let totalAmyItems = 0;

  console.log(`\nĐã nhận diện thành công ${sheetsData.length} Nhà cung cấp với tổng cộng ${totalProducts} sản phẩm:\n`);

  for (const s of sheetsData) {
    const whLabel =
      s.targetWarehouse === 'warehouse1'
        ? 'Kho 1'
        : s.targetWarehouse === 'warehouse2'
        ? 'Kho 2'
        : 'Tồn 0';

    const stockSum = s.products.reduce((acc, p) => acc + p.totalStock, 0);
    const uniqueCats = [...new Set(s.products.map((p) => p.category).filter(Boolean))];

    if (s.targetWarehouse === 'warehouse1') {
      totalKho1Stock += stockSum;
      totalKho1Items += s.products.length;
    } else if (s.targetWarehouse === 'warehouse2') {
      totalKho2Stock += stockSum;
      totalKho2Items += s.products.length;
    } else {
      totalAmyItems += s.products.length;
    }

    console.log(
      `  • [Sheet: ${s.sheetName.padEnd(10)}] -> ${s.supplierName.padEnd(14)} (Mã: ${s.supplierCode.padEnd(6)}) | ${whLabel.padEnd(6)} | Số SP: ${String(s.products.length).padStart(3)} | Loại SP: ${String(uniqueCats.length).padStart(2)} | Tổng tồn: ${stockSum.toLocaleString('vi-VN').padStart(8)}`
    );
  }

  console.log('\n-------------------------------------------------------------------------');
  console.log(`TỔNG KẾT TỒN KHO:`);
  console.log(`  + Kho 1 (Hoàng Hà + Nice + Royal + Ấn Độ) : ${totalKho1Items} SP | ${totalKho1Stock.toLocaleString('vi-VN')} Hộp`);
  console.log(`  + Kho 2 (Toko + Takao + Vĩnh Thắng + Mira + Dmax) : ${totalKho2Items} SP | ${totalKho2Stock.toLocaleString('vi-VN')} Hộp`);
  console.log(`  + Á Mỹ (Tồn kho tạm để 0)                : ${totalAmyItems} SP | 0 Hộp`);
  console.log(`  => TỔNG CỘNG HỆ THỐNG                     : ${totalProducts} SP | ${(totalKho1Stock + totalKho2Stock).toLocaleString('vi-VN')} Hộp`);
  console.log('-------------------------------------------------------------------------');

  // Luôn tạo sẵn file SQL để tham chiếu
  const sqlOutPath = path.join(__dirname, 'seed_excel_products.sql');
  generateSqlSeed(sheetsData, sqlOutPath);
  console.log(`\n✓ Đã tạo file SQL seed: ${sqlOutPath}`);

  if (isDryRun) {
    console.log('\n[DRY-RUN] Chế độ kiểm tra hoàn tất. Không có dữ liệu nào được ghi.');
    return;
  }

  if (isSqlOnly) {
    console.log('\n[SQL ONLY] Đã sinh file SQL thành công. Bạn có thể chạy:');
    console.log(`  Get-Content seed_excel_products.sql | docker exec -i debtmanager_db psql -U postgres -d debtmanager_db`);
    return;
  }

  if (isDirectDb) {
    console.log('\nĐang thực thi SQL trực tiếp vào PostgreSQL container (debtmanager_db)...');
    try {
      const sqlContent = fs.readFileSync(sqlOutPath, 'utf8');
      execSync('docker exec -i debtmanager_db psql -U postgres -d debtmanager_db', {
        input: sqlContent,
        stdio: ['pipe', 'inherit', 'inherit'],
      });
      console.log('✓ Thực thi SQL trực tiếp vào database thành công!');
      return;
    } catch (err) {
      console.error('Không thể thực thi docker command, chuyển sang gọi qua API...', err.message);
    }
  }

  // Chế độ mặc định: Gọi API
  console.log(`\nBắt đầu cập nhật vào cơ sở dữ liệu qua API (${API_BASE})...`);

  // 1. Đảm bảo cấu hình Kho 1 và Kho 2 trong Owners
  try {
    const ownerData = await requestApi('/owners');
    let infoObj = {};
    if (ownerData && ownerData.info) {
      try {
        infoObj = JSON.parse(ownerData.info);
      } catch {
        infoObj = { storeName: ownerData.info };
      }
    }
    const currentWarehouses = infoObj.warehouses || [];
    const hasWh1 = currentWarehouses.some((w) => w.id === 'warehouse1');
    const hasWh2 = currentWarehouses.some((w) => w.id === 'warehouse2');

    if (!hasWh1 || !hasWh2) {
      const updatedWarehouses = [
        { id: 'warehouse1', name: 'Kho 1', shortName: 'Kho 1', color: 'primary' },
        { id: 'warehouse2', name: 'Kho 2', shortName: 'Kho 2', color: 'info' },
        ...currentWarehouses.filter((w) => w.id !== 'warehouse1' && w.id !== 'warehouse2'),
      ];
      infoObj.warehouses = updatedWarehouses;
      await requestApi('/owners', {
        method: 'PUT',
        body: JSON.stringify({ info: JSON.stringify(infoObj) }),
      });
      console.log('✓ Đã cập nhật Kho 1 và Kho 2 vào Cấu hình Cửa hàng');
    } else {
      console.log('✓ Kho 1 và Kho 2 đã có sẵn trong Cấu hình');
    }
  } catch (err) {
    console.warn('  ! Lưu ý khi kiểm tra cấu hình kho:', err.message);
  }

  // 2. Lấy danh sách Nhà cung cấp hiện có
  const existingSuppliers = (await requestApi('/suppliers')) || [];
  const supplierByCode = new Map(existingSuppliers.map((s) => [s.code.trim().toUpperCase(), s]));
  const supplierByName = new Map(existingSuppliers.map((s) => [s.name.trim().toUpperCase(), s]));

  const supplierEntityMap = new Map();

  for (const s of sheetsData) {
    let supp = supplierByCode.get(s.supplierCode.toUpperCase()) || supplierByName.get(s.supplierName.toUpperCase());
    if (!supp) {
      supp = await requestApi('/suppliers', {
        method: 'POST',
        body: JSON.stringify({
          code: s.supplierCode,
          name: s.supplierName,
          creditLimit: 0,
          initialDebt: 0,
          notes: `Nhập từ Sheet "${s.sheetName}" (TK_T11.2026.xlsx)`,
        }),
      });
      console.log(`+ Đã tạo mới NCC: [${supp.code}] ${supp.name} (ID: ${supp.id})`);
    } else {
      console.log(`= Đã có NCC: [${supp.code}] ${supp.name} (ID: ${supp.id})`);
    }
    supplierEntityMap.set(s.supplierCode, supp);
  }

  // 3. Lấy danh sách sản phẩm hiện có
  console.log('\nĐang kiểm tra danh sách sản phẩm hiện có...');
  let existingProducts = [];
  try {
    const paged = await requestApi('/products?page=1&pageSize=2000');
    existingProducts = paged.items || [];
  } catch {
    existingProducts = [];
  }
  const productBySku = new Map(existingProducts.map((p) => [p.sku.trim().toUpperCase(), p]));
  const productBySupplierAndName = new Map(
    existingProducts.map((p) => [`${p.supplierId || 0}::${p.name.trim().toUpperCase()}`, p])
  );

  let createdCount = 0;
  let updatedCount = 0;
  let errorCount = 0;

  console.log('\nBắt đầu import từng sản phẩm...');

  for (const s of sheetsData) {
    const supplier = supplierEntityMap.get(s.supplierCode);
    let sheetCreated = 0;
    let sheetUpdated = 0;

    // Chạy concurrent theo chunk để tối ưu tốc độ
    const CHUNK_SIZE = 15;
    for (let i = 0; i < s.products.length; i += CHUNK_SIZE) {
      const chunk = s.products.slice(i, i + CHUNK_SIZE);
      await Promise.all(
        chunk.map(async (p) => {
          const skuKey = p.sku.trim().toUpperCase();
          const nameKey = `${supplier.id}::${p.name.trim().toUpperCase()}`;
          const existing = productBySku.get(skuKey) || productBySupplierAndName.get(nameKey);

          const payload = {
            sku: p.sku,
            name: p.name,
            category: p.category,
            uom: p.uom,
            supplierId: supplier.id,
            unitCost: 0,
            wholesalePrice: 0,
            retailPrice: 0,
            stockWarehouse1: p.stockWarehouse1,
            stockWarehouse2: p.stockWarehouse2,
            stockWarehouse3: 0,
            reorderPoint: 0,
          };

          try {
            if (existing) {
              await requestApi(`/products/${existing.id}`, {
                method: 'PUT',
                body: JSON.stringify(payload),
              });
              updatedCount++;
              sheetUpdated++;
            } else {
              const created = await requestApi('/products', {
                method: 'POST',
                body: JSON.stringify(payload),
              });
              productBySku.set(skuKey, created);
              createdCount++;
              sheetCreated++;
            }
          } catch (err) {
            errorCount++;
            console.error(`  - Lỗi [SKU: ${p.sku}]: ${err.message}`);
          }
        })
      );
    }

    console.log(
      `  -> Hoàn tất [${s.supplierCode}] ${s.supplierName}: Thêm mới ${sheetCreated} SP, Cập nhật ${sheetUpdated} SP.`
    );
  }

  console.log('\n=========================================================================');
  console.log('✓ HOÀN TẤT ĐỒNG BỘ DỮ LIỆU VÀO DATABASE THÀNH CÔNG!');
  console.log(`- Tổng sản phẩm xử lý   : ${totalProducts}`);
  console.log(`- Sản phẩm tạo mới      : ${createdCount}`);
  console.log(`- Sản phẩm cập nhật     : ${updatedCount}`);
  console.log(`- Sản phẩm lỗi          : ${errorCount}`);
  console.log(`- Tổng tồn Kho 1        : ${totalKho1Stock.toLocaleString('vi-VN')} Hộp (${totalKho1Items} SP)`);
  console.log(`- Tổng tồn Kho 2        : ${totalKho2Stock.toLocaleString('vi-VN')} Hộp (${totalKho2Items} SP)`);
  console.log(`- Tồn Á Mỹ (gán 0)      : 0 Hộp (${totalAmyItems} SP)`);
  console.log('=========================================================================');
}

main().catch((err) => {
  console.error('\nLỗi thực thi:', err.message);
  process.exit(1);
});

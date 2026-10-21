// import-excel-products.js - Script đọc file Excel (TK T10.2026.xlsx) và thêm Nhà cung cấp + Sản phẩm
// Cách chạy:
//   node import-excel-products.js             (chạy thêm vào hệ thống qua API)
//   node import-excel-products.js --dry-run   (chỉ đọc Excel và in thống kê kiểm tra, không gọi API)

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const API_BASE = process.env.API_BASE || 'http://localhost:5050/api';
const EXCEL_FILE = path.join(__dirname, 'TK T10.2026.xlsx');
const EXCLUDED_SHEETS = new Set(['TỔNG HỢP TK', 'TONG CK', 'TỔNG CK', 'SHEET1', 'SHEET2']);

const SUPPLIER_CODES = {
  'H.HÀ': 'NCC-HHA',
  'NICE': 'NCC-NICE',
  'TAKAO': 'NCC-TAKAO',
  'VĨNH THẮNG': 'NCC-VINHTHANG',
  'DMAX+MIRA': 'NCC-DMAXMIRA',
  'ROYAL+ẤN': 'NCC-ROYALAN',
  'TOKO': 'NCC-TOKO',
  'Á Mỹ': 'NCC-AMY',
};

// ============================================================================
// 1. Bộ đọc file .xlsx (ZIP + XML) thuần Node.js (không cần cài thêm thư viện)
// ============================================================================
function readZipEntries(filePath) {
  const buf = fs.readFileSync(filePath);
  // Tìm End of Central Directory (EOCD) signature: 0x06054b50
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

    // Đọc Local File Header
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

function normalizeSupplierName(rawSheetName) {
  // Bỏ dấu phẩy ở cuối (ví dụ: 'TOKO,' -> 'TOKO') và chuẩn hóa khoảng trắng
  return rawSheetName.trim().replace(/,+$/, '').trim();
}

function parseExcelProducts(filePath) {
  const entries = readZipEntries(filePath);

  // 1. Đọc sharedStrings.xml
  const sharedStrings = [];
  const ssXml = entries.get('xl/sharedStrings.xml') || '';
  const siMatches = ssXml.matchAll(/<si\b[^>]*>([\s\S]*?)<\/si>/g);
  for (const match of siMatches) {
    const siBody = match[1];
    const tMatches = siBody.matchAll(/<t(?:\s[^>]*)?>([\s\S]*?)<\/t>/g);
    let text = '';
    for (const tm of tMatches) {
      text += decodeXmlEntities(tm[1]);
    }
    sharedStrings.push(text);
  }

  // 2. Đọc relaciones trong xl/_rels/workbook.xml.rels
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

  // 3. Đọc danh sách sheets từ xl/workbook.xml
  const wbXml = entries.get('xl/workbook.xml') || '';
  const sheets = [];
  for (const match of wbXml.matchAll(/<sheet\b([^>]*?)\/?>/g)) {
    const attrs = match[1];
    const name = getAttr(attrs, 'name');
    const state = getAttr(attrs, 'state') || '';
    const rId = getAttr(attrs, 'r:id');
    const targetPath = relsMap.get(rId);
    if (name && targetPath) {
      sheets.push({ rawName: name, state, targetPath });
    }
  }

  // 4. Lọc các sheet hợp lệ (bỏ qua sheet ẩn & các sheet TỔNG HỢP TK, Sheet1, Sheet2)
  const result = [];
  for (const sheet of sheets) {
    if (sheet.state === 'hidden' || sheet.state === 'veryHidden') {
      continue;
    }
    if (EXCLUDED_SHEETS.has(sheet.rawName.trim().toUpperCase())) {
      continue;
    }

    const supplierName = normalizeSupplierName(sheet.rawName);
    const supplierCode =
      SUPPLIER_CODES[supplierName] ||
      'NCC-' +
        supplierName
          .normalize('NFD')
          .replace(/[\u0300-\u036f]/g, '')
          .replace(/đ/gi, 'd')
          .replace(/[^a-zA-Z0-9]/g, '')
          .toUpperCase();

    const wsXml = entries.get(sheet.targetPath) || '';
    const products = [];
    let currentCategory = '';

    for (const rowMatch of wsXml.matchAll(/<row\b([^>]*)>([\s\S]*?)<\/row>/g)) {
      const rowAttrs = rowMatch[1];
      const rowNum = parseInt(getAttr(rowAttrs, 'r') || '0', 10);
      // Dữ liệu sản phẩm bắt đầu từ dòng 5 (dòng 1-4 là tiêu đề và tổng cộng)
      if (rowNum <= 4) continue;

      const rowBody = rowMatch[2];
      const cells = {};

      for (const cellMatch of rowBody.matchAll(/<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)) {
        const cAttrs = cellMatch[1];
        const cBody = cellMatch[2] || '';
        const ref = getAttr(cAttrs, 'r') || '';
        const col = ref.replace(/\d+/g, '');
        if (col !== 'A' && col !== 'B') continue;

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

      // Cột 1 (Cột A): Loại sản phẩm (fill-down cho các dòng bên dưới)
      if (cells.A) {
        currentCategory = cells.A;
      }

      // Cột 2 (Cột B): Mã sản phẩm (SKU)
      if (cells.B) {
        // Nếu mã SP là số thập phân bị lỗi làm tròn float trong XML (VD: "16.126000000000001" -> "16.126")
        let sku = cells.B;
        if (/^\d+\.\d{10,}$/.test(sku)) {
          sku = parseFloat(sku).toString();
        }

        products.push({
          row: rowNum,
          sku,
          name: supplierName, // Tên SP để theo tên hãng
          category: currentCategory || null,
          uom: 'Hộp',
          unitCost: 0,
          wholesalePrice: 0,
          retailPrice: 0,
          stockWarehouse1: 0,
          stockWarehouse2: 0,
          stockWarehouse3: 0,
          reorderPoint: 0,
        });
      }
    }

    result.push({
      rawSheetName: sheet.rawName,
      supplierName,
      supplierCode,
      products,
    });
  }

  return result;
}

// ============================================================================
// 2. Hàm gọi API & thực thi thêm Nhà cung cấp + Sản phẩm
// ============================================================================
async function request(apiPath, options = {}) {
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

async function main() {
  const isDryRun = process.argv.includes('--dry-run');

  console.log(`Đang đọc file Excel: ${EXCEL_FILE}`);
  const sheetsData = parseExcelProducts(EXCEL_FILE);

  const totalProductsCount = sheetsData.reduce((sum, s) => sum + s.products.length, 0);
  console.log(`\nĐã phân tích xong ${sheetsData.length} Sheet Tabs (Nhà cung cấp) với tổng cộng ${totalProductsCount} sản phẩm:`);
  console.log('-------------------------------------------------------------------------');
  for (const s of sheetsData) {
    const uniqueCategories = [...new Set(s.products.map((p) => p.category).filter(Boolean))];
    console.log(
      `  • Hãng/NCC: ${s.supplierName.padEnd(12)} (Mã: ${s.supplierCode.padEnd(14)}) | Số SP: ${String(s.products.length).padStart(3)} | Số loại SP (Cột 1): ${uniqueCategories.length}`
    );
  }
  console.log('-------------------------------------------------------------------------');

  if (isDryRun) {
    console.log('\n[DRY-RUN] Chế độ kiểm tra hoàn tất (không gọi API).');
    return;
  }

  console.log(`\nBắt đầu đồng bộ dữ liệu lên API (${API_BASE})...`);

  // Lấy danh sách NCC và SP hiện có để tránh trùng lặp khi chạy lại
  const existingSuppliers = (await request('/suppliers')) || [];
  const supplierByName = new Map(
    existingSuppliers.map((s) => [s.name.trim().toUpperCase(), s])
  );
  const supplierByCode = new Map(
    existingSuppliers.map((s) => [s.code.trim().toUpperCase(), s])
  );

  const existingProducts = (await request('/products')) || [];
  const productBySku = new Map(
    existingProducts.map((p) => [p.sku.trim().toUpperCase(), p])
  );

  let createdSuppliersCount = 0;
  let reusedSuppliersCount = 0;
  let createdProductsCount = 0;
  let skippedProductsCount = 0;
  let failedProductsCount = 0;

  for (const sheet of sheetsData) {
    console.log(`\n>>> Xử lý Hãng / Nhà cung cấp: [${sheet.supplierCode}] ${sheet.supplierName}`);

    let supplier =
      supplierByName.get(sheet.supplierName.toUpperCase()) ||
      supplierByCode.get(sheet.supplierCode.toUpperCase());

    if (!supplier) {
      supplier = await request('/suppliers', {
        method: 'POST',
        body: JSON.stringify({
          code: sheet.supplierCode,
          name: sheet.supplierName,
          creditLimit: 0,
          initialDebt: 0,
          notes: `Nhập từ Sheet "${sheet.rawSheetName}" (TK T10.2026.xlsx)`,
        }),
      });
      createdSuppliersCount++;
      supplierByName.set(supplier.name.trim().toUpperCase(), supplier);
      supplierByCode.set(supplier.code.trim().toUpperCase(), supplier);
      console.log(`  + Đã tạo mới NCC: [${supplier.code}] ${supplier.name} (ID: ${supplier.id})`);
    } else {
      reusedSuppliersCount++;
      console.log(`  = Đã tồn tại NCC: [${supplier.code}] ${supplier.name} (ID: ${supplier.id})`);
    }

    let sheetCreated = 0;
    let sheetSkipped = 0;

    for (const prod of sheet.products) {
      const skuKey = prod.sku.toUpperCase();
      if (productBySku.has(skuKey)) {
        skippedProductsCount++;
        sheetSkipped++;
        continue;
      }

      try {
        const created = await request('/products', {
          method: 'POST',
          body: JSON.stringify({
            sku: prod.sku,
            name: prod.name,
            category: prod.category,
            uom: prod.uom,
            supplierId: supplier.id,
            unitCost: 0,
            wholesalePrice: 0,
            retailPrice: 0,
            stockWarehouse1: 0,
            stockWarehouse2: 0,
            stockWarehouse3: 0,
            reorderPoint: 0,
          }),
        });
        productBySku.set(skuKey, created);
        createdProductsCount++;
        sheetCreated++;
      } catch (err) {
        failedProductsCount++;
        console.error(`  - Lỗi tạo SP [SKU: ${prod.sku}] (Dòng ${prod.row}): ${err.message}`);
      }
    }

    console.log(
      `  -> Hoàn tất sheet ${sheet.supplierName}: Thêm mới ${sheetCreated} SP, Bỏ qua (đã tồn tại) ${sheetSkipped} SP.`
    );
  }

  console.log('\n=========================================================================');
  console.log('HOÀN TẤT IMPORT DỮ LIỆU TỪ EXCEL!');
  console.log(`- Nhà cung cấp tạo mới : ${createdSuppliersCount} (Đã có sẵn: ${reusedSuppliersCount})`);
  console.log(`- Sản phẩm tạo mới     : ${createdProductsCount}`);
  console.log(`- Sản phẩm đã tồn tại  : ${skippedProductsCount}`);
  console.log(`- Sản phẩm lỗi         : ${failedProductsCount}`);
  console.log('=========================================================================');
}

main().catch((err) => {
  console.error('\nLỗi thực thi script:', err.message);
  process.exit(1);
});

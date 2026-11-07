// month11/import-product-units.js
// Script đọc bảng quy đổi đơn vị (Cột C / Quy cách trong TK_T10.2026.xlsx)
// và cập nhật đơn vị tính (ProductUnits + Products.Uom + quy đổi tồn kho cơ sở)
// cho toàn bộ các sản phẩm tương ứng đã có trong Database.
//
// Quy tắc nghiệp vụ:
//   1. "1H = 8 viên = 1,44 m2" => 1 Hộp = 8 Viên (bỏ qua m2/m, chỉ lấy Hộp và Viên):
//        - Đơn vị cơ sở (nhỏ nhất): Viên (ConversionRate = 1, IsBaseUnit = true)
//        - Đơn vị quy đổi (lớn)   : Hộp  (ConversionRate = 8, IsBaseUnit = false)
//        - Đơn vị hiển thị chính  : Products.Uom = 'Hộp'
//   2. Các đơn vị đặc thù khác như Túi, Hòm, Bao, Thùng, Can, Chai, Bộ...:
//        - Nếu đơn lẻ (VD: "Túi", "Hòm", "Bao"): tạo 1 đơn vị gốc (ConversionRate = 1, IsBaseUnit = true), Products.Uom = tên đơn vị.
//        - Nếu có quy đổi (VD: "1 Hòm = 10 túi"): tự động tách đơn vị nhỏ (x1) và đơn vị lớn (xN).
//   3. Xoá toàn bộ đơn vị cũ (DELETE FROM "ProductUnits") của sản phẩm khớp trước khi thêm mới để tránh xung đột.
//   4. Tự động quy đổi tồn kho hiện có từ Hộp sang đơn vị gốc nhỏ nhất (Viên) một cách idempotent
//      (chạy lại nhiều lần không bị nhân đôi tồn kho).
//
// Cách sử dụng:
//   node month11/import-product-units.js --dry-run    (Kiểm tra khớp SP & thống kê quy đổi, sinh SQL, không ghi DB)
//   node month11/import-product-units.js --sql        (Chỉ sinh file month11/update_product_units.sql)
//   node month11/import-product-units.js --direct-db  (Mặc định: Thực thi SQL trực tiếp vào PostgreSQL container debtmanager_db)
//   node month11/import-product-units.js --api        (Đồng bộ qua Backend REST API)

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { execSync } = require('child_process');

const API_BASE = process.env.API_BASE || 'http://localhost:5050/api';
const DB_CONTAINER = process.env.DB_CONTAINER || 'debtmanager_db';
const DB_USER = process.env.DB_USER || 'postgres';
const DB_NAME = process.env.DB_NAME || 'debtmanager_db';

// File Excel bảng quy đổi đơn vị (ưu tiên tham số dòng lệnh -> TK_T10.2026.xlsx trong month11)
const cliXlsx = process.argv.slice(2).find((arg) => !arg.startsWith('--') && arg.toLowerCase().endsWith('.xlsx'));
const POSSIBLE_SPEC_PATHS = [
  cliXlsx ? path.resolve(cliXlsx) : null,
  path.join(__dirname, 'TK_T10.2026.xlsx'),
  path.join(__dirname, 'TK T10.2026.xlsx'),
  path.join(__dirname, '..', 'TK_T10.2026.xlsx'),
  path.join(__dirname, '..', 'TK T10.2026.xlsx'),
].filter(Boolean);

const SPEC_EXCEL_FILE = POSSIBLE_SPEC_PATHS.find((p) => fs.existsSync(p)) || POSSIBLE_SPEC_PATHS[0];
const T11_EXCEL_FILE = path.join(__dirname, 'TK_T11.2026.xlsx');
const SQL_OUT_FILE = path.join(__dirname, 'update_product_units.sql');

const SUPPLIER_CONFIGS = [
  { sheet: 'H.HÀ', code: 'HH', name: 'Hoàng Hà' },
  { sheet: 'NICE', code: 'NICE', name: 'Nice' },
  { sheet: 'ROYAL+ẤN', code: 'RA', name: 'Royal + Ấn Độ' },
  { sheet: 'TOKO,', code: 'TOKO', name: 'Toko' },
  { sheet: 'TAKAO', code: 'TAKAO', name: 'Takao' },
  { sheet: 'VĨNH THẮNG', code: 'VT', name: 'Vĩnh Thắng' },
  { sheet: 'DMAX+MIRA', code: 'DMAX', name: 'Dmax + Mira' },
  { sheet: 'Á Mỹ', code: 'AMY', name: 'Á Mỹ' },
];

const SHEET_TO_SUPPLIER = new Map(SUPPLIER_CONFIGS.map((c) => [c.sheet.toUpperCase(), c]));

// ============================================================================
// 1. Bộ đọc file .xlsx (ZIP + XML) thuần Node.js (không phụ thuộc thư viện ngoài)
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
    throw new Error(`File không đúng định dạng ZIP/XLSX: ${filePath}`);
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

    let content = null;
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
  return String(str).replace(/\s+/g, ' ').trim();
}

// ============================================================================
// 2. Bộ phân tích chuỗi Quy cách / Quy đổi đơn vị
// ============================================================================
const CANONICAL_UNIT_NAMES = {
  'h': 'Hộp',
  'hộp': 'Hộp',
  'hop': 'Hộp',
  'v': 'Viên',
  'viên': 'Viên',
  'vien': 'Viên',
  'túi': 'Túi',
  'tui': 'Túi',
  'hòm': 'Hòm',
  'hom': 'Hòm',
  'bao': 'Bao',
  'thùng': 'Thùng',
  'thung': 'Thùng',
  'kiện': 'Kiện',
  'kien': 'Kiện',
  'can': 'Can',
  'chai': 'Chai',
  'lọ': 'Lọ',
  'lo': 'Lọ',
  'gói': 'Gói',
  'goi': 'Gói',
  'bộ': 'Bộ',
  'bo': 'Bộ',
  'cái': 'Cái',
  'cai': 'Cái',
  'chiếc': 'Chiếc',
  'chiec': 'Chiếc',
  'kg': 'Kg',
};

function canonicalUnitName(rawUnit) {
  if (!rawUnit) return null;
  const key = normalizeText(rawUnit).toLowerCase();
  return CANONICAL_UNIT_NAMES[key] || null;
}

/**
 * Phân tích chuỗi quy đổi đơn vị:
 *   - "1H = 8 viên = 1,44 m2" => { mode: 'multi', primaryUom: 'Hộp', baseUom: 'Viên', conversionRate: 8, units: [Viên(x1), Hộp(x8)] }
 *   - "1H = 11 viên"          => { mode: 'multi', primaryUom: 'Hộp', baseUom: 'Viên', conversionRate: 11, ... }
 *   - "1 Hòm = 10 túi"        => { mode: 'multi', primaryUom: 'Hòm', baseUom: 'Túi', conversionRate: 10, ... }
 *   - "Túi" / "Hòm" / "Bao"   => { mode: 'single', primaryUom: 'Túi'|'Hòm'|'Bao', baseUom: ..., conversionRate: 1, units: [...] }
 *   - Bỏ qua hoàn toàn thành phần diện tích m2 / m.
 */
function parseUnitSpec(specStr, prodName = '') {
  const raw = normalizeText(specStr);

  // Tách các vế theo dấu "=" và loại bỏ các vế diện tích (m2, m², m)
  if (raw.includes('=')) {
    const parts = raw
      .split('=')
      .map((s) => s.trim())
      .filter((s) => s && !/^\d+(?:[.,]\d+)?\s*m(?:2|²)?$/i.test(s));

    if (parts.length >= 2) {
      // Vế trái: "1H", "1 Hộp", "1 Hòm", "1 Túi", "1 Thùng", "1 Bao", "1 Bộ"...
      const leftMatch = parts[0].match(/^1\s*([a-zA-ZÀ-ỹ]+)$/i);
      // Vế phải: "8 viên", "8v", "10 túi", "12 cái"...
      const rightMatch = parts[1].match(/^(\d+(?:[.,]\d+)?)\s*([a-zA-ZÀ-ỹ]+)$/i);

      if (leftMatch && rightMatch) {
        const bigUnit = canonicalUnitName(leftMatch[1]);
        const rate = parseFloat(rightMatch[1].replace(',', '.'));
        const smallUnit = canonicalUnitName(rightMatch[2]);

        if (bigUnit && smallUnit && !isNaN(rate) && rate > 1 && bigUnit !== smallUnit) {
          return {
            mode: 'multi',
            primaryUom: bigUnit,
            baseUom: smallUnit,
            conversionRate: rate,
            label: `1 ${bigUnit} = ${rate} ${smallUnit}`,
            units: [
              { unitName: smallUnit, conversionRate: 1, isBaseUnit: true },
              { unitName: bigUnit, conversionRate: rate, isBaseUnit: false },
            ],
          };
        }
      }
    }
  }

  // Trường hợp cột quy cách ghi trực tiếp tên 1 đơn vị: "Túi", "Hòm", "Bao", "Thùng", "Can", "Chai", "Viên", "Hộp"...
  if (raw) {
    const single = canonicalUnitName(raw);
    if (single) {
      return {
        mode: 'single',
        primaryUom: single,
        baseUom: single,
        conversionRate: 1,
        label: single,
        units: [{ unitName: single, conversionRate: 1, isBaseUnit: true }],
      };
    }
  }

  // Trường hợp cột quy cách để trống nhưng trong tên SP có ghi chú đơn vị rõ ràng:
  // VD: "Keo CK vỏ cam(bao 25kg)", "46301-(8v/h)", "... (túi)", "... (hòm)"
  const nameText = normalizeText(prodName);
  const inlineBoxVien = nameText.match(/\(?\s*(\d+)\s*(?:v|viên|vien)\s*\/\s*(?:h|hộp|hop)\s*\)?/i);
  if (inlineBoxVien) {
    const rate = parseInt(inlineBoxVien[1], 10);
    if (rate > 1) {
      return {
        mode: 'multi',
        primaryUom: 'Hộp',
        baseUom: 'Viên',
        conversionRate: rate,
        label: `1 Hộp = ${rate} Viên`,
        units: [
          { unitName: 'Viên', conversionRate: 1, isBaseUnit: true },
          { unitName: 'Hộp', conversionRate: rate, isBaseUnit: false },
        ],
      };
    }
  }

  const pLower = nameText.toLowerCase();
  const specialHintPatterns = [
    { regex: /\(\s*hòm\b|\bhòm\b|-\s*hòm$/i, unit: 'Hòm' },
    { regex: /\(\s*túi\b|-\s*túi$/i, unit: 'Túi' },
    { regex: /\(\s*bao\b|\bbao\s+\d+\s*kg\b/i, unit: 'Bao' },
    { regex: /\(\s*thùng\b/i, unit: 'Thùng' },
    { regex: /\(\s*can\b/i, unit: 'Can' },
    { regex: /\(\s*chai\b/i, unit: 'Chai' },
  ];
  for (const item of specialHintPatterns) {
    if (item.regex.test(pLower)) {
      return {
        mode: 'single',
        primaryUom: item.unit,
        baseUom: item.unit,
        conversionRate: 1,
        label: item.unit,
        units: [{ unitName: item.unit, conversionRate: 1, isBaseUnit: true }],
      };
    }
  }

  return null;
}

// ============================================================================
// 3. Đọc dữ liệu quy cách từ file Excel (TK_T10.2026.xlsx & đối chiếu TK_T11.2026.xlsx)
// ============================================================================
function loadSupplierSheetsFromWorkbook(filePath) {
  if (!filePath || !fs.existsSync(filePath)) return {};

  const entries = readZipEntries(filePath);
  const sharedStrings = [];
  const ssXml = entries.get('xl/sharedStrings.xml') || '';
  for (const match of ssXml.matchAll(/<si\b[^>]*>([\s\S]*?)<\/si>/g)) {
    let text = '';
    for (const tm of match[1].matchAll(/<t(?:\s[^>]*)?>([\s\S]*?)<\/t>/g)) {
      text += decodeXmlEntities(tm[1]);
    }
    sharedStrings.push(text);
  }

  const relsMap = new Map();
  const relsXml = entries.get('xl/_rels/workbook.xml.rels') || '';
  for (const match of relsXml.matchAll(/<Relationship\b([^>]*?)\/?>/g)) {
    const id = getAttr(match[1], 'Id');
    const target = getAttr(match[1], 'Target');
    if (id && target) {
      relsMap.set(id, 'xl/' + target.replace(/^\/+/, ''));
    }
  }

  const bySupplierCode = {};
  const wbXml = entries.get('xl/workbook.xml') || '';

  for (const match of wbXml.matchAll(/<sheet\b([^>]*?)\/?>/g)) {
    const attrs = match[1];
    const sheetName = getAttr(attrs, 'name') || '';
    const state = getAttr(attrs, 'state') || 'visible';
    if (state === 'hidden' || state === 'veryHidden') continue;

    const suppCfg = SHEET_TO_SUPPLIER.get(sheetName.toUpperCase());
    const targetPath = relsMap.get(getAttr(attrs, 'r:id'));
    if (!suppCfg || !targetPath) continue;

    const wsXml = entries.get(targetPath) || '';
    const rows = [];
    let currentCategory = '';

    for (const rowMatch of wsXml.matchAll(/<row\b([^>]*)>([\s\S]*?)<\/row>/g)) {
      const rNum = parseInt(getAttr(rowMatch[1], 'r') || '0', 10);
      const cells = {};

      for (const cellMatch of rowMatch[2].matchAll(/<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)) {
        const ref = getAttr(cellMatch[1], 'r') || '';
        const col = ref.replace(/\d+/g, '');
        if (!['A', 'B', 'C', 'D', 'BS'].includes(col)) continue;

        const cellType = getAttr(cellMatch[1], 't') || '';
        const cBody = cellMatch[2] || '';
        let val = '';

        if (cellType === 'inlineStr') {
          const im = cBody.match(/<t(?:\s[^>]*)?>([\s\S]*?)<\/t>/);
          val = im ? decodeXmlEntities(im[1]) : '';
        } else {
          const vm = cBody.match(/<v>([\s\S]*?)<\/v>/);
          if (vm) {
            const rawVal = decodeXmlEntities(vm[1]);
            val = cellType === 's' ? (sharedStrings[parseInt(rawVal, 10)] ?? '') : rawVal;
          }
        }

        const cleaned = normalizeText(val);
        if (cleaned !== '') cells[col] = cleaned;
      }

      if (cells.A && !['KÍCH THƯỚC', 'KT', 'TỔNG TỒN', 'TỔNG CỘNG', 'STT'].includes(cells.A.toUpperCase())) {
        currentCategory = cells.A;
      }

      if (!cells.B || ['TÊN SP', 'MÃ SP', 'TỔNG CỘNG', 'TỔNG TỒN'].includes(cells.B.toUpperCase())) {
        continue;
      }

      let prodName = cells.B;
      if (/^\d+\.\d{10,}$/.test(prodName)) {
        prodName = parseFloat(prodName).toString();
      }

      // Cột quy cách: ở các sheet H.HÀ, TAKAO, VĨNH THẮNG, ROYAL+ẤN nằm tại Cột C;
      // ở các sheet giữ cột TỒN CK (NICE, DMAX+MIRA, TOKO,, Á Mỹ) nằm ngay kế bên tại Cột D.
      let specText = '';
      if (cells.D && isNaN(Number(cells.D)) && !cells.D.toUpperCase().startsWith('TỒN')) {
        specText = cells.D;
      } else if (
        cells.C &&
        isNaN(Number(cells.C)) &&
        !cells.C.toUpperCase().startsWith('TỒN') &&
        cells.C.toUpperCase() !== 'QUY CÁCH'
      ) {
        specText = cells.C;
      }

      const m2PerBox = cells.BS && !isNaN(parseFloat(cells.BS)) ? parseFloat(cells.BS) : null;

      rows.push({
        row: rNum,
        skuCandidate: `${suppCfg.code}${String(rows.length + 1).padStart(3, '0')}`,
        supplierCode: suppCfg.code,
        supplierName: suppCfg.name,
        category: currentCategory || null,
        name: prodName,
        specText,
        m2PerBox,
      });
    }

    bySupplierCode[suppCfg.code] = rows;
  }

  return bySupplierCode;
}

// ============================================================================
// 4. Chuẩn hoá mã & đối sánh sản phẩm giữa DB và bảng quy đổi Excel
// ============================================================================
function normKey(s) {
  return String(s || '')
    .toUpperCase()
    .replace(/\s+/g, '')
    .replace(/[-_.,]/g, '');
}

function stripA1(s) {
  return String(s || '').replace(/[\s-]*\bA1\b$/i, '').trim();
}

function cleanBatchAnnotations(name) {
  let s = String(name || '').trim();
  // Loại bỏ ghi chú diện tích / lô / ngày sản xuất / số hộp trên kiện (VD: "-53(30.12.23)", "-Đ58(3.3.26)", "(40h/k)", "(1.44M2)")
  s = s.replace(/\(\s*\d+(?:[.,]\d+)?\s*m2?\s*\)/gi, '');
  s = s.replace(/[-–\s]*\(?[đd]\d+[:.]?[^)]*\)?(?:-\d+\.\d+\.\d+)?/gi, '');
  s = s.replace(/-\d+\(\d+\.\d+\.\d+\)/gi, '');
  s = s.replace(/[-–\s]*\(?\d+\s*h\/k\)?/gi, '');
  s = s.replace(/[-–\s]+h\d+\b/gi, '');
  return s.trim();
}

function extractCoreModelKey(name) {
  let s = cleanBatchAnnotations(name);
  s = s.replace(/[-–\s]+(?:gỗ mát|men đường|đen vân)\b/gi, '');
  s = s.replace(/[-–\s]+\b(?:VT)\b/gi, '');
  s = s.replace(/[-–\s]+\b(?:A1|A2|A3)\b/gi, '');
  return normKey(s);
}

function inferTileAreaM2(categoryStr) {
  const c = String(categoryStr || '').toUpperCase();
  if (/1\s*MÉT|1M\*1M|100\*100|\b1M\b/.test(c)) return 1.0;
  const m = c.match(/(\d{2,3})\s*[*x/]\s*(\d{2,3})/i);
  if (m) {
    const w = parseInt(m[1], 10) / 100;
    const h = parseInt(m[2], 10) / 100;
    return w * h;
  }
  if (/\b80\b/.test(c)) return 0.64;
  if (/\b60\b/.test(c)) return 0.36;
  if (/\b50\b/.test(c)) return 0.25;
  return null;
}

function matchProductToUnitSpec(product, specRowsBySupplier, t11RowsBySupplier) {
  const suppCode = product.supplierCode || '';
  const specList = specRowsBySupplier[suppCode] || [];
  const t11List = t11RowsBySupplier[suppCode] || [];

  // 1. Khớp trực tiếp hoặc chuẩn hoá mã SP trên cùng Nhà cung cấp
  const matchedRow =
    specList.find((x) => x.name.toUpperCase() === product.name.toUpperCase()) ||
    specList.find((x) => normKey(x.name) === normKey(product.name)) ||
    specList.find((x) => normKey(stripA1(x.name)) === normKey(stripA1(product.name))) ||
    specList.find(
      (x) => normKey(stripA1(cleanBatchAnnotations(x.name))) === normKey(stripA1(cleanBatchAnnotations(product.name)))
    ) ||
    specList.find((x) => extractCoreModelKey(x.name) === extractCoreModelKey(product.name));

  if (matchedRow) {
    const parsed = parseUnitSpec(matchedRow.specText, product.name);
    if (parsed) {
      return { ...parsed, matchSource: `Excel [${suppCode}] "${matchedRow.name}" (${matchedRow.specText || 'tên SP'})` };
    }
  }

  // 2. Kiểm tra gợi ý đơn vị trực tiếp trong tên sản phẩm (VD: "Keo CK vỏ cam(bao 25kg)", "... (túi)", "... (hòm)")
  const directFromName = parseUnitSpec('', product.name);
  if (directFromName) {
    return { ...directFromName, matchSource: `Tên SP "${product.name}"` };
  }

  // 3. Đối với vài mã mới phát sinh thêm ở T11: đối chiếu cột M2/H trong TK_T11.2026.xlsx chia cho diện tích viên gạch
  const t11Row = t11List.find((r) => r.name.toUpperCase() === product.name.toUpperCase());
  const tileArea = inferTileAreaM2(product.category);
  if (t11Row && t11Row.m2PerBox && tileArea && t11Row.m2PerBox > 0.3) {
    const vienCount = Math.round(t11Row.m2PerBox / tileArea);
    if (vienCount >= 2 && Math.abs(vienCount * tileArea - t11Row.m2PerBox) < 0.02) {
      return {
        mode: 'multi',
        primaryUom: 'Hộp',
        baseUom: 'Viên',
        conversionRate: vienCount,
        label: `1 Hộp = ${vienCount} Viên`,
        units: [
          { unitName: 'Viên', conversionRate: 1, isBaseUnit: true },
          { unitName: 'Hộp', conversionRate: vienCount, isBaseUnit: false },
        ],
        matchSource: `Quy cách nhóm ${product.category} (${t11Row.m2PerBox} m2/hộp)`,
      };
    }
  }

  // 4. Kế thừa quy cách đồng nhất của cùng nhóm kích thước (Category) thuộc cùng Nhà cung cấp
  if (product.category) {
    const catSpecs = specList
      .filter((x) => normKey(x.category) === normKey(product.category) && x.specText)
      .map((x) => parseUnitSpec(x.specText, x.name))
      .filter(Boolean);

    const uniqueByLabel = new Map(catSpecs.map((s) => [s.label, s]));
    if (uniqueByLabel.size === 1) {
      const inherited = [...uniqueByLabel.values()][0];
      return { ...inherited, matchSource: `Cùng nhóm kích thước "${product.category}"` };
    }
  }

  return null;
}

// ============================================================================
// 5. Lấy danh sách sản phẩm đã có từ DB (hoặc API / file T11 khi chạy offline)
// ============================================================================
function tryLoadProductsFromPostgres() {
  const query = `
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) FROM (
  SELECT p."Id" AS "id",
         p."Sku" AS "sku",
         p."Name" AS "name",
         p."Category" AS "category",
         p."Uom" AS "uom",
         p."StockWarehouse1" AS "stockWarehouse1",
         p."StockWarehouse2" AS "stockWarehouse2",
         p."StockWarehouse3" AS "stockWarehouse3",
         p."TotalStock" AS "totalStock",
         s."Code" AS "supplierCode",
         s."Name" AS "supplierName"
  FROM "Products" p
  LEFT JOIN "Suppliers" s ON s."Id" = p."SupplierId"
  ORDER BY p."Id"
) t;
`;
  try {
    const out = execSync(`docker exec -i ${DB_CONTAINER} psql -U ${DB_USER} -d ${DB_NAME} -t -A`, {
      input: query,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();
    if (!out) return null;
    return JSON.parse(out);
  } catch {
    return null;
  }
}

async function tryLoadProductsFromApi() {
  try {
    const suppliersRes = await fetch(`${API_BASE}/suppliers`);
    const suppliersJson = suppliersRes.ok ? await suppliersRes.json() : { data: [] };
    const suppById = new Map((suppliersJson.data || []).map((s) => [s.id, s]));

    const res = await fetch(`${API_BASE}/products?page=1&pageSize=5000`);
    if (!res.ok) return null;
    const json = await res.json();
    const items = json.data?.items || [];
    return items.map((p) => {
      const supp = suppById.get(p.supplierId);
      return {
        id: p.id,
        sku: p.sku,
        name: p.name,
        category: p.category,
        uom: p.uom,
        stockWarehouse1: Number(p.warehouseStocks?.warehouse1 ?? p.stockWarehouse1 ?? 0),
        stockWarehouse2: Number(p.warehouseStocks?.warehouse2 ?? p.stockWarehouse2 ?? 0),
        stockWarehouse3: Number(p.warehouseStocks?.warehouse3 ?? p.stockWarehouse3 ?? 0),
        totalStock: Number(p.totalStock ?? 0),
        units: p.units || [],
        unitCost: Number(p.unitCost ?? 0),
        wholesalePrice: Number(p.wholesalePrice ?? 0),
        retailPrice: Number(p.retailPrice ?? 0),
        reorderPoint: Number(p.reorderPoint ?? 0),
        barcode: p.barcode || null,
        supplierId: p.supplierId || null,
        supplierCode: supp?.code || null,
        supplierName: supp?.name || p.supplierName || null,
      };
    });
  } catch {
    return null;
  }
}

// ============================================================================
// 6. Sinh file SQL chuẩn (xoá đơn vị cũ -> thêm đơn vị mới -> quy đổi tồn kho cơ sở idempotent)
// ============================================================================
function escapeSql(val) {
  if (val === null || val === undefined) return '';
  return String(val).replace(/'/g, "''");
}

function generateSqlScript(resolvedItems, extraSpecRows, outFilePath) {
  let sql = `-- update_product_units.sql
-- Tự động sinh bởi month11/import-product-units.js vào lúc ${new Date().toISOString()}
-- Nguồn quy đổi: ${path.basename(SPEC_EXCEL_FILE)}
-- Nghiệp vụ:
--   1. Xoá toàn bộ đơn vị tính cũ (ProductUnits) của sản phẩm khớp để tránh xung đột.
--   2. Thêm lại đơn vị tính mới:
--        + Với "1H = N viên ...": thêm Viên (x1, đơn vị gốc) + Hộp (xN), giữ Uom hiển thị chính = 'Hộp' (bỏ qua m2).
--        + Với đơn vị đơn (Túi, Hòm, Bao...): thêm đơn vị gốc (x1), cập nhật Uom = tên đơn vị.
--   3. Quy đổi tồn kho hiện tại về đơn vị cơ sở nhỏ nhất (Viên) một cách idempotent (an toàn khi chạy lại nhiều lần).

BEGIN;

-- Hàm phụ trợ quy đổi số lượng sang đơn vị gốc nhỏ nhất (làm tròn số nguyên Viên cho các số lẻ thập phân từ Hộp như 426.33 * 6 = 2558)
CREATE OR REPLACE FUNCTION pg_temp.scale_base_qty(val numeric, factor numeric)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    raw_val numeric;
    nearest_int numeric;
BEGIN
    IF factor IS NULL OR factor = 1 OR val = 0 THEN
        RETURN val;
    END IF;
    raw_val := val * factor;
    nearest_int := ROUND(raw_val, 0);
    IF ABS(raw_val - nearest_int) <= 0.11 THEN
        RETURN nearest_int;
    END IF;
    RETURN ROUND(raw_val, 3);
END;
$$;

-- Hàm cập nhật đơn vị tính cho từng sản phẩm đã tồn tại trong bảng Products
CREATE OR REPLACE FUNCTION pg_temp.apply_product_unit_spec(
    p_supplier_code text,
    p_sku text,
    p_name text,
    p_primary_uom text,
    p_base_uom text,
    p_conversion_rate numeric
) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
    v_supp_id int;
    v_prod_id int;
    v_old_primary_rate numeric;
    v_old_primary_retail numeric := 0;
    v_old_primary_wholesale numeric := 0;
    v_old_primary_barcode text := NULL;
    v_old_base_barcode text := NULL;
    v_max_old_rate numeric;
    v_scale_factor numeric := 1;
    v_wh1 numeric;
    v_wh2 numeric;
    v_wh3 numeric;
BEGIN
    SELECT s."Id" INTO v_supp_id
    FROM "Suppliers" s
    WHERE UPPER(BTRIM(s."Code")) = UPPER(BTRIM(p_supplier_code))
    LIMIT 1;

    -- Chỉ tìm các sản phẩm ĐÃ CÓ trong hệ thống
    SELECT p."Id" INTO v_prod_id
    FROM "Products" p
    WHERE (v_supp_id IS NOT NULL AND p."SupplierId" = v_supp_id AND UPPER(BTRIM(p."Name")) = UPPER(BTRIM(p_name)))
       OR (p_sku <> '' AND UPPER(BTRIM(p."Sku")) = UPPER(BTRIM(p_sku)))
    ORDER BY
       CASE WHEN v_supp_id IS NOT NULL AND p."SupplierId" = v_supp_id AND UPPER(BTRIM(p."Name")) = UPPER(BTRIM(p_name)) THEN 0 ELSE 1 END,
       p."Id" ASC
    LIMIT 1;

    IF v_prod_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Đọc thông tin đơn vị cũ trước khi xoá để bảo toàn giá/barcode (nếu có) và tính hệ số quy đổi tồn kho idempotent
    SELECT u."ConversionRate", u."RetailPrice", u."WholesalePrice", u."Barcode"
      INTO v_old_primary_rate, v_old_primary_retail, v_old_primary_wholesale, v_old_primary_barcode
    FROM "ProductUnits" u
    WHERE u."ProductId" = v_prod_id
      AND UPPER(BTRIM(u."UnitName")) = UPPER(BTRIM(p_primary_uom))
    LIMIT 1;

    SELECT u."Barcode"
      INTO v_old_base_barcode
    FROM "ProductUnits" u
    WHERE u."ProductId" = v_prod_id
      AND UPPER(BTRIM(u."UnitName")) = UPPER(BTRIM(p_base_uom))
    LIMIT 1;

    IF p_conversion_rate > 1 AND UPPER(BTRIM(p_base_uom)) <> UPPER(BTRIM(p_primary_uom)) THEN
        IF v_old_primary_rate IS NULL OR v_old_primary_rate <= 0 THEN
            v_old_primary_rate := 1;
        END IF;
        v_scale_factor := p_conversion_rate / v_old_primary_rate;
    ELSE
        SELECT MAX(u."ConversionRate") INTO v_max_old_rate
        FROM "ProductUnits" u
        WHERE u."ProductId" = v_prod_id;

        IF v_max_old_rate IS NOT NULL AND v_max_old_rate > 1 THEN
            v_scale_factor := 1.0 / v_max_old_rate;
        ELSE
            v_scale_factor := 1;
        END IF;
    END IF;

    -- Cập nhật tồn kho cơ sở & giá gốc trên bảng Products nếu hệ số cơ sở thay đổi
    IF ABS(v_scale_factor - 1) > 0.000001 THEN
        SELECT
            pg_temp.scale_base_qty(p."StockWarehouse1", v_scale_factor),
            pg_temp.scale_base_qty(p."StockWarehouse2", v_scale_factor),
            pg_temp.scale_base_qty(p."StockWarehouse3", v_scale_factor)
        INTO v_wh1, v_wh2, v_wh3
        FROM "Products" p
        WHERE p."Id" = v_prod_id;

        -- Nếu sản phẩm đã có giá lẻ / giá sỉ trên Products nhưng chưa lưu riêng trên đơn vị lớn thì giữ lại trên đơn vị lớn
        IF COALESCE(v_old_primary_retail, 0) = 0 THEN
            SELECT ROUND(p."RetailPrice" * COALESCE(v_old_primary_rate, 1), 2)
              INTO v_old_primary_retail
            FROM "Products" p WHERE p."Id" = v_prod_id;
        END IF;
        IF COALESCE(v_old_primary_wholesale, 0) = 0 THEN
            SELECT ROUND(p."WholesalePrice" * COALESCE(v_old_primary_rate, 1), 2)
              INTO v_old_primary_wholesale
            FROM "Products" p WHERE p."Id" = v_prod_id;
        END IF;

        UPDATE "Products"
        SET "StockWarehouse1" = v_wh1,
            "StockWarehouse2" = v_wh2,
            "StockWarehouse3" = v_wh3,
            "TotalStock"      = v_wh1 + v_wh2 + v_wh3,
            "UnitCost"        = CASE WHEN "UnitCost" <> 0 THEN ROUND("UnitCost" / v_scale_factor, 2) ELSE 0 END,
            "WholesalePrice"  = CASE WHEN "WholesalePrice" <> 0 THEN ROUND("WholesalePrice" / v_scale_factor, 2) ELSE 0 END,
            "RetailPrice"     = CASE WHEN "RetailPrice" <> 0 THEN ROUND("RetailPrice" / v_scale_factor, 2) ELSE 0 END,
            "Uom"             = p_primary_uom,
            "UpdatedAt"       = NOW()
        WHERE "Id" = v_prod_id;

        -- Đồng bộ bản ghi tồn kho đầu kỳ trong StockHistories để sổ kho khớp 100%
        UPDATE "StockHistories"
        SET "BeforeWarehouseStock" = pg_temp.scale_base_qty("BeforeWarehouseStock", v_scale_factor),
            "Delta"                = pg_temp.scale_base_qty("Delta", v_scale_factor),
            "AfterWarehouseStock"  = pg_temp.scale_base_qty("AfterWarehouseStock", v_scale_factor),
            "BeforeTotalStock"     = pg_temp.scale_base_qty("BeforeTotalStock", v_scale_factor),
            "AfterTotalStock"      = pg_temp.scale_base_qty("AfterTotalStock", v_scale_factor)
        WHERE "ProductId" = v_prod_id
          AND "SourceType" = 'init';
    ELSE
        UPDATE "Products"
        SET "Uom" = p_primary_uom,
            "UpdatedAt" = NOW()
        WHERE "Id" = v_prod_id;
    END IF;

    -- XOÁ ĐƠN VỊ CŨ TRƯỚC KHI THÊM LẠI ĐỂ TRÁNH XUNG ĐỘT
    DELETE FROM "ProductUnits" WHERE "ProductId" = v_prod_id;

    -- THÊM LẠI ĐƠN VỊ MỚI
    IF p_conversion_rate > 1 AND UPPER(BTRIM(p_base_uom)) <> UPPER(BTRIM(p_primary_uom)) THEN
        -- 1. Đơn vị nhỏ nhất (VD: Viên - ConversionRate = 1, IsBaseUnit = true)
        INSERT INTO "ProductUnits" (
            "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
            "Barcode", "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
        ) VALUES (
            v_prod_id, p_base_uom, 1, true,
            v_old_base_barcode, 0, 0, true, NOW()
        );

        -- 2. Đơn vị quy đổi lớn (VD: Hộp = N Viên - ConversionRate = N, IsBaseUnit = false)
        INSERT INTO "ProductUnits" (
            "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
            "Barcode", "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
        ) VALUES (
            v_prod_id, p_primary_uom, p_conversion_rate, false,
            v_old_primary_barcode, COALESCE(v_old_primary_retail, 0), COALESCE(v_old_primary_wholesale, 0), true, NOW()
        );
    ELSE
        -- Đơn vị đơn lẻ (VD: Túi, Hòm, Bao, Thùng, Can, Chai, Viên...)
        INSERT INTO "ProductUnits" (
            "ProductId", "UnitName", "ConversionRate", "IsBaseUnit",
            "Barcode", "RetailPrice", "WholesalePrice", "CanSell", "CreatedAt"
        ) VALUES (
            v_prod_id, p_primary_uom, 1, true,
            COALESCE(v_old_primary_barcode, v_old_base_barcode),
            COALESCE(v_old_primary_retail, 0), COALESCE(v_old_primary_wholesale, 0), true, NOW()
        );
    END IF;

    RETURN TRUE;
END;
$$;

`;

  // Nhóm theo nhà cung cấp cho dễ đọc
  const grouped = new Map();
  for (const item of resolvedItems) {
    const key = item.product.supplierCode || 'OTHER';
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(item);
  }

  sql += `DO $$\nBEGIN\n`;

  for (const [suppCode, list] of grouped.entries()) {
    sql += `    -- >>> Nhà cung cấp [${suppCode}] - ${list.length} sản phẩm\n`;
    for (const { product, spec } of list) {
      sql += `    PERFORM pg_temp.apply_product_unit_spec('${escapeSql(suppCode)}', '${escapeSql(product.sku || '')}', '${escapeSql(product.name)}', '${escapeSql(spec.primaryUom)}', '${escapeSql(spec.baseUom)}', ${spec.conversionRate});\n`;
    }
    sql += `\n`;
  }

  if (extraSpecRows.length > 0) {
    sql += `    -- >>> Các tên mã quy cách dự phòng trong bảng quy đổi (chỉ cập nhật nếu tồn tại tên tương ứng trong DB)\n`;
    for (const extra of extraSpecRows) {
      sql += `    PERFORM pg_temp.apply_product_unit_spec('${escapeSql(extra.supplierCode)}', '', '${escapeSql(extra.name)}', '${escapeSql(extra.spec.primaryUom)}', '${escapeSql(extra.spec.baseUom)}', ${extra.spec.conversionRate});\n`;
    }
    sql += `\n`;
  }

  sql += `    -- Đồng bộ lại sequence cho bảng ProductUnits
    PERFORM setval(pg_get_serial_sequence('"ProductUnits"', 'Id'), COALESCE((SELECT MAX("Id") FROM "ProductUnits"), 1), true);
END $$;

COMMIT;
`;

  fs.writeFileSync(outFilePath, sql, 'utf8');
}

// ============================================================================
// 7. Đồng bộ qua API (chế độ tuỳ chọn --api khi không dùng Docker CLI)
// ============================================================================
function scaleBaseQtyJs(val, factor) {
  const num = Number(val || 0);
  if (!factor || factor === 1 || num === 0) return num;
  const raw = num * factor;
  const nearestInt = Math.round(raw);
  if (Math.abs(raw - nearestInt) <= 0.11) return nearestInt;
  return Number(raw.toFixed(3));
}

async function requestApi(apiPath, options = {}) {
  const res = await fetch(`${API_BASE}${apiPath}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`HTTP ${res.status} on ${apiPath}: ${errText}`);
  }
  const json = await res.json();
  return json.data;
}

async function applyViaApi(resolvedItems) {
  let updated = 0;
  let errors = 0;

  for (const { product, spec } of resolvedItems) {
    try {
      const existingUnits = Array.isArray(product.units) ? product.units : [];
      const oldPrimary = existingUnits.find(
        (u) => String(u.unitName || '').trim().toUpperCase() === spec.primaryUom.toUpperCase()
      );
      let scaleFactor = 1;
      if (spec.conversionRate > 1 && spec.baseUom.toUpperCase() !== spec.primaryUom.toUpperCase()) {
        const oldRate = Number(oldPrimary?.conversionRate) > 0 ? Number(oldPrimary.conversionRate) : 1;
        scaleFactor = spec.conversionRate / oldRate;
      } else {
        const maxOld = existingUnits.reduce((m, u) => Math.max(m, Number(u.conversionRate || 1)), 1);
        scaleFactor = maxOld > 1 ? 1 / maxOld : 1;
      }

      // Bước 1: Xoá đơn vị cũ bằng cách đưa về 1 đơn vị tạm trước khi ghi bộ đơn vị mới
      await requestApi(`/products/${product.id}`, {
        method: 'PUT',
        body: JSON.stringify({
          sku: product.sku,
          name: product.name,
          category: product.category,
          uom: spec.baseUom,
          barcode: product.barcode,
          supplierId: product.supplierId,
          unitCost: scaleFactor !== 1 && product.unitCost ? Number((product.unitCost / scaleFactor).toFixed(2)) : product.unitCost || 0,
          wholesalePrice:
            scaleFactor !== 1 && product.wholesalePrice ? Number((product.wholesalePrice / scaleFactor).toFixed(2)) : product.wholesalePrice || 0,
          retailPrice:
            scaleFactor !== 1 && product.retailPrice ? Number((product.retailPrice / scaleFactor).toFixed(2)) : product.retailPrice || 0,
          reorderPoint: product.reorderPoint || 0,
          units: [{ unitName: spec.baseUom, conversionRate: 1, isBaseUnit: true, canSell: true }],
        }),
      });

      // Bước 2: Ghi bộ đơn vị mới chuẩn xác
      await requestApi(`/products/${product.id}`, {
        method: 'PUT',
        body: JSON.stringify({
          sku: product.sku,
          name: product.name,
          category: product.category,
          uom: spec.primaryUom,
          barcode: product.barcode,
          supplierId: product.supplierId,
          unitCost: scaleFactor !== 1 && product.unitCost ? Number((product.unitCost / scaleFactor).toFixed(2)) : product.unitCost || 0,
          wholesalePrice:
            scaleFactor !== 1 && product.wholesalePrice ? Number((product.wholesalePrice / scaleFactor).toFixed(2)) : product.wholesalePrice || 0,
          retailPrice:
            scaleFactor !== 1 && product.retailPrice ? Number((product.retailPrice / scaleFactor).toFixed(2)) : product.retailPrice || 0,
          reorderPoint: product.reorderPoint || 0,
          units: spec.units.map((u) => ({
            unitName: u.unitName,
            conversionRate: u.conversionRate,
            isBaseUnit: u.isBaseUnit,
            canSell: true,
            retailPrice: 0,
            wholesalePrice: 0,
          })),
        }),
      });

      // Bước 3: Quy đổi tồn kho sang đơn vị gốc nếu cần
      if (Math.abs(scaleFactor - 1) > 1e-6) {
        for (const [whId, curQty] of [
          ['warehouse1', product.stockWarehouse1],
          ['warehouse2', product.stockWarehouse2],
          ['warehouse3', product.stockWarehouse3],
        ]) {
          if (Number(curQty || 0) !== 0) {
            const newQty = scaleBaseQtyJs(curQty, scaleFactor);
            await requestApi(`/products/${product.id}/adjust-stock`, {
              method: 'POST',
              body: JSON.stringify({
                warehouse: whId,
                quantity: newQty,
                reason: 'Quy đổi đơn vị gốc',
                note: `Quy đổi tồn kho sang đơn vị cơ sở ${spec.baseUom} (${spec.label})`,
              }),
            });
          }
        }
      }

      updated++;
    } catch (err) {
      errors++;
      console.error(`  ! Lỗi SP [${product.sku}] ${product.name}: ${err.message}`);
    }
  }

  return { updated, errors };
}

// ============================================================================
// 8. Hàm thực thi chính
// ============================================================================
async function main() {
  const isDryRun = process.argv.includes('--dry-run');
  const isSqlOnly = process.argv.includes('--sql');
  const isApiMode = process.argv.includes('--api');

  console.log('==============================================================================');
  console.log('   CÔNG CỤ CẬP NHẬT BẢNG QUY ĐỔI ĐƠN VỊ TÍNH (HỘP / VIÊN / TÚI / HÒM / BAO)');
  console.log('==============================================================================');
  console.log(`• File bảng quy đổi đơn vị : ${SPEC_EXCEL_FILE}`);

  const specRowsBySupplier = loadSupplierSheetsFromWorkbook(SPEC_EXCEL_FILE);
  const t11RowsBySupplier = fs.existsSync(T11_EXCEL_FILE) ? loadSupplierSheetsFromWorkbook(T11_EXCEL_FILE) : {};

  // Lấy danh sách sản phẩm hiện có
  let targetProducts = null;
  let productSourceLabel = '';

  if (isApiMode) {
    targetProducts = await tryLoadProductsFromApi();
    if (targetProducts) productSourceLabel = `Backend API (${API_BASE})`;
  }

  if (!targetProducts) {
    targetProducts = tryLoadProductsFromPostgres();
    if (targetProducts) productSourceLabel = `PostgreSQL Docker (${DB_CONTAINER}/${DB_NAME})`;
  }

  if (!targetProducts) {
    targetProducts = await tryLoadProductsFromApi();
    if (targetProducts) productSourceLabel = `Backend API (${API_BASE})`;
  }

  if (!targetProducts) {
    // Offline fallback từ danh sách SP trong TK_T11.2026.xlsx hoặc TK_T10.2026.xlsx
    const baseMap = Object.keys(t11RowsBySupplier).length > 0 ? t11RowsBySupplier : specRowsBySupplier;
    targetProducts = [];
    for (const rows of Object.values(baseMap)) {
      for (const r of rows) {
        targetProducts.push({
          id: null,
          sku: r.skuCandidate,
          name: r.name,
          category: r.category,
          uom: 'Hộp',
          supplierCode: r.supplierCode,
          supplierName: r.supplierName,
        });
      }
    }
    productSourceLabel = 'Danh sách SP trích xuất từ file Excel (Offline mode)';
  }

  console.log(`• Nguồn sản phẩm đối chiếu : ${productSourceLabel} (${targetProducts.length} sản phẩm)`);

  const resolvedItems = [];
  const unmatchedProducts = [];
  const statsByLabel = new Map();
  const statsBySupplier = new Map();

  for (const prod of targetProducts) {
    const spec = matchProductToUnitSpec(prod, specRowsBySupplier, t11RowsBySupplier);
    if (spec) {
      resolvedItems.push({ product: prod, spec });
      statsByLabel.set(spec.label, (statsByLabel.get(spec.label) || 0) + 1);

      const sKey = `${prod.supplierCode || 'KHÁC'} - ${prod.supplierName || 'Khác'}`;
      const cur = statsBySupplier.get(sKey) || { matched: 0, multi: 0, single: 0 };
      cur.matched++;
      if (spec.mode === 'multi') cur.multi++;
      else cur.single++;
      statsBySupplier.set(sKey, cur);
    } else {
      unmatchedProducts.push(prod);
    }
  }

  // Các dòng quy cách phụ trong TK_T10.2026.xlsx có tên viết khác đôi chút (đưa thêm vào cuối SQL để dự phòng)
  const matchedNameKeys = new Set(
    resolvedItems.map((x) => `${x.product.supplierCode}::${x.product.name.trim().toUpperCase()}`)
  );
  const extraSpecRows = [];
  for (const [suppCode, rows] of Object.entries(specRowsBySupplier)) {
    for (const r of rows) {
      const k = `${suppCode}::${r.name.trim().toUpperCase()}`;
      if (matchedNameKeys.has(k)) continue;
      const spec = parseUnitSpec(r.specText, r.name);
      if (spec) {
        matchedNameKeys.add(k);
        extraSpecRows.push({ supplierCode: suppCode, name: r.name, spec });
      }
    }
  }

  console.log('\n1. THỐNG KÊ THEO NHÀ CUNG CẤP:');
  for (const [sLabel, st] of statsBySupplier.entries()) {
    console.log(
      `   • ${sLabel.padEnd(24)} : Khớp ${String(st.matched).padStart(3)} SP (Quy đổi Hộp/Viên: ${String(st.multi).padStart(3)} | Đơn vị đơn Túi/Hòm/Bao...: ${String(st.single).padStart(2)})`
    );
  }

  console.log('\n2. THỐNG KÊ CHI TIẾT THEO QUY CÁCH ĐƠN VỊ (ĐÃ BỎ QUA M2):');
  const sortedLabels = [...statsByLabel.entries()].sort((a, b) => b[1] - a[1]);
  for (const [label, count] of sortedLabels) {
    console.log(`   • ${label.padEnd(24)} : ${String(count).padStart(3)} sản phẩm`);
  }

  console.log('\n------------------------------------------------------------------------------');
  console.log(`TỔNG KẾT ĐỐI SÁNH: Khớp thành công ${resolvedItems.length} / ${targetProducts.length} sản phẩm.`);
  if (unmatchedProducts.length > 0) {
    console.log(`Sản phẩm chưa có quy cách (${unmatchedProducts.length}):`);
    for (const u of unmatchedProducts) {
      console.log(`   - [${u.supplierCode}] ${u.sku} | ${u.name} (${u.category || 'Không rõ nhóm'})`);
    }
  }
  console.log('------------------------------------------------------------------------------');

  // Luôn sinh file SQL để lưu trữ và đối chiếu
  generateSqlScript(resolvedItems, extraSpecRows, SQL_OUT_FILE);
  console.log(`\n✓ Đã sinh file SQL cập nhật đơn vị: ${SQL_OUT_FILE}`);

  if (isDryRun) {
    console.log('[DRY-RUN] Hoàn tất kiểm tra, chưa ghi thay đổi vào Database.');
    return;
  }

  if (isSqlOnly) {
    console.log('[SQL ONLY] Đã tạo file SQL. Có thể chạy trực tiếp bằng:');
    console.log(`  docker cp "${SQL_OUT_FILE}" ${DB_CONTAINER}:/tmp/update_product_units.sql`);
    console.log(`  docker exec -i ${DB_CONTAINER} psql -U ${DB_USER} -d ${DB_NAME} -f /tmp/update_product_units.sql`);
    return;
  }

  if (!isApiMode) {
    console.log(`\nĐang thực thi cập nhật trực tiếp vào PostgreSQL container (${DB_CONTAINER})...`);
    try {
      const sqlContent = fs.readFileSync(SQL_OUT_FILE, 'utf8');
      execSync(`docker exec -i ${DB_CONTAINER} psql -v ON_ERROR_STOP=1 -U ${DB_USER} -d ${DB_NAME} -q`, {
        input: sqlContent,
        stdio: ['pipe', 'inherit', 'inherit'],
      });
      console.log('✓ Đã xoá đơn vị cũ, thêm lại bộ đơn vị mới và đồng bộ tồn kho cơ sở thành công!');
      return;
    } catch (err) {
      console.warn('! Không thể thực thi qua Docker psql, chuyển sang đồng bộ qua REST API...', err.message);
    }
  }

  console.log(`\nĐang đồng bộ đơn vị tính qua REST API (${API_BASE})...`);
  const { updated, errors } = await applyViaApi(resolvedItems);
  console.log(`✓ Hoàn tất qua API: Cập nhật thành công ${updated} SP, lỗi ${errors} SP.`);
}

main().catch((err) => {
  console.error('\n[LỖI THỰC THI]:', err.message);
  process.exit(1);
});

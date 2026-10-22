// generate-seed-2000.js
// Sinh 2000 lệnh nhập & xuất (1000 lệnh nhập, 1000 lệnh xuất)
// Trải dài từ năm 2021 đến nay (tháng 10/2026)
// Gán 5 nhân viên kinh doanh có sẵn
// Tự động tạo và thực thi file seed_2000_transactions.sql vào PostgreSQL Docker container

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const API_BASE = 'http://localhost:5050/api';

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomChoice(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function sqlStr(val) {
  if (val === null || val === undefined) return 'NULL';
  return `'${String(val).replace(/'/g, "''")}'`;
}

function sqlNum(val) {
  if (val === null || val === undefined || isNaN(val)) return '0';
  return Number(val).toFixed(2);
}

function sqlDate(date) {
  return `'${date.toISOString()}'`;
}

async function main() {
  console.log('🚀 [1/5] Đang tải danh mục từ hệ thống (API / DB)...');

  const [resCust, resSupp, resProd, resEmp] = await Promise.all([
    fetch(`${API_BASE}/customers?all=true`).then(r => r.json()),
    fetch(`${API_BASE}/suppliers?all=true`).then(r => r.json()),
    fetch(`${API_BASE}/products?all=true`).then(r => r.json()),
    fetch(`${API_BASE}/employees`).then(r => r.json())
  ]);

  const customers = resCust.data || [];
  const suppliers = resSupp.data || [];
  const products = resProd.data || [];
  const employees = resEmp.data || [];

  console.log(`✅ Đã tải: ${customers.length} KH, ${suppliers.length} NCC, ${products.length} Sản phẩm, ${employees.length} Nhân viên.`);

  if (!customers.length || !suppliers.length || !products.length || !employees.length) {
    console.error('❌ Thiếu danh mục cơ bản.');
    process.exit(1);
  }

  // Lấy MAX ID hiện tại từ Database
  const getMaxQuery = `
    SELECT 
      (SELECT COALESCE(MAX("Id"), 0) FROM "ExportVouchers") AS max_exp,
      (SELECT COALESCE(MAX("Id"), 0) FROM "ExportVoucherItems") AS max_exp_item,
      (SELECT COALESCE(MAX("Id"), 0) FROM "ImportVouchers") AS max_imp,
      (SELECT COALESCE(MAX("Id"), 0) FROM "ImportVoucherItems") AS max_imp_item,
      (SELECT COALESCE(MAX("Id"), 0) FROM "StockHistories") AS max_stock,
      (SELECT COALESCE(MAX("Id"), 0) FROM "CustomerDebtHistories") AS max_cd,
      (SELECT COALESCE(MAX("Id"), 0) FROM "SupplierDebtHistories") AS max_sd,
      (SELECT COALESCE(MAX("Id"), 0) FROM "Receipts") AS max_rc,
      (SELECT COALESCE(MAX("Id"), 0) FROM "Payments") AS max_pm;
  `.trim();

  const maxRes = execSync('docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -t', {
    input: getMaxQuery,
    encoding: 'utf-8'
  });

  const maxParts = maxRes.trim().split('|').map(s => parseInt(s.trim(), 10) || 0);
  let nextExportId = maxParts[0] + 1;
  let nextExportItemId = maxParts[1] + 1;
  let nextImportId = maxParts[2] + 1;
  let nextImportItemId = maxParts[3] + 1;
  let nextStockHistoryId = maxParts[4] + 1;
  let nextCustDebtId = maxParts[5] + 1;
  let nextSuppDebtId = maxParts[6] + 1;
  let nextReceiptId = maxParts[7] + 1;
  let nextPaymentId = maxParts[8] + 1;

  console.log(`📌 Starting IDs: Export=${nextExportId}, Import=${nextImportId}, StockHist=${nextStockHistoryId}`);

  // Chuẩn bị theo dõi tồn kho & công nợ trong bộ nhớ
  const productStock = {};
  for (const p of products) {
    const unitCost = p.unitCost > 0 ? p.unitCost : randomInt(40, 250) * 1000;
    const retailPrice = p.retailPrice > 0 ? p.retailPrice : Math.round(unitCost * 1.3 / 1000) * 1000;
    productStock[p.id] = {
      id: p.id,
      name: p.name,
      sku: p.sku,
      unitCost: unitCost,
      retailPrice: retailPrice,
      warehouse1: Number(p.stockWarehouse1 || 0) + 100, // Thêm đệm ban đầu để tồn kho luôn dương an toàn
      warehouse2: Number(p.stockWarehouse2 || 0) + 60,
      warehouse3: Number(p.stockWarehouse3 || 0) + 40,
    };
    productStock[p.id].total = productStock[p.id].warehouse1 + productStock[p.id].warehouse2 + productStock[p.id].warehouse3;
  }

  const customerDebts = {};
  for (const c of customers) {
    customerDebts[c.id] = Number(c.debt || 0);
  }

  const supplierDebts = {};
  for (const s of suppliers) {
    supplierDebts[s.id] = Number(s.debt || 0);
  }

  // Map sản phẩm theo NCC
  const productsBySupp = {};
  for (const p of products) {
    const sId = p.supplierId || 0;
    if (!productsBySupp[sId]) productsBySupp[sId] = [];
    productsBySupp[sId].push(p);
  }

  const warehouses = ['warehouse1', 'warehouse1', 'warehouse2', 'warehouse2', 'warehouse3'];

  // Tạo danh sách 70 tháng: từ Tháng 01/2021 đến Tháng 10/2026
  const months = [];
  for (let year = 2021; year <= 2026; year++) {
    const maxMonth = (year === 2026) ? 10 : 12;
    for (let m = 1; m <= maxMonth; m++) {
      months.push({ year, month: m });
    }
  }

  console.log(`📅 Tổng số tháng phân bổ: ${months.length} tháng (01/2021 -> 10/2026).`);

  // Phân bổ 1,000 lệnh nhập và 1,000 lệnh xuất qua 70 tháng (~14-15 lệnh mỗi loại/tháng)
  const TOTAL_IMPORTS = 1000;
  const TOTAL_EXPORTS = 1000;

  const importCounts = new Array(months.length).fill(Math.floor(TOTAL_IMPORTS / months.length));
  let remImp = TOTAL_IMPORTS % months.length;
  for (let i = months.length - 1; i >= 0 && remImp > 0; i--, remImp--) {
    importCounts[i]++;
  }

  const exportCounts = new Array(months.length).fill(Math.floor(TOTAL_EXPORTS / months.length));
  let remExp = TOTAL_EXPORTS % months.length;
  for (let i = months.length - 1; i >= 0 && remExp > 0; i--, remExp--) {
    exportCounts[i]++;
  }

  console.log('⚡ [2/5] Đang tạo dữ liệu 2,000 lệnh nhập xuất kèm liên kết nhân viên...');

  const importVouchersRows = [];
  const importItemsRows = [];
  const exportVouchersRows = [];
  const exportItemsRows = [];
  const stockHistoriesRows = [];
  const custDebtRows = [];
  const suppDebtRows = [];
  const receiptRows = [];
  const paymentRows = [];

  let voucherSeq = 1;
  let empIdx = 0;

  for (let mIdx = 0; mIdx < months.length; mIdx++) {
    const { year, month } = months[mIdx];
    const nImports = importCounts[mIdx];
    const nExports = exportCounts[mIdx];

    // --- A. TẠO CÁC LỆNH NHẬP (Đầu - giữa tháng) ---
    for (let i = 0; i < nImports; i++) {
      const impId = nextImportId++;
      const day = randomInt(1, Math.min(20, month === 2 ? 28 : 30));
      const hour = randomInt(8, 16);
      const min = randomInt(0, 59);
      const sec = randomInt(0, 59);
      const voucherDate = new Date(Date.UTC(year, month - 1, day, hour, min, sec));

      const dateStr = `${year}${String(month).padStart(2, '0')}${String(day).padStart(2, '0')}`;
      const voucherNumber = `PN${dateStr}-${String(voucherSeq++).padStart(4, '0')}`;
      const warehouse = randomChoice(warehouses);

      const supplier = randomChoice(suppliers);
      const assignedEmp = employees[empIdx % employees.length];
      empIdx++;

      // Chọn 2-4 sản phẩm
      const suppProds = productsBySupp[supplier.id] || [];
      const pool = suppProds.length >= 2 ? suppProds : products;
      const numItems = Math.min(randomInt(2, 4), pool.length);
      const chosen = [...pool].sort(() => 0.5 - Math.random()).slice(0, numItems);

      let subtotal = 0;
      const itemsList = [];

      for (const prod of chosen) {
        const itemId = nextImportItemId++;
        const pInfo = productStock[prod.id];
        const qty = randomInt(15, 60);
        const unitPrice = pInfo.unitCost;
        const lineTotal = qty * unitPrice;
        subtotal += lineTotal;

        itemsList.push({
          id: itemId,
          voucherId: impId,
          productId: prod.id,
          productName: prod.name,
          sku: prod.sku,
          quantity: qty,
          unitPrice: unitPrice,
          lineTotal: lineTotal
        });

        // Cập nhật tồn kho
        const beforeWhStock = pInfo[warehouse];
        const afterWhStock = beforeWhStock + qty;
        const beforeTotal = pInfo.total;
        const afterTotal = beforeTotal + qty;
        pInfo[warehouse] = afterWhStock;
        pInfo.total = afterTotal;

        // StockHistory
        const shId = nextStockHistoryId++;
        stockHistoriesRows.push(
          `(${shId}, ${prod.id}, ${sqlStr(warehouse)}, 'import', 'import_voucher', ${sqlStr(voucherNumber)}, ` +
          `${sqlStr(`Nhập hàng theo phiếu ${voucherNumber}`)}, ${sqlStr(`NV tiếp nhận: ${assignedEmp.name}`)}, ` +
          `${sqlNum(beforeWhStock)}, ${sqlNum(qty)}, ${sqlNum(afterWhStock)}, ${sqlNum(beforeTotal)}, ${sqlNum(afterTotal)}, ` +
          `${sqlDate(voucherDate)}, ${sqlDate(voucherDate)})`
        );
      }

      const discount = randomChoice([0, 0, 50000, 100000]);
      const totalAmount = Math.max(0, subtotal - discount);
      const payRatio = randomChoice([0, 0.5, 0.7, 1.0]);
      const paidAmount = Math.round((totalAmount * payRatio) / 1000) * 1000;
      const unpaidAmount = totalAmount - paidAmount;

      const notes = `Nhân viên tiếp nhận: ${assignedEmp.name} | Lệnh nhập bổ sung kho ${warehouse} đợt T${month}/${year}`;

      importVouchersRows.push(
        `(${impId}, ${sqlStr(voucherNumber)}, ${sqlDate(voucherDate)}, ${sqlStr(warehouse)}, ${supplier.id}, ` +
        `${sqlNum(subtotal)}, ${sqlNum(discount)}, ${sqlNum(totalAmount)}, ${sqlNum(paidAmount)}, ${sqlNum(unpaidAmount)}, ` +
        `'confirmed', NULL, ${sqlStr(notes)}, ${sqlDate(voucherDate)})`
      );

      for (const it of itemsList) {
        importItemsRows.push(
          `(${it.id}, ${it.voucherId}, ${it.productId}, ${sqlStr(it.productName)}, ${sqlStr(it.sku)}, ` +
          `${sqlNum(it.quantity)}, ${sqlNum(it.unitPrice)}, ${sqlNum(it.lineTotal)})`
        );
      }

      // Công nợ NCC
      if (unpaidAmount > 0) {
        const curDebt = supplierDebts[supplier.id];
        const newDebt = curDebt + unpaidAmount;
        supplierDebts[supplier.id] = newDebt;

        const sdId = nextSuppDebtId++;
        suppDebtRows.push(
          `(${sdId}, ${supplier.id}, 'import', 'import_voucher', ${sqlStr(voucherNumber)}, ` +
          `${sqlStr(`Ghi nhận nợ phải trả theo phiếu nhập ${voucherNumber}`)}, ${sqlStr(notes)}, ` +
          `${sqlNum(curDebt)}, ${sqlNum(unpaidAmount)}, ${sqlNum(newDebt)}, ${sqlDate(voucherDate)})`
        );
      }

      // Phiếu chi nếu thanh toán
      if (paidAmount > 0) {
        const pmId = nextPaymentId++;
        const pmNum = `PC${dateStr}-${String(pmId).padStart(6, '0')}`;
        paymentRows.push(
          `(${pmId}, ${sqlStr(pmNum)}, ${sqlDate(voucherDate)}, ${supplier.id}, NULL, ${sqlNum(paidAmount)}, ` +
          `'bank_transfer', 'completed', NULL, 'import_voucher', ${sqlStr(voucherNumber)}, ` +
          `${sqlStr(`Thanh toán tiền nhập hàng ${voucherNumber} - ${assignedEmp.name}`)}, ${sqlDate(voucherDate)})`
        );
      }
    }

    // --- B. TẠO CÁC LỆNH XUẤT (Giữa - cuối tháng) ---
    for (let i = 0; i < nExports; i++) {
      const expId = nextExportId++;
      const maxDay = (year === 2026 && month === 10) ? 20 : (month === 2 ? 28 : 28);
      const day = randomInt(5, maxDay);
      const hour = randomInt(8, 17);
      const min = randomInt(0, 59);
      const sec = randomInt(0, 59);
      const voucherDate = new Date(Date.UTC(year, month - 1, day, hour, min, sec));

      const dateStr = `${year}${String(month).padStart(2, '0')}${String(day).padStart(2, '0')}`;
      const voucherNumber = `PX${dateStr}-${String(voucherSeq++).padStart(4, '0')}`;
      const warehouse = randomChoice(warehouses);

      const customer = randomChoice(customers);
      const assignedEmp = employees[empIdx % employees.length];
      empIdx++;

      // Chọn 2-5 sản phẩm
      const numItems = Math.min(randomInt(2, 5), products.length);
      const chosen = [...products].sort(() => 0.5 - Math.random()).slice(0, numItems);

      let subtotalSale = 0;
      let totalCost = 0;
      const itemsList = [];

      for (const prod of chosen) {
        const itemId = nextExportItemId++;
        const pInfo = productStock[prod.id];
        const qty = randomInt(2, 12);
        const salePrice = pInfo.retailPrice;
        const unitCost = pInfo.unitCost;
        const lineTotal = qty * salePrice;

        subtotalSale += lineTotal;
        totalCost += (qty * unitCost);

        itemsList.push({
          id: itemId,
          voucherId: expId,
          productId: prod.id,
          quantity: qty,
          unitCost: unitCost,
          salePrice: salePrice,
          lineTotal: lineTotal
        });

        // Cập nhật tồn kho (-qty)
        const beforeWhStock = pInfo[warehouse];
        const afterWhStock = beforeWhStock - qty;
        const beforeTotal = pInfo.total;
        const afterTotal = beforeTotal - qty;
        pInfo[warehouse] = afterWhStock;
        pInfo.total = afterTotal;

        // StockHistory
        const shId = nextStockHistoryId++;
        stockHistoriesRows.push(
          `(${shId}, ${prod.id}, ${sqlStr(warehouse)}, 'export', 'export_voucher', ${sqlStr(voucherNumber)}, ` +
          `${sqlStr(`Xuất bán hàng ${voucherNumber}`)}, ${sqlStr(`NV bán hàng: ${assignedEmp.name}`)}, ` +
          `${sqlNum(beforeWhStock)}, ${sqlNum(-qty)}, ${sqlNum(afterWhStock)}, ${sqlNum(beforeTotal)}, ${sqlNum(afterTotal)}, ` +
          `${sqlDate(voucherDate)}, ${sqlDate(voucherDate)})`
        );
      }

      const discount = randomChoice([0, 0, 30000, 70000, 150000]);
      const totalSale = Math.max(0, subtotalSale - discount);
      const payRatio = randomChoice([0, 0.4, 0.7, 1.0]);
      const paidAmount = Math.round((totalSale * payRatio) / 1000) * 1000;
      const unpaidAmount = totalSale - paidAmount;

      const notes = `Nhân viên bán hàng: ${assignedEmp.name} | Xuất hàng cho khách ${customer.name}`;

      exportVouchersRows.push(
        `(${expId}, ${sqlStr(voucherNumber)}, ${sqlDate(voucherDate)}, ${sqlStr(warehouse)}, ${customer.id}, ` +
        `${sqlNum(subtotalSale)}, ${sqlNum(discount)}, ${sqlNum(totalSale)}, ${sqlNum(paidAmount)}, ${sqlNum(unpaidAmount)}, ` +
        `${sqlNum(totalCost)}, 'active', NULL, ${sqlStr(notes)}, ${sqlDate(voucherDate)}, ` +
        `${assignedEmp.id}, ${sqlStr(assignedEmp.name)})`
      );

      for (const it of itemsList) {
        exportItemsRows.push(
          `(${it.id}, ${it.voucherId}, ${it.productId}, ` +
          `${sqlNum(it.quantity)}, ${sqlNum(it.unitCost)}, ${sqlNum(it.salePrice)}, ${sqlNum(it.lineTotal)})`
        );
      }

      // Công nợ Khách hàng
      if (unpaidAmount > 0) {
        const curDebt = customerDebts[customer.id];
        const newDebt = curDebt + unpaidAmount;
        customerDebts[customer.id] = newDebt;

        const cdId = nextCustDebtId++;
        custDebtRows.push(
          `(${cdId}, ${customer.id}, 'export', 'export_voucher', ${sqlStr(voucherNumber)}, ` +
          `${sqlStr(`Xuất bán nợ theo phiếu ${voucherNumber}`)}, ${sqlStr(notes)}, ` +
          `${sqlNum(curDebt)}, ${sqlNum(unpaidAmount)}, ${sqlNum(newDebt)}, ${sqlDate(voucherDate)})`
        );
      }

      // Phiếu thu nếu khách trả tiền
      if (paidAmount > 0) {
        const rcId = nextReceiptId++;
        const rcNum = `PT${dateStr}-${String(rcId).padStart(6, '0')}`;
        receiptRows.push(
          `(${rcId}, ${sqlStr(rcNum)}, ${sqlDate(voucherDate)}, ${customer.id}, NULL, ${sqlNum(paidAmount)}, ` +
          `'cash', 'export_voucher', ${sqlStr(voucherNumber)}, ` +
          `${sqlStr(`Thu tiền bán hàng ${voucherNumber} - NV: ${assignedEmp.name}`)}, ${sqlDate(voucherDate)})`
        );
      }
    }
  }

  console.log(`📊 Đã tổng hợp thành công:`);
  console.log(`   - Phiếu Nhập: ${importVouchersRows.length} (Items: ${importItemsRows.length})`);
  console.log(`   - Phiếu Xuất: ${exportVouchersRows.length} (Items: ${exportItemsRows.length})`);
  console.log(`   - Sổ kho (StockHistories): ${stockHistoriesRows.length}`);
  console.log(`   - Lịch sử nợ KH / NCC: ${custDebtRows.length} / ${suppDebtRows.length}`);
  console.log(`   - Phiếu thu / chi: ${receiptRows.length} / ${paymentRows.length}`);

  console.log('\n✍️  [3/5] Đang tạo file SQL seed_2000_transactions.sql...');

  const sqlFilePath = path.join(__dirname, 'seed_2000_transactions.sql');
  const ws = fs.createWriteStream(sqlFilePath, { encoding: 'utf8' });

  ws.write(`-- =====================================================================\n`);
  ws.write(`-- Script: seed_2000_transactions.sql\n`);
  ws.write(`-- Tự động sinh 2,000 lệnh nhập & xuất (1,000 lệnh nhập, 1,000 lệnh xuất)\n`);
  ws.write(`-- Phân bổ trải dài từ 2021 đến 2026, gán với 5 nhân viên kinh doanh có sẵn\n`);
  ws.write(`-- Đồng bộ đầy đủ: StockHistories, Debts, Receipts, Payments\n`);
  ws.write(`-- =====================================================================\n\n`);
  ws.write(`SET client_encoding = 'UTF8';\n`);
  ws.write(`BEGIN;\n\n`);

  function writeChunkedInserts(tableName, columns, rows, chunkSize = 400) {
    if (!rows.length) return;
    ws.write(`-- Chèn dữ liệu vào bảng "${tableName}" (${rows.length} dòng)\n`);
    for (let i = 0; i < rows.length; i += chunkSize) {
      const slice = rows.slice(i, i + chunkSize);
      ws.write(`INSERT INTO "${tableName}" (${columns.map(c => `"${c}"`).join(', ')})\nVALUES\n  `);
      ws.write(slice.join(',\n  '));
      ws.write(`;\n\n`);
    }
  }

  // 1. Import Vouchers
  writeChunkedInserts('ImportVouchers', [
    'Id', 'VoucherNumber', 'Date', 'Warehouse', 'SupplierId',
    'SubtotalAmount', 'DiscountAmount', 'TotalAmount', 'PaidAmount', 'UnpaidAmount',
    'Status', 'CancelledAt', 'Notes', 'CreatedAt'
  ], importVouchersRows);

  // 2. Import Voucher Items
  writeChunkedInserts('ImportVoucherItems', [
    'Id', 'ImportVoucherId', 'ProductId', 'ProductName', 'Sku',
    'Quantity', 'UnitPrice', 'LineTotal'
  ], importItemsRows);

  // 3. Export Vouchers
  writeChunkedInserts('ExportVouchers', [
    'Id', 'VoucherNumber', 'Date', 'Warehouse', 'CustomerId',
    'SubtotalSale', 'DiscountAmount', 'TotalSale', 'PaidAmount', 'UnpaidAmount',
    'TotalCost', 'Status', 'CancelledAt', 'Notes', 'CreatedAt',
    'EmployeeId', 'EmployeeName'
  ], exportVouchersRows);

  // 4. Export Voucher Items
  writeChunkedInserts('ExportVoucherItems', [
    'Id', 'ExportVoucherId', 'ProductId',
    'Quantity', 'UnitCost', 'SalePrice', 'LineTotal'
  ], exportItemsRows);

  // 5. Stock Histories
  writeChunkedInserts('StockHistories', [
    'Id', 'ProductId', 'Warehouse', 'SourceType', 'ReferenceType', 'ReferenceId',
    'Reason', 'Note',
    'BeforeWarehouseStock', 'Delta', 'AfterWarehouseStock', 'BeforeTotalStock', 'AfterTotalStock',
    'ChangeDate', 'CreatedAt'
  ], stockHistoriesRows);

  // 6. Customer Debt Histories
  writeChunkedInserts('CustomerDebtHistories', [
    'Id', 'CustomerId', 'SourceType', 'ReferenceType', 'ReferenceId',
    'Reason', 'Note',
    'BeforeDebt', 'Delta', 'AfterDebt', 'CreatedAt'
  ], custDebtRows);

  // 7. Supplier Debt Histories
  writeChunkedInserts('SupplierDebtHistories', [
    'Id', 'SupplierId', 'SourceType', 'ReferenceType', 'ReferenceId',
    'Reason', 'Note',
    'BeforeDebt', 'Delta', 'AfterDebt', 'CreatedAt'
  ], suppDebtRows);

  // 8. Receipts
  writeChunkedInserts('Receipts', [
    'Id', 'ReceiptNumber', 'Date', 'CustomerId', 'SupplierId',
    'Amount', 'Method', 'RelatedVoucherType', 'RelatedVoucherId', 'Notes', 'CreatedAt'
  ], receiptRows);

  // 9. Payments
  writeChunkedInserts('Payments', [
    'Id', 'PaymentNumber', 'Date', 'SupplierId', 'CustomerId',
    'Amount', 'Method', 'Status', 'CancelledAt', 'RelatedVoucherType', 'RelatedVoucherId', 'Notes', 'CreatedAt'
  ], paymentRows);

  // 10. Cập nhật tồn kho sản phẩm
  ws.write(`-- Cập nhật tồn kho cuối cùng cho Products\n`);
  for (const pid in productStock) {
    const p = productStock[pid];
    ws.write(
      `UPDATE "Products" SET ` +
      `"StockWarehouse1" = ${sqlNum(p.warehouse1)}, ` +
      `"StockWarehouse2" = ${sqlNum(p.warehouse2)}, ` +
      `"StockWarehouse3" = ${sqlNum(p.warehouse3)}, ` +
      `"TotalStock" = ${sqlNum(p.total)}, ` +
      `"UnitCost" = ${sqlNum(p.unitCost)}, ` +
      `"RetailPrice" = ${sqlNum(p.retailPrice)}, ` +
      `"UpdatedAt" = NOW() ` +
      `WHERE "Id" = ${p.id};\n`
    );
  }
  ws.write(`\n`);

  // 11. Cập nhật nợ khách hàng
  ws.write(`-- Cập nhật nợ cuối cùng cho Customers\n`);
  for (const cid in customerDebts) {
    ws.write(`UPDATE "Customers" SET "Debt" = ${sqlNum(customerDebts[cid])}, "UpdatedAt" = NOW() WHERE "Id" = ${cid};\n`);
  }
  ws.write(`\n`);

  // 12. Cập nhật nợ NCC
  ws.write(`-- Cập nhật nợ cuối cùng cho Suppliers\n`);
  for (const sid in supplierDebts) {
    ws.write(`UPDATE "Suppliers" SET "Debt" = ${sqlNum(supplierDebts[sid])}, "UpdatedAt" = NOW() WHERE "Id" = ${sid};\n`);
  }
  ws.write(`\n`);

  // 13. Cập nhật lại Identity Sequence cho tất cả các bảng
  ws.write(`-- Reset các Sequence về giá trị MAX mới nhất để tránh đụng khóa chính trong tương lai\n`);
  const tablesWithSeq = [
    'ExportVouchers', 'ExportVoucherItems',
    'ImportVouchers', 'ImportVoucherItems',
    'StockHistories', 'CustomerDebtHistories', 'SupplierDebtHistories',
    'Receipts', 'Payments'
  ];
  for (const tbl of tablesWithSeq) {
    ws.write(`SELECT setval(pg_get_serial_sequence('"${tbl}"', 'Id'), (SELECT COALESCE(MAX("Id"), 1) FROM "${tbl}"));\n`);
  }

  ws.write(`\nCOMMIT;\n`);
  ws.end();

  await new Promise(res => ws.on('finish', res));
  console.log(`💾 Đã ghi xong file SQL: ${sqlFilePath} (${(fs.statSync(sqlFilePath).size / 1024 / 1024).toFixed(2)} MB)`);

  // Tạo file batch để tiện chạy thủ công bất cứ lúc nào
  const batFilePath = path.join(__dirname, 'run_seed_2000.bat');
  fs.writeFileSync(batFilePath, `@echo off
chcp 65001 > nul
echo Đang nạp 2000 giao dịch vào PostgreSQL container debtmanager_db...
docker cp seed_2000_transactions.sql debtmanager_db:/tmp/seed_2000_transactions.sql
docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/seed_2000_transactions.sql
echo Hoàn tất nạp dữ liệu!
pause
`, 'utf8');

  // [4/5] Thực thi trực tiếp vào PostgreSQL
  console.log('\n🚀 [4/5] Đang nạp script SQL trực tiếp vào PostgreSQL container debtmanager_db...');
  execSync(`docker cp "${sqlFilePath}" debtmanager_db:/tmp/seed_2000_transactions.sql`, { stdio: 'pipe' });
  const psqlOutput = execSync(`docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/seed_2000_transactions.sql`, {
    encoding: 'utf-8'
  });

  // [5/5] Kiểm tra và hiển thị kết quả
  console.log('\n📊 [5/5] Kiểm tra lại dữ liệu sau khi nạp:');
  const verifyQuery = `
    SELECT 
      (SELECT COUNT(*) FROM "ImportVouchers") AS "Tổng Phiếu Nhập",
      (SELECT COUNT(*) FROM "ExportVouchers") AS "Tổng Phiếu Xuất",
      (SELECT COUNT(*) FROM "StockHistories") AS "Tổng Sổ Kho",
      (SELECT MIN("Date")::date FROM "ExportVouchers") AS "Từ Ngày",
      (SELECT MAX("Date")::date FROM "ExportVouchers") AS "Đến Ngày";

    SELECT 
      e."Id" AS "Mã NV",
      e."Name" AS "Tên Nhân Viên",
      COUNT(ev."Id") AS "Số Đơn Xuất",
      COALESCE(SUM(ev."TotalSale"), 0) AS "Tổng Doanh Thu (VNĐ)"
    FROM "Employees" e
    LEFT JOIN "ExportVouchers" ev ON e."Id" = ev."EmployeeId"
    GROUP BY e."Id", e."Name"
    ORDER BY e."Id";
  `.trim();

  const verifyRes = execSync('docker exec -i debtmanager_db psql -U postgres -d debtmanager_db', {
    input: verifyQuery,
    encoding: 'utf-8'
  });

  console.log(verifyRes);
  console.log('🎉 ĐÃ HOÀN TẤT THÊM 2,000 LỆNH VÀO DATABASE THÀNH CÔNG!');
}

main().catch(err => {
  console.error('❌ Thất bại:', err);
  process.exit(1);
});

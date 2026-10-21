// seed-more-transactions.js
// Tạo thêm số lượng lớn phiếu xuất / nhập / thu / chi cho KH, NCC, SP hiện có
// Trải rộng khắp năm 2026 và tập trung nhiều vào tháng 8, 9, 10/2026

const API_BASE = 'http://localhost:5050/api';

async function request(path, options = {}) {
  const url = `${API_BASE}${path}`;
  const res = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`HTTP ${res.status} on ${path}: ${errorText}`);
  }
  const json = await res.json();
  return json.data;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomChoice(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomDate(year, month, minDay = 1, maxDay = 28) {
  const day = randomInt(minDay, maxDay);
  const hour = randomInt(8, 17);
  const min = randomInt(0, 59);
  const sec = randomInt(0, 59);
  return new Date(Date.UTC(year, month - 1, day, hour, min, sec)).toISOString();
}

async function run() {
  console.log('🚀 Đang tải danh mục hiện có từ hệ thống...');

  const [suppliers, customers, products] = await Promise.all([
    request('/suppliers?all=true'),
    request('/customers?all=true'),
    request('/products?all=true'),
  ]);

  console.log(`✅ Đã tải: ${suppliers.length} NCC, ${customers.length} KH, ${products.length} Sản phẩm.`);

  if (!suppliers.length || !customers.length || !products.length) {
    console.error('❌ Dữ liệu không đầy đủ để tạo giao dịch.');
    process.exit(1);
  }

  const warehouses = ['warehouse1', 'warehouse2', 'warehouse3'];

  // Map sản phẩm theo NCC
  const productsBySupplier = {};
  for (const p of products) {
    const sId = p.supplierId || 0;
    if (!productsBySupplier[sId]) productsBySupplier[sId] = [];
    productsBySupplier[sId].push(p);
  }

  // 10 tháng trong năm 2026 (với tỷ trọng cao ở tháng 8, 9, 10)
  const monthConfigs = [
    { year: 2026, month: 1, imports: 4, exports: 8, receipts: 4, payments: 3 },
    { year: 2026, month: 2, imports: 4, exports: 8, receipts: 4, payments: 3 },
    { year: 2026, month: 3, imports: 5, exports: 10, receipts: 5, payments: 4 },
    { year: 2026, month: 4, imports: 5, exports: 10, receipts: 5, payments: 4 },
    { year: 2026, month: 5, imports: 6, exports: 12, receipts: 6, payments: 4 },
    { year: 2026, month: 6, imports: 6, exports: 12, receipts: 6, payments: 4 },
    { year: 2026, month: 7, imports: 7, exports: 14, receipts: 6, payments: 5 },
    { year: 2026, month: 8, imports: 10, exports: 20, receipts: 8, payments: 6 },
    { year: 2026, month: 9, imports: 12, exports: 24, receipts: 10, payments: 8 },
    { year: 2026, month: 10, imports: 15, exports: 30, receipts: 12, payments: 10 },
  ];

  let createdImportsCount = 0;
  let createdExportsCount = 0;
  let createdReceiptsCount = 0;
  let createdPaymentsCount = 0;

  for (const cfg of monthConfigs) {
    console.log(`\n📅 === Đang tạo giao dịch cho Tháng ${cfg.month}/${cfg.year} ===`);

    // A. TẠO PHIẾU NHẬP
    for (let i = 0; i < cfg.imports; i++) {
      const supplier = randomChoice(suppliers);
      const suppProducts = productsBySupplier[supplier.id] || [];
      const productPool = suppProducts.length >= 2 ? suppProducts : products;

      const numItems = Math.min(randomInt(2, 5), productPool.length);
      const chosenItems = [...productPool].sort(() => 0.5 - Math.random()).slice(0, numItems);

      const items = chosenItems.map((prod) => {
        const qty = randomInt(15, 75);
        const unitPrice = prod.unitCost > 0 ? prod.unitCost : randomInt(20, 120) * 10000;
        return {
          productId: prod.id,
          quantity: qty,
          unitPrice: unitPrice,
        };
      });

      const wh = randomChoice(warehouses);
      const maxDay = cfg.month === 10 ? 19 : 28;
      const voucherDate = randomDate(cfg.year, cfg.month, 1, maxDay);
      const subtotal = items.reduce((s, it) => s + it.quantity * it.unitPrice, 0);

      const payRatio = randomChoice([0, 0.4, 0.7, 1.0]);
      const paidAmount = Math.round((subtotal * payRatio) / 1000) * 1000;

      try {
        const created = await request('/imports', {
          method: 'POST',
          body: JSON.stringify({
            supplierId: supplier.id,
            warehouse: wh,
            date: voucherDate,
            discountAmount: randomChoice([0, 0, 50000, 100000]),
            paidAmount: paidAmount,
            notes: `Nhập bổ sung kho ${wh} đợt tháng ${cfg.month}/${cfg.year}`,
            items: items,
          }),
        });
        createdImportsCount++;
        process.stdout.write(`+`);
      } catch (err) {
        console.error(`\nLỗi tạo phiếu nhập: ${err.message}`);
      }
      await sleep(25);
    }

    // B. TẠO PHIẾU XUẤT
    for (let i = 0; i < cfg.exports; i++) {
      const customer = randomChoice(customers);
      const numItems = Math.min(randomInt(2, 6), products.length);
      const chosenItems = [...products].sort(() => 0.5 - Math.random()).slice(0, numItems);

      const items = chosenItems.map((prod) => {
        const qty = randomInt(2, 20);
        const salePrice = prod.retailPrice > 0 ? prod.retailPrice : (prod.unitCost > 0 ? prod.unitCost * 1.3 : 150000);
        return {
          productId: prod.id,
          quantity: qty,
          salePrice: Math.round(salePrice / 1000) * 1000,
        };
      });

      const wh = randomChoice(warehouses);
      const maxDay = cfg.month === 10 ? 19 : 28;
      const voucherDate = randomDate(cfg.year, cfg.month, 1, maxDay);
      const subtotal = items.reduce((s, it) => s + it.quantity * it.salePrice, 0);

      const discountPercent = randomChoice([0, 0, 0, 3, 5]);
      const discountVal = subtotal * (discountPercent / 100);
      const totalSale = subtotal - discountVal;

      const payRatio = randomChoice([0, 0.5, 0.8, 1.0]);
      const paidAmount = Math.round((totalSale * payRatio) / 1000) * 1000;

      try {
        const created = await request('/exports', {
          method: 'POST',
          body: JSON.stringify({
            customerId: customer.id,
            warehouse: wh,
            date: voucherDate,
            discountPercent: discountPercent > 0 ? discountPercent : null,
            paidAmount: paidAmount,
            notes: `Xuất bán cho ${customer.name} tháng ${cfg.month}/${cfg.year}`,
            items: items,
          }),
        });
        createdExportsCount++;
        process.stdout.write(`*`);
      } catch (err) {
        console.error(`\nLỗi tạo phiếu xuất: ${err.message}`);
      }
      await sleep(25);
    }

    // C. TẠO PHIẾU THU TIỀN TỪ KHÁCH
    for (let i = 0; i < cfg.receipts; i++) {
      const customer = randomChoice(customers);
      const amount = randomInt(10, 100) * 50000; // 500k -> 5tr
      const maxDay = cfg.month === 10 ? 19 : 28;
      const voucherDate = randomDate(cfg.year, cfg.month, 2, maxDay);

      try {
        await request('/receipts', {
          method: 'POST',
          body: JSON.stringify({
            customerId: customer.id,
            amount: amount,
            method: randomChoice(['cash', 'bank_transfer']),
            date: voucherDate,
            notes: `Thu tiền thanh toán công nợ tháng ${cfg.month}/${cfg.year}`,
          }),
        });
        createdReceiptsCount++;
        process.stdout.write(`$`);
      } catch (err) {
        // ignore
      }
      await sleep(20);
    }

    // D. TẠO PHIẾU CHI TIỀN CHO NCC
    for (let i = 0; i < cfg.payments; i++) {
      const supplier = randomChoice(suppliers);
      const amount = randomInt(20, 150) * 100000; // 2tr -> 15tr
      const maxDay = cfg.month === 10 ? 19 : 28;
      const voucherDate = randomDate(cfg.year, cfg.month, 3, maxDay);

      try {
        await request('/payments', {
          method: 'POST',
          body: JSON.stringify({
            supplierId: supplier.id,
            amount: amount,
            method: randomChoice(['bank_transfer', 'cash']),
            date: voucherDate,
            notes: `Chi tiền thanh toán tiền hàng NCC tháng ${cfg.month}/${cfg.year}`,
          }),
        });
        createdPaymentsCount++;
        process.stdout.write(`%`);
      } catch (err) {
        // ignore
      }
      await sleep(20);
    }
  }

  console.log(`\n\n🎉 === HOÀN THÀNH TẠO THÊM DỮ LIỆU ===`);
  console.log(`- Phiếu nhập kho đã tạo mới: ${createdImportsCount}`);
  console.log(`- Phiếu xuất kho đã tạo mới: ${createdExportsCount}`);
  console.log(`- Phiếu thu tiền đã tạo mới: ${createdReceiptsCount}`);
  console.log(`- Phiếu chi tiền đã tạo mới: ${createdPaymentsCount}`);
  console.log(`- Toàn bộ dữ liệu trải dài từ Tháng 1/2026 đến Tháng 10/2026 cho tất cả các NCC, KH, SP và Kho.`);
}

run().catch((err) => {
  console.error('Fatal error:', err);
});

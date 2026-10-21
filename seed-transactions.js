// seed-transactions.js
// Script tạo lịch sử nhập / xuất random test cho KH / NCC / SP hiện tại
// Trải dài trên nhiều ngày và nhiều tháng khác nhau qua API http://localhost:5050/api
// Đảm bảo cập nhật chính xác tồn kho từng kho, công nợ và sổ kho (StockHistory, DebtHistory)

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
  console.log('🚀 Bắt đầu tạo dữ liệu lịch sử Nhập / Xuất ngẫu nhiên...');

  // 1. Lấy dữ liệu NCC, KH, SP hiện tại
  const [suppliers, customers, products] = await Promise.all([
    request('/suppliers?all=true'),
    request('/customers?all=true'),
    request('/products?all=true'),
  ]);

  console.log(`📦 Tải thành công: ${suppliers.length} NCC, ${customers.length} KH, ${products.length} Sản phẩm.`);

  if (!suppliers.length || !customers.length || !products.length) {
    console.error('❌ Dữ liệu nhà cung cấp, khách hàng hoặc sản phẩm bị trống.');
    process.exit(1);
  }

  // Danh sách các tháng để phân bổ (từ T1 đến T10 năm 2026)
  const targetMonths = [
    { year: 2026, month: 1 },
    { year: 2026, month: 2 },
    { year: 2026, month: 3 },
    { year: 2026, month: 4 },
    { year: 2026, month: 5 },
    { year: 2026, month: 6 },
    { year: 2026, month: 7 },
    { year: 2026, month: 8 },
    { year: 2026, month: 9 },
    { year: 2026, month: 10 },
  ];

  const warehouses = ['warehouse1', 'warehouse2', 'warehouse3'];

  // Tạo map sản phẩm theo NCC
  const productsBySupplier = {};
  for (const p of products) {
    if (!productsBySupplier[p.supplierId]) {
      productsBySupplier[p.supplierId] = [];
    }
    productsBySupplier[p.supplierId].push(p);
  }

  let totalImports = 0;
  let totalExports = 0;
  let totalReceipts = 0;
  let totalPayments = 0;

  // Lần lượt từng tháng: Tạo các đợt Nhập hàng, Xuất bán, Thu tiền và Chi tiền
  for (const m of targetMonths) {
    console.log(`\n📅 --- ĐANG XỬ LÝ THÁNG ${m.month}/${m.year} ---`);

    // A. TẠO 3-5 PHIẾU NHẬP HÀNG TRONG THÁNG (Đầu tháng đến giữa tháng: ngày 1 -> 15)
    const numImports = randomInt(3, 5);
    for (let i = 0; i < numImports; i++) {
      const supplier = randomChoice(suppliers);
      const suppProducts = productsBySupplier[supplier.id] || [];
      const chosenProducts = suppProducts.length > 0 ? suppProducts : products;

      // Chọn 2-4 sản phẩm để nhập
      const numItems = Math.min(randomInt(2, 4), chosenProducts.length);
      const shuffled = [...chosenProducts].sort(() => 0.5 - Math.random());
      const selectedProds = shuffled.slice(0, numItems);

      const items = selectedProds.map((prod) => {
        const qty = randomInt(20, 80);
        const unitPrice = prod.unitCost > 0 ? prod.unitCost : 50000;
        return {
          productId: prod.id,
          quantity: qty,
          unitPrice: unitPrice,
        };
      });

      const wh = randomChoice(warehouses);
      const voucherDate = randomDate(m.year, m.month, 1, 15);
      const subtotal = items.reduce((s, it) => s + it.quantity * it.unitPrice, 0);
      
      // Tỷ lệ trả trước: 0%, 50%, 80% hoặc 100%
      const payRatios = [0, 0.5, 0.8, 1.0];
      const payRatio = randomChoice(payRatios);
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
            notes: `Nhập bổ sung kho ${wh} đợt tháng ${m.month}/${m.year}`,
            items: items,
          }),
        });
        totalImports++;
        console.log(`  ➕ [Nhập kho] ${created.voucherNumber} - ${supplier.name.substring(0, 30)}... | Kho: ${wh} | Ngày: ${voucherDate.substring(0, 10)} | Tiền: ${created.totalAmount.toLocaleString('vi-VN')} đ`);
      } catch (err) {
        console.error(`  ❌ Lỗi tạo phiếu nhập:`, err.message);
      }
      await sleep(50);
    }

    // B. TẠO 5-8 PHIẾU XUẤT BÁN TRONG THÁNG (Rải rác từ ngày 5 -> 28)
    const numExports = randomInt(5, 8);
    for (let i = 0; i < numExports; i++) {
      const customer = randomChoice(customers);
      const numItems = Math.min(randomInt(2, 5), products.length);
      const shuffled = [...products].sort(() => 0.5 - Math.random());
      const selectedProds = shuffled.slice(0, numItems);

      const items = selectedProds.map((prod) => {
        const qty = randomInt(3, 15);
        const salePrice = prod.retailPrice > 0 ? prod.retailPrice : (prod.unitCost * 1.25);
        return {
          productId: prod.id,
          quantity: qty,
          salePrice: salePrice,
        };
      });

      const wh = randomChoice(warehouses);
      const voucherDate = randomDate(m.year, m.month, 5, 28);
      const subtotal = items.reduce((s, it) => s + it.quantity * it.salePrice, 0);

      // Chiết khấu ngẫu nhiên 0%, 2%, 5%
      const discountPercent = randomChoice([0, 0, 2, 5]);
      const discountVal = subtotal * (discountPercent / 100);
      const totalSale = subtotal - discountVal;

      // Khách trả trước: 0%, 50%, 80% hoặc 100%
      const payRatios = [0, 0.4, 0.7, 1.0];
      const payRatio = randomChoice(payRatios);
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
            notes: `Xuất bán cho ${customer.name.substring(0, 25)} tháng ${m.month}/${m.year}`,
            items: items,
          }),
        });
        totalExports++;
        console.log(`  🛒 [Xuất kho] ${created.voucherNumber} - ${customer.name.substring(0, 30)}... | Kho: ${wh} | Ngày: ${voucherDate.substring(0, 10)} | Tiền: ${created.totalSale.toLocaleString('vi-VN')} đ (Còn nợ: ${created.unpaidAmount.toLocaleString('vi-VN')} đ)`);
      } catch (err) {
        console.error(`  ❌ Lỗi tạo phiếu xuất:`, err.message);
      }
      await sleep(50);
    }

    // C. TẠO 4-6 PHIẾU THU TIỀN TỪ KHÁCH HÀNG (Thu nợ tiền hàng: ngày 10 -> 28)
    const numCustomerReceipts = randomInt(4, 6);
    for (let i = 0; i < numCustomerReceipts; i++) {
      const customer = randomChoice(customers);
      const amount = randomInt(10, 80) * 50000; // 500.000 -> 4.000.000 đ
      const method = randomChoice(['cash', 'bank_transfer']);
      const voucherDate = randomDate(m.year, m.month, 10, 28);

      try {
        const created = await request('/receipts', {
          method: 'POST',
          body: JSON.stringify({
            customerId: customer.id,
            amount: amount,
            method: method,
            date: voucherDate,
            notes: `Thu tiền thanh toán công nợ của ${customer.name} đợt tháng ${m.month}/${m.year}`,
          }),
        });
        totalReceipts++;
        console.log(`  💵 [Thu tiền KH] ${created.receiptNumber} - ${customer.name.substring(0, 30)}... | Số tiền: ${amount.toLocaleString('vi-VN')} đ (${method === 'bank_transfer' ? 'CK' : 'Tiền mặt'})`);
      } catch (err) {
        console.error(`  ❌ Lỗi tạo phiếu thu KH:`, err.message);
      }
      await sleep(40);
    }

    // D. TẠO 3-5 PHIẾU CHI TIỀN TRẢ NHÀ CUNG CẤP (Thanh toán công nợ NCC: ngày 12 -> 28)
    const numSupplierPayments = randomInt(3, 5);
    for (let i = 0; i < numSupplierPayments; i++) {
      const supplier = randomChoice(suppliers);
      const amount = randomInt(20, 120) * 100000; // 2.000.000 -> 12.000.000 đ
      const method = randomChoice(['bank_transfer', 'bank_transfer', 'cash']);
      const voucherDate = randomDate(m.year, m.month, 12, 28);

      try {
        const created = await request('/payments', {
          method: 'POST',
          body: JSON.stringify({
            supplierId: supplier.id,
            amount: amount,
            method: method,
            date: voucherDate,
            notes: `Chi tiền thanh toán tiền hàng NCC ${supplier.name} tháng ${m.month}/${m.year}`,
          }),
        });
        totalPayments++;
        console.log(`  💳 [Chi trả NCC] ${created.paymentNumber} - ${supplier.name.substring(0, 30)}... | Số tiền: ${amount.toLocaleString('vi-VN')} đ (${method === 'bank_transfer' ? 'CK' : 'Tiền mặt'})`);
      } catch (err) {
        console.error(`  ❌ Lỗi tạo phiếu chi NCC:`, err.message);
      }
      await sleep(40);
    }

    // E. GIAO DỊCH ĐẶC BIỆT THỈNH THOẢNG:
    // 1. Chi hoàn lại tiền cho Khách Hàng (1 phiếu mỗi 2 tháng)
    if (m.month % 2 === 0) {
      const customer = randomChoice(customers);
      const amount = randomInt(4, 20) * 50000; // 200.000 -> 1.000.000 đ
      const voucherDate = randomDate(m.year, m.month, 15, 28);
      try {
        const created = await request('/payments', {
          method: 'POST',
          body: JSON.stringify({
            customerId: customer.id,
            amount: amount,
            method: 'cash',
            date: voucherDate,
            notes: `Chi tiền hoàn trả khách hàng ${customer.name} (trả cọc/hàng hoàn)`,
          }),
        });
        totalPayments++;
        console.log(`  💸 [Chi hoàn tiền KH] ${created.paymentNumber} - ${customer.name.substring(0, 25)}... | Tiền: ${amount.toLocaleString('vi-VN')} đ`);
      } catch (err) {
        console.error(`  ❌ Lỗi chi hoàn tiền KH:`, err.message);
      }
      await sleep(40);
    }

    // 2. Thu tiền từ NCC (chiết khấu / hoàn tiền thừa) (1 phiếu mỗi 2 tháng)
    if (m.month % 2 === 1) {
      const supplier = randomChoice(suppliers);
      const amount = randomInt(5, 30) * 100000; // 500.000 -> 3.000.000 đ
      const voucherDate = randomDate(m.year, m.month, 15, 28);
      try {
        const created = await request('/receipts', {
          method: 'POST',
          body: JSON.stringify({
            supplierId: supplier.id,
            amount: amount,
            method: 'bank_transfer',
            date: voucherDate,
            notes: `Thu tiền chiết khấu / hoàn tiền từ NCC ${supplier.name}`,
          }),
        });
        totalReceipts++;
        console.log(`  💰 [Thu tiền từ NCC] ${created.receiptNumber} - ${supplier.name.substring(0, 25)}... | Tiền: ${amount.toLocaleString('vi-VN')} đ`);
      } catch (err) {
        console.error(`  ❌ Lỗi thu tiền NCC:`, err.message);
      }
      await sleep(40);
    }
  }

  console.log(`\n🎉 HOÀN THÀNH TẠO DỮ LIỆU!`);
  console.log(`- Tổng số phiếu nhập đã tạo: ${totalImports}`);
  console.log(`- Tổng số phiếu xuất đã tạo: ${totalExports}`);
  console.log(`- Tổng số phiếu thu đã tạo: ${totalReceipts}`);
  console.log(`- Tổng số phiếu chi đã tạo: ${totalPayments}`);
  console.log(`- Phạm vi thời gian: Trải dài từ Tháng 1/2026 đến Tháng 10/2026`);
  console.log(`- Tất cả dữ liệu Sổ Quỹ (Thu/Chi), Sổ Nợ KH/NCC và Báo cáo Nhập-Xuất-Tồn đã đầy đủ.`);
}

run().catch((err) => {
  console.error('Fatal error:', err);
});

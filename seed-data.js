// seed-data.js - Script tạo dữ liệu ngẫu nhiên cho Nhà cung cấp, Khách hàng, và Sản phẩm
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

// 1. Dữ liệu Nhà Cung Cấp
const suppliersData = [
  {
    code: 'NCC-DMD01',
    name: 'Công ty TNHH Phân Phối Điện Máy Toàn Cầu',
    contactName: 'Trần Văn Mạnh',
    phonesJson: '0903112233',
    email: 'contact@toancaudienmay.vn',
    addressesJson: 'Tầng 5, Tòa nhà Charmvit, 117 Trần Duy Hưng, Cầu Giấy, Hà Nội',
    creditLimit: 500000000,
    initialDebt: 45000000,
    bankAccount: '19035678901019 - Techcombank CN Hà Nội',
    taxNumber: '0108923451',
    notes: 'Đối tác chiến lược nhóm thiết bị gia dụng và điện tử',
  },
  {
    code: 'NCC-VLXD02',
    name: 'Tổng Kho Vật Liệu Xây Dựng Miền Nam',
    contactName: 'Nguyễn Thị Bích Ngọc',
    phonesJson: '0918234567',
    email: 'sales@vlxdmiennam.com.vn',
    addressesJson: 'Lô C2, KCN Cát Lái 2, TP. Thủ Đức, TP. Hồ Chí Minh',
    creditLimit: 300000000,
    initialDebt: 82000000,
    bankAccount: '0071001234567 - Vietcombank CN TP.HCM',
    taxNumber: '0312456789',
    notes: 'Cung cấp sắt thép, xi măng, sơn nước công trình',
  },
  {
    code: 'NCC-TIEDUNG03',
    name: 'Nhà Phân Phối Hàng Tiêu Dùng & Nước Giải Khát Ánh Dương',
    contactName: 'Lê Hoàng Nam',
    phonesJson: '0987654321',
    email: 'anhduong.fmcg@gmail.com',
    addressesJson: '45 Đường số 8, Phường An Khánh, TP. Thủ Đức, TP. Hồ Chí Minh',
    creditLimit: 200000000,
    initialDebt: 15500000,
    bankAccount: '1028374650 - Vietinbank CN Chợ Lớn',
    taxNumber: '0319876543',
    notes: 'Chiết khấu 3% cho đơn hàng thanh toán trong vòng 15 ngày',
  },
  {
    code: 'NCC-THIETBI04',
    name: 'Công ty CP Công Nghệ & Thiết Bị Số An Khang',
    contactName: 'Phạm Đức Thắng',
    phonesJson: '0934567890',
    email: 'kinhdoanh@ankhangtech.vn',
    addressesJson: '234 Hoàng Văn Thụ, Phường 4, Quận Tân Bình, TP. Hồ Chí Minh',
    creditLimit: 400000000,
    initialDebt: 0,
    bankAccount: '0441000678901 - VCB CN Tân Bình',
    taxNumber: '0314561234',
    notes: 'Nhà nhập khẩu chính hãng phụ kiện máy tính, camera và mạng',
  },
  {
    code: 'NCC-MAYMAC05',
    name: 'Xưởng May Gia Công & Bảo Hộ Lao Động Việt Đức',
    contactName: 'Vũ Quốc Huy',
    phonesJson: '0978112244',
    email: 'vietduc.garment@gmail.com',
    addressesJson: 'Khu công nghiệp Sóng Thần 1, Dĩ An, Bình Dương',
    creditLimit: 150000000,
    initialDebt: 22000000,
    bankAccount: '2200205123456 - Agribank CN Bình Dương',
    taxNumber: '3702123456',
    notes: 'Chuyên cung cấp quần áo đồng phục, bảo hộ lao động, vải sợi',
  },
  {
    code: 'NCC-HOACHAT06',
    name: 'Công ty TNHH Hóa Mỹ Phẩm & Tẩy Rửa Xanh EcoClean',
    contactName: 'Đặng Mai Phương',
    phonesJson: '0909887766',
    email: 'info@ecoclean.vn',
    addressesJson: '128 Lê Văn Khương, Quận 12, TP. Hồ Chí Minh',
    creditLimit: 180000000,
    initialDebt: 0,
    bankAccount: '119000188999 - MB Bank CN Sài Gòn',
    taxNumber: '0318991122',
    notes: 'Hàng tiêu dùng sinh học xuất xứ chuẩn an toàn môi trường',
  },
];

// 2. Dữ liệu Khách Hàng
const customersData = [
  {
    code: 'KH-DAINAM',
    name: 'Công ty Cổ Phần Xây Dựng & Trang Trí Đại Nam',
    contactName: 'Ông Đỗ Quốc Bảo',
    phonesJson: '0913556677',
    email: 'dainam.corp@gmail.com',
    addressesJson: '88 Nguyễn Thị Minh Khai, Phường 6, Quận 3, TP. Hồ Chí Minh',
    creditLimit: 150000000,
    initialDebt: 35000000,
    notes: 'Khách hàng VIP mảng thi công dân dụng, hạn nợ 30 ngày',
  },
  {
    code: 'KH-MINHANH',
    name: 'Chuỗi Cửa Hàng Tiện Lợi Minh Anh Mart',
    contactName: 'Bà Nguyễn Thu Hà',
    phonesJson: '0908123456',
    email: 'minhanhmart@yahoo.com',
    addressesJson: '12 Tân Kỳ Tân Quý, Quận Tân Phú, TP. Hồ Chí Minh',
    creditLimit: 80000000,
    initialDebt: 12500000,
    notes: 'Lấy hàng định kỳ hàng tuần, thanh toán chuyển khoản',
  },
  {
    code: 'KH-TUANHUNG',
    name: 'Đại Lý Điện Nước & Kim Khí Tuấn Hưng',
    contactName: 'Anh Lê Tuấn Hưng',
    phonesJson: '0979888999',
    email: 'tuanhungdiennuoc@gmail.com',
    addressesJson: '456 Lê Duẩn, TP. Buôn Ma Thuột, Đắk Lắk',
    creditLimit: 200000000,
    initialDebt: 68000000,
    notes: 'Đại lý cấp 1 khu vực Tây Nguyên',
  },
  {
    code: 'KH-GREENLIFE',
    name: 'Siêu Thị Mini GreenLife Organic',
    contactName: 'Chị Hoàng Mai Lan',
    phonesJson: '0938445566',
    email: 'greenlife.organics@gmail.com',
    addressesJson: '15 Thảo Điền, TP. Thủ Đức, TP. Hồ Chí Minh',
    creditLimit: 50000000,
    initialDebt: 8200000,
    notes: 'Chuyên hàng hóa mỹ phẩm sinh học và gia dụng thân thiện môi trường',
  },
  {
    code: 'KH-HUNGPHAT',
    name: 'Công ty TNHH Cơ Điện & Công Nghệ Hưng Phát',
    contactName: 'Kỹ sư Vũ Đình Trọng',
    phonesJson: '0983223344',
    email: 'hungphat.mep@gmail.com',
    addressesJson: 'Số 10 KCN Quang Minh, Mê Linh, Hà Nội',
    creditLimit: 300000000,
    initialDebt: 95000000,
    notes: 'Nhận thầu cơ điện tòa nhà cao tầng',
  },
  {
    code: 'KH-THANHTAM',
    name: 'Hộ Kinh Doanh Bách Hóa Tổng Hợp Thanh Tâm',
    contactName: 'Cô Võ Thanh Tâm',
    phonesJson: '0902334455',
    email: 'thanhtam.bachhoa@gmail.com',
    addressesJson: 'Chợ Bà Chiểu, Quận Bình Thạnh, TP. Hồ Chí Minh',
    creditLimit: 40000000,
    initialDebt: 0,
    notes: 'Khách hàng uy tín lâu năm, trả tiền mặt khi giao hàng',
  },
  {
    code: 'KH-SAOVIET',
    name: 'Công ty Giải Pháp Tin Học & Viễn Thông Sao Việt',
    contactName: 'Trương Công Danh',
    phonesJson: '0912998877',
    email: 'saoviet.telecom@gmail.com',
    addressesJson: '77 Võ Văn Tần, Phường Võ Thị Sáu, Quận 3, TP. Hồ Chí Minh',
    creditLimit: 120000000,
    initialDebt: 24000000,
    notes: 'Thường mua cáp mạng, camera, thiết bị chia cổng',
  },
  {
    code: 'KH-VIETTIEN',
    name: 'Xí Nghiệp Sản Xuất & Chế Biến Gỗ Việt Tiến',
    contactName: 'Đặng Quốc Huy',
    phonesJson: '0944556677',
    email: 'viettien.wood@gmail.com',
    addressesJson: 'Ấp 3, Xã Bình Mỹ, Huyện Củ Chi, TP. Hồ Chí Minh',
    creditLimit: 100000000,
    initialDebt: 41000000,
    notes: 'Nhập bảo hộ lao động và vật tư kim khí phục vụ nhà xưởng',
  },
];

// 3. Danh mục các sản phẩm mẫu tương ứng với từng Nhà cung cấp (theo index ncc 0 -> 5)
const productsTemplate = [
  // NCC 0: Công ty TNHH Phân Phối Điện Máy Toàn Cầu
  {
    supplierIndex: 0,
    sku: 'SP-DM-001',
    name: 'Quạt Đứng Công Nghiệp Senko DCN1806',
    category: 'Điện Gia Dụng',
    uom: 'Cái',
    barcode: '8936012340011',
    unitCost: 380000,
    wholesalePrice: 440000,
    retailPrice: 520000,
    stockWarehouse1: 45,
    stockWarehouse2: 20,
    stockWarehouse3: 15,
    reorderPoint: 10,
  },
  {
    supplierIndex: 0,
    sku: 'SP-DM-002',
    name: 'Nồi Cơm Điện Tử Sunhouse Mama 1.8L',
    category: 'Điện Gia Dụng',
    uom: 'Cái',
    barcode: '8936012340028',
    unitCost: 850000,
    wholesalePrice: 980000,
    retailPrice: 1190000,
    stockWarehouse1: 25,
    stockWarehouse2: 15,
    stockWarehouse3: 5,
    reorderPoint: 8,
  },
  {
    supplierIndex: 0,
    sku: 'SP-DM-003',
    name: 'Bếp Từ Đôi Inverter Kangaroo KG498N',
    category: 'Thiết Bị Nhà Bếp',
    uom: 'Bộ',
    barcode: '8936012340035',
    unitCost: 3200000,
    wholesalePrice: 3800000,
    retailPrice: 4500000,
    stockWarehouse1: 12,
    stockWarehouse2: 6,
    stockWarehouse3: 2,
    reorderPoint: 3,
  },

  // NCC 1: Tổng Kho Vật Liệu Xây Dựng Miền Nam
  {
    supplierIndex: 1,
    sku: 'SP-VL-001',
    name: 'Sơn Nước Ngoại Thất Dulux Weathershield 5L',
    category: 'Sơn & Hóa Chất Xây Dựng',
    uom: 'Thùng',
    barcode: '8935012380012',
    unitCost: 920000,
    wholesalePrice: 1050000,
    retailPrice: 1280000,
    stockWarehouse1: 60,
    stockWarehouse2: 30,
    stockWarehouse3: 10,
    reorderPoint: 15,
  },
  {
    supplierIndex: 1,
    sku: 'SP-VL-002',
    name: 'Xi Măng Holcim Đa Dụng PCB40 (Bao 50kg)',
    category: 'Vật Liệu Thô',
    uom: 'Bao',
    barcode: '8935012380029',
    unitCost: 82000,
    wholesalePrice: 89000,
    retailPrice: 98000,
    stockWarehouse1: 200,
    stockWarehouse2: 150,
    stockWarehouse3: 50,
    reorderPoint: 50,
  },
  {
    supplierIndex: 1,
    sku: 'SP-VL-003',
    name: 'Keo Dán Gạch Chống Thấm Weber Tai Fix 25kg',
    category: 'Vật Liệu Hoàn Thiện',
    uom: 'Bao',
    barcode: '8935012380036',
    unitCost: 260000,
    wholesalePrice: 295000,
    retailPrice: 340000,
    stockWarehouse1: 80,
    stockWarehouse2: 40,
    stockWarehouse3: 20,
    reorderPoint: 20,
  },

  // NCC 2: Nhà Phân Phối Hàng Tiêu Dùng & Nước Giải Khát Ánh Dương
  {
    supplierIndex: 2,
    sku: 'SP-TD-001',
    name: 'Nước Ngọt Coca Cola Thùng 24 Lon 320ml',
    category: 'Đồ Uống & Giải Khát',
    uom: 'Thùng',
    barcode: '8934567890019',
    unitCost: 185000,
    wholesalePrice: 202000,
    retailPrice: 230000,
    stockWarehouse1: 150,
    stockWarehouse2: 80,
    stockWarehouse3: 40,
    reorderPoint: 30,
  },
  {
    supplierIndex: 2,
    sku: 'SP-TD-002',
    name: 'Trà Xanh Không Độ Thùng 24 Chai 455ml',
    category: 'Đồ Uống & Giải Khát',
    uom: 'Thùng',
    barcode: '8934567890026',
    unitCost: 165000,
    wholesalePrice: 180000,
    retailPrice: 210000,
    stockWarehouse1: 120,
    stockWarehouse2: 50,
    stockWarehouse3: 30,
    reorderPoint: 25,
  },
  {
    supplierIndex: 2,
    sku: 'SP-TD-003',
    name: 'Mì Ăn Liền Hảo Hảo Tôm Chua Cay (Thùng 30 gói)',
    category: 'Thực Phẩm Đóng Gói',
    uom: 'Thùng',
    barcode: '8934567890033',
    unitCost: 112000,
    wholesalePrice: 122000,
    retailPrice: 138000,
    stockWarehouse1: 300,
    stockWarehouse2: 120,
    stockWarehouse3: 60,
    reorderPoint: 50,
  },

  // NCC 3: Công ty CP Công Nghệ & Thiết Bị Số An Khang
  {
    supplierIndex: 3,
    sku: 'SP-TB-001',
    name: 'Camera IP Wifi Ezviz C6N 1080P Xoay 360',
    category: 'Thiết Bị Số & Mạng',
    uom: 'Cái',
    barcode: '8938991230015',
    unitCost: 430000,
    wholesalePrice: 490000,
    retailPrice: 590000,
    stockWarehouse1: 50,
    stockWarehouse2: 25,
    stockWarehouse3: 15,
    reorderPoint: 10,
  },
  {
    supplierIndex: 3,
    sku: 'SP-TB-002',
    name: 'Cáp Mạng Cat6 UTP CommScope Cuộn 305m',
    category: 'Vật Tư Mạng',
    uom: 'Cuộn',
    barcode: '8938991230022',
    unitCost: 1750000,
    wholesalePrice: 1950000,
    retailPrice: 2300000,
    stockWarehouse1: 18,
    stockWarehouse2: 10,
    stockWarehouse3: 4,
    reorderPoint: 5,
  },
  {
    supplierIndex: 3,
    sku: 'SP-TB-003',
    name: 'Bộ Phát Wifi TP-Link Archer C6 Chuẩn AC1200',
    category: 'Thiết Bị Số & Mạng',
    uom: 'Cái',
    barcode: '8938991230039',
    unitCost: 580000,
    wholesalePrice: 650000,
    retailPrice: 790000,
    stockWarehouse1: 35,
    stockWarehouse2: 15,
    stockWarehouse3: 8,
    reorderPoint: 8,
  },

  // NCC 4: Xưởng May Gia Công & Bảo Hộ Lao Động Việt Đức
  {
    supplierIndex: 4,
    sku: 'SP-BH-001',
    name: 'Áo Phản Quang Lưới Công Trình Tiêu Chuẩn',
    category: 'Bảo Hộ Lao Động',
    uom: 'Cái',
    barcode: '8937123450017',
    unitCost: 32000,
    wholesalePrice: 42000,
    retailPrice: 55000,
    stockWarehouse1: 250,
    stockWarehouse2: 100,
    stockWarehouse3: 50,
    reorderPoint: 40,
  },
  {
    supplierIndex: 4,
    sku: 'SP-BH-002',
    name: 'Giày Bảo Hộ Mũi Lót Thép Jogger Bestboy S3',
    category: 'Bảo Hộ Lao Động',
    uom: 'Đôi',
    barcode: '8937123450024',
    unitCost: 410000,
    wholesalePrice: 470000,
    retailPrice: 560000,
    stockWarehouse1: 40,
    stockWarehouse2: 20,
    stockWarehouse3: 10,
    reorderPoint: 10,
  },
  {
    supplierIndex: 4,
    sku: 'SP-BH-003',
    name: 'Mũ Bảo Hộ Công Trình Thùy Dương Núm Vặn',
    category: 'Bảo Hộ Lao Động',
    uom: 'Cái',
    barcode: '8937123450031',
    unitCost: 55000,
    wholesalePrice: 68000,
    retailPrice: 85000,
    stockWarehouse1: 150,
    stockWarehouse2: 60,
    stockWarehouse3: 30,
    reorderPoint: 25,
  },

  // NCC 5: Công ty TNHH Hóa Mỹ Phẩm & Tẩy Rửa Xanh EcoClean
  {
    supplierIndex: 5,
    sku: 'SP-MP-001',
    name: 'Nước Rửa Chén Sinh Học Tinh Dầu Quế Can 4L',
    category: 'Hóa Mỹ Phẩm',
    uom: 'Can',
    barcode: '8939112230018',
    unitCost: 110000,
    wholesalePrice: 130000,
    retailPrice: 165000,
    stockWarehouse1: 90,
    stockWarehouse2: 45,
    stockWarehouse3: 20,
    reorderPoint: 15,
  },
  {
    supplierIndex: 5,
    sku: 'SP-MP-002',
    name: 'Nước Lau Sàn Sả Chanh Đậm Đặc Can 3.8L',
    category: 'Hóa Mỹ Phẩm',
    uom: 'Can',
    barcode: '8939112230025',
    unitCost: 95000,
    wholesalePrice: 115000,
    retailPrice: 145000,
    stockWarehouse1: 85,
    stockWarehouse2: 40,
    stockWarehouse3: 15,
    reorderPoint: 15,
  },
  {
    supplierIndex: 5,
    sku: 'SP-MP-003',
    name: 'Nước Giặt Xả Kháng Khuẩn EcoClean Túi 3.5kg',
    category: 'Hóa Mỹ Phẩm',
    uom: 'Túi',
    barcode: '8939112230032',
    unitCost: 135000,
    wholesalePrice: 158000,
    retailPrice: 195000,
    stockWarehouse1: 110,
    stockWarehouse2: 50,
    stockWarehouse3: 25,
    reorderPoint: 20,
  },
];

async function seed() {
  console.log('--- BẮT ĐẦU SEED DỮ LIỆU KIỂM THỬ ---');

  // 1. Tạo Nhà Cung Cấp
  console.log('\n[1/3] Đang tạo danh sách Nhà Cung Cấp...');
  const createdSuppliers = [];
  for (const s of suppliersData) {
    try {
      const res = await request('/suppliers', {
        method: 'POST',
        body: JSON.stringify(s),
      });
      console.log(`  + Đã tạo NCC: [${res.code}] ${res.name} (ID: ${res.id})`);
      createdSuppliers.push(res);
    } catch (err) {
      console.error(`  - Lỗi khi tạo NCC ${s.name}:`, err.message);
    }
  }

  // 2. Tạo Khách Hàng
  console.log('\n[2/3] Đang tạo danh sách Khách Hàng...');
  const createdCustomers = [];
  for (const c of customersData) {
    try {
      const res = await request('/customers', {
        method: 'POST',
        body: JSON.stringify(c),
      });
      console.log(`  + Đã tạo Khách hàng: [${res.code}] ${res.name} (ID: ${res.id})`);
      createdCustomers.push(res);
    } catch (err) {
      console.error(`  - Lỗi khi tạo Khách hàng ${c.name}:`, err.message);
    }
  }

  // 3. Tạo Sản Phẩm (Liên kết chặt chẽ với Nhà Cung Cấp đã tạo)
  console.log('\n[3/3] Đang tạo Sản Phẩm (kèm nhà cung cấp & tồn kho đa điểm)...');
  const createdProducts = [];
  for (const p of productsTemplate) {
    const targetSupplier = createdSuppliers[p.supplierIndex];
    if (!targetSupplier) {
      console.warn(`  ! Không tìm thấy NCC tại vị trí ${p.supplierIndex} cho sản phẩm ${p.name}`);
      continue;
    }

    const payload = {
      sku: p.sku,
      name: p.name,
      category: p.category,
      uom: p.uom,
      barcode: p.barcode,
      supplierId: targetSupplier.id,
      unitCost: p.unitCost,
      wholesalePrice: p.wholesalePrice,
      retailPrice: p.retailPrice,
      stockWarehouse1: p.stockWarehouse1,
      stockWarehouse2: p.stockWarehouse2,
      stockWarehouse3: p.stockWarehouse3,
      reorderPoint: p.reorderPoint,
    };

    try {
      const res = await request('/products', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      console.log(`  + Đã tạo SP: [${res.sku}] ${res.name} (Thuộc NCC: ${res.supplierName || targetSupplier.name}, Tổng tồn: ${res.totalStock})`);
      createdProducts.push(res);
    } catch (err) {
      console.error(`  - Lỗi khi tạo sản phẩm ${p.name}:`, err.message);
    }
  }

  console.log('\n==========================================');
  console.log(`HOÀN TẤT SEED DỮ LIỆU THÀNH CÔNG!`);
  console.log(`- Nhà Cung Cấp: ${createdSuppliers.length}`);
  console.log(`- Khách Hàng:    ${createdCustomers.length}`);
  console.log(`- Sản Phẩm:     ${createdProducts.length} (100% gắn với Nhà Cung Cấp)`);
  console.log('==========================================');
}

seed().catch((err) => {
  console.error('Fatal error seeding data:', err);
  process.exit(1);
});

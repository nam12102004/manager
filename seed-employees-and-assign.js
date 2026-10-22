// seed-employees-and-assign.js
// Script tạo 5 nhân viên mẫu và gán các phiếu xuất hiện có cho nhân viên
// Tương thích môi trường Node.js và Docker PostgreSQL của hệ thống DebtManager

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const API_BASE = 'http://localhost:5050/api';

const sampleEmployees = [
  {
    name: 'Nguyễn Văn An',
    phone: '0912345678',
    notes: 'Nhân viên kinh doanh phụ trách Miền Nam',
  },
  {
    name: 'Trần Thị Mai',
    phone: '0923456789',
    notes: 'Nhân viên bán hàng phụ trách Miền Bắc',
  },
  {
    name: 'Lê Hoàng Nam',
    phone: '0934567890',
    notes: 'Nhân viên kinh doanh khu vực TP.HCM',
  },
  {
    name: 'Phạm Quốc Dũng',
    phone: '0945678901',
    notes: 'Nhân viên bán hàng dự án & đại lý',
  },
  {
    name: 'Hoàng Kim Oanh',
    phone: '0956789012',
    notes: 'Nhân viên kinh doanh kênh siêu thị & bán lẻ',
  },
];

async function checkApiRunning() {
  try {
    const res = await fetch(`${API_BASE}/employees`);
    return res.ok;
  } catch {
    return false;
  }
}

async function run() {
  console.log('🚀 Bắt đầu quá trình tạo 5 nhân viên và gán phiếu xuất...\n');

  const sqlFilePath = path.join(__dirname, 'seed_employees_and_assign_exports.sql');
  if (!fs.existsSync(sqlFilePath)) {
    console.error(`❌ Không tìm thấy file SQL: ${sqlFilePath}`);
    process.exit(1);
  }

  // 1. Thực thi script SQL trực tiếp vào PostgreSQL qua Docker container
  try {
    console.log('📦 Đang thực thi script SQL vào PostgreSQL (container debtmanager_db)...');
    
    // Copy file vào container hoặc pipe nội dung để đảm bảo mã hóa UTF-8 chính xác
    execSync(`docker cp "${sqlFilePath}" debtmanager_db:/tmp/seed_employees.sql`, { stdio: 'pipe' });
    const output = execSync(
      `docker exec debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/seed_employees.sql`,
      { encoding: 'utf-8' }
    );
    
    console.log('✅ Đã chạy script SQL thành công!\n');
    console.log('📊 Kết quả thống kê từ Database:');
    console.log(output);
  } catch (err) {
    console.warn('⚠️  Không thể chạy qua Docker CLI trực tiếp:', err.message);
    console.log('👉 Bạn có thể chạy thủ công file "seed_employees_and_assign_exports.sql" trong DBeaver/pgAdmin hoặc lệnh:');
    console.log('   docker exec -i debtmanager_db psql -U postgres -d debtmanager_db < seed_employees_and_assign_exports.sql\n');
  }

  // 2. Kiểm tra lại qua Backend API nếu API đang chạy
  const isApiUp = await checkApiRunning();
  if (isApiUp) {
    try {
      console.log('🔍 Đang kiểm tra dữ liệu qua Backend API (http://localhost:5050/api/employees)...');
      const res = await fetch(`${API_BASE}/employees`);
      const json = await res.json();
      const emps = json.data || [];
      console.log(`✨ Hệ thống hiện có ${emps.length} nhân viên:`);
      emps.forEach((emp) => {
        console.log(
          `   - [ID: ${emp.id}] ${emp.name.padEnd(20)} | SĐT: ${(emp.phone || 'N/A').padEnd(12)} | Số đơn: ${String(emp.exportCount || 0).padStart(3)} | Doanh thu: ${Number(emp.totalExportValue || 0).toLocaleString('vi-VN')} đ`
        );
      });
    } catch (apiErr) {
      console.warn('⚠️ Lỗi khi gọi API kiểm tra:', apiErr.message);
    }
  }

  console.log('\n🎉 Hoàn thành!');
}

run();

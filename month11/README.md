# BỘ SCRIPTS IMPORT KHÁCH HÀNG & CÔNG NỢ THÁNG 11 (KHO 2) VÀO DATABASE

Thư mục này chứa toàn bộ các script trích xuất dữ liệu từ **Sheet `T11,2026`** (file Excel Kho 2) và nạp vào cơ sở dữ liệu PostgreSQL (`debtmanager_db`) theo đúng các yêu cầu nghiệp vụ:

---

## 1. QUY TẮC MAPPING DỮ LIỆU CHỈ ĐỊNH

| Cột trong Excel (Sheet `T11,2026`) | Bảng & Cột trong CSDL | Quy tắc xử lý |
| :--- | :--- | :--- |
| **Cột B (MÃ KHÁCH)** | `Customers.Code` | Nếu cột B có mã $\rightarrow$ giữ nguyên mã (VD: `KH.140723099`). Nếu mã bị trùng giữa 2 khách khác nhau $\rightarrow$ tự động gắn đuôi `_2`. Nếu để trống $\rightarrow$ tự sinh mã chuẩn định dạng `KH_T11_R{hàng:03d}` (VD: `KH_T11_R038`). |
| **Cột C (TÊN KH)** | `Customers.Name` | Nhập nguyên văn tên đại lý/khách hàng từ Excel. |
| **Cột D (NỢ ĐK) & Cột E (CÓ ĐK)** | `Customers.Debt` | **Công nợ ròng:** $\text{Debt} = \text{Nợ ĐK} - \text{Có ĐK}$.<br>• Nếu $\text{Debt} > 0$: Khách đang nợ cửa hàng (Phải thu).<br>• Nếu $\text{Debt} < 0$: Cửa hàng đang nợ khách/khách trả thừa (Phải trả). |
| **Tuyến bán hàng** | `Customers.Region` | Gán khách hàng tương ứng theo 3 tuyến trong Excel:<br>1. `THÀNH PHỐ`<br>2. `NAM TRỰC - TRỰC NINH - Ý YÊN - VỤ BẢN - XUÂN TRƯỜNG`<br>3. `GIAO THUỶ - NGHĨA HƯNG - HẢI HẬU` |
| **Các cột chỉ định** | `Customers` | Chỉ thêm/cập nhật các trường: `Code`, `Name`, `Debt`, `Region`, `CreditLimit` = 0, `CreatedAt`, `UpdatedAt`. Không nạp các cột không được chỉ định. |
| **Kho 2 (Warehouse 2)** | `CustomerWarehouseDebts`<br>`CustomerDebtHistories` | Đồng bộ công nợ vào `warehouse2` và ghi nhận bản ghi sổ nợ ban đầu (`SourceType = 'init'`) để theo dõi chi tiết trên giao diện. |

---

## 2. THỐNG KÊ SỐ LIỆU ĐỐI CHIẾU 100% VỚI EXCEL

Tổng số khách hàng trích xuất: **289 khách hàng**

| Tuyến bán hàng (Địa điểm / Region) | Số lượng KH | Tổng Nợ ĐK (Cột D) | Tổng Có ĐK (Cột E) | Công nợ ròng (Debt) |
| :--- | :---: | :---: | :---: | :---: |
| **1. THÀNH PHỐ** | 57 | 355.196.650 đ | 22.123.220 đ | 333.073.430 đ |
| **2. NAM TRỰC - TRỰC NINH - Ý YÊN - VỤ BẢN - XUÂN TRƯỜNG** | 123 | 1.165.443.400 đ | 91.190.000 đ | 1.074.253.400 đ |
| **3. GIAO THUỶ - NGHĨA HƯNG - HẢI HẬU** | 109 | 643.843.600 đ | 9.310.600 đ | 634.533.000 đ |
| **TỔNG CỘNG** | **289** | **2.164.483.650 đ** | **122.623.820 đ** | **2.041.859.830 đ** |

> ✅ **Đối chiếu:** Tổng Nợ ĐK (`2.164.483.650 đ`) và Có ĐK (`122.623.820 đ`) **khớp 100.00%** với hàng **Tổng cộng tuyến (1+2+3)** ở cuối Sheet T11,2026.

---

## 3. DANH SÁCH CÁC FILE TRONG FOLDER `month11`

* **`cong_no_kho2_t11.xlsx`**: Bản sao file Excel dữ liệu nguồn dùng trực tiếp cho script.
* **`import_customers_t11.sql`**: Script SQL chạy trực tiếp vào PostgreSQL (hỗ trợ `ON CONFLICT DO UPDATE` idempotency, có sẵn lệnh kiểm tra).
* **`import_customers_t11.js`**: Tool Node.js đọc Excel không cần thư viện ngoài, hỗ trợ `--dry-run`, `--sql`, `--direct-db`, `--api`.
* **`import_customers_t11.py`**: Tool Python đọc Excel và xuất SQL / chạy trực tiếp.
* **`run_import.bat`**: File Batch 1-click cho Windows để nạp ngay vào Docker PostgreSQL container `debtmanager_db`.

---

## 4. HƯỚNG DẪN THỰC THI

### Cách 1: Chạy 1-Click bằng Batch (Khuyên dùng trên Windows)
Nhấp đúp chuột vào file `month11/run_import.bat` hoặc mở PowerShell / CMD chạy:
```cmd
month11\run_import.bat
```

### Cách 2: Chạy bằng Node.js
```bash
# Xem trước số liệu (không ghi DB):
node month11/import_customers_t11.js --dry-run

# Nạp trực tiếp vào Docker PostgreSQL:
node month11/import_customers_t11.js --direct-db

# Hoặc nạp thông qua Backend REST API:
node month11/import_customers_t11.js --api
```

### Cách 3: Chạy trực tiếp file SQL bằng Docker / psql
```bash
docker cp month11/import_customers_t11.sql debtmanager_db:/tmp/import_customers_t11.sql
docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/import_customers_t11.sql
```

---

## 5. CÂU LỆNH KIỂM TRA DỮ LIỆU SAU KHI NẠP

Sau khi nạp, có thể chạy câu lệnh sau trong psql để kiểm tra số lượng và tổng nợ:
```sql
SELECT 
    "Region", 
    COUNT(*) AS "SoLuongKH", 
    SUM(CASE WHEN "Debt" > 0 THEN "Debt" ELSE 0 END) AS "TongNoDK", 
    SUM(CASE WHEN "Debt" < 0 THEN -"Debt" ELSE 0 END) AS "TongCoDK", 
    SUM("Debt") AS "CongNoRong" 
FROM "Customers" 
GROUP BY "Region" 
ORDER BY "Region";
```

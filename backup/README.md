# Module Backup Database Tự Động Lên Google Drive

Module chạy hoàn toàn độc lập trong container Docker riêng biệt (`debtmanager_backup`), định kỳ tự động trích xuất bản sao lưu thô (raw database dump) của PostgreSQL và tải lên Google Drive mà **không làm ảnh hưởng tới bất kỳ đoạn code nào khác trong hệ thống**.

---

## 🌟 Tính Năng Nổi Bật

1. **Sao lưu dữ liệu thô (Raw Database Backup)**:
   - Sử dụng `pg_dump` chính thức kết hợp nén `gzip -9` tạo file `.sql.gz` tiêu chuẩn.
   - Chứa đầy đủ cấu trúc bảng (DDL), index, sequence, dữ liệu (INSERT/COPY).
   - Dung lượng gọn nhẹ, khôi phục được trên bất kỳ môi trường PostgreSQL nào.
2. **Lịch trình tự động**:
   - Chạy định kỳ 24 giờ một lần vào đúng **12:00 AM (12h sáng / 00:00:00 đêm)** theo múi giờ Việt Nam (`Asia/Ho_Chi_Minh` UTC+7).
3. **Đồng bộ Google Drive**:
   - Tải file backup trực tiếp lên Google Drive thông qua Google Drive API v3 chính thống.
   - Cơ chế Resumable Upload (chia chunk 5MB) giúp tải lên mượt mà, không lo đứt mạng đối với database dung lượng lớn.
4. **Bảo vệ tài nguyên & Dọn dẹp tự động (Retention Policy)**:
   - Tự động xóa các bản backup cũ hơn 30 ngày (cả trên Google Drive và lưu trữ cục bộ) để tiết kiệm dung lượng.
5. **Cách ly hoàn toàn & Không ảnh hưởng hệ thống**:
   - Container `backup` chạy độc lập, kết nối nội bộ qua mạng Docker tới container `db`.
   - Nếu chưa cấu hình Google Drive, container vẫn tự động lưu backup cục bộ và không bao giờ gây lỗi hoặc làm dừng API/Frontend/Database.

---

## 📁 Cấu Trúc Thư Mục

```text
backup/
├── credentials/
│   ├── .gitkeep
│   └── service_account.json      <-- Đặt file JSON khóa của Google Service Account tại đây
├── local_backups/                <-- Thư mục chứa các file .sql.gz lưu trữ cục bộ
│   ├── .gitkeep
│   ├── debtmanager_db_*.sql.gz
│   └── last_backup_status.json   <-- Trạng thái lần backup gần nhất
├── backup.py                     <-- Mã nguồn Python chính thực hiện backup, upload & schedule
├── Dockerfile                    <-- Cấu hình container Python Alpine + postgresql-client
├── requirements.txt              <-- Thư viện Google API & pytz
└── README.md
```

---

## 🚀 Hướng Dẫn Cấu Hình Google Drive (3 Bước Đơn Giản)

### Bước 1: Tạo Google Service Account & Tải khóa JSON
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/).
2. Tạo dự án mới (ví dụ: `DebtManager`) hoặc chọn dự án sẵn có.
3. Vào **APIs & Services** > **Library** > Tìm **Google Drive API** > Bấm **Enable**.
4. Vào **APIs & Services** > **Credentials** > Bấm **Create Credentials** > Chọn **Service Account**:
   - Nhập tên: `backup-bot` > Bấm **Create and Continue** > Bấm **Done**.
5. Nhấp vào Service Account vừa tạo trong danh sách:
   - Chuyển sang tab **Keys** > Bấm **Add Key** > **Create new key**.
   - Chọn định dạng **JSON** > Bấm **Create**.
   - File JSON sẽ được tải về máy của bạn.
6. Đổi tên file vừa tải về thành `service_account.json` và chép vào thư mục:
   `backup/credentials/service_account.json`

### Bước 2: Tạo thư mục trên Google Drive & Chia sẻ quyền
1. Mở [Google Drive](https://drive.google.com/) trên trình duyệt.
2. Tạo một thư mục mới (ví dụ: `DebtManager_Backups`).
3. Mở thư mục đó, nhìn lên thanh địa chỉ trình duyệt URL:
   `https://drive.google.com/drive/folders/1aBcDeFgHiJkLmNoPqRsTuVwXyZ`
   👉 Chuỗi ký tự phía sau `/folders/` chính là **`GDRIVE_FOLDER_ID`**.
4. Nhấp chuột phải vào thư mục trên Google Drive > Chọn **Chia sẻ (Share)**:
   - Dán địa chỉ email của Service Account (dạng `backup-bot@<project-id>.iam.gserviceaccount.com` trong file JSON).
   - Chọn quyền: **Người chỉnh sửa (Editor)**.
   - Bỏ chọn "Gửi thông báo" > Bấm **Chia sẻ / Gửi**.

### Bước 3: Cấu hình biến môi trường
Mở file `.env` (tạo từ `.env.example` nếu chưa có) và điền `GDRIVE_FOLDER_ID`:
```env
GDRIVE_FOLDER_ID=1aBcDeFgHiJkLmNoPqRsTuVwXyZ
```

---

## 🧪 Kiểm Tra Thử Nghiệm

Bạn không cần phải đợi tới 12h sáng để biết backup có hoạt động hay không. Hãy chạy thử nghiệm ngay:

### Cách 1: Chạy file script có sẵn (Khuyên dùng trên Windows)
Nhấp đúp chuột vào file:
```bat
test_backup.bat
```

### Cách 2: Chạy qua dòng lệnh Docker Compose
```bash
docker compose run --rm backup python backup.py --run-once
```

Sau khi chạy xong, hãy kiểm tra:
1. Thư mục trên Google Drive xem file `.sql.gz` đã xuất hiện chưa.
2. Thư mục `backup/local_backups/` xem file backup và `last_backup_status.json`.

---

## 🔄 Khởi Động Toàn Bộ Hệ Thống Cùng Lúc

Chạy lệnh quen thuộc:
```bat
start.bat
```
hoặc:
```bash
docker compose up -d
```
Container `debtmanager_backup` sẽ tự khởi động cùng hệ thống và đếm ngược tới 12:00 AM (00:00:00) mỗi ngày để thực hiện sao lưu.

---

## 🛠️ Hướng Dẫn Khôi Phục Dữ Liệu (Restore) Khi Cần

Nếu bạn cần khôi phục lại database từ file raw backup `.sql.gz`:

```bash
# Trên Linux / Git Bash / WSL:
gunzip -c backup/local_backups/debtmanager_db_YYYYMMDD_HHMMSS.sql.gz | docker compose exec -T db psql -U postgres -d debtmanager_db

# Trên Windows PowerShell (sử dụng container backup để giải nén trực tiếp vào db):
docker compose exec -T db psql -U postgres -d debtmanager_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker compose run --rm -v ${PWD}/backup/local_backups:/backups backup sh -c "gunzip -c /backups/debtmanager_db_YYYYMMDD_HHMMSS.sql.gz | psql -h db -U postgres -d debtmanager_db"
```

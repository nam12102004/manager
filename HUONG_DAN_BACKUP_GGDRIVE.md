# HƯỚNG DẪN MODULE TỰ ĐỘNG SAO LƯU DATABASE LÊN GOOGLE DRIVE (24H / 1 LẦN VÀO 12H SÁNG)

Hệ thống đã được bổ sung một module Docker độc lập mang tên **`backup`** (`debtmanager_backup`), có nhiệm vụ tự động trích xuất toàn bộ dữ liệu thô (raw database dump) của PostgreSQL, nén gzip và đồng bộ lên Google Drive định kỳ 24h một lần vào lúc **12h sáng (00:00:00 midnight múi giờ Việt Nam UTC+7)**.

> [!IMPORTANT]
> **Cam kết không ảnh hưởng code hiện tại:**
> Module này chạy trong container Docker riêng biệt, kết nối tới database qua mạng nội bộ Docker. Mã nguồn Backend .NET (`src/`), Frontend Angular (`frontend/`), và cơ sở dữ liệu đều **hoàn toàn không bị sửa đổi hay ảnh hưởng**.

---

## 1. Cấu Trúc Các Tệp Đã Thêm

| Tệp / Thư mục | Chức năng |
| :--- | :--- |
| `backup/backup.py` | Script Python tự động dump DB bằng `pg_dump`, nén gzip, tải lên Google Drive API v3, lập lịch chạy lúc 00:00 và tự xóa bản backup cũ hơn 30 ngày. |
| `backup/Dockerfile` | Docker image nhẹ dựa trên Alpine Linux tích hợp sẵn `postgresql-client` và Python. |
| `backup/requirements.txt` | Khai báo thư viện Google API Client, Google Auth, Pytz. |
| `backup/credentials/` | Thư mục chứa tệp khóa xác thực `service_account.json` của Google Drive. |
| `backup/local_backups/` | Thư mục lưu trữ bản backup `.sql.gz` cục bộ trên máy để dự phòng song song. |
| `test_backup.bat` | Script 1-click trên Windows để chạy thử nghiệm backup ngay lập tức. |
| `.env.example` | Mẫu cấu hình môi trường chuẩn bao gồm ID thư mục Google Drive. |
| `docker-compose.yml` | Đã tích hợp thêm service `backup` chạy song song với `db`, `api`, `frontend`. |

---

## 2. Các Bước Kích Hoạt Tải Lên Google Drive

Chỉ cần làm 3 bước đơn giản một lần duy nhất:

### Bước 1: Lấy tệp xác thực Google Service Account (Hoàn toàn miễn phí, không bao giờ hết hạn token)
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/) bằng tài khoản Gmail của bạn.
2. Chọn hoặc tạo mới một Dự án (Project), ví dụ: `DebtManager`.
3. Tìm kiếm **Google Drive API** trên thanh tìm kiếm hoặc vào mục **APIs & Services** > **Library**, bấm nút **Enable (Bật)**.
4. Vào menu **APIs & Services** > **Credentials** > Bấm **Create Credentials** > Chọn **Service Account**.
   - Đặt tên tài khoản (ví dụ: `gdrive-backup-bot`).
   - Bấm **Create and Continue**, sau đó bấm **Done**.
5. Nhấp vào tài khoản Service Account vừa tạo trong danh sách:
   - Vào tab **Keys** > Bấm **Add Key** > **Create new key** > Chọn định dạng **JSON** > Bấm **Create**.
   - Máy tính sẽ tải về 1 file `.json`.
6. Đổi tên file vừa tải về thành:
   `service_account.json`
   và chép vào thư mục:
   `backup/credentials/service_account.json`

### Bước 2: Tạo thư mục trên Google Drive & Chia sẻ quyền cho Service Account
1. Vào [Google Drive](https://drive.google.com/) trên trình duyệt, tạo một thư mục mới (ví dụ: `DebtManager_Backups`).
2. Mở thư mục đó ra, nhìn vào đường dẫn URL trên trình duyệt:
   ```text
   https://drive.google.com/drive/folders/1ABC_XYZ123456789abcdef...
   ```
   Sao chép phần mã phía sau `/folders/` (đây là `GDRIVE_FOLDER_ID`).
3. Nhấp chuột phải vào thư mục trên Google Drive > Chọn **Chia sẻ (Share)**:
   - Dán địa chỉ email của Service Account (dạng `gdrive-backup-bot@...iam.gserviceaccount.com` trong file JSON vừa tải).
   - Chọn quyền: **Người chỉnh sửa (Editor)**.
   - Bấm **Chia sẻ / Gửi** (bỏ chọn thông báo nếu có).

### Bước 3: Cấu hình biến môi trường
Mở file `.env` (nếu chưa có thì copy từ file `.env.example`) và điền ID thư mục:
```env
GDRIVE_FOLDER_ID=1ABC_XYZ123456789abcdef...
```

---

## 3. Cách Kiểm Tra Thử Nghiệm Ngay Lập Tức

Không cần đợi tới 12h sáng, bạn có thể kiểm tra ngay:

- **Cách 1 (Nhanh nhất trên Windows):** Nhấp đúp chuột chạy file:
  ```bat
  test_backup.bat
  ```
- **Cách 2 (Bằng lệnh Docker Compose):**
  ```bash
  docker compose run --rm backup python backup.py --run-once
  ```

Kiểm tra:
- File nén `.sql.gz` sẽ xuất hiện ngay lập tức trong thư mục Google Drive của bạn!
- Một bản copy cũng được lưu tại thư mục `backup/local_backups/`.

---

## 4. Cách Vận Hành Thường Ngày

- Khi khởi động hệ thống bằng `start.bat` hoặc lệnh:
  ```bash
  docker compose up -d
  ```
  Container `debtmanager_backup` sẽ tự động khởi động và chuyển sang trạng thái chờ, tự động kích hoạt backup vào đúng **12h sáng (00:00:00)** mỗi ngày.
- Để xem nhật ký hoạt động hoặc thời gian đếm ngược tới lần backup kế tiếp:
  ```bash
  docker compose logs -f backup
  ```
- Để dừng hệ thống:
  ```bat
  stop.bat
  ```

---

## 5. Khôi Phục Dữ Liệu (Restore) Khi Cần

Nếu muốn khôi phục lại database từ file raw backup `.sql.gz`:

```powershell
# Chạy lệnh khôi phục qua Docker Compose:
docker compose run --rm -v ${PWD}/backup/local_backups:/backups backup sh -c "gunzip -c /backups/<TÊN_FILE_BACKUP>.sql.gz | psql -h db -U postgres -d debtmanager_db"
```

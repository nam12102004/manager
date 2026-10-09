-- Seed Data cho Nhà Cung Cấp, Khách Hàng, Sản Phẩm (Gấp đôi số lượng & kèm Khu Vực)
-- Chạy cho PostgreSQL / SQLite với UTF-8 đầy đủ

BEGIN;

-- Xóa dữ liệu cũ nếu chưa có chứng từ phụ thuộc
TRUNCATE TABLE "StockHistories", "CustomerDebtHistories", "SupplierDebtHistories", "ExportVoucherItems", "ExportVouchers", "ImportVoucherItems", "ImportVouchers", "Receipts", "Payments", "Products", "Customers", "Suppliers" RESTART IDENTITY CASCADE;

-- 1. TẠO NHÀ CUNG CẤP (SUPPLIERS) - 16 NCC
INSERT INTO "Suppliers" ("Code", "Name", "ContactName", "PhonesJson", "Email", "AddressesJson", "Region", "Debt", "CreditLimit", "BankAccount", "TaxNumber", "Notes", "CreatedAt", "UpdatedAt")
VALUES
('NCC001', 'Công ty TNHH Nước Giải Khát & Thực Phẩm Ánh Dương', 'Nguyễn Văn Tuấn', '["0903112233", "02838123456"]', 'anhduong.beverage@gmail.com', '["128 Đường Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM"]', 'TP. Hồ Chí Minh', 15000000.00, 200000000.00, '19033456789012 - Techcombank HCM', '0312456789', 'Nhà phân phối chính thức bia & nước giải khát', NOW(), NOW()),
('NCC002', 'Đại lý Phân phối Bánh kẹo & Snack Hưng Phát', 'Trần Thị Thanh Mai', '["0918223344"]', 'hungphat.snack@gmail.com', '["450 Lý Thường Kiệt, Phường 7, Quận Tân Bình, TP.HCM"]', 'TP. Hồ Chí Minh', 0.00, 150000000.00, '0071001234567 - Vietcombank Tân Bình', '0318765432', 'Cung cấp bánh kẹo Orion, AFC, Kinh Đô', NOW(), NOW()),
('NCC003', 'Tổng kho Hóa mỹ phẩm & Tẩy rửa Việt Nhật', 'Lê Hoàng Long', '["0988776655", "0977665544"]', 'vietnhat.cosmetics@gmail.com', '["72 Nguyễn Kiệm, Phường 4, Quận Phú Nhuận, TP.HCM"]', 'Miền Nam', 24500000.00, 300000000.00, '102839485721 - Vietinbank Phú Nhuận', '0319988776', 'Phân phối OMO, Sunlight, Clear, Comfort', NOW(), NOW()),
('NCC004', 'Công ty CP Nông sản & Gia vị Thực phẩm VinaSpice', 'Phạm Quốc Dũng', '["0934556677"]', 'vinaspice.sales@gmail.com', '["88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM"]', 'Miền Nam', 5200000.00, 100000000.00, '060012345678 - Sacombank Tân Bình', '0315544332', 'Chuyên cung cấp mì tôm, dầu ăn, nước mắm, gia vị', NOW(), NOW()),
('NCC005', 'Tổng công ty Sữa & Chế phẩm Dinh dưỡng Dairy Farm', 'Hoàng Kim Oanh', '["0908998877"]', 'dairyfarm.vietnam@gmail.com', '["215 Điện Biên Phủ, Phường 15, Quận Bình Thạnh, TP.HCM"]', 'TP. Hồ Chí Minh', 0.00, 250000000.00, '200014849372 - Eximbank HCM', '0311223344', 'Đối tác cung cấp sữa Vinamilk, TH True Milk, Dutch Lady', NOW(), NOW()),
('NCC006', 'Công ty TNHH Đồ uống & Rượu bia Kim Long', 'Vũ Đức Thịnh', '["0913889900"]', 'kimlong.drinks@gmail.com', '["19 Cộng Hòa, Phường 4, Quận Tân Bình, TP.HCM"]', 'TP. Hồ Chí Minh', 42000000.00, 500000000.00, '119000182736 - MBBank Tân Bình', '0313322114', 'Phân phối bia Heineken, Tiger, Sài Gòn', NOW(), NOW()),
('NCC007', 'Nhà cung cấp Bao bì & Vật tư Đóng gói Toàn Cầu', 'Đặng Hải Yến', '["0976123987"]', 'toancau.packaging@gmail.com', '["302 Kha Vạn Cân, Phường Hiệp Bình Chánh, TP. Thủ Đức"]', 'Miền Nam', 0.00, 80000000.00, '31410001928374 - BIDV Đông Sài Gòn', '0316677889', 'Túi nilon, màng bọc, băng keo, thùng carton', NOW(), NOW()),
('NCC008', 'Công ty TNHH Bách Hóa & Đồ hộp Minh Khang', 'Bùi Đình Trọng', '["0909443322"]', 'minhkhang.foods@gmail.com', '["55 Nguyễn Văn Cừ, Phường 2, Quận 5, TP.HCM"]', 'TP. Hồ Chí Minh', 18700000.00, 180000000.00, '0181003495867 - Vietcombank Nam Sài Gòn', '0314455667', 'Đồ hộp Hạ Long, cá hộp, pate, xúc xích', NOW(), NOW()),
('NCC009', 'Tập đoàn Thiết Bị Điện Máy Thủ Đô', 'Nguyễn Tiến Đạt', '["0904112233"]', 'thudo.electronics@gmail.com', '["117 Trần Duy Hưng, Cầu Giấy, Hà Nội"]', 'Hà Nội', 35000000.00, 400000000.00, '19035678901019 - Techcombank Hà Nội', '0108923451', 'Phân phối quạt, nồi cơm, đồ gia dụng miền Bắc', NOW(), NOW()),
('NCC010', 'Tổng kho Vật Liệu & Thiết Bị Điện Nước Bắc Trung Nam', 'Trịnh Văn Vinh', '["0912334455"]', 'bactrungnam.hardware@gmail.com', '["45 Nguyễn Lương Bằng, Đống Đa, Hà Nội"]', 'Hà Nội', 0.00, 350000000.00, '0011004567890 - VCB Hà Nội', '0102345678', 'Cung cấp thiết bị điện nước công trình', NOW(), NOW()),
('NCC011', 'Công ty TNHH Phân Phối Dược Mỹ Phẩm Thiên Hà', 'Lý Ngọc Trinh', '["0989112233"]', 'thienha.pharma@gmail.com', '["12 Lý Thường Kiệt, Quận Hải Châu, Đà Nẵng"]', 'Miền Trung', 12000000.00, 200000000.00, '1012345678 - Vietinbank Đà Nẵng', '0401234567', 'Dược mỹ phẩm nhập khẩu chính hãng', NOW(), NOW()),
('NCC012', 'Tổng kho Nông sản & Trái cây Sạch Tây Nguyên', 'Nguyễn Văn Hùng', '["0935112233"]', 'taynguyen.agri@gmail.com', '["88 Lê Duẩn, TP. Buôn Ma Thuột, Đắk Lắk"]', 'Miền Trung', 0.00, 150000000.00, '060099887766 - Sacombank Đắk Lắk', '6001234567', 'Nông sản, cà phê, hạt điều đóng gói', NOW(), NOW()),
('NCC013', 'Xưởng Sản Xuất & Nhập Khẩu Đồ Gia Dụng Gia Phát', 'Đỗ Minh Tuấn', '["0977889900"]', 'giaphat.household@gmail.com', '["234 Hoàng Quốc Việt, Cầu Giấy, Hà Nội"]', 'Hà Nội', 28000000.00, 250000000.00, '119000887766 - MBBank Hà Nội', '0109988776', 'Gia dụng thông minh, bình giữ nhiệt, hộp thực phẩm', NOW(), NOW()),
('NCC014', 'Công ty TNHH Vật Tư Bảo Hộ & Lao Động Đại Việt', 'Trần Quốc Việt', '["0908119922"]', 'daiviet.safety@gmail.com', '["56 Nguyễn Văn Linh, Quận Thanh Khê, Đà Nẵng"]', 'Miền Trung', 0.00, 180000000.00, '3141000998877 - BIDV Đà Nẵng', '0409988776', 'Quần áo bảo hộ, giày boot, nón bảo hiểm', NOW(), NOW()),
('NCC015', 'Tổng Phân Phối Văn Phòng Phẩm & Giấy In Hồng Hà', 'Bùi Thanh Hương', '["0919228833"]', 'hongha.stationery@gmail.com', '["102 Hai Bà Trưng, Quận Hoàn Kiếm, Hà Nội"]', 'Hà Nội', 8400000.00, 120000000.00, '018100998877 - VCB Hoàn Kiếm', '0107766554', 'Giấy in A4, sổ sách, bút mực văn phòng', NOW(), NOW()),
('NCC016', 'Công ty CP Thực Phẩm & Thủy Sản Đồng Tháp', 'Lê Văn Miền', '["0939112244"]', 'dongthap.seafood@gmail.com', '["15 Lý Thường Kiệt, TP. Cao Lãnh, Đồng Tháp"]', 'Miền Nam', 19500000.00, 220000000.00, '200014889900 - Eximbank Đồng Tháp', '1401234567', 'Cá tra, tôm đông lạnh, đồ khô đóng gói', NOW(), NOW());

-- 2. TẠO KHÁCH HÀNG (CUSTOMERS) - 20 KH
INSERT INTO "Customers" ("Code", "Name", "ContactName", "PhonesJson", "Email", "AddressesJson", "Region", "Debt", "CreditLimit", "Notes", "CreatedAt", "UpdatedAt")
VALUES
('KH001', 'Cửa hàng Tạp hóa Cô Ba Sài Gòn', 'Nguyễn Thị Hoa', '["0987112233"]', 'coba.taphoa@gmail.com', '["34 Nguyễn Đình Chiểu, Quận 3, TP.HCM"]', 'TP. Hồ Chí Minh', 8500000.00, 50000000.00, 'Khách quen bán buôn khu vực Quận 3', NOW(), NOW()),
('KH002', 'Siêu thị mini An Khang Mart', 'Trương Minh Tâm', '["0938445566", "02838999888"]', 'ankhangmart@gmail.com', '["112 Nguyễn Trãi, Phường 3, Quận 5, TP.HCM"]', 'TP. Hồ Chí Minh', 14200000.00, 100000000.00, 'Chuỗi 2 cửa hàng mini mart', NOW(), NOW()),
('KH003', 'Đại lý Bán lẻ Thanh Hằng', 'Phạm Thanh Hằng', '["0919332211"]', 'thanhhang.store@gmail.com', '["56 Phan Đăng Lưu, Quận Phú Nhuận, TP.HCM"]', 'Miền Nam', 0.00, 40000000.00, 'Thanh toán tiền mặt hoặc chuyển khoản theo tuần', NOW(), NOW()),
('KH004', 'Cửa hàng Tiện lợi 24/7 Phúc Lộc', 'Võ Hoàng Quân', '["0902998877"]', 'phucloc247@gmail.com', '["89 Cách Mạng Tháng 8, Quận 10, TP.HCM"]', 'TP. Hồ Chí Minh', 6700000.00, 60000000.00, 'Lấy hàng định kỳ thứ 3 và thứ 6', NOW(), NOW()),
('KH005', 'Tạp hóa Bách Hóa Đức Thịnh', 'Đỗ Đức Thịnh', '["0977221100"]', 'ducthinh.bachhoa@gmail.com', '["201 Lê Trọng Tấn, Quận Tân Phú, TP.HCM"]', 'Miền Nam', 0.00, 30000000.00, 'Khách hàng mới tiềm năng', NOW(), NOW()),
('KH006', 'Đại lý Bia & Nước ngọt Hoàng Gia', 'Lê Văn Hoàng', '["0945667788"]', 'hoanggia.beverage@gmail.com', '["78 Quang Trung, Phường 10, Quận Gò Vấp, TP.HCM"]', 'TP. Hồ Chí Minh', 29000000.00, 150000000.00, 'Tiêu thụ sản lượng đồ uống rất lớn', NOW(), NOW()),
('KH007', 'Cửa hàng Bánh kẹo Mẹ & Bé Thỏ Ngọc', 'Vũ Thị Ngọc Bích', '["0981234567"]', 'thongoc.mebe@gmail.com', '["412 Huỳnh Tấn Phát, Quận 7, TP.HCM"]', 'TP. Hồ Chí Minh', 3200000.00, 35000000.00, 'Ưu tiên lấy các loại sữa, bánh ăn dặm', NOW(), NOW()),
('KH008', 'Căn tin Trường THPT Gia Định', 'Trần Văn Hùng', '["0903882211"]', 'cantin.giadinh@gmail.com', '["44 Võ Oanh, Phường 25, Quận Bình Thạnh, TP.HCM"]', 'Miền Nam', 0.00, 20000000.00, 'Đặt bánh kẹo, xúc xích và nước ngọt theo tuần', NOW(), NOW()),
('KH009', 'Tạp hóa Lan Hương', 'Bùi Lan Hương', '["0912348765"]', 'lanhuong.store@gmail.com', '["15 Đỗ Xuân Hợp, Phước Long B, TP. Thủ Đức"]', 'TP. Hồ Chí Minh', 5100000.00, 40000000.00, 'Khách ổn định, thanh toán đúng hạn', NOW(), NOW()),
('KH010', 'Quán Ăn & Bán lẻ Đồng Đội', 'Cao Minh Trí', '["0933119955"]', 'dongdoi.quan@gmail.com', '["29 Tô Hiến Thành, Quận 10, TP.HCM"]', 'TP. Hồ Chí Minh', 0.00, 25000000.00, 'Mua gia vị, dầu ăn, nước mắm, bia', NOW(), NOW()),
('KH011', 'Công ty Cổ Phần Xây Dựng & Trang Trí Đại Nam', 'Đỗ Quốc Bảo', '["0913556677"]', 'dainam.corp@gmail.com', '["88 Nguyễn Thị Minh Khai, Quận 3, TP.HCM"]', 'TP. Hồ Chí Minh', 35000000.00, 150000000.00, 'Thi công dân dụng, lấy vật tư sơn & điện', NOW(), NOW()),
('KH012', 'Chuỗi Cửa Hàng Tiện Lợi Minh Anh Mart', 'Nguyễn Thu Hà', '["0908123456"]', 'minhanhmart@yahoo.com', '["12 Tân Kỳ Tân Quý, Tân Phú, TP.HCM"]', 'Miền Nam', 12500000.00, 80000000.00, 'Lấy bánh kẹo & nước ngọt định kỳ', NOW(), NOW()),
('KH013', 'Đại Lý Điện Nước & Kim Khí Tuấn Hưng', 'Lê Tuấn Hưng', '["0979888999"]', 'tuanhungdiennuoc@gmail.com', '["456 Lê Duẩn, TP. Buôn Ma Thuột, Đắk Lắk"]', 'Miền Trung', 68000000.00, 200000000.00, 'Đại lý cấp 1 khu vực Tây Nguyên', NOW(), NOW()),
('KH014', 'Siêu Thị Mini GreenLife Organic', 'Hoàng Mai Lan', '["0938445566"]', 'greenlife.organics@gmail.com', '["15 Thảo Điền, TP. Thủ Đức, TP.HCM"]', 'TP. Hồ Chí Minh', 8200000.00, 50000000.00, 'Chuyên đồ sinh học & gia dụng', NOW(), NOW()),
('KH015', 'Công ty TNHH Cơ Điện Hưng Phát', 'Vũ Đình Trọng', '["0983223344"]', 'hungphat.mep@gmail.com', '["Số 10 KCN Quang Minh, Mê Linh, Hà Nội"]', 'Hà Nội', 95000000.00, 300000000.00, 'Nhận thầu cơ điện tòa nhà', NOW(), NOW()),
('KH016', 'Hộ Kinh Doanh Bách Hóa Thanh Tâm', 'Võ Thanh Tâm', '["0902334455"]', 'thanhtam.bachhoa@gmail.com', '["Chợ Bà Chiểu, Bình Thạnh, TP.HCM"]', 'TP. Hồ Chí Minh', 0.00, 40000000.00, 'Khách hàng uy tín lâu năm', NOW(), NOW()),
('KH017', 'Công ty Viễn Thông Sao Việt', 'Trương Công Danh', '["0912998877"]', 'saoviet.telecom@gmail.com', '["77 Võ Văn Tần, Quận 3, TP.HCM"]', 'TP. Hồ Chí Minh', 24000000.00, 120000000.00, 'Thường mua vật tư bao bì & phụ kiện', NOW(), NOW()),
('KH018', 'Xí Nghiệp Chế Biến Gỗ Việt Tiến', 'Đặng Quốc Huy', '["0944556677"]', 'viettien.wood@gmail.com', '["Ấp 3, Xã Bình Mỹ, Củ Chi, TP.HCM"]', 'Miền Nam', 41000000.00, 100000000.00, 'Nhập bảo hộ lao động & kim khí', NOW(), NOW()),
('KH019', 'Đại Lý Tạp Hóa Kim Ngân Hà Nội', 'Trần Kim Ngân', '["0904887766"]', 'kimngan.hanoi@gmail.com', '["158 Phố Huế, Hai Bà Trưng, Hà Nội"]', 'Hà Nội', 18500000.00, 90000000.00, 'Đại lý phân phối bánh kẹo & sữa Hà Nội', NOW(), NOW()),
('KH020', 'Cửa Hàng Nông Sản & Thực Phẩm Đà Nẵng', 'Nguyễn Thị Hải', '["0913778899"]', 'danang.foods@gmail.com', '["99 Điện Biên Phủ, Thanh Khê, Đà Nẵng"]', 'Miền Trung', 0.00, 60000000.00, 'Khách quen nhập gia vị & dầu ăn', NOW(), NOW());

-- 3. TẠO SẢN PHẨM (PRODUCTS) - 44 SP LIÊN KẾT VỚI 16 NCC
INSERT INTO "Products" 
("Sku", "Name", "Category", "Uom", "Barcode", "SupplierId", "UnitCost", "WholesalePrice", "RetailPrice", "StockWarehouse1", "StockWarehouse2", "StockWarehouse3", "TotalStock", "ReorderPoint", "CreatedAt", "UpdatedAt")
VALUES
-- Nhóm 1 (NCC001 - Ánh Dương)
('SP001', 'Nước ngọt Coca Cola 320ml (Thùng 24 lon)', 'Đồ uống', 'Thùng', '8935049500011', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC001' LIMIT 1), 185000.00, 205000.00, 220000.00, 80.0, 40.0, 30.0, 150.0, 20.0, NOW(), NOW()),
('SP002', 'Nước ngọt Pepsi lon 320ml (Thùng 24 lon)', 'Đồ uống', 'Thùng', '8935049500028', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC001' LIMIT 1), 180000.00, 200000.00, 215000.00, 60.0, 30.0, 10.0, 100.0, 20.0, NOW(), NOW()),
('SP003', 'Nước tăng lực Redbull Thái Lan 250ml (Khay 24 lon)', 'Đồ uống', 'Khay', '8935049500035', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC001' LIMIT 1), 240000.00, 265000.00, 280000.00, 45.0, 25.0, 10.0, 80.0, 15.0, NOW(), NOW()),
('SP004', 'Trà xanh Không Độ 455ml (Lốc 6 chai)', 'Đồ uống', 'Lốc', '8935049500042', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC001' LIMIT 1), 48000.00, 54000.00, 60000.00, 90.0, 50.0, 20.0, 160.0, 25.0, NOW(), NOW()),

-- Nhóm 2 (NCC002 - Hưng Phát)
('SP005', 'Bánh Chocopie Orion Hộp 12 cái (360g)', 'Bánh kẹo', 'Hộp', '8936036010015', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC002' LIMIT 1), 49000.00, 55000.00, 62000.00, 100.0, 50.0, 30.0, 180.0, 25.0, NOW(), NOW()),
('SP006', 'Bánh quy AFC Dinh dưỡng Vị Rau Cải Hộp 200g', 'Bánh kẹo', 'Hộp', '8936036010022', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC002' LIMIT 1), 28000.00, 32000.00, 36000.00, 150.0, 70.0, 40.0, 260.0, 30.0, NOW(), NOW()),
('SP007', 'Snack Khoai tây OStar Vị Tự Nhiên Gói 90g', 'Bánh kẹo', 'Gói', '8936036010039', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC002' LIMIT 1), 16000.00, 18500.00, 22000.00, 200.0, 100.0, 50.0, 350.0, 40.0, NOW(), NOW()),
('SP008', 'Kẹo dẻo Chupa Chups Trái Cây Hỗn Hợp Gói 100g', 'Bánh kẹo', 'Gói', '8936036010046', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC002' LIMIT 1), 12000.00, 14000.00, 17000.00, 180.0, 80.0, 40.0, 300.0, 35.0, NOW(), NOW()),

-- Nhóm 3 (NCC003 - Việt Nhật)
('SP009', 'Nước giặt OMO Matic Cửa trên Túi 3.6kg', 'Hóa mỹ phẩm', 'Túi', '8934868100018', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC003' LIMIT 1), 175000.00, 195000.00, 215000.00, 50.0, 30.0, 20.0, 100.0, 15.0, NOW(), NOW()),
('SP010', 'Nước rửa chén Sunlight Trà xanh Chai 750g', 'Hóa mỹ phẩm', 'Chai', '8934868100025', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC003' LIMIT 1), 27000.00, 31000.00, 35000.00, 140.0, 80.0, 30.0, 250.0, 30.0, NOW(), NOW()),
('SP011', 'Nước lau sàn Sunlight Hương Hoa Hạ Chai 1kg', 'Hóa mỹ phẩm', 'Chai', '8934868100032', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC003' LIMIT 1), 32000.00, 36500.00, 42000.00, 110.0, 50.0, 25.0, 185.0, 25.0, NOW(), NOW()),
('SP012', 'Dầu gội Clear Men Mát Lạnh Bạc Hà Chai 650g', 'Hóa mỹ phẩm', 'Chai', '8934868100049', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC003' LIMIT 1), 145000.00, 162000.00, 179000.00, 60.0, 30.0, 15.0, 105.0, 15.0, NOW(), NOW()),

-- Nhóm 4 (NCC004 - VinaSpice)
('SP013', 'Mì ăn liền Hảo Hảo Tôm chua cay (Thùng 30 gói)', 'Gia vị & Thực phẩm', 'Thùng', '8934563100012', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC004' LIMIT 1), 108000.00, 118000.00, 128000.00, 250.0, 120.0, 80.0, 450.0, 50.0, NOW(), NOW()),
('SP014', 'Dầu ăn Simply Tinh luyện Đậu Nành Chai 1L', 'Gia vị & Thực phẩm', 'Chai', '8934563100029', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC004' LIMIT 1), 52000.00, 58000.00, 64000.00, 120.0, 60.0, 40.0, 220.0, 30.0, NOW(), NOW()),
('SP015', 'Nước mắm Nam Ngư Đệ Nhị Chai 900ml', 'Gia vị & Thực phẩm', 'Chai', '8934563100036', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC004' LIMIT 1), 26000.00, 29500.00, 33000.00, 160.0, 80.0, 50.0, 290.0, 35.0, NOW(), NOW()),
('SP016', 'Hạt nêm Knorr Thịt thăn Xương ống Gói 900g', 'Gia vị & Thực phẩm', 'Gói', '8934563100043', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC004' LIMIT 1), 68000.00, 75000.00, 82000.00, 95.0, 45.0, 25.0, 165.0, 20.0, NOW(), NOW()),

-- Nhóm 5 (NCC005 - Dairy Farm)
('SP017', 'Sữa tươi tiệt trùng Vinamilk 100% Có đường (Lốc 4 hộp 180ml)', 'Sữa & Bơ', 'Lốc', '8935001700010', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC005' LIMIT 1), 32000.00, 35500.00, 39000.00, 180.0, 90.0, 50.0, 320.0, 40.0, NOW(), NOW()),
('SP018', 'Sữa chua ăn Vinamilk Có đường (Lốc 4 hộp 100g)', 'Sữa & Bơ', 'Lốc', '8935001700027', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC005' LIMIT 1), 24500.00, 27000.00, 30000.00, 140.0, 60.0, 30.0, 230.0, 30.0, NOW(), NOW()),
('SP019', 'Sữa đặc có đường Ông Thọ Lon đỏ 380g', 'Sữa & Bơ', 'Lon', '8935001700034', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC005' LIMIT 1), 23000.00, 25500.00, 28000.00, 160.0, 80.0, 40.0, 280.0, 30.0, NOW(), NOW()),
('SP020', 'Sữa chua uống Probi Men sống Chai 130ml (Lốc 5 chai)', 'Sữa & Bơ', 'Lốc', '8935001700041', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC005' LIMIT 1), 34000.00, 38000.00, 42000.00, 120.0, 50.0, 30.0, 200.0, 25.0, NOW(), NOW()),

-- Nhóm 6 (NCC006 - Kim Long)
('SP021', 'Bia Tiger Crystal 330ml (Thùng 24 lon)', 'Bia & Rượu', 'Thùng', '8935012400015', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC006' LIMIT 1), 385000.00, 410000.00, 435000.00, 90.0, 40.0, 20.0, 150.0, 20.0, NOW(), NOW()),
('SP022', 'Bia Heineken Sleek 330ml (Thùng 24 lon)', 'Bia & Rượu', 'Thùng', '8935012400022', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC006' LIMIT 1), 430000.00, 460000.00, 485000.00, 70.0, 35.0, 15.0, 120.0, 15.0, NOW(), NOW()),
('SP023', 'Bia Sài Gòn Special 330ml (Thùng 24 lon)', 'Bia & Rượu', 'Thùng', '8935012400039', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC006' LIMIT 1), 32000.00, 345000.00, 365000.00, 80.0, 40.0, 20.0, 140.0, 20.0, NOW(), NOW()),

-- Nhóm 7 (NCC007 - Toàn Cầu)
('SP024', 'Túi nilon quai xách tự hủy sinh học 5kg (Bịch 1kg)', 'Bao bì & Gia dụng', 'Bịch', '8938889900010', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC007' LIMIT 1), 38000.00, 43000.00, 48000.00, 100.0, 50.0, 30.0, 180.0, 20.0, NOW(), NOW()),
('SP025', 'Cuộn màng bọc thực phẩm PE 30cm x 150m', 'Bao bì & Gia dụng', 'Cuộn', '8938889900027', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC007' LIMIT 1), 65000.00, 74000.00, 85000.00, 60.0, 30.0, 20.0, 110.0, 15.0, NOW(), NOW()),

-- Nhóm 8 (NCC008 - Minh Khang)
('SP026', 'Thịt heo hầm đóng hộp Hạ Long Can 175g', 'Đồ hộp & Chế biến', 'Hộp', '8937776600019', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC008' LIMIT 1), 31000.00, 35000.00, 39000.00, 90.0, 40.0, 20.0, 150.0, 20.0, NOW(), NOW()),
('SP027', 'Cá nục sốt cà Vissan Hộp 175g', 'Đồ hộp & Chế biến', 'Hộp', '8937776600026', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC008' LIMIT 1), 22000.00, 25000.00, 28500.00, 110.0, 50.0, 25.0, 185.0, 25.0, NOW(), NOW()),
('SP028', 'Pate gan heo CP Hộp 150g', 'Đồ hộp & Chế biến', 'Hộp', '8937776600033', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC008' LIMIT 1), 26000.00, 29000.00, 33000.00, 85.0, 40.0, 20.0, 145.0, 20.0, NOW(), NOW()),

-- Nhóm 9 (NCC009 - Điện Máy Thủ Đô)
('SP029', 'Quạt Đứng Công Nghiệp Senko DCN1806', 'Điện Gia Dụng', 'Cái', '8936012340011', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC009' LIMIT 1), 380000.00, 440000.00, 520000.00, 45.0, 20.0, 15.0, 80.0, 10.0, NOW(), NOW()),
('SP030', 'Nồi Cơm Điện Tử Sunhouse Mama 1.8L', 'Điện Gia Dụng', 'Cái', '8936012340028', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC009' LIMIT 1), 850000.00, 980000.00, 1190000.00, 25.0, 15.0, 5.0, 45.0, 8.0, NOW(), NOW()),

-- Nhóm 10 (NCC010 - Bắc Trung Nam)
('SP031', 'Ống nhựa PVC Bình Minh Phi 21 (Cây 4m)', 'Thiết bị điện nước', 'Cây', '8935012380055', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC010' LIMIT 1), 35000.00, 42000.00, 48000.00, 200.0, 100.0, 50.0, 350.0, 30.0, NOW(), NOW()),
('SP032', 'Vòi sen tắm nóng lạnh Inox 304', 'Thiết bị điện nước', 'Bộ', '8935012380062', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC010' LIMIT 1), 320000.00, 380000.00, 450000.00, 40.0, 20.0, 10.0, 70.0, 10.0, NOW(), NOW()),

-- Nhóm 11 (NCC011 - Dược Mỹ Phẩm Thiên Hà)
('SP033', 'Kem chống nắng Anessa Perfect UV 60ml', 'Mỹ phẩm', 'Chai', '8935012380079', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC011' LIMIT 1), 380000.00, 430000.00, 490000.00, 60.0, 30.0, 20.0, 110.0, 15.0, NOW(), NOW()),
('SP034', 'Sữa rửa mặt Senka Perfect Whip 120g', 'Mỹ phẩm', 'Tuýp', '8935012380086', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC011' LIMIT 1), 75000.00, 88000.00, 105000.00, 120.0, 60.0, 30.0, 210.0, 25.0, NOW(), NOW()),

-- Nhóm 12 (NCC012 - Nông Sản Tây Nguyên)
('SP035', 'Cà phê hạt Rang xay Nguyên chất Robusta 500g', 'Thực phẩm', 'Túi', '8935012380093', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC012' LIMIT 1), 95000.00, 115000.00, 135000.00, 150.0, 80.0, 40.0, 270.0, 30.0, NOW(), NOW()),
('SP036', 'Hạt điều rang muối vỏ lụa Hộp 500g', 'Thực phẩm', 'Hộp', '8935012380109', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC012' LIMIT 1), 110000.00, 130000.00, 155000.00, 90.0, 40.0, 20.0, 150.0, 20.0, NOW(), NOW()),

-- Nhóm 13 (NCC013 - Gia Phát)
('SP037', 'Bình giữ nhiệt Inox 304 Lock&Lock 800ml', 'Gia dụng', 'Cái', '8935012380116', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC013' LIMIT 1), 180000.00, 215000.00, 260000.00, 80.0, 40.0, 20.0, 140.0, 15.0, NOW(), NOW()),
('SP038', 'Bộ 3 hộp thủy tinh đậy kín chịu nhiệt Glasslock', 'Gia dụng', 'Bộ', '8935012380123', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC013' LIMIT 1), 160000.00, 190000.00, 230000.00, 65.0, 30.0, 15.0, 110.0, 15.0, NOW(), NOW()),

-- Nhóm 14 (NCC014 - Bảo Hộ Đại Việt)
('SP039', 'Giày bảo hộ lao động Mũi thép Jogger Safety', 'Bảo hộ', 'Đôi', '8935012380130', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC014' LIMIT 1), 350000.00, 410000.00, 480000.00, 50.0, 25.0, 10.0, 85.0, 10.0, NOW(), NOW()),
('SP040', 'Nón bảo hộ lao động Thùy Dương có núm vặn', 'Bảo hộ', 'Cái', '8935012380147', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC014' LIMIT 1), 45000.00, 55000.00, 68000.00, 120.0, 60.0, 30.0, 210.0, 25.0, NOW(), NOW()),

-- Nhóm 15 (NCC015 - Văn Phòng Phẩm Hồng Hà)
('SP041', 'Giấy in A4 Double A 70gsm (Ram 500 tờ)', 'Văn phòng phẩm', 'Ram', '8935012380154', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC015' LIMIT 1), 62000.00, 69000.00, 78000.00, 300.0, 150.0, 80.0, 530.0, 50.0, NOW(), NOW()),
('SP042', 'Bút bi Thiên Long TL-027 Xanh (Hộp 20 cây)', 'Văn phòng phẩm', 'Hộp', '8935012380161', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC015' LIMIT 1), 65000.00, 75000.00, 88000.00, 180.0, 90.0, 40.0, 310.0, 30.0, NOW(), NOW()),

-- Nhóm 16 (NCC016 - Thực Phẩm Đồng Tháp)
('SP043', 'Cá tra cắt khúc đông lạnh Túi 1kg', 'Thực phẩm đông lạnh', 'Túi', '8935012380178', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC016' LIMIT 1), 58000.00, 68000.00, 79000.00, 110.0, 50.0, 30.0, 190.0, 25.0, NOW(), NOW()),
('SP044', 'Tôm thẻ chân trắng hấp đông lạnh Túi 500g', 'Thực phẩm đông lạnh', 'Túi', '8935012380185', (SELECT "Id" FROM "Suppliers" WHERE "Code"='NCC016' LIMIT 1), 92000.00, 108000.00, 125000.00, 85.0, 40.0, 20.0, 145.0, 20.0, NOW(), NOW());

-- 4. TẠO LỊCH SỬ TỒN KHO BAN ĐẦU (STOCK HISTORIES)
INSERT INTO "StockHistories" ("ProductId", "Warehouse", "SourceType", "BeforeWarehouseStock", "Delta", "AfterWarehouseStock", "BeforeTotalStock", "AfterTotalStock", "ChangeDate", "CreatedAt", "Reason", "Note")
SELECT 
    p."Id", 
    'warehouse1', 
    'initial', 
    0, 
    p."StockWarehouse1", 
    p."StockWarehouse1", 
    0, 
    p."StockWarehouse1", 
    NOW(), 
    NOW(),
    'Khởi tạo tồn kho ban đầu', 
    'Khởi tạo dữ liệu mẫu kho 1'
FROM "Products" p
WHERE p."StockWarehouse1" > 0;

INSERT INTO "StockHistories" ("ProductId", "Warehouse", "SourceType", "BeforeWarehouseStock", "Delta", "AfterWarehouseStock", "BeforeTotalStock", "AfterTotalStock", "ChangeDate", "CreatedAt", "Reason", "Note")
SELECT 
    p."Id", 
    'warehouse2', 
    'initial', 
    0, 
    p."StockWarehouse2", 
    p."StockWarehouse2", 
    p."StockWarehouse1", 
    p."StockWarehouse1" + p."StockWarehouse2", 
    NOW(), 
    NOW(),
    'Khởi tạo tồn kho ban đầu', 
    'Khởi tạo dữ liệu mẫu kho 2'
FROM "Products" p
WHERE p."StockWarehouse2" > 0;

INSERT INTO "StockHistories" ("ProductId", "Warehouse", "SourceType", "BeforeWarehouseStock", "Delta", "AfterWarehouseStock", "BeforeTotalStock", "AfterTotalStock", "ChangeDate", "CreatedAt", "Reason", "Note")
SELECT 
    p."Id", 
    'warehouse3', 
    'initial', 
    0, 
    p."StockWarehouse3", 
    p."StockWarehouse3", 
    p."StockWarehouse1" + p."StockWarehouse2", 
    p."TotalStock", 
    NOW(), 
    NOW(),
    'Khởi tạo tồn kho ban đầu', 
    'Khởi tạo dữ liệu mẫu kho 3'
FROM "Products" p
WHERE p."StockWarehouse3" > 0;

COMMIT;

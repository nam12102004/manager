@echo off
chcp 65001 >nul
echo =====================================================================
echo   IMPORT KHÁCH HÀNG & CÔNG NỢ THÁNG 11 (SHEET BÁO CÁO)
echo =====================================================================
echo.
echo 1. Chạy import vào Database qua API Backend (Mặc định)
echo 2. Kiểm tra số liệu & Tuyến bán hàng (Dry-run, không ghi DB)
echo 3. Tạo lại file SQL seed (seed_customers_month11.sql)
echo 4. Chạy SQL trực tiếp vào PostgreSQL Docker container (nhanh nhất)
echo.
set /p opt="Chọn tùy chọn (1-4, Enter để chọn 1): "

if "%opt%"=="" set opt=1
if "%opt%"=="1" (
    node "%~dp0import-customers-month11.js"
) else if "%opt%"=="2" (
    node "%~dp0import-customers-month11.js" --dry-run
) else if "%opt%"=="3" (
    node "%~dp0import-customers-month11.js" --sql
) else if "%opt%"=="4" (
    node "%~dp0import-customers-month11.js" --direct-db
) else (
    echo Lựa chọn không hợp lệ!
)

echo.
pause

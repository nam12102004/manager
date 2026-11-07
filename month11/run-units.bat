@echo off
chcp 65001 >nul
echo ======================================================================
echo   CAP NHAT DON VI TINH SAN PHAM TU BANG QUY DOI (TK_T10.2026.xlsx)
echo ======================================================================
echo.
echo 1. Chay cap nhat truc tiep vao PostgreSQL Docker (Mac dinh - Khuyen dung)
echo 2. Kiem tra doi sanh so lieu (Dry-run, khong ghi Database)
echo 3. Chi tao file SQL (update_product_units.sql)
echo 4. Dong bo qua Backend REST API
echo.
set /p opt="Chon tuy chon (1-4, Enter de chon 1): "

if "%opt%"=="" set opt=1
if "%opt%"=="1" (
    node "%~dp0import-product-units.js" --direct-db
) else if "%opt%"=="2" (
    node "%~dp0import-product-units.js" --dry-run
) else if "%opt%"=="3" (
    node "%~dp0import-product-units.js" --sql
) else if "%opt%"=="4" (
    node "%~dp0import-product-units.js" --api
) else (
    echo Lua chon khong hop le!
)

echo.
pause

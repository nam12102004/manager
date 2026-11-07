@echo off
chcp 65001 >nul
echo =========================================================
echo   IMPORT DU LIEU THANG 11 (TK_T11.2026.xlsx)
echo =========================================================
echo.
echo 1. Chay import vao Database qua API (Mac dinh)
echo 2. Kiem tra so lieu (Dry-run, khong ghi Database)
echo 3. Tao file SQL seed (seed_excel_products.sql)
echo 4. Chay SQL truc tiep vao PostgreSQL Docker container
echo.
set /p opt="Chon tuy chon (1-4, Enter de chon 1): "

if "%opt%"=="" set opt=1
if "%opt%"=="1" (
    node "%~dp0import-excel-products.js"
) else if "%opt%"=="2" (
    node "%~dp0import-excel-products.js" --dry-run
) else if "%opt%"=="3" (
    node "%~dp0import-excel-products.js" --sql
) else if "%opt%"=="4" (
    node "%~dp0import-excel-products.js" --direct-db
) else (
    echo Lua chon khong hop le!
)

echo.
pause

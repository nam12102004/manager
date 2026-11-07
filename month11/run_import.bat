@echo off
chcp 65001 >nul
echo ======================================================================
echo  IMPORT DANH SACH KHACH HANG & CONG NO T11/2026 VAO DATABASE
echo ======================================================================
echo.

cd /d "%~dp0"

REM 1. Chay script Node.js de cap nhat file SQL moi nhat tu Excel
echo [1/3] Trich xuat du lieu tu Sheet T11,2026...
node import_customers_t11.js --dry-run
if %ERRORLEVEL% NEQ 0 (
    echo [LOI] Khong the trich xuat file Excel.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Chep file SQL vao container Docker debtmanager_db...
docker cp import_customers_t11.sql debtmanager_db:/tmp/import_customers_t11.sql
if %ERRORLEVEL% NEQ 0 (
    echo [LOI] Khong the chep file vao container debtmanager_db. Vui long kiem tra Docker!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Dang thuc thi lenh psql trong PostgreSQL container...
docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/import_customers_t11.sql
if %ERRORLEVEL% NEQ 0 (
    echo [LOI] Thuc thi SQL that bai.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ======================================================================
echo  HOAN TAT IMPORT THANH CONG!
echo ======================================================================
echo.
pause

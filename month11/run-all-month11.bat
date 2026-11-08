@echo off
chcp 65001 >nul
echo ======================================================================
echo   CHAY TONG HOP TOAN BO DATABASE THANG 11 (1 TRANSACTION DUY NHAT)
echo ======================================================================
echo.
echo Cac phan duoc tong hop:
echo   1. seed_excel_products.sql     (Kho, NCC, San pham ^& Gia)
echo   2. update_product_units.sql     (Don vi tinh ^& Quy doi ton kho)
echo   3. seed_customers_month11.sql   (Khach hang ^& Cong no Kho 1)
echo   4. import_customers_t11.sql     (Khach hang ^& Cong no Kho 2)
echo.
echo * Luu y: Tat ca chay trong 1 TRANSACTION duy nhat.
echo   Neu co bat ky loi nao, he thong se ROLLBACK ve nguyen trang.
echo.

set /p confirm="Ban co chac chan muon chay vao database debtmanager_db? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo [HUY] Da huy thao tac chay script.
    pause
    exit /b 0
)

echo.
echo [1/2] Chep all_month11_migration.sql vao container debtmanager_db...
docker cp "%~dp0all_month11_migration.sql" debtmanager_db:/tmp/all_month11_migration.sql
if %ERRORLEVEL% NEQ 0 (
    echo [LOI] Khong the copy file vao container debtmanager_db. Vui long kiem tra Docker!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/2] Dang thuc thi file tong hop qua psql...
docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/all_month11_migration.sql
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [LOI] Co loi xay ra khi thuc thi SQL! Toan bo da duoc ROLLBACK tu dong.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ======================================================================
echo  CHUC MUNG! TOAN BO DU LIEU THANG 11 DA DUOC NHOI VAO DB THANH CONG!
echo ======================================================================
echo.
pause

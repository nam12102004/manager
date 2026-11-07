@echo off
chcp 65001 > nul
echo ===================================================
echo   RESET DATABASE (GIỮ LẠI TÀI KHOẢN NGƯỜI DÙNG)
echo ===================================================
echo Đang thực hiện xóa dữ liệu nghiệp vụ trên debtmanager_db...
docker exec -i debtmanager_db psql -U postgres -d debtmanager_db < reset_db_keep_users.sql
if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================================
    echo   ĐÃ RESET DATABASE THÀNH CÔNG!
    echo   Dữ liệu tài khoản (Users) và cấu hình đã được giữ nguyên.
    echo ===================================================
) else (
    echo.
    echo Có lỗi xảy ra trong quá trình reset database!
)
pause

@echo off
echo ===================================================
echo   KHOI DONG HE THONG QUAN LY CONG NO (DEBT MANAGER)
echo ===================================================
echo Dang build va khoi dong Database, Backend API va Frontend...
docker compose up -d --build

echo.
echo ===================================================
echo   HE THONG DA KHOI DONG THANH CONG!
echo ===================================================
echo - Ung dung Frontend (Web UI): http://localhost:3000
echo - Backend API Swagger UI:      http://localhost:5050/swagger
echo - Tai khoan mac dinh:          admin / admin123
echo ===================================================
pause

@echo off
chcp 65001 > nul
echo Đang nạp 2000 giao dịch vào PostgreSQL container debtmanager_db...
docker cp seed_2000_transactions.sql debtmanager_db:/tmp/seed_2000_transactions.sql
docker exec -i debtmanager_db psql -U postgres -d debtmanager_db -f /tmp/seed_2000_transactions.sql
echo Hoàn tất nạp dữ liệu!
pause

@echo off
echo ===================================================
echo   KIEM TRA MODULE BACKUP DATABASE VA GOOGLE DRIVE
echo ===================================================
echo Dang chay thu nghiem tien trinh backup 1 lan (--run-once)...
docker compose run --rm backup python backup.py --run-once
echo.
echo ===================================================
echo Kiem tra log hoac file backup trong thu muc: backup\local_backups
echo ===================================================
pause

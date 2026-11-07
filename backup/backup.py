#!/usr/bin/env python3
"""
Automated Database Backup to Google Drive
- Creates raw PostgreSQL database dumps (compressed with gzip)
- Uploads backups automatically to Google Drive
- Runs every 24 hours at 12:00 AM (00:00 midnight) in timezone Asia/Ho_Chi_Minh
- Automatically cleans up backups older than RETENTION_DAYS (both local and Google Drive)
"""

import os
import sys
import time
import subprocess
import glob
import json
import signal
import argparse
import logging
from datetime import datetime, timedelta
import pytz

# Google API client imports
try:
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
    from googleapiclient.errors import HttpError
    from google.oauth2 import service_account
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    GOOGLE_LIBS_AVAILABLE = True
except ImportError:
    GOOGLE_LIBS_AVAILABLE = False

# Setup Logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# Shutdown handler
SHUTDOWN_REQUESTED = False

def sig_handler(signum, frame):
    global SHUTDOWN_REQUESTED
    logging.info("Shutdown signal received (SIGTERM/SIGINT). Exiting gracefully...")
    SHUTDOWN_REQUESTED = True

signal.signal(signal.SIGTERM, sig_handler)
signal.signal(signal.SIGINT, sig_handler)

def format_size(bytes_num):
    """Format bytes into human-readable string (KB, MB, GB)."""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_num < 1024.0:
            return f"{bytes_num:.2f} {unit}"
        bytes_num /= 1024.0
    return f"{bytes_num:.2f} TB"

def get_config():
    """Load configuration from environment variables."""
    return {
        "db_host": os.getenv("DB_HOST", "db"),
        "db_port": int(os.getenv("DB_PORT", "5432")),
        "db_user": os.getenv("DB_USER", "postgres"),
        "db_password": os.getenv("DB_PASSWORD", "postgres"),
        "db_name": os.getenv("DB_NAME", "debtmanager_db"),
        "backup_dir": os.getenv("BACKUP_DIR", "/backups"),
        "backup_time": os.getenv("BACKUP_TIME", "00:00"), # 12:00 AM midnight
        "timezone": os.getenv("TZ", os.getenv("TIMEZONE", "Asia/Ho_Chi_Minh")),
        "retention_days": int(os.getenv("RETENTION_DAYS", "30")),
        "run_on_startup": os.getenv("RUN_ON_STARTUP", "false").lower() in ("true", "1", "yes"),
        # Google Drive auth options
        "gdrive_folder_id": os.getenv("GDRIVE_FOLDER_ID", "").strip(),
        "gdrive_service_account_file": os.getenv("GDRIVE_SERVICE_ACCOUNT_FILE", "/app/credentials/service_account.json"),
        "gdrive_token_file": os.getenv("GDRIVE_TOKEN_FILE", "/app/credentials/token.json"),
        "gdrive_service_account_json": os.getenv("GDRIVE_SERVICE_ACCOUNT_JSON", "").strip(),
        "gdrive_client_id": os.getenv("GDRIVE_CLIENT_ID", "").strip(),
        "gdrive_client_secret": os.getenv("GDRIVE_CLIENT_SECRET", "").strip(),
        "gdrive_refresh_token": os.getenv("GDRIVE_REFRESH_TOKEN", "").strip(),
    }

def dump_database(config):
    """
    Execute pg_dump with gzip compression.
    Retries up to 3 times in case of transient database connection errors.
    """
    backup_dir = config["backup_dir"]
    os.makedirs(backup_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{config['db_name']}_{timestamp}.sql.gz"
    filepath = os.path.join(backup_dir, filename)

    env = os.environ.copy()
    env["PGPASSWORD"] = config["db_password"]

    max_attempts = 3
    for attempt in range(1, max_attempts + 1):
        logging.info(f"Dumping database '{config['db_name']}' from {config['db_host']}:{config['db_port']} (attempt {attempt}/{max_attempts})...")
        start_time = time.time()
        
        try:
            with open(filepath, "wb") as f_out:
                # Run pg_dump and pipe directly into gzip -9
                p_dump = subprocess.Popen(
                    [
                        "pg_dump",
                        "-h", config["db_host"],
                        "-p", str(config["db_port"]),
                        "-U", config["db_user"],
                        "-d", config["db_name"],
                        "--clean",
                        "--if-exists"
                    ],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env=env
                )
                p_gzip = subprocess.Popen(
                    ["gzip", "-9"],
                    stdin=p_dump.stdout,
                    stdout=f_out,
                    stderr=subprocess.PIPE
                )
                p_dump.stdout.close()
                _, gzip_err = p_gzip.communicate()
                _, dump_err = p_dump.communicate()

                if p_dump.returncode != 0:
                    err_msg = dump_err.decode("utf-8", errors="replace")
                    raise RuntimeError(f"pg_dump failed with exit code {p_dump.returncode}: {err_msg.strip()}")
                
                if p_gzip.returncode != 0:
                    err_msg = gzip_err.decode("utf-8", errors="replace")
                    raise RuntimeError(f"gzip failed with exit code {p_gzip.returncode}: {err_msg.strip()}")

            file_size = os.path.getsize(filepath)
            if file_size == 0:
                raise RuntimeError("Backup generated an empty file (0 bytes)")

            duration = time.time() - start_time
            logging.info(f"Database dump succeeded in {duration:.2f}s: {filename} ({format_size(file_size)})")
            return filepath, filename, file_size

        except Exception as e:
            logging.warning(f"Dump attempt {attempt} failed: {e}")
            if os.path.exists(filepath):
                try:
                    os.remove(filepath)
                except OSError:
                    pass
            if attempt < max_attempts:
                time.sleep(5)
            else:
                raise

def get_gdrive_service(config):
    """
    Initialize Google Drive v3 API client.
    Supports:
    1. User OAuth2 token.json file (Best for personal @gmail.com accounts - uses personal 15GB quota)
    2. Service Account JSON file (Best for Google Workspace Shared Drives)
    3. Service Account JSON string in environment variable
    4. OAuth2 Refresh Token credentials via env vars
    """
    if not GOOGLE_LIBS_AVAILABLE:
        logging.warning("Google API client libraries are not installed.")
        return None

    scopes = ['https://www.googleapis.com/auth/drive']

    # 1. Check User OAuth2 token.json file (Priority 1: Has full personal storage quota)
    token_file = config.get("gdrive_token_file", "/app/credentials/token.json")
    if os.path.isfile(token_file):
        try:
            creds = Credentials.from_authorized_user_file(token_file, scopes=scopes)
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            logging.info(f"Authenticated with Google Drive via User OAuth token file: {token_file}")
            return build('drive', 'v3', credentials=creds, cache_discovery=False)
        except Exception as e:
            logging.error(f"Failed to load User OAuth token file '{token_file}': {e}")

    # 2. Check Service Account JSON file
    sa_file = config["gdrive_service_account_file"]
    if os.path.isfile(sa_file):
        try:
            creds = service_account.Credentials.from_service_account_file(sa_file, scopes=scopes)
            logging.info(f"Authenticated with Google Drive via Service Account file: {sa_file}")
            return build('drive', 'v3', credentials=creds, cache_discovery=False)
        except Exception as e:
            logging.error(f"Failed to load Service Account file '{sa_file}': {e}")

    # 3. Check Service Account JSON content string
    sa_json = config["gdrive_service_account_json"]
    if sa_json:
        try:
            info = json.loads(sa_json)
            creds = service_account.Credentials.from_service_account_info(info, scopes=scopes)
            logging.info("Authenticated with Google Drive via Service Account JSON environment variable")
            return build('drive', 'v3', credentials=creds, cache_discovery=False)
        except Exception as e:
            logging.error(f"Failed to parse Service Account JSON string: {e}")

    # 4. Check OAuth2 refresh token credentials via environment variables
    client_id = config["gdrive_client_id"]
    client_secret = config["gdrive_client_secret"]
    refresh_token = config["gdrive_refresh_token"]
    if client_id and client_secret and refresh_token:
        try:
            creds = Credentials(
                token=None,
                refresh_token=refresh_token,
                token_uri="https://oauth2.googleapis.com/token",
                client_id=client_id,
                client_secret=client_secret,
                scopes=scopes
            )
            creds.refresh(Request())
            logging.info("Authenticated with Google Drive via OAuth2 refresh token environment variables")
            return build('drive', 'v3', credentials=creds, cache_discovery=False)
        except Exception as e:
            logging.error(f"Failed to authenticate with OAuth2 refresh token: {e}")

    return None

def upload_to_gdrive(service, filepath, filename, folder_id):
    """
    Upload backup file to Google Drive folder using resumable upload.
    Uses supportsAllDrives=True to support both standard folders and Shared Drives.
    """
    file_metadata = {'name': filename}
    if folder_id:
        file_metadata['parents'] = [folder_id]

    media = MediaFileUpload(
        filepath,
        mimetype='application/gzip',
        resumable=True,
        chunksize=5 * 1024 * 1024 # 5 MB chunks
    )

    logging.info(f"Uploading '{filename}' to Google Drive" + (f" (folder: {folder_id})" if folder_id else "") + "...")
    start_time = time.time()
    
    request = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id, name, size, webViewLink',
        supportsAllDrives=True
    )

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            progress = int(status.progress() * 100)
            logging.info(f"Upload progress: {progress}%")

    duration = time.time() - start_time
    file_id = response.get('id')
    web_link = response.get('webViewLink', '')
    logging.info(f"Upload to Google Drive succeeded in {duration:.2f}s! File ID: {file_id}")
    return file_id, web_link

def cleanup_old_local_backups(backup_dir, retention_days, prefix):
    """Delete local backups older than retention_days."""
    if retention_days <= 0:
        return
    
    cutoff_time = time.time() - (retention_days * 86400)
    pattern = os.path.join(backup_dir, f"{prefix}_*.sql.gz")
    
    cleaned_count = 0
    for file_path in glob.glob(pattern):
        try:
            if os.path.getmtime(file_path) < cutoff_time:
                os.remove(file_path)
                cleaned_count += 1
                logging.info(f"Removed expired local backup: {os.path.basename(file_path)}")
        except Exception as e:
            logging.warning(f"Failed to remove expired local backup {file_path}: {e}")
    
    if cleaned_count > 0:
        logging.info(f"Cleaned up {cleaned_count} expired local backup(s) older than {retention_days} days.")

def cleanup_old_gdrive_backups(service, folder_id, retention_days, prefix):
    """Delete backups on Google Drive older than retention_days."""
    if not service or retention_days <= 0 or not folder_id:
        return

    try:
        cutoff_date = (datetime.now(pytz.utc) - timedelta(days=retention_days)).isoformat()
        query = f"'{folder_id}' in parents and trashed = false and name contains '{prefix}_' and createdTime < '{cutoff_date}'"
        
        results = service.files().list(
            q=query,
            fields="files(id, name, createdTime)",
            pageSize=100,
            supportsAllDrives=True,
            includeItemsFromAllDrives=True
        ).execute()

        files_to_delete = results.get('files', [])
        for f in files_to_delete:
            try:
                service.files().delete(fileId=f['id'], supportsAllDrives=True).execute()
                logging.info(f"Removed expired Google Drive backup: {f['name']} (ID: {f['id']})")
            except Exception as e:
                logging.warning(f"Failed to delete expired Google Drive backup {f['id']}: {e}")

        if files_to_delete:
            logging.info(f"Cleaned up {len(files_to_delete)} expired Google Drive backup(s) older than {retention_days} days.")
    except Exception as e:
        logging.warning(f"Failed to perform Google Drive backup cleanup: {e}")

def run_backup_job(config):
    """
    Perform a complete backup cycle:
    1. Dump DB to .sql.gz
    2. Upload to Google Drive (if credentials configured)
    3. Cleanup expired backups
    4. Save status to last_backup_status.json
    """
    status_record = {
        "timestamp": datetime.now().isoformat(),
        "status": "RUNNING",
        "database": config["db_name"],
    }
    
    status_file = os.path.join(config["backup_dir"], "last_backup_status.json")
    start_time = time.time()

    try:
        # Step 1: Dump Database
        filepath, filename, file_size = dump_database(config)
        status_record["filename"] = filename
        status_record["size_bytes"] = file_size
        status_record["size_formatted"] = format_size(file_size)

        # Step 2: Google Drive Upload
        drive_service = get_gdrive_service(config)
        folder_id = config["gdrive_folder_id"]

        if drive_service:
            if not folder_id:
                logging.warning("GDRIVE_FOLDER_ID is not set. The backup will be uploaded to the root of Google Drive / Service Account Drive.")
            try:
                file_id, web_link = upload_to_gdrive(drive_service, filepath, filename, folder_id)
                status_record["gdrive_uploaded"] = True
                status_record["gdrive_file_id"] = file_id
                status_record["gdrive_link"] = web_link
            except HttpError as e:
                err_content = str(e)
                if "storageQuotaExceeded" in err_content or "Service Accounts do not have storage quota" in err_content:
                    logging.warning("=" * 60)
                    logging.warning("[GOOGLE DRIVE STORAGE QUOTA POLICY]")
                    logging.warning("Tài khoản Service Account không có dung lượng lưu trữ trên Google Drive cá nhân.")
                    logging.warning("Giải pháp:")
                    logging.warning("1. Nếu dùng Google Workspace: Chuyển thư mục vào 'Bộ nhớ dùng chung (Shared Drive)' và thêm email Service Account vào đó.")
                    logging.warning("2. Nếu dùng Gmail cá nhân (@gmail.com): Dùng đăng nhập OAuth2 bằng cách chạy 'backup_login_google.bat' để sử dụng 15GB miễn phí của tài khoản cá nhân.")
                    logging.warning("=" * 60)
                logging.error(f"Failed to upload backup to Google Drive: {e}")
                status_record["gdrive_uploaded"] = False
                status_record["gdrive_error"] = str(e)
            except Exception as e:
                logging.error(f"Failed to upload backup to Google Drive: {e}")
                status_record["gdrive_uploaded"] = False
                status_record["gdrive_error"] = str(e)
        else:
            logging.warning("=" * 60)
            logging.warning("[GOOGLE DRIVE NOT CONFIGURED]")
            logging.warning("No valid Google Drive credentials found.")
            logging.warning("Local raw backup saved successfully at: " + filepath)
            logging.warning("=" * 60)
            status_record["gdrive_uploaded"] = False
            status_record["gdrive_error"] = "Google Drive credentials not configured"

        # Step 3: Cleanup expired backups
        cleanup_old_local_backups(config["backup_dir"], config["retention_days"], config["db_name"])
        if drive_service and folder_id:
            cleanup_old_gdrive_backups(drive_service, folder_id, config["retention_days"], config["db_name"])

        duration = time.time() - start_time
        status_record["status"] = "SUCCESS"
        status_record["duration_seconds"] = round(duration, 2)
        logging.info(f"Backup job cycle completed successfully in {duration:.2f}s.")

    except Exception as e:
        duration = time.time() - start_time
        status_record["status"] = "ERROR"
        status_record["error_message"] = str(e)
        status_record["duration_seconds"] = round(duration, 2)
        logging.error(f"Backup job cycle failed: {e}", exc_info=True)

    # Save status file
    try:
        with open(status_file, "w", encoding="utf-8") as f:
            json.dump(status_record, f, indent=2, ensure_ascii=False)
    except Exception as e:
        logging.warning(f"Failed to write status file: {e}")

    return status_record["status"] == "SUCCESS"

def get_seconds_until_next_run(target_time_str="00:00", timezone_str="Asia/Ho_Chi_Minh"):
    """
    Calculate seconds until the next occurrence of target_time_str in timezone_str.
    Default: 00:00 (12:00 AM midnight) in Asia/Ho_Chi_Minh.
    """
    try:
        tz = pytz.timezone(timezone_str)
    except Exception:
        logging.warning(f"Invalid timezone '{timezone_str}', falling back to 'Asia/Ho_Chi_Minh'")
        tz = pytz.timezone("Asia/Ho_Chi_Minh")

    now = datetime.now(tz)
    parts = target_time_str.strip().split(":")
    hour = int(parts[0])
    minute = int(parts[1]) if len(parts) > 1 else 0

    target = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
    if target <= now:
        target += timedelta(days=1)

    wait_seconds = (target - now).total_seconds()
    return wait_seconds, target

def main():
    parser = argparse.ArgumentParser(description="Automated PostgreSQL Backup to Google Drive")
    parser.add_argument("--run-once", action="store_true", help="Run a single backup immediately and exit")
    args = parser.parse_args()

    config = get_config()
    logging.info("=" * 60)
    logging.info("  DATABASE BACKUP TO GOOGLE DRIVE SERVICE STARTED")
    logging.info("=" * 60)
    logging.info(f"Target Database : {config['db_name']} on {config['db_host']}:{config['db_port']}")
    logging.info(f"Timezone        : {config['timezone']}")
    logging.info(f"Daily Schedule  : {config['backup_time']} (12:00 AM / 24h once)")
    logging.info(f"Retention Days  : {config['retention_days']} days")
    logging.info(f"Backup Directory: {config['backup_dir']}")
    logging.info(f"GDrive Folder ID: {config['gdrive_folder_id'] or '(Not configured)'}")
    logging.info("=" * 60)

    # If --run-once requested from CLI
    if args.run_once:
        logging.info("Running single backup (--run-once)...")
        success = run_backup_job(config)
        sys.exit(0 if success else 1)

    # If RUN_ON_STARTUP is enabled, execute one run immediately
    if config["run_on_startup"]:
        logging.info("RUN_ON_STARTUP is enabled. Executing initial backup...")
        run_backup_job(config)

    # Periodic Scheduler Loop
    while not SHUTDOWN_REQUESTED:
        wait_seconds, next_run = get_seconds_until_next_run(config["backup_time"], config["timezone"])
        hours = wait_seconds / 3600.0
        logging.info(f"Next scheduled backup at: {next_run.strftime('%Y-%m-%d %H:%M:%S %Z')} (in {hours:.2f} hours)")

        # Sleep in small chunks of 5 seconds to respond quickly to shutdown signals
        slept = 0
        while slept < wait_seconds and not SHUTDOWN_REQUESTED:
            sleep_chunk = min(5, wait_seconds - slept)
            time.sleep(sleep_chunk)
            slept += sleep_chunk

        if SHUTDOWN_REQUESTED:
            break

        logging.info("Triggering scheduled 24h daily backup...")
        try:
            run_backup_job(config)
        except Exception as e:
            logging.error(f"Unhandled error in scheduled backup: {e}", exc_info=True)

    logging.info("Backup service has stopped.")

if __name__ == "__main__":
    main()

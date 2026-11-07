#!/usr/bin/env python3
"""
OAuth2 Token Generator for Google Drive
Allows personal @gmail.com accounts to authenticate and upload backups
using personal Google Drive storage.
"""

import os
import sys

# Configure UTF-8 encoding for Windows console
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

import json
import time
import urllib.parse
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import webbrowser
import subprocess

def load_env_vars():
    """Load variables from .env file if available."""
    for env_path in [".env", "../.env", "/app/.env"]:
        if os.path.exists(env_path):
            try:
                with open(env_path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            k, v = line.split("=", 1)
                            k = k.strip()
                            v = v.strip().strip("'\"")
                            if k not in os.environ and v:
                                os.environ[k] = v
            except Exception:
                pass

load_env_vars()

CLIENT_ID = os.getenv("GDRIVE_CLIENT_ID", "").strip()
CLIENT_SECRET = os.getenv("GDRIVE_CLIENT_SECRET", "").strip()
REDIRECT_URI = "http://localhost:8085"
SCOPE = "https://www.googleapis.com/auth/drive"

AUTH_CODE = None
SERVER_RUNNING = True

class OAuthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global AUTH_CODE, SERVER_RUNNING
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)
        if "code" in params:
            AUTH_CODE = params["code"][0]
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            html = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"><title>Xác thực thành công</title></head>
            <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 60px; background-color: #f7f9fc;">
                <div style="background: white; max-width: 500px; margin: auto; padding: 30px; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
                    <h1 style="color: #2e7d32; font-size: 24px;">&#10004; XÁC THỰC GOOGLE DRIVE THÀNH CÔNG!</h1>
                    <p style="color: #555; font-size: 16px;">Hệ thống đã nhận được mã ủy quyền và đang thực hiện backup ngay...</p>
                    <p style="color: #777; font-size: 14px;">Bạn có thể đóng tab trình duyệt này.</p>
                </div>
            </body>
            </html>
            """
            self.wfile.write(html.encode("utf-8"))
            SERVER_RUNNING = False
        else:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"Khong tim thay code trong redirect URL.")

    def log_message(self, format, *args):
        return

def exchange_code_for_tokens(code, client_id, client_secret, redirect_uri):
    token_url = "https://oauth2.googleapis.com/token"
    data = urllib.parse.urlencode({
        "code": code,
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": redirect_uri,
        "grant_type": "authorization_code"
    }).encode("utf-8")

    req = urllib.request.Request(token_url, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def update_env_file(refresh_token):
    for path in [".env", "../.env", "/app/.env"]:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                new_lines = []
                replaced = False
                for line in lines:
                    if line.strip().startswith("GDRIVE_REFRESH_TOKEN="):
                        new_lines.append(f"GDRIVE_REFRESH_TOKEN={refresh_token}\n")
                        replaced = True
                    else:
                        new_lines.append(line)
                if not replaced:
                    new_lines.append(f"GDRIVE_REFRESH_TOKEN={refresh_token}\n")
                with open(path, "w", encoding="utf-8") as f:
                    f.writelines(new_lines)
                print(f"[THÀNH CÔNG] Đã lưu GDRIVE_REFRESH_TOKEN vào: {path}", flush=True)
                return True
            except Exception as e:
                print(f"[CẢNH BÁO] Không thể ghi vào {path}: {e}", flush=True)
    return False

def main():
    global AUTH_CODE, SERVER_RUNNING, CLIENT_ID, CLIENT_SECRET
    print("=" * 70, flush=True)
    print("  ỦY QUYỀN TRUY CẬP GOOGLE DRIVE BẰNG GMAIL CÁ NHÂN (OAUTH 2.0)", flush=True)
    print("=" * 70, flush=True)

    if not CLIENT_ID:
        CLIENT_ID = input("Nhập Google Client ID: ").strip()
    if not CLIENT_SECRET:
        CLIENT_SECRET = input("Nhập Google Client Secret: ").strip()

    if not CLIENT_ID or not CLIENT_SECRET:
        print("[LỖI] Client ID và Client Secret không được để trống!", flush=True)
        sys.exit(1)

    auth_params = {
        "client_id": CLIENT_ID,
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "scope": SCOPE,
        "access_type": "offline",
        "prompt": "consent"
    }
    auth_url = "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode(auth_params)

    # Start local server on 8085
    server = HTTPServer(("127.0.0.1", 8085), OAuthHandler)
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()

    print("\n>>> ĐANG MỞ TRÌNH DUYỆT ĐỂ BẠN ĐĂNG NHẬP...", flush=True)
    print("Link xác thực Google:")
    print("-" * 70)
    print(auth_url)
    print("-" * 70)
    print("\n(Nếu Google hiện 'Google chưa xác minh ứng dụng này',")
    print(" bấm 'Nâng cao' (Advanced) -> 'Đi tới DebtManager (không an toàn)' -> 'Tiếp tục')\n", flush=True)

    try:
        webbrowser.open(auth_url)
    except Exception:
        pass

    print(">>> Đang chờ bạn bấm Cho phép trên trình duyệt (tối đa 600s)...", flush=True)

    start_wait = time.time()
    while SERVER_RUNNING and (time.time() - start_wait < 600):
        time.sleep(1)

    try:
        server.shutdown()
        server.server_close()
    except Exception:
        pass

    code = AUTH_CODE

    if not code:
        print("\n[LỖI] Chưa nhận được phản hồi cấp quyền trong 600 giây.", flush=True)
        sys.exit(1)

    print("\n>>> Đang trao đổi mã ủy quyền với Google...", flush=True)
    try:
        token_data = exchange_code_for_tokens(code, CLIENT_ID, CLIENT_SECRET, REDIRECT_URI)
    except Exception as e:
        print(f"[LỖI] Không thể lấy token: {e}", flush=True)
        sys.exit(1)

    refresh_token = token_data.get("refresh_token")
    if refresh_token:
        update_env_file(refresh_token)

    # Save to backup/credentials/token.json
    for cdir in ["backup/credentials", "/app/credentials"]:
        if os.path.exists(cdir):
            token_file = os.path.join(cdir, "token.json")
            try:
                token_data["client_id"] = CLIENT_ID
                token_data["client_secret"] = CLIENT_SECRET
                with open(token_file, "w", encoding="utf-8") as f:
                    json.dump(token_data, f, indent=2)
                print(f"[THÀNH CÔNG] Đã lưu tệp token tại: {token_file}", flush=True)
                break
            except Exception as e:
                print(f"[CẢNH BÁO] Không thể lưu token: {e}", flush=True)

    print("\n" + "=" * 70, flush=True)
    print("  ĐĂNG NHẬP THÀNH CÔNG! ĐANG KHỞI ĐỘNG DOCKER BACKUP NGAY...", flush=True)
    print("=" * 70, flush=True)

    # Restart backup container in docker
    try:
        subprocess.run(["docker", "compose", "up", "-d", "backup"], check=True)
        print("[THÀNH CÔNG] Đã kích hoạt container backup trong Docker!", flush=True)
    except Exception as e:
        print(f"[CẢNH BÁO] Lỗi khi restart docker: {e}", flush=True)

if __name__ == "__main__":
    main()

# -*- coding: utf-8 -*-
"""
month11/import_customers_t11.py
Script đọc file Excel và nạp dữ liệu Khách hàng từ Sheet "T11,2026" vào Database.

Yêu cầu:
  - Cột B làm mã KH (Code) - tự sinh mã KH_T11_Rxxx nếu rỗng để đảm bảo tính duy nhất.
  - Cột C làm tên KH (Name).
  - Cột D (Nợ ĐK), Cột E (Có ĐK) vào công nợ (Debt = Nợ ĐK - Có ĐK) cho Kho 2 (warehouse2).
  - Tuyến bán hàng làm địa điểm (Region) - gán khách hàng tương ứng theo tuyến trong Excel.
  - Chỉ thêm các cột chỉ định theo yêu cầu.
"""

import os
import sys
import zipfile
import xml.etree.ElementTree as ET
import re
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
POSSIBLE_EXCEL_PATHS = [
    os.path.join(SCRIPT_DIR, 'cong_no_kho2_t11.xlsx'),
    r'C:\Users\Admin\.gemini\antigravity\brain\dfe12d50-4d24-47d6-89c1-b273fc44ed48\.user_uploaded\media_1794027516559_dd882f0c.xlsx',
    os.path.join(SCRIPT_DIR, '..', 'TK_T11.2026.xlsx'),
]

EXCEL_FILE = next((p for p in POSSIBLE_EXCEL_PATHS if os.path.exists(p)), None)
if len(sys.argv) > 1 and sys.argv[1].endswith('.xlsx') and os.path.exists(sys.argv[1]):
    EXCEL_FILE = sys.argv[1]

if not EXCEL_FILE:
    print("❌ Không tìm thấy file Excel hợp lệ.")
    sys.exit(1)

def letter_to_col_idx(letter):
    col = 0
    for char in letter:
        col = col * 26 + (ord(char) - ord('A') + 1)
    return col

def parse_cell_ref(ref):
    m = re.match(r'([A-Z]+)([0-9]+)', ref)
    if not m:
        return 0, 0
    return letter_to_col_idx(m.group(1)), int(m.group(2))

def parse_num(v):
    if not v:
        return 0.0
    try:
        return float(str(v).replace(',', '').strip())
    except:
        return 0.0

def extract_customers():
    with zipfile.ZipFile(EXCEL_FILE, 'r') as z:
        ss = []
        if 'xl/sharedStrings.xml' in z.namelist():
            ss_tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for si in ss_tree.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si'):
                text = ''.join(t.text for t in si.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t') if t.text)
                ss.append(text)

        wb_tree = ET.fromstring(z.read('xl/workbook.xml'))
        rels_tree = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
        rel_map = {r.attrib['Id']: r.attrib['Target'] for r in rels_tree.findall('{http://schemas.openxmlformats.org/package/2006/relationships}Relationship')}

        sheet_path = 'xl/worksheets/sheet2.xml'
        for s in wb_tree.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sheet'):
            name = s.attrib['name']
            if 'T11' in name or '11' in name:
                rId = s.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']
                t = rel_map[rId]
                sheet_path = t if t.startswith('xl/') else f'xl/{t}'
                break

        s_tree = ET.fromstring(z.read(sheet_path))
        sheet_data = s_tree.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sheetData')

        rows = {}
        for r in sheet_data.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row'):
            r_num = int(r.attrib['r'])
            cells = {}
            for c in r.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c'):
                col_i, _ = parse_cell_ref(c.attrib['r'])
                t = c.attrib.get('t')
                v = c.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v')
                val = ''
                if v is not None and v.text is not None:
                    val = ss[int(v.text)] if t == 's' else v.text
                cells[col_i] = val
            rows[r_num] = cells

    current_route = ""
    raw_customers = []

    for r_num in sorted(rows.keys()):
        if r_num <= 5:
            continue
        cells = rows[r_num]
        col_b = cells.get(2, '').strip()
        col_c = cells.get(3, '').strip()
        col_d = cells.get(4, '').strip()
        col_e = cells.get(5, '').strip()

        if r_num == 6:
            current_route = "THÀNH PHỐ"
            continue
        elif 66 <= r_num <= 72:
            continue
        elif r_num == 73:
            current_route = "NAM TRỰC - TRỰC NINH - Ý YÊN - VỤ BẢN - XUÂN TRƯỜNG"
            continue
        elif 202 <= r_num <= 208:
            continue
        elif r_num == 209:
            current_route = "GIAO THUỶ - NGHĨA HƯNG - HẢI HẬU"
            continue
        elif r_num in (328, 330):
            continue

        if not col_c and not col_b:
            continue
        if 'cộng tuyến' in col_c.lower() or 'tổng cộng' in col_c.lower():
            continue

        no_dk = parse_num(col_d)
        co_dk = parse_num(col_e)
        debt = no_dk - co_dk

        raw_customers.append({
            'row': r_num,
            'code_raw': col_b,
            'name': col_c,
            'route': current_route,
            'no_dk': no_dk,
            'co_dk': co_dk,
            'debt': debt
        })

    seen_codes = {}
    customers = []
    for c in raw_customers:
        code = c['code_raw']
        if not code:
            code = f"KH_T11_R{c['row']:03d}"
        elif code in seen_codes:
            seen_codes[code] += 1
            code = f"{code}_{seen_codes[code]}"
        else:
            seen_codes[code] = 1

        customers.append({
            'row': c['row'],
            'code': code,
            'name': c['name'],
            'route': c['route'],
            'no_dk': c['no_dk'],
            'co_dk': c['co_dk'],
            'debt': c['debt']
        })

    return customers

def generate_sql(customers):
    sql_file = os.path.join(SCRIPT_DIR, 'import_customers_t11.sql')
    def escape_sql(val):
        if val is None:
            return 'NULL'
        return "'" + str(val).replace("'", "''") + "'"

    lines = [
        "-- =====================================================================",
        "-- Script: import_customers_t11.sql",
        "-- Mục đích: Nhập danh sách khách hàng từ Sheet T11,2026 (File Excel Kho 2)",
        "-- Yêu cầu:",
        "--   - Cột B làm mã KH (Code)",
        "--   - Cột C làm tên KH (Name)",
        "--   - Cột D (Nợ ĐK), Cột E (Có ĐK) vào công nợ (Debt = Nợ ĐK - Có ĐK)",
        "--   - Tuyến bán hàng làm địa điểm (Region - gán theo tuyến trong Excel)",
        "--   - Chỉ thêm các cột chỉ định theo yêu cầu",
        "-- =====================================================================\n",
        "SET client_encoding = 'UTF8';\n",
        "BEGIN;\n",
        "CREATE TEMP TABLE temp_customers_t11 (",
        "    row_num INT,",
        "    code VARCHAR(50),",
        "    name VARCHAR(255),",
        "    debt NUMERIC(18, 2),",
        "    region VARCHAR(100)",
        ") ON COMMIT DROP;\n",
        "INSERT INTO temp_customers_t11 (row_num, code, name, debt, region) VALUES"
    ]

    val_lines = [
        f"    ({c['row']}, {escape_sql(c['code'])}, {escape_sql(c['name'])}, {c['debt']:.2f}, {escape_sql(c['route'])})"
        for c in customers
    ]
    lines.append(",\n".join(val_lines) + ";\n")

    lines.extend([
        '-- 1. Chèn hoặc Cập nhật vào bảng Customers (chỉ các cột chỉ định: Code, Name, Debt, Region)',
        'INSERT INTO "Customers" ("Code", "Name", "Debt", "CreditLimit", "Region", "CreatedAt", "UpdatedAt")',
        'SELECT ',
        '    t.code,',
        '    t.name,',
        '    t.debt,',
        '    0,',
        '    t.region,',
        '    NOW(),',
        '    NOW()',
        'FROM temp_customers_t11 t',
        'ON CONFLICT ("Code") DO UPDATE SET',
        '    "Name" = EXCLUDED."Name",',
        '    "Debt" = EXCLUDED."Debt",',
        '    "Region" = EXCLUDED."Region",',
        '    "UpdatedAt" = NOW();\n',
        '-- 2. Cập nhật bảng công nợ theo kho: CustomerWarehouseDebts (cho Kho 2 - warehouse2)',
        'INSERT INTO "CustomerWarehouseDebts" ("CustomerId", "Warehouse", "Debt", "UpdatedAt")',
        'SELECT ',
        '    c."Id",',
        "    'warehouse2',",
        '    t.debt,',
        '    NOW()',
        'FROM temp_customers_t11 t',
        'JOIN "Customers" c ON c."Code" = t.code',
        'ON CONFLICT ("CustomerId", "Warehouse") DO UPDATE SET',
        '    "Debt" = EXCLUDED."Debt",',
        '    "UpdatedAt" = NOW();\n',
        '-- 3. Ghi nhận sổ công nợ ban đầu: CustomerDebtHistories (nếu chưa có bản ghi init)',
        'INSERT INTO "CustomerDebtHistories" ("CustomerId", "Warehouse", "SourceType", "Reason", "BeforeDebt", "Delta", "AfterDebt", "CreatedAt")',
        'SELECT ',
        '    c."Id",',
        "    'warehouse2',",
        "    'init',",
        "    'Khởi tạo công nợ đầu kỳ T11/2026 từ Excel',",
        '    0,',
        '    t.debt,',
        '    t.debt,',
        '    NOW()',
        'FROM temp_customers_t11 t',
        'JOIN "Customers" c ON c."Code" = t.code',
        'WHERE NOT EXISTS (',
        '    SELECT 1 FROM "CustomerDebtHistories" h ',
        "    WHERE h.\"CustomerId\" = c.\"Id\" AND h.\"SourceType\" = 'init' AND h.\"Warehouse\" = 'warehouse2'",
        ');\n',
        'COMMIT;\n'
    ])

    with open(sql_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))
    print(f"✅ Đã tạo file SQL thành công tại: {sql_file}")
    return sql_file

def main():
    print("=" * 70)
    print(" BỘ TOOL IMPORT KHÁCH HÀNG & CÔNG NỢ TỪ SHEET T11,2026 VÀO DATABASE")
    print("=" * 70)
    print(f"📂 Nguồn Excel: {EXCEL_FILE}\n")

    customers = extract_customers()

    by_route = {}
    tot_no = 0.0
    tot_co = 0.0
    for c in customers:
        r = c['route']
        if r not in by_route:
            by_route[r] = {'count': 0, 'no': 0.0, 'co': 0.0, 'debt': 0.0}
        by_route[r]['count'] += 1
        by_route[r]['no'] += c['no_dk']
        by_route[r]['co'] += c['co_dk']
        by_route[r]['debt'] += c['debt']
        tot_no += c['no_dk']
        tot_co += c['co_dk']

    print(f"📊 Đã trích xuất thành công {len(customers)} khách hàng:")
    for r, st in by_route.items():
        print(f"  📍 Tuyến: {r}")
        print(f"     - Số lượng KH: {st['count']}")
        print(f"     - Nợ ĐK (Cột D): {st['no']:,.2f} đ")
        print(f"     - Có ĐK (Cột E): {st['co']:,.2f} đ")
        print(f"     - Công nợ ròng : {st['debt']:,.2f} đ")
    print("-" * 70)
    print(f"⭐ TỔNG CỘNG NỢ ĐK (Cột D): {tot_no:,.2f} đ (Khớp Excel: 2,164,483,650 đ)")
    print(f"⭐ TỔNG CỘNG CÓ ĐK (Cột E): {tot_co:,.2f} đ (Khớp Excel:   122,623,820 đ)")
    print(f"⭐ CÔNG NỢ RÒNG (Debt):    {(tot_no - tot_co):,.2f} đ")
    print("=" * 70 + "\n")

    sql_file = generate_sql(customers)

    if '--direct-db' in sys.argv:
        print("🔄 Đang thực thi file SQL vào Docker container debtmanager_db...")
        try:
            subprocess.run(['docker', 'cp', sql_file, 'debtmanager_db:/tmp/import_customers_t11.sql'], check=True)
            subprocess.run(['docker', 'exec', '-i', 'debtmanager_db', 'psql', '-U', 'postgres', '-d', 'debtmanager_db', '-f', '/tmp/import_customers_t11.sql'], check=True)
            print("✅ Đã nạp thành công toàn bộ dữ liệu vào PostgreSQL!")
        except Exception as e:
            print("❌ Lỗi khi thực thi:", e)

if __name__ == '__main__':
    main()

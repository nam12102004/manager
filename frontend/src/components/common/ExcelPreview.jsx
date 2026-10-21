import React, { useState, useEffect, useMemo, useRef } from 'react';
import {
  FileSpreadsheet,
  Table,
  Layers,
  Sparkles,
  Loader2,
  Inbox,
  AlertCircle,
  Database,
} from 'lucide-react';
import { exportApi } from '../../api/endpoints';
import { formatNumber, formatVND } from '../../utils/formatters';

const PREVIEW_STYLES = `
.ep-card {
  margin-top: 24px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}
.ep-header {
  padding: 16px 20px;
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}
.ep-title-group {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
.ep-title {
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  gap: 8px;
}
.ep-badge {
  font-size: 0.73rem;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: var(--radius-full);
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
.ep-badge-live {
  background: var(--success-light);
  color: var(--success-text);
  border: 1px solid rgba(16, 185, 129, 0.3);
}
.ep-badge-loading {
  background: rgba(59, 130, 246, 0.1);
  color: #3b82f6;
  border: 1px solid rgba(59, 130, 246, 0.3);
}
.ep-badge-empty {
  background: rgba(245, 158, 11, 0.1);
  color: #d97706;
  border: 1px solid rgba(245, 158, 11, 0.3);
}
.ep-sheet-tabs {
  display: flex;
  align-items: center;
  gap: 6px;
}
.ep-sheet-tab {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-color);
  background: var(--bg-tertiary);
  color: var(--text-secondary);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: all var(--transition-fast);
}
.ep-sheet-tab:hover {
  color: var(--text-primary);
  border-color: var(--primary);
}
.ep-sheet-tab.active {
  background: var(--primary);
  border-color: var(--primary);
  color: #ffffff;
}

/* Excel Viewport */
.ep-viewport {
  overflow-x: auto;
  max-width: 100%;
  background: #ffffff;
  min-height: 220px;
  max-height: 600px;
}
[data-theme='dark'] .ep-viewport {
  background: #0f172a;
}
.ep-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8125rem;
  font-family: var(--font-sans);
  min-width: 800px;
}
.ep-table th,
.ep-table td {
  border: 1px solid #cbd5e1;
  padding: 7px 10px;
  line-height: 1.35;
}
[data-theme='dark'] .ep-table th,
[data-theme='dark'] .ep-table td {
  border-color: #334155;
}

/* Column Header Row with Excel styling */
.ep-th-main {
  background: #047857;
  color: #ffffff;
  font-weight: 700;
  text-align: center;
  vertical-align: middle;
  white-space: nowrap;
}
[data-theme='dark'] .ep-th-main {
  background: #064e3b;
}

.ep-th-sub {
  background: #10b981;
  color: #ffffff;
  font-weight: 600;
  font-size: 0.74rem;
  text-align: center;
  white-space: nowrap;
}
[data-theme='dark'] .ep-th-sub {
  background: #047857;
}

.ep-th-fixed {
  background: #065f46;
  color: #ffffff;
  font-weight: 700;
  text-align: center;
  vertical-align: middle;
  white-space: nowrap;
}
[data-theme='dark'] .ep-th-fixed {
  background: #022c22;
}

.ep-th-total {
  background: #0f766e;
  color: #ffffff;
  font-weight: 700;
  text-align: center;
  vertical-align: middle;
  white-space: nowrap;
}
[data-theme='dark'] .ep-th-total {
  background: #115e59;
}

/* Data Cells */
.ep-td-stt {
  text-align: center;
  color: var(--text-muted);
  width: 44px;
  white-space: nowrap;
}
.ep-td-code {
  font-family: var(--font-mono);
  font-weight: 600;
  color: var(--primary);
  white-space: nowrap;
}
.ep-td-name {
  font-weight: 500;
  color: var(--text-primary);
  min-width: 160px;
}
.ep-td-num {
  text-align: right;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
.ep-td-bold {
  font-weight: 700;
}

/* Sub-row */
.ep-tr-subrow td {
  background: rgba(0, 0, 0, 0.02);
  color: var(--text-secondary);
}
[data-theme='dark'] .ep-tr-subrow td {
  background: rgba(255, 255, 255, 0.02);
}

/* Grand Total Row */
.ep-tr-total td {
  background: #dcfce7 !important;
  font-weight: 800;
  color: #065f46 !important;
  border-top: 2px solid #059669;
  border-bottom: 2px solid #059669;
}
[data-theme='dark'] .ep-tr-total td {
  background: #064e3b !important;
  color: #a7f3d0 !important;
  border-color: #10b981;
}

/* Empty State & Loader */
.ep-center-container {
  padding: 48px 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  text-align: center;
}
.ep-empty-title {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--text-primary);
}
.ep-empty-sub {
  font-size: 0.8125rem;
  color: var(--text-secondary);
  max-width: 460px;
}

.ep-footer {
  padding: 10px 18px;
  background: var(--bg-tertiary);
  border-top: 1px solid var(--border-color);
  font-size: 0.78rem;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px;
}
`;

let previewStylesInjected = false;
function ensurePreviewStyles() {
  if (previewStylesInjected || typeof document === 'undefined') return;
  const styleEl = document.createElement('style');
  styleEl.setAttribute('data-component', 'excel-preview');
  styleEl.textContent = PREVIEW_STYLES;
  document.head.appendChild(styleEl);
  previewStylesInjected = true;
}

function formatCellValue(key, value) {
  if (value === null || value === undefined || value === '') return '—';
  if (typeof value === 'number') {
    const k = key.toLowerCase();

    // 1. Explicit currency / price / amount / cashflow / debt (unambiguous money fields)
    if (
      k.includes('giá trị tồn') ||
      k.includes('thành tiền') ||
      k.includes('tiền nhập') ||
      k.includes('tiền xuất') ||
      k.includes('đơn giá') ||
      k.includes('đơn giá tb') ||
      k.includes('đơn giá vốn') ||
      k.includes('giá vốn') ||
      k.includes('doanh số') ||
      k.includes('giá trị') ||
      k.includes('thu') ||
      k.includes('chi') ||
      k.includes('ròng') ||
      k.includes('đầu kỳ') ||
      k.includes('cuối kỳ') ||
      k.includes('dư nợ') ||
      (k.includes('tiền') && !k.includes('tiến'))
    ) {
      return formatVND(value);
    }

    // 2. Quantity / count / stock / delta / STT (ALWAYS number, NEVER currency with ₫)
    if (
      k === 'stt' ||
      k.includes('sl') ||
      k.includes('số lượng') ||
      k.includes('tồn kho') ||
      k.includes('tồn') ||
      k.includes('chênh lệch') ||
      k.includes('thay đổi')
    ) {
      return formatNumber(value);
    }

    // 3. Fallback price / balance keywords
    if (
      k.includes('giá') ||
      k.includes('nợ') ||
      k.includes('tăng') ||
      k.includes('giảm') ||
      (k.includes('ds') && !k.includes('danh sách'))
    ) {
      return formatVND(value);
    }

    // 4. Warehouse breakdown amount column when metric label is just warehouse name (e.g. "01/10 (Kho 1)" for revenue)
    // Note: Any warehouse quantity column already matched rule 2 (includes 'sl') above!
    if (k.includes('kho')) {
      return formatVND(value);
    }

    return formatNumber(value);
  }
  return String(value);
}

function isNumericColumn(key) {
  const k = key.toLowerCase();
  return (
    k.includes('(sl') ||
    k.includes('số lượng') ||
    k.includes('tồn') ||
    k.includes('chênh lệch') ||
    k.includes('doanh số') ||
    k.includes('tiền') ||
    k.includes('giá') ||
    k.includes('thu') ||
    k.includes('chi') ||
    k.includes('ròng') ||
    k.includes('đầu kỳ') ||
    k.includes('tăng') ||
    k.includes('giảm') ||
    k.includes('cuối kỳ') ||
    k.includes('nợ') ||
    k.includes('kho') ||
    k.includes('ds') ||
    k.startsWith('sl')
  );
}

export default function ExcelPreview({
  requestPayload = null,
  includeDetailSheet = true,
}) {
  ensurePreviewStyles();

  const [activeSheet, setActiveSheet] = useState('summary'); // 'summary' | 'detail'
  const [previewData, setPreviewData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const payloadKey = useMemo(() => {
    return requestPayload ? JSON.stringify(requestPayload) : '';
  }, [requestPayload]);

  useEffect(() => {
    if (!requestPayload) return;

    let cancelled = false;
    setLoading(true);
    setError(null);

    const timer = setTimeout(async () => {
      try {
        const res = await exportApi.getPreview(requestPayload);
        if (!cancelled) {
          setPreviewData(res);
          setLoading(false);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err?.response?.data?.message || err?.message || 'Không thể tải bản xem trước dữ liệu');
          setLoading(false);
        }
      }
    }, 200);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [payloadKey]);

  const hasDetailSheet = Boolean(
    (includeDetailSheet || requestPayload?.includeDetailSheet) &&
      previewData?.detailColumns &&
      previewData?.detailColumns.length > 0
  );

  const fixedCols = previewData?.fixedColumns || [];
  const buckets = previewData?.buckets || [];
  const bucketMetrics = previewData?.bucketMetrics || [];
  const totalCols = previewData?.totalColumns || [];
  const summaryRows = previewData?.summaryRows || [];
  const detailCols = previewData?.detailColumns || [];
  const detailRows = previewData?.detailRows || [];

  return (
    <div className="ep-card">
      {/* Header bar */}
      <div className="ep-header">
        <div className="ep-title-group">
          <div className="ep-title">
            <FileSpreadsheet size={20} color="var(--success)" />
            <span>Mẫu cấu trúc Excel dự kiến</span>
          </div>

          {loading ? (
            <span className="ep-badge ep-badge-loading">
              <Loader2 size={12} className="animate-spin" />
              <span>Đang cập nhật số liệu thật</span>
            </span>
          ) : previewData?.hasData ? (
            <span className="ep-badge ep-badge-live">
              <Database size={12} />
              <span>Dữ liệu thật ({previewData.totalSummaryRows} dòng)</span>
            </span>
          ) : (
            <span className="ep-badge ep-badge-empty">
              <span>Chưa có phát sinh trong kỳ</span>
            </span>
          )}

          {previewData?.breakdownByWarehouse && (
            <span
              className="ep-badge"
              style={{
                background: 'rgba(16, 185, 129, 0.12)',
                color: 'var(--primary)',
                border: '1px solid rgba(16, 185, 129, 0.3)',
                fontWeight: 700,
              }}
            >
              Tách cột theo từng kho (1 sheet)
            </span>
          )}
        </div>

        {/* Sheet Tabs */}
        <div className="ep-sheet-tabs">
          <button
            type="button"
            className={`ep-sheet-tab ${activeSheet === 'summary' ? 'active' : ''}`}
            onClick={() => setActiveSheet('summary')}
          >
            <Table size={14} />
            <span>Sheet 1: Tổng hợp</span>
          </button>
          {hasDetailSheet && (
            <button
              type="button"
              className={`ep-sheet-tab ${activeSheet === 'detail' ? 'active' : ''}`}
              onClick={() => setActiveSheet('detail')}
            >
              <Layers size={14} />
              <span>Sheet 2: Dữ liệu chi tiết</span>
            </button>
          )}
        </div>
      </div>

      {/* Viewport for Sheet 1: Summary Matrix */}
      {activeSheet === 'summary' && (
        <div className="ep-viewport">
          {error ? (
            <div className="ep-center-container">
              <AlertCircle size={32} color="var(--danger)" />
              <div className="ep-empty-title">Không thể tải trước dữ liệu</div>
              <div className="ep-empty-sub">{error}</div>
            </div>
          ) : summaryRows.length === 0 && !loading ? (
            <div className="ep-center-container">
              <Inbox size={36} color="var(--text-muted)" />
              <div className="ep-empty-title">Không có dữ liệu trong khoảng thời gian đã chọn</div>
              <div className="ep-empty-sub">
                Hãy thử chọn khoảng thời gian khác hoặc nới lỏng bộ lọc đối tác và sản phẩm
              </div>
            </div>
          ) : (
            <table className="ep-table">
              <thead>
                {/* Header Row 1: Fixed columns (rowSpan 2) + Buckets (colSpan metrics.length) + Total (colSpan totalCols.length) */}
                <tr>
                  {fixedCols.map((col) => (
                    <th key={col} rowSpan={2} className="ep-th-fixed" style={col === 'STT' ? { width: 44 } : undefined}>
                      {col}
                    </th>
                  ))}
                  {buckets.map((b) => (
                    <th key={b} colSpan={Math.max(1, bucketMetrics.length)} className="ep-th-main">
                      {b}
                    </th>
                  ))}
                  {totalCols.length > 0 && (
                    <th colSpan={totalCols.length} className="ep-th-total">
                      Tổng cộng
                    </th>
                  )}
                </tr>

                {/* Header Row 2: Sub-headers for metrics */}
                <tr>
                  {buckets.map((b) =>
                    bucketMetrics.map((m) => (
                      <th key={`${b}-${m.key}`} className="ep-th-sub">
                        {m.label}
                      </th>
                    ))
                  )}
                  {totalCols.map((tCol) => (
                    <th key={`tot-${tCol}`} className="ep-th-sub" style={{ background: '#0d9488' }}>
                      {tCol}
                    </th>
                  ))}
                </tr>
              </thead>

              <tbody>
                {summaryRows.map((row, rIdx) => {
                  const isTotalRow =
                    row['STT'] === 'TỔNG' ||
                    row['STT'] === 'TỔNG CỘNG' ||
                    row['Mã SKU'] === 'CỘNG' ||
                    row['Mã đối tác'] === 'CỘNG';
                  const isSubRow =
                    String(row['Tên sản phẩm'] || '').startsWith('↳') ||
                    String(row['Khách hàng'] || '').startsWith('↳') ||
                    String(row['Nhà cung cấp'] || '').startsWith('↳');

                  const rowClass = isTotalRow
                    ? 'ep-tr-total'
                    : isSubRow
                    ? 'ep-tr-subrow'
                    : '';

                  return (
                    <tr key={`sr-${rIdx}`} className={rowClass}>
                      {/* Fixed column cells */}
                      {fixedCols.map((fc) => {
                        const val = row[fc];
                        let tdClass = '';
                        if (fc === 'STT') tdClass = 'ep-td-stt';
                        else if (fc.includes('Mã')) tdClass = 'ep-td-code';
                        else if (fc.includes('Tên') || fc.includes('Khách') || fc.includes('Nhà'))
                          tdClass = 'ep-td-name';

                        return (
                          <td key={`fc-${fc}`} className={tdClass}>
                            {val ?? '—'}
                          </td>
                        );
                      })}

                      {/* Bucket metric cells */}
                      {buckets.map((b) =>
                        bucketMetrics.map((m) => {
                          const colKey = `${b}${m.suffix}`;
                          const val = row[colKey];
                          return (
                            <td key={`cell-${b}-${m.key}`} className="ep-td-num">
                              {formatCellValue(colKey, val)}
                            </td>
                          );
                        })
                      )}

                      {/* Total columns cells */}
                      {totalCols.map((tCol) => {
                        const val = row[tCol];
                        return (
                          <td key={`tot-cell-${tCol}`} className="ep-td-num ep-td-bold">
                            {formatCellValue(tCol, val)}
                          </td>
                        );
                      })}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Viewport for Sheet 2: Detail Data */}
      {activeSheet === 'detail' && (
        <div className="ep-viewport">
          {detailRows.length === 0 ? (
            <div className="ep-center-container">
              <Inbox size={36} color="var(--text-muted)" />
              <div className="ep-empty-title">Không có chứng từ chi tiết trong kỳ</div>
              <div className="ep-empty-sub">Toàn bộ chứng từ phát sinh thực tế sẽ hiển thị ở đây khi có dữ liệu</div>
            </div>
          ) : (
            <table className="ep-table">
              <thead>
                <tr>
                  <th className="ep-th-fixed" style={{ width: 44 }}>
                    STT
                  </th>
                  {detailCols.map((col) => (
                    <th key={col} className="ep-th-main">
                      {col}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {detailRows.map((row, idx) => (
                  <tr key={`dr-${idx}`}>
                    <td className="ep-td-stt">{idx + 1}</td>
                    {detailCols.map((col) => {
                      const val = row[col];
                      const isNum = isNumericColumn(col);
                      let tdClass = isNum ? 'ep-td-num' : '';
                      if (col.includes('Số phiếu') || col.includes('Mã')) tdClass = 'ep-td-code';
                      if (col.includes('Tên') || col.includes('Khách') || col.includes('Nhà') || col.includes('Sản phẩm'))
                        tdClass = 'ep-td-name';
                      if (col.includes('Ngày')) tdClass = 'text-center';

                      return (
                        <td key={`drc-${col}`} className={tdClass}>
                          {formatCellValue(col, val)}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Footer bar */}
      <div className="ep-footer">
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Sparkles size={14} color="var(--primary)" />
          <span>
            {activeSheet === 'summary'
              ? `Hiển thị ${summaryRows.length} / ${previewData?.totalSummaryRows || summaryRows.length} dòng tổng hợp thực tế từ cơ sở dữ liệu`
              : `Hiển thị ${detailRows.length} / ${previewData?.totalDetailRows || detailRows.length} chứng từ chi tiết thực tế`}
          </span>
        </div>
        <div>
          <span>Định dạng số và màu sắc được đồng bộ chính xác với tệp Excel tải về</span>
        </div>
      </div>
    </div>
  );
}

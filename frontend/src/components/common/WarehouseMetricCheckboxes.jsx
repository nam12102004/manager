import React, { useState, useEffect } from 'react';
import { SlidersHorizontal, Calendar } from 'lucide-react';
import { warehouseService } from '../../services';

const pad2 = (n) => String(n).padStart(2, '0');

export const getTodayYMD = () => {
  const d = new Date();
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
};

export const getCurrentYM = () => {
  const d = new Date();
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}`;
};

const formatDateYMD = (d) =>
  `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;

const formatShortDM = (d) =>
  `${pad2(d.getDate())}/${pad2(d.getMonth() + 1)}`;

export const getWeekBounds = (dateStr) => {
  const ref = dateStr || getTodayYMD();
  const parts = ref.split('-').map(Number);
  const dt = parts.length === 3 ? new Date(parts[0], parts[1] - 1, parts[2]) : new Date();
  const dayOfWeek = dt.getDay() || 7; // 1 (Mon) .. 7 (Sun)
  const mon = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate() - dayOfWeek + 1);
  const sun = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate() - dayOfWeek + 7);
  return {
    fromDate: formatDateYMD(mon),
    toDate: formatDateYMD(sun),
    label: `${formatShortDM(mon)} - ${formatShortDM(sun)}`,
  };
};

export const getMetricTimeParams = (visibleMetrics) => {
  const mode = visibleMetrics?.timeMode || 'all';
  if (mode === 'day') {
    const d = visibleMetrics?.timeDate || getTodayYMD();
    return { fromDate: d, toDate: d };
  }
  if (mode === 'week') {
    const { fromDate, toDate } = getWeekBounds(visibleMetrics?.timeDate);
    return { fromDate, toDate };
  }
  if (mode === 'month') {
    const mStr = visibleMetrics?.timeMonth || getCurrentYM();
    const [y, m] = mStr.split('-').map(Number);
    if (y && m) {
      const firstDay = new Date(y, m - 1, 1);
      const lastDay = new Date(y, m, 0);
      return {
        fromDate: formatDateYMD(firstDay),
        toDate: formatDateYMD(lastDay),
      };
    }
  }
  return { fromDate: undefined, toDate: undefined };
};

export const DEFAULT_VISIBLE_METRICS = {
  exportTotal: false,
  exportWarehouses: {},
  importTotal: false,
  importWarehouses: {},
  receipt: false,
  payment: false,
  timeMode: 'all', // 'all' | 'day' | 'week' | 'month'
  timeDate: getTodayYMD(),
  timeMonth: getCurrentYM(),
};

export const loadSavedMetrics = (storageKey, defaults = DEFAULT_VISIBLE_METRICS) => {
  if (!storageKey) return { ...defaults, timeDate: getTodayYMD(), timeMonth: getCurrentYM() };
  try {
    const saved = localStorage.getItem(storageKey);
    if (!saved) return { ...defaults, timeDate: getTodayYMD(), timeMonth: getCurrentYM() };
    const parsed = JSON.parse(saved);
    return {
      exportTotal: parsed.exportTotal ?? parsed.export ?? defaults.exportTotal ?? false,
      exportWarehouses: parsed.exportWarehouses || defaults.exportWarehouses || {},
      importTotal: parsed.importTotal ?? parsed.import ?? defaults.importTotal ?? false,
      importWarehouses: parsed.importWarehouses || defaults.importWarehouses || {},
      receipt: parsed.receipt ?? defaults.receipt ?? false,
      payment: parsed.payment ?? defaults.payment ?? false,
      timeMode: parsed.timeMode || 'all',
      timeDate: parsed.timeDate || getTodayYMD(),
      timeMonth: parsed.timeMonth || getCurrentYM(),
    };
  } catch {
    return { ...defaults, timeDate: getTodayYMD(), timeMonth: getCurrentYM() };
  }
};

export const saveMetrics = (storageKey, metrics) => {
  if (!storageKey) return;
  try {
    localStorage.setItem(storageKey, JSON.stringify(metrics));
  } catch (err) {
    console.warn('Could not save metrics to localStorage:', err);
  }
};

export default function WarehouseMetricCheckboxes({
  warehouses: propWarehouses,
  activeWarehouse = null, // When viewing a specific warehouse tab (e.g. Kho 1), scope checkboxes to that warehouse
  visibleMetrics = DEFAULT_VISIBLE_METRICS,
  onChange,
  showCashBook = true,
  primaryDirection = 'export', // 'export' | 'import'
  storageKey,
}) {
  const [warehouses, setWarehouses] = useState(() => {
    if (Array.isArray(propWarehouses) && propWarehouses.length > 0) return propWarehouses;
    return warehouseService.getWarehousesSync();
  });

  useEffect(() => {
    if (Array.isArray(propWarehouses) && propWarehouses.length > 0) {
      setWarehouses(propWarehouses);
    } else {
      warehouseService.getWarehouses().then((res) => {
        if (Array.isArray(res) && res.length > 0) setWarehouses(res);
      });
    }
  }, [propWarehouses]);

  const updateMetrics = (next) => {
    if (storageKey) {
      saveMetrics(storageKey, next);
    }
    onChange?.(next);
  };

  const toggleExportTotal = () => {
    updateMetrics({
      ...visibleMetrics,
      exportTotal: !visibleMetrics.exportTotal,
    });
  };

  const toggleExportWh = (whId) => {
    const cur = visibleMetrics.exportWarehouses || {};
    updateMetrics({
      ...visibleMetrics,
      exportWarehouses: {
        ...cur,
        [whId]: !cur[whId],
      },
    });
  };

  const toggleImportTotal = () => {
    updateMetrics({
      ...visibleMetrics,
      importTotal: !visibleMetrics.importTotal,
    });
  };

  const toggleImportWh = (whId) => {
    const cur = visibleMetrics.importWarehouses || {};
    updateMetrics({
      ...visibleMetrics,
      importWarehouses: {
        ...cur,
        [whId]: !cur[whId],
      },
    });
  };

  const toggleReceipt = () => {
    updateMetrics({
      ...visibleMetrics,
      receipt: !visibleMetrics.receipt,
    });
  };

  const togglePayment = () => {
    updateMetrics({
      ...visibleMetrics,
      payment: !visibleMetrics.payment,
    });
  };

  const setTimeMode = (mode) => {
    updateMetrics({
      ...visibleMetrics,
      timeMode: mode,
      timeDate: visibleMetrics.timeDate || getTodayYMD(),
      timeMonth: visibleMetrics.timeMonth || getCurrentYM(),
    });
  };

  const setTimeDate = (dateVal) => {
    if (!dateVal) return;
    updateMetrics({
      ...visibleMetrics,
      timeDate: dateVal,
    });
  };

  const setTimeMonth = (monthVal) => {
    if (!monthVal) return;
    updateMetrics({
      ...visibleMetrics,
      timeMonth: monthVal,
    });
  };

  const curTimeMode = visibleMetrics.timeMode || 'all';
  const curTimeDate = visibleMetrics.timeDate || getTodayYMD();
  const curTimeMonth = visibleMetrics.timeMonth || getCurrentYM();
  const weekInfo = curTimeMode === 'week' ? getWeekBounds(curTimeDate) : null;

  // Section renderers
  const renderExportSection = () => {
    if (activeWarehouse) {
      const wh = activeWarehouse;
      const isChecked = !!visibleMetrics.exportWarehouses?.[wh.id] || !!visibleMetrics.exportTotal;
      return (
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.45rem',
            padding: '0.2rem 0.55rem',
            borderRadius: '6px',
            backgroundColor: '#fff7ed',
            border: '1px solid #fed7aa',
            fontSize: '0.8125rem',
          }}
          title={`Xem số liệu Xuất tại ${wh.name}`}
        >
          <label
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '4px',
              cursor: 'pointer',
              color: '#c2410c',
              fontWeight: isChecked ? 700 : 600,
            }}
          >
            <input
              type="checkbox"
              checked={isChecked}
              onChange={() => {
                const nextVal = !isChecked;
                updateMetrics({
                  ...visibleMetrics,
                  exportWarehouses: {
                    ...(visibleMetrics.exportWarehouses || {}),
                    [wh.id]: nextVal,
                  },
                });
              }}
              style={{ cursor: 'pointer', accentColor: '#ea580c' }}
            />
            <span>Xuất ({wh.shortName || wh.name})</span>
          </label>
        </div>
      );
    }

    return (
      <div
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '0.45rem',
          padding: '0.2rem 0.55rem',
          borderRadius: '6px',
          backgroundColor: '#fff7ed',
          border: '1px solid #fed7aa',
          fontSize: '0.8125rem',
        }}
        title="Xem số liệu Xuất theo từng kho hoặc tổng"
      >
        <span style={{ fontWeight: 700, color: '#c2410c' }}>Xuất:</span>
        <label
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '3px',
            cursor: 'pointer',
            color: '#c2410c',
            fontWeight: visibleMetrics.exportTotal ? 700 : 500,
          }}
          title="Xem Tổng Xuất"
        >
          <input
            type="checkbox"
            checked={!!visibleMetrics.exportTotal}
            onChange={toggleExportTotal}
            style={{ cursor: 'pointer', accentColor: '#ea580c' }}
          />
          <span>Tổng</span>
        </label>

        {warehouses.map((wh) => {
          const isChecked = !!visibleMetrics.exportWarehouses?.[wh.id];
          return (
            <label
              key={`export-${wh.id}`}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '3px',
                cursor: 'pointer',
                color: isChecked ? '#9a3412' : '#c2410c',
                fontWeight: isChecked ? 700 : 500,
                padding: '1px 3px',
                borderRadius: '3px',
                backgroundColor: isChecked ? 'rgba(234, 88, 12, 0.12)' : 'transparent',
              }}
              title={`Xem Xuất của ${wh.name}`}
            >
              <input
                type="checkbox"
                checked={isChecked}
                onChange={() => toggleExportWh(wh.id)}
                style={{ cursor: 'pointer', accentColor: '#ea580c' }}
              />
              <span>{wh.shortName || wh.name}</span>
            </label>
          );
        })}
      </div>
    );
  };

  const renderImportSection = () => {
    if (activeWarehouse) {
      const wh = activeWarehouse;
      const isChecked = !!visibleMetrics.importWarehouses?.[wh.id] || !!visibleMetrics.importTotal;
      return (
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.45rem',
            padding: '0.2rem 0.55rem',
            borderRadius: '6px',
            backgroundColor: '#eff6ff',
            border: '1px solid #bfdbfe',
            fontSize: '0.8125rem',
          }}
          title={`Xem số liệu Nhập tại ${wh.name}`}
        >
          <label
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '4px',
              cursor: 'pointer',
              color: '#1d4ed8',
              fontWeight: isChecked ? 700 : 600,
            }}
          >
            <input
              type="checkbox"
              checked={isChecked}
              onChange={() => {
                const nextVal = !isChecked;
                updateMetrics({
                  ...visibleMetrics,
                  importWarehouses: {
                    ...(visibleMetrics.importWarehouses || {}),
                    [wh.id]: nextVal,
                  },
                });
              }}
              style={{ cursor: 'pointer', accentColor: '#2563eb' }}
            />
            <span>Nhập ({wh.shortName || wh.name})</span>
          </label>
        </div>
      );
    }

    return (
      <div
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '0.45rem',
          padding: '0.2rem 0.55rem',
          borderRadius: '6px',
          backgroundColor: '#eff6ff',
          border: '1px solid #bfdbfe',
          fontSize: '0.8125rem',
        }}
        title="Xem số liệu Nhập theo từng kho hoặc tổng"
      >
        <span style={{ fontWeight: 700, color: '#1d4ed8' }}>Nhập:</span>
        <label
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '3px',
            cursor: 'pointer',
            color: '#1d4ed8',
            fontWeight: visibleMetrics.importTotal ? 700 : 500,
          }}
          title="Xem Tổng Nhập"
        >
          <input
            type="checkbox"
            checked={!!visibleMetrics.importTotal}
            onChange={toggleImportTotal}
            style={{ cursor: 'pointer', accentColor: '#2563eb' }}
          />
          <span>Tổng</span>
        </label>

        {warehouses.map((wh) => {
          const isChecked = !!visibleMetrics.importWarehouses?.[wh.id];
          return (
            <label
              key={`import-${wh.id}`}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '3px',
                cursor: 'pointer',
                color: isChecked ? '#1e40af' : '#1d4ed8',
                fontWeight: isChecked ? 700 : 500,
                padding: '1px 3px',
                borderRadius: '3px',
                backgroundColor: isChecked ? 'rgba(37, 99, 235, 0.12)' : 'transparent',
              }}
              title={`Xem Nhập của ${wh.name}`}
            >
              <input
                type="checkbox"
                checked={isChecked}
                onChange={() => toggleImportWh(wh.id)}
                style={{ cursor: 'pointer', accentColor: '#2563eb' }}
              />
              <span>{wh.shortName || wh.name}</span>
            </label>
          );
        })}
      </div>
    );
  };

  const renderTimeFilterSection = () => (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '0.35rem',
        padding: '0.18rem 0.45rem',
        borderRadius: '6px',
        backgroundColor: '#f1f5f9',
        border: '1px solid #cbd5e1',
        fontSize: '0.78rem',
      }}
      title="Lọc thời gian tính chỉ số Nhập / Xuất / Thu / Chi"
    >
      <Calendar size={13} style={{ color: '#475569', flexShrink: 0 }} />
      <span style={{ fontWeight: 700, color: '#334155' }}>TG:</span>
      {[
        { id: 'all', label: 'Toàn bộ' },
        { id: 'day', label: 'Ngày' },
        { id: 'week', label: 'Tuần' },
        { id: 'month', label: 'Tháng' },
      ].map((t) => {
        const isActive = curTimeMode === t.id;
        return (
          <button
            key={t.id}
            type="button"
            onClick={() => setTimeMode(t.id)}
            style={{
              padding: '2px 7px',
              borderRadius: '4px',
              border: isActive ? '1px solid #2563eb' : '1px solid transparent',
              backgroundColor: isActive ? '#2563eb' : 'transparent',
              color: isActive ? '#ffffff' : '#475569',
              fontWeight: isActive ? 700 : 500,
              fontSize: '0.76rem',
              cursor: 'pointer',
              transition: 'all 0.15s ease',
            }}
          >
            {t.label}
          </button>
        );
      })}

      {(curTimeMode === 'day' || curTimeMode === 'week') && (
        <input
          type="date"
          value={curTimeDate}
          onChange={(e) => setTimeDate(e.target.value)}
          style={{
            padding: '1px 5px',
            borderRadius: '4px',
            border: '1px solid #94a3b8',
            fontSize: '0.75rem',
            fontFamily: 'inherit',
            backgroundColor: '#ffffff',
            color: '#0f172a',
            cursor: 'pointer',
          }}
          title={curTimeMode === 'day' ? 'Chọn ngày xem chỉ số' : 'Chọn 1 ngày bất kỳ trong tuần cần xem'}
        />
      )}

      {curTimeMode === 'week' && weekInfo && (
        <span
          style={{
            fontSize: '0.72rem',
            fontWeight: 700,
            color: '#1e40af',
            backgroundColor: '#dbeafe',
            padding: '1px 5px',
            borderRadius: '4px',
          }}
          title={`Tuần từ ${weekInfo.fromDate} đến ${weekInfo.toDate}`}
        >
          {weekInfo.label}
        </span>
      )}

      {curTimeMode === 'month' && (
        <input
          type="month"
          value={curTimeMonth}
          onChange={(e) => setTimeMonth(e.target.value)}
          style={{
            padding: '1px 5px',
            borderRadius: '4px',
            border: '1px solid #94a3b8',
            fontSize: '0.75rem',
            fontFamily: 'inherit',
            backgroundColor: '#ffffff',
            color: '#0f172a',
            cursor: 'pointer',
          }}
          title="Chọn tháng xem chỉ số"
        />
      )}
    </div>
  );

  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '0.5rem',
        flexWrap: 'wrap',
      }}
    >
      <span
        style={{
          fontSize: '0.8125rem',
          fontWeight: 700,
          color: 'var(--text-secondary, #475569)',
          display: 'inline-flex',
          alignItems: 'center',
          gap: '4px',
        }}
      >
        <SlidersHorizontal size={13} />
        <span>{activeWarehouse ? `Chỉ số (${activeWarehouse.shortName || activeWarehouse.name}):` : 'Xem chỉ số:'}</span>
      </span>

      {primaryDirection === 'import' ? (
        <>
          {renderImportSection()}
          {renderExportSection()}
        </>
      ) : (
        <>
          {renderExportSection()}
          {renderImportSection()}
        </>
      )}

      {showCashBook && (
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.5rem',
            padding: '0.2rem 0.55rem',
            borderRadius: '6px',
            backgroundColor: '#f8fafc',
            border: '1px solid var(--border-color, #e2e8f0)',
            fontSize: '0.8125rem',
          }}
        >
          <span style={{ fontWeight: 700, color: '#475569' }}>Quỹ:</span>
          <label
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '3px',
              cursor: 'pointer',
              color: '#16a34a',
              fontWeight: visibleMetrics.receipt ? 700 : 500,
            }}
            title={activeWarehouse ? `Xem Đã Thu tại ${activeWarehouse.name}` : 'Xem Đã Thu'}
          >
            <input
              type="checkbox"
              checked={!!visibleMetrics.receipt}
              onChange={toggleReceipt}
              style={{ cursor: 'pointer', accentColor: '#16a34a' }}
            />
            <span>{activeWarehouse ? `Thu (${activeWarehouse.shortName || activeWarehouse.name})` : 'Thu'}</span>
          </label>
          <label
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '3px',
              cursor: 'pointer',
              color: '#dc2626',
              fontWeight: visibleMetrics.payment ? 700 : 500,
            }}
            title={activeWarehouse ? `Xem Đã Chi tại ${activeWarehouse.name}` : 'Xem Đã Chi'}
          >
            <input
              type="checkbox"
              checked={!!visibleMetrics.payment}
              onChange={togglePayment}
              style={{ cursor: 'pointer', accentColor: '#dc2626' }}
            />
            <span>{activeWarehouse ? `Chi (${activeWarehouse.shortName || activeWarehouse.name})` : 'Chi'}</span>
          </label>
        </div>
      )}

      {renderTimeFilterSection()}
    </div>
  );
}

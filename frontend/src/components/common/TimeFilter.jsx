import React from 'react';
import { Calendar, ChevronLeft, ChevronRight, Clock } from 'lucide-react';
import { getCurrentMonthStr, getCurrentDateStr } from '../../utils/formatters';

/**
 * Universal Time & Date Filter Component
 * Supports:
 * - Filter by Month (e.g. 2026-10) with previous/next and "Tháng này"
 * - Filter by Day (e.g. 2026-10-09) with previous/next and "Hôm nay"
 * - Filter by Range (fromDate -> toDate)
 * - Filter All (unfiltered)
 */
export default function TimeFilter({
  mode = 'month', // 'month' | 'day' | 'range' | 'all'
  onModeChange,
  month = getCurrentMonthStr(),
  onMonthChange,
  date = getCurrentDateStr(),
  onDateChange,
  fromDate = '',
  onFromDateChange,
  toDate = '',
  onToDateChange,
  showAll = true,
  showRange = true,
  style = {},
}) {
  // Navigation helpers for Month
  const handlePrevMonth = () => {
    if (!month) return;
    const [y, m] = month.split('-').map(Number);
    const prevDate = new Date(y, m - 2, 1);
    onMonthChange?.(getCurrentMonthStr(prevDate));
  };

  const handleNextMonth = () => {
    if (!month) return;
    const [y, m] = month.split('-').map(Number);
    const nextDate = new Date(y, m, 1);
    onMonthChange?.(getCurrentMonthStr(nextDate));
  };

  // Navigation helpers for Day
  const handlePrevDay = () => {
    if (!date) return;
    const d = new Date(date);
    d.setDate(d.getDate() - 1);
    onDateChange?.(getCurrentDateStr(d));
  };

  const handleNextDay = () => {
    if (!date) return;
    const d = new Date(date);
    d.setDate(d.getDate() + 1);
    onDateChange?.(getCurrentDateStr(d));
  };

  return (
    <div
      className="time-filter-container"
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '0.5rem',
        flexWrap: 'wrap',
        ...style,
      }}
    >
      {/* Mode Switcher Buttons */}
      <div
        style={{
          display: 'inline-flex',
          background: 'var(--bg-tertiary)',
          padding: '2px',
          borderRadius: 'var(--radius-md)',
          border: '1px solid var(--border-color)',
        }}
      >
        <button
          type="button"
          className={`btn btn-sm ${mode === 'month' ? 'btn-primary' : 'btn-ghost'}`}
          style={{
            padding: '0.35rem 0.65rem',
            fontSize: '0.8125rem',
            borderRadius: 'var(--radius-sm)',
            border: 'none',
          }}
          onClick={() => onModeChange?.('month')}
        >
          Theo tháng
        </button>
        <button
          type="button"
          className={`btn btn-sm ${mode === 'day' ? 'btn-primary' : 'btn-ghost'}`}
          style={{
            padding: '0.35rem 0.65rem',
            fontSize: '0.8125rem',
            borderRadius: 'var(--radius-sm)',
            border: 'none',
          }}
          onClick={() => onModeChange?.('day')}
        >
          Theo ngày
        </button>
        {showRange && (
          <button
            type="button"
            className={`btn btn-sm ${mode === 'range' ? 'btn-primary' : 'btn-ghost'}`}
            style={{
              padding: '0.35rem 0.65rem',
              fontSize: '0.8125rem',
              borderRadius: 'var(--radius-sm)',
              border: 'none',
            }}
            onClick={() => onModeChange?.('range')}
          >
            Khoảng ngày
          </button>
        )}
        {showAll && (
          <button
            type="button"
            className={`btn btn-sm ${mode === 'all' ? 'btn-primary' : 'btn-ghost'}`}
            style={{
              padding: '0.35rem 0.65rem',
              fontSize: '0.8125rem',
              borderRadius: 'var(--radius-sm)',
              border: 'none',
            }}
            onClick={() => onModeChange?.('all')}
          >
            Tất cả
          </button>
        )}
      </div>

      {/* Mode = Month Picker */}
      {mode === 'month' && (
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            title="Tháng trước"
            onClick={handlePrevMonth}
          >
            <ChevronLeft size={16} />
          </button>

          <div style={{ position: 'relative', display: 'inline-flex', alignItems: 'center' }}>
            <Calendar
              size={15}
              style={{
                position: 'absolute',
                left: '0.65rem',
                color: 'var(--text-muted)',
                pointerEvents: 'none',
              }}
            />
            <input
              type="month"
              className="form-input mono"
              style={{
                width: '150px',
                padding: '0.4rem 0.5rem 0.4rem 2rem',
                fontSize: '0.8125rem',
                height: '34px',
              }}
              value={month || getCurrentMonthStr()}
              onChange={(e) => onMonthChange?.(e.target.value)}
            />
          </div>

          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            title="Tháng sau"
            onClick={handleNextMonth}
          >
            <ChevronRight size={16} />
          </button>

          <button
            type="button"
            className="btn btn-outline btn-sm"
            style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem', height: '34px' }}
            onClick={() => onMonthChange?.(getCurrentMonthStr())}
          >
            Tháng này
          </button>
        </div>
      )}

      {/* Mode = Day Picker */}
      {mode === 'day' && (
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            title="Hôm qua"
            onClick={handlePrevDay}
          >
            <ChevronLeft size={16} />
          </button>

          <div style={{ position: 'relative', display: 'inline-flex', alignItems: 'center' }}>
            <Calendar
              size={15}
              style={{
                position: 'absolute',
                left: '0.65rem',
                color: 'var(--text-muted)',
                pointerEvents: 'none',
              }}
            />
            <input
              type="date"
              className="form-input mono"
              style={{
                width: '150px',
                padding: '0.4rem 0.5rem 0.4rem 2rem',
                fontSize: '0.8125rem',
                height: '34px',
              }}
              value={date || getCurrentDateStr()}
              onChange={(e) => onDateChange?.(e.target.value)}
            />
          </div>

          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            title="Ngày mai"
            onClick={handleNextDay}
          >
            <ChevronRight size={16} />
          </button>

          <button
            type="button"
            className="btn btn-outline btn-sm"
            style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem', height: '34px' }}
            onClick={() => onDateChange?.(getCurrentDateStr())}
          >
            Hôm nay
          </button>
        </div>
      )}

      {/* Mode = Date Range Picker */}
      {mode === 'range' && (
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>Từ:</span>
          <input
            type="date"
            className="form-input mono"
            style={{ width: '140px', padding: '0.4rem 0.5rem', fontSize: '0.8125rem', height: '34px' }}
            value={fromDate}
            onChange={(e) => onFromDateChange?.(e.target.value)}
          />
          <span style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>Đến:</span>
          <input
            type="date"
            className="form-input mono"
            style={{ width: '140px', padding: '0.4rem 0.5rem', fontSize: '0.8125rem', height: '34px' }}
            value={toDate}
            onChange={(e) => onToDateChange?.(e.target.value)}
          />
        </div>
      )}
    </div>
  );
}

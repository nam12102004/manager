import React from 'react';
import { Sun, Moon, PlusCircle, ArrowUpRight, ArrowDownLeft, Receipt, Bell, ShieldCheck } from 'lucide-react';
import { useTheme } from '../../context/ThemeContext';
import { useAuth } from '../../context/AuthContext';

export default function Header({
  pageTitle,
  pageSubtitle,
  onQuickAction,
}) {
  const { isDark, toggleTheme } = useTheme();
  const { user } = useAuth();

  return (
    <header
      className="header"
      style={{
        height: 'var(--header-height)',
        backgroundColor: 'var(--bg-glass)',
        backdropFilter: 'blur(12px)',
        WebkitBackdropFilter: 'blur(12px)',
        borderBottom: '1px solid var(--border-color)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 2rem',
        position: 'sticky',
        top: 0,
        zIndex: 40,
      }}
    >
      {/* Title & Subtitle */}
      <div>
        <h2 style={{ fontSize: '1.1875rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.01em' }}>
          {pageTitle}
        </h2>
        {pageSubtitle && (
          <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
            {pageSubtitle}
          </p>
        )}
      </div>

      {/* Header Actions */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.875rem' }}>
        {/* Multi-Warehouse Status */}
        <div
          className="badge badge-neutral"
          style={{ padding: '0.35rem 0.75rem', gap: '0.5rem', display: 'none', lgDisplay: 'inline-flex' }}
          title="Hệ thống quản lý tồn kho đa điểm"
        >
          <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--success)' }} />
          <span>Kho đa điểm (Kho 1, 2, 3)</span>
        </div>

        {/* Quick Actions Dropdown / Buttons */}
        {onQuickAction && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <button
              onClick={() => onQuickAction('new-export')}
              className="btn btn-primary btn-sm"
              title="Tạo phiếu bán hàng mới"
            >
              <ArrowUpRight size={15} />
              <span>Bán hàng</span>
            </button>
            <button
              onClick={() => onQuickAction('new-import')}
              className="btn btn-outline btn-sm"
              title="Tạo phiếu nhập hàng mới"
            >
              <ArrowDownLeft size={15} />
              <span>Nhập hàng</span>
            </button>
            <button
              onClick={() => onQuickAction('new-receipt')}
              className="btn btn-outline btn-sm"
              title="Lập phiếu thu tiền"
            >
              <Receipt size={15} />
              <span>Thu tiền</span>
            </button>
          </div>
        )}

        <div style={{ width: '1px', height: '24px', backgroundColor: 'var(--border-color)', margin: '0 0.25rem' }} />

        {/* Theme Toggle Button */}
        <button
          onClick={toggleTheme}
          className="btn btn-outline btn-icon"
          style={{ width: '36px', height: '36px' }}
          title={isDark ? 'Chuyển sang giao diện Sáng' : 'Chuyển sang giao diện Tối'}
        >
          {isDark ? <Sun size={18} color="var(--warning)" /> : <Moon size={18} color="var(--primary)" />}
        </button>
      </div>
    </header>
  );
}

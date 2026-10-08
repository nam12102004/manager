import React from 'react';
import {
  LayoutDashboard,
  Boxes,
  ArrowUpRight,
  ArrowDownLeft,
  Users,
  Truck,
  WalletCards,
  BarChart3,
  Settings,
  ChevronLeft,
  ChevronRight,
  LogOut,
  Building2,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function Sidebar({
  activeTab,
  onTabChange,
  collapsed,
  onToggleCollapse,
}) {
  const { user, logout } = useAuth();

  const navItems = [
    { id: 'dashboard', label: 'Tổng quan', icon: LayoutDashboard },
    { id: 'products', label: 'Sản phẩm & Kho', icon: Boxes },
    { id: 'exports', label: 'Bán hàng / Xuất', icon: ArrowUpRight },
    { id: 'imports', label: 'Mua hàng / Nhập', icon: ArrowDownLeft },
    { id: 'customers', label: 'Khách hàng', icon: Users },
    { id: 'suppliers', label: 'Nhà cung cấp', icon: Truck },
    { id: 'cashbook', label: 'Sổ quỹ Thu - Chi', icon: WalletCards },
    { id: 'reports', label: 'Báo cáo', icon: BarChart3 },
    { id: 'settings', label: 'Cài đặt Cửa hàng', icon: Settings },
  ];

  return (
    <aside
      className="sidebar"
      style={{
        width: collapsed ? 'var(--sidebar-collapsed-width)' : 'var(--sidebar-width)',
        backgroundColor: 'var(--bg-secondary)',
        borderRight: '1px solid var(--border-color)',
        display: 'flex',
        flexDirection: 'column',
        transition: 'width var(--transition-normal)',
        position: 'sticky',
        top: 0,
        height: '100vh',
        zIndex: 50,
        flexShrink: 0,
      }}
    >
      {/* Brand Header */}
      <div
        style={{
          height: 'var(--header-height)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: collapsed ? 'center' : 'space-between',
          padding: collapsed ? '0' : '0 1.25rem',
          borderBottom: '1px solid var(--border-color)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', overflow: 'hidden' }}>
          <div
            style={{
              width: '38px',
              height: '38px',
              borderRadius: 'var(--radius-md)',
              background: 'linear-gradient(135deg, #2563eb, #7c3aed)',
              color: '#ffffff',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
              boxShadow: '0 4px 12px rgba(37, 99, 235, 0.35)',
            }}
          >
            <Building2 size={20} />
          </div>
          {!collapsed && (
            <div style={{ overflow: 'hidden', whiteSpace: 'nowrap' }}>
              <div style={{ fontWeight: 800, fontSize: '1.0625rem', letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
                DebtManager
              </div>
              <div style={{ fontSize: '0.6875rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Kho & Công Nợ
              </div>
            </div>
          )}
        </div>

        {!collapsed && (
          <button
            onClick={onToggleCollapse}
            className="btn btn-ghost btn-icon"
            style={{ width: '28px', height: '28px' }}
            title="Thu gọn menu"
          >
            <ChevronLeft size={16} />
          </button>
        )}
      </div>

      {/* Navigation List */}
      <nav
        style={{
          flex: 1,
          padding: '1rem 0.625rem',
          overflowY: 'auto',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.35rem',
        }}
      >
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              title={collapsed ? item.label : undefined}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem',
                width: '100%',
                padding: collapsed ? '0.75rem 0' : '0.6875rem 0.875rem',
                justifyContent: collapsed ? 'center' : 'flex-start',
                borderRadius: 'var(--radius-md)',
                border: 'none',
                background: isActive ? 'var(--primary-light)' : 'transparent',
                color: isActive ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: isActive ? 700 : 500,
                fontSize: '0.875rem',
                cursor: 'pointer',
                transition: 'all var(--transition-fast)',
                position: 'relative',
              }}
              onMouseEnter={(e) => {
                if (!isActive) e.currentTarget.style.background = 'var(--bg-hover)';
              }}
              onMouseLeave={(e) => {
                if (!isActive) e.currentTarget.style.background = 'transparent';
              }}
            >
              <Icon
                size={20}
                style={{
                  flexShrink: 0,
                  color: isActive ? 'var(--primary)' : 'var(--text-muted)',
                }}
              />
              {!collapsed && (
                <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {item.label}
                </span>
              )}
              {isActive && (
                <span
                  style={{
                    position: 'absolute',
                    left: 0,
                    top: '20%',
                    bottom: '20%',
                    width: '3.5px',
                    borderRadius: '0 4px 4px 0',
                    backgroundColor: 'var(--primary)',
                  }}
                />
              )}
            </button>
          );
        })}
      </nav>

      {/* Bottom User Area */}
      <div
        style={{
          padding: collapsed ? '0.875rem 0.25rem' : '0.875rem 1rem',
          borderTop: '1px solid var(--border-color)',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.5rem',
        }}
      >
        {collapsed ? (
          <button
            onClick={onToggleCollapse}
            className="btn btn-ghost btn-icon"
            style={{ width: '100%', height: '36px' }}
            title="Mở rộng menu"
          >
            <ChevronRight size={18} />
          </button>
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem', overflow: 'hidden' }}>
              <div
                style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: 'var(--radius-full)',
                  background: 'var(--primary-light)',
                  color: 'var(--primary)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 700,
                  fontSize: '0.8125rem',
                  flexShrink: 0,
                  textTransform: 'uppercase',
                }}
              >
                {user?.username ? user.username.charAt(0) : 'A'}
              </div>
              <div style={{ overflow: 'hidden', whiteSpace: 'nowrap' }}>
                <div style={{ fontWeight: 600, fontSize: '0.8125rem', color: 'var(--text-primary)' }}>
                  {user?.username || 'Admin'}
                </div>
                <span className="badge badge-primary" style={{ padding: '0.15rem 0.4rem', fontSize: '0.6875rem' }}>
                  {user?.role || 'admin'}
                </span>
              </div>
            </div>

            <button
              onClick={logout}
              className="btn btn-ghost btn-icon"
              style={{ width: '32px', height: '32px', color: 'var(--danger)' }}
              title="Đăng xuất"
            >
              <LogOut size={16} />
            </button>
          </div>
        )}
      </div>
    </aside>
  );
}

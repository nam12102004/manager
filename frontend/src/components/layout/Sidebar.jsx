import React from 'react';
import { useAuth } from '../../context/AuthContext';
import { warehouseService } from '../../services';

export default function Sidebar({
  activeTab,
  onTabChange,
  collapsed,
  onToggleCollapse,
}) {
  const { user, logout } = useAuth();
  const isAdmin = user?.role?.toLowerCase() === 'admin';

  const [warehouses, setWarehouses] = React.useState(() => warehouseService.getWarehousesSync());
  const [productsExpanded, setProductsExpanded] = React.useState(true);

  React.useEffect(() => {
    warehouseService.getWarehouses().then((res) => {
      if (res && Array.isArray(res)) setWarehouses(res);
    });

    const handleUpdate = (e) => {
      if (e.detail && Array.isArray(e.detail)) {
        setWarehouses(e.detail);
      } else {
        warehouseService.getWarehouses().then((res) => setWarehouses(res));
      }
    };

    window.addEventListener('warehouses-updated', handleUpdate);
    return () => window.removeEventListener('warehouses-updated', handleUpdate);
  }, []);

  const isProductsActive = activeTab === 'products' || activeTab.startsWith('products:');
  const currentSubTab = activeTab.includes(':') ? activeTab.split(':')[1] : 'overview';

  const navItems = [
    { id: 'dashboard', label: 'Tổng quan' },
    { id: 'products', label: 'Sản phẩm & Kho', hasSubmenu: true },
    { id: 'exports', label: 'Xuất' },
    { id: 'imports', label: 'Nhập' },
    { id: 'customers', label: 'Khách hàng' },
    { id: 'suppliers', label: 'Nhà cung cấp' },
    { id: 'cashbook', label: 'Thu - Chi' },
    { id: 'reports', label: 'Báo cáo' },
    ...(isAdmin
      ? [
          { id: 'history', label: 'Lịch sử thao tác' },
          { id: 'users', label: 'Quản lý tài khoản' },
        ]
      : []),
    { id: 'settings', label: 'Cài đặt Cửa hàng' },
  ];

  return (
    <aside
      className={`sidebar ${collapsed ? 'collapsed' : ''}`}
      style={{
        width: collapsed ? 'var(--sidebar-collapsed-width)' : 'var(--sidebar-width)',
        backgroundColor: 'var(--sidebar-bg)',
        borderRight: '1px solid var(--sidebar-border)',
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
          borderBottom: '1px solid var(--sidebar-border)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', overflow: 'hidden' }}>
          {!collapsed && (
            <div style={{ overflow: 'hidden', whiteSpace: 'nowrap' }}>
              <div style={{ fontWeight: 800, fontSize: '1.0625rem', letterSpacing: '-0.02em', color: 'var(--sidebar-text-primary)' }}>
                DebtManager
              </div>
              <div style={{ fontSize: '0.6875rem', color: 'var(--sidebar-text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Kho & Công Nợ
              </div>
            </div>
          )}
          {collapsed && (
            <div style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--sidebar-text-primary)' }}>
              DM
            </div>
          )}
        </div>

        {!collapsed && (
          <button
            onClick={onToggleCollapse}
            className="btn btn-ghost btn-sm"
            style={{ color: 'var(--sidebar-text-muted)', padding: '2px 6px', fontSize: '0.75rem' }}
            title="Thu gọn menu"
          >
            Thu gọn
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
          const isItemActive = item.id === 'products' ? isProductsActive : activeTab === item.id;

          if (item.id === 'products' && item.hasSubmenu) {
            return (
              <div key={item.id} style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
                <button
                  onClick={() => {
                    if (collapsed) {
                      onTabChange('products:overview');
                    } else {
                      setProductsExpanded(!productsExpanded);
                      onTabChange(`products:${currentSubTab}`);
                    }
                  }}
                  title={collapsed ? item.label : undefined}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.75rem',
                    width: '100%',
                    padding: collapsed ? '0.75rem 0' : '0.6875rem 0.875rem',
                    justifyContent: collapsed ? 'center' : 'space-between',
                    borderRadius: 'var(--radius-md)',
                    border: 'none',
                    background: isItemActive ? 'var(--sidebar-active-bg)' : 'transparent',
                    color: isItemActive ? 'var(--sidebar-active-text)' : 'var(--sidebar-text-secondary)',
                    fontWeight: isItemActive ? 700 : 500,
                    fontSize: '0.875rem',
                    cursor: 'pointer',
                    transition: 'all var(--transition-fast)',
                    position: 'relative',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    {!collapsed && (
                      <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {item.label}
                      </span>
                    )}
                    {collapsed && (
                      <span>SP</span>
                    )}
                  </div>

                  {!collapsed && (
                    <span style={{ fontSize: '0.75rem', color: 'var(--sidebar-text-muted)' }}>
                      {productsExpanded ? '▲' : '▼'}
                    </span>
                  )}

                  {isItemActive && (
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

                {/* Submenu for Products & Warehouses */}
                {!collapsed && productsExpanded && (
                  <div
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.2rem',
                      marginLeft: '0.75rem',
                      paddingLeft: '0.75rem',
                      borderLeft: '1px dashed rgba(255, 255, 255, 0.15)',
                      marginTop: '0.1rem',
                    }}
                  >
                    <button
                      onClick={() => onTabChange('products:overview')}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        width: '100%',
                        padding: '0.45rem 0.65rem',
                        borderRadius: 'var(--radius-sm)',
                        border: 'none',
                        background: isProductsActive && currentSubTab === 'overview' ? 'rgba(59, 130, 246, 0.25)' : 'transparent',
                        color: isProductsActive && currentSubTab === 'overview' ? '#93c5fd' : 'var(--sidebar-text-muted)',
                        fontWeight: isProductsActive && currentSubTab === 'overview' ? 700 : 500,
                        fontSize: '0.8125rem',
                        cursor: 'pointer',
                        textAlign: 'left',
                        transition: 'all var(--transition-fast)',
                      }}
                    >
                      <span>Tổng quan kho</span>
                    </button>

                    {warehouses.map((wh) => {
                      const isWhActive = isProductsActive && currentSubTab === wh.id;
                      return (
                        <button
                          key={wh.id}
                          onClick={() => onTabChange(`products:${wh.id}`)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            width: '100%',
                            padding: '0.45rem 0.65rem',
                            borderRadius: 'var(--radius-sm)',
                            border: 'none',
                            background: isWhActive ? 'rgba(59, 130, 246, 0.25)' : 'transparent',
                            color: isWhActive ? '#93c5fd' : 'var(--sidebar-text-muted)',
                            fontWeight: isWhActive ? 700 : 500,
                            fontSize: '0.8125rem',
                            cursor: 'pointer',
                            textAlign: 'left',
                            transition: 'all var(--transition-fast)',
                          }}
                        >
                          <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {wh.shortName || wh.name}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          }

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
                background: isItemActive ? 'var(--sidebar-active-bg)' : 'transparent',
                color: isItemActive ? 'var(--sidebar-active-text)' : 'var(--sidebar-text-secondary)',
                fontWeight: isItemActive ? 700 : 500,
                fontSize: '0.875rem',
                cursor: 'pointer',
                transition: 'all var(--transition-fast)',
                position: 'relative',
              }}
            >
              {!collapsed ? (
                <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {item.label}
                </span>
              ) : (
                <span>{item.label.substring(0, 2)}</span>
              )}
              {isItemActive && (
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
          borderTop: '1px solid var(--sidebar-border)',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.5rem',
        }}
      >
        {collapsed ? (
          <button
            onClick={onToggleCollapse}
            className="btn btn-ghost btn-sm"
            style={{ width: '100%', color: 'var(--sidebar-text-muted)', fontSize: '0.75rem', padding: '4px' }}
            title="Mở rộng menu"
          >
            Mở
          </button>
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem', overflow: 'hidden' }}>
              <div
                style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: 'var(--radius-full)',
                  background: 'rgba(37, 99, 235, 0.25)',
                  color: '#60a5fa',
                  border: '1px solid rgba(59, 130, 246, 0.35)',
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
                <div style={{ fontWeight: 600, fontSize: '0.8125rem', color: 'var(--sidebar-text-primary)' }}>
                  {user?.username || 'Admin'}
                </div>
                <span
                  className={`badge ${isAdmin ? 'badge-primary' : 'badge-neutral'}`}
                  style={{
                    padding: '0.15rem 0.4rem',
                    fontSize: '0.6875rem',
                    fontWeight: 600,
                    background: isAdmin ? 'rgba(37, 99, 235, 0.2)' : 'rgba(100, 116, 139, 0.2)',
                    color: isAdmin ? '#60a5fa' : 'var(--text-secondary)',
                    border: `1px solid ${isAdmin ? 'rgba(59, 130, 246, 0.4)' : 'rgba(148, 163, 184, 0.3)'}`,
                  }}
                >
                  {isAdmin ? 'Quản trị viên' : 'Nhân viên'}
                </span>
              </div>
            </div>

            <button
              onClick={logout}
              className="btn btn-ghost btn-sm"
              style={{ color: '#f87171', padding: '4px 8px', fontSize: '0.75rem' }}
              title="Đăng xuất"
            >
              Thoát
            </button>
          </div>
        )}
      </div>
    </aside>
  );
}

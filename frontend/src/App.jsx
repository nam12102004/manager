import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import { NotificationProvider } from './context/NotificationContext';
import Layout from './components/layout/Layout';

// Pages
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Exports from './pages/Exports';
import Imports from './pages/Imports';
import Customers from './pages/Customers';
import Suppliers from './pages/Suppliers';
import CashBook from './pages/CashBook';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import AuditHistory from './pages/AuditHistory';
import Users from './pages/Users';

const VALID_BASE_TABS = [
  'dashboard',
  'products',
  'exports',
  'imports',
  'customers',
  'suppliers',
  'cashbook',
  'reports',
  'history',
  'users',
  'settings',
];

const isValidTab = (tab) => {
  if (!tab) return false;
  const base = tab.split(':')[0];
  return VALID_BASE_TABS.includes(base);
};

const getInitialTab = () => {
  const hash = window.location.hash.replace(/^#\/?/, '').trim();
  if (isValidTab(hash)) {
    return hash;
  }
  const savedTab = localStorage.getItem('debtmanager_active_tab');
  if (savedTab && isValidTab(savedTab)) {
    return savedTab;
  }
  return 'dashboard';
};

function AppContent() {
  const { user, isAuthenticated, loading } = useAuth();
  const [activeTab, setActiveTabState] = useState(getInitialTab);
  const [quickActionTrigger, setQuickActionTrigger] = useState(null);

  const isAdmin = user?.role?.toLowerCase() === 'admin';

  const setActiveTab = React.useCallback(
    (tab) => {
      // Role Guard: non-admin cannot access history or users
      if (!isAdmin && (tab === 'history' || tab === 'users')) {
        tab = 'dashboard';
      }

      if (isValidTab(tab)) {
        setActiveTabState(tab);
        localStorage.setItem('debtmanager_active_tab', tab);
        if (window.location.hash.replace(/^#\/?/, '').trim() !== tab) {
          window.location.hash = tab;
        }
      }
    },
    [isAdmin]
  );

  React.useEffect(() => {
    // If user is not admin and activeTab is a protected route, fallback to dashboard
    if (!isAdmin && (activeTab === 'history' || activeTab === 'users')) {
      setActiveTab('dashboard');
      return;
    }

    // Keep URL hash synchronized on initial mount
    const currentHash = window.location.hash.replace(/^#\/?/, '').trim();
    if (currentHash !== activeTab) {
      window.location.hash = activeTab;
    }
    localStorage.setItem('debtmanager_active_tab', activeTab);

    const handleHashChange = () => {
      let newHash = window.location.hash.replace(/^#\/?/, '').trim();
      if (!isAdmin && (newHash === 'history' || newHash === 'users')) {
        newHash = 'dashboard';
      }
      if (isValidTab(newHash)) {
        setActiveTabState(newHash);
        localStorage.setItem('debtmanager_active_tab', newHash);
      }
    };

    window.addEventListener('hashchange', handleHashChange);
    return () => window.removeEventListener('hashchange', handleHashChange);
  }, [activeTab, isAdmin, setActiveTab]);

  if (loading) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'var(--bg-primary)',
          color: 'var(--text-muted)',
          fontSize: '1rem',
          fontWeight: 600,
        }}
      >
        Đang khởi động hệ thống DebtManager...
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Login />;
  }

  // Handle Quick Action from Header
  const handleQuickAction = (actionType) => {
    if (actionType === 'new-export') {
      setActiveTab('exports');
      setQuickActionTrigger('new-export-' + Date.now());
    } else if (actionType === 'new-import') {
      setActiveTab('imports');
      setQuickActionTrigger('new-import-' + Date.now());
    } else if (actionType === 'new-receipt') {
      setActiveTab('cashbook');
      setQuickActionTrigger('new-receipt-' + Date.now());
    }
  };

  const isProductsTab = activeTab === 'products' || activeTab.startsWith('products:');
  const selectedWarehouse = activeTab.includes(':') ? activeTab.split(':')[1] : 'overview';

  const getPageMeta = () => {
    if (isProductsTab) {
      if (selectedWarehouse === 'overview') {
        return {
          title: 'Tổng Quan Kho & Danh Mục Sản Phẩm',
          subtitle: 'Xem toàn bộ tồn kho các kho, thêm kho mới và đổi tên kho',
        };
      }
      return {
        title: 'Chi Tiết Tồn Kho & Sản Phẩm',
        subtitle: 'Quản lý, thêm và điều chỉnh tồn kho cho kho đã chọn',
      };
    }

    switch (activeTab) {
      case 'dashboard':
        return {
          title: 'Tổng Quan Hoạt Động',
          subtitle: 'Trung tâm chỉ huy bán hàng, kho đa điểm và công nợ',
        };
      case 'exports':
        return {
          title: 'Phiếu Xuất',
          subtitle: 'Lập hóa đơn xuất hàng, trừ kho và tính nợ khách',
        };
      case 'imports':
        return {
          title: 'Phiếu Nhập',
          subtitle: 'Nhập hàng từ nhà cung cấp, tăng tồn kho và tính nợ NCC',
        };
      case 'customers':
        return {
          title: 'Khách Hàng & Sổ Nợ',
          subtitle: 'Theo dõi lịch sử mua nợ và thu tiền khách hàng',
        };
      case 'suppliers':
        return {
          title: 'Nhà Cung Cấp & Sổ Nợ',
          subtitle: 'Quản lý thông tin nhà cung ứng và công nợ phải chi',
        };
      case 'cashbook':
        return {
          title: 'Thu - Chi Tiền Mặt',
          subtitle: 'Quản lý dòng tiền vào/ra và tồn quỹ ròng',
        };
      case 'reports':
        return {
          title: 'Báo Cáo Thống Kê Định Kỳ',
          subtitle: 'Báo cáo xuất nhập tồn và tổng hợp công nợ theo tháng',
        };
      case 'settings':
        return {
          title: 'Cài Đặt Cửa Hàng & VietQR',
          subtitle: 'Cấu hình thông tin in hóa đơn và thanh toán ngân hàng',
        };
      case 'history':
        return {
          title: 'Lịch Sử Chỉnh Sửa & Đăng Nhập',
          subtitle: 'Nhật ký kiểm toán hoạt động hệ thống và lịch sử truy cập tài khoản',
        };
      case 'users':
        return {
          title: 'Quản Lý Tài Khoản & Phân Quyền',
          subtitle: 'Quản lý người dùng, tạo tài khoản nhân viên và đổi mật khẩu',
        };
      default:
        return { title: 'DebtManager', subtitle: '' };
    }
  };

  const meta = getPageMeta();

  return (
    <Layout
      activeTab={activeTab}
      onTabChange={setActiveTab}
      pageTitle={meta.title}
      pageSubtitle={meta.subtitle}
      onQuickAction={handleQuickAction}
    >
      {activeTab === 'dashboard' && (
        <Dashboard
          onNavigate={setActiveTab}
          onQuickAction={handleQuickAction}
        />
      )}
      {isProductsTab && (
        <Products
          key={quickActionTrigger}
          initialWarehouse={selectedWarehouse}
          onWarehouseChange={(whId) => setActiveTab(`products:${whId}`)}
        />
      )}
      {activeTab === 'exports' && (
        <Exports
          key={quickActionTrigger}
          initialOpenCreate={quickActionTrigger?.startsWith('new-export')}
        />
      )}
      {activeTab === 'imports' && (
        <Imports
          key={quickActionTrigger}
          initialOpenCreate={quickActionTrigger?.startsWith('new-import')}
        />
      )}
      {activeTab === 'customers' && (
        <Customers onQuickAction={handleQuickAction} />
      )}
      {activeTab === 'suppliers' && <Suppliers />}
      {activeTab === 'cashbook' && (
        <CashBook
          key={quickActionTrigger}
          initialOpenReceipt={quickActionTrigger?.startsWith('new-receipt')}
        />
      )}
      {activeTab === 'reports' && <Reports />}
      {activeTab === 'history' && (isAdmin ? <AuditHistory /> : <Dashboard />)}
      {activeTab === 'users' && (isAdmin ? <Users /> : <Dashboard />)}
      {activeTab === 'settings' && <Settings />}
    </Layout>
  );
}

export default function App() {
  return (
    <ThemeProvider>
      <NotificationProvider>
        <AuthProvider>
          <AppContent />
        </AuthProvider>
      </NotificationProvider>
    </ThemeProvider>
  );
}

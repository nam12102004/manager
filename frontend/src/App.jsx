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

function AppContent() {
  const { isAuthenticated, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [quickActionTrigger, setQuickActionTrigger] = useState(null);

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

  const getPageMeta = () => {
    switch (activeTab) {
      case 'dashboard':
        return {
          title: 'Tổng Quan Hoạt Động',
          subtitle: 'Trung tâm chỉ huy bán hàng, kho đa điểm và công nợ',
        };
      case 'products':
        return {
          title: 'Danh Mục Hàng Hóa & Kho',
          subtitle: 'Phân bổ và quản lý tồn kho tại Kho 1, Kho 2, Kho 3',
        };
      case 'exports':
        return {
          title: 'Bán Hàng & Phiếu Xuất',
          subtitle: 'Lập hóa đơn xuất hàng, trừ kho và tính nợ khách',
        };
      case 'imports':
        return {
          title: 'Mua Hàng & Phiếu Nhập',
          subtitle: 'Nhập hàng từ nhà cung cấp, tăng tồn kho và tính nợ NCC',
        };
      case 'customers':
        return {
          title: 'Khách Hàng & Sổ Nợ',
          subtitle: 'Theo dõi hạn mức nợ, lịch sử mua nợ và thu tiền',
        };
      case 'suppliers':
        return {
          title: 'Nhà Cung Cấp & Sổ Nợ',
          subtitle: 'Quản lý thông tin nhà cung ứng và công nợ phải chi',
        };
      case 'cashbook':
        return {
          title: 'Sổ Quỹ Thu - Chi Tiền Mặt',
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
      {activeTab === 'products' && <Products key={quickActionTrigger} />}
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

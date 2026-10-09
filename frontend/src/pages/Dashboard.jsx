import React, { useState, useEffect } from 'react';
import {
  Boxes,
  TrendingUp,
  CreditCard,
  Building,
  ArrowUpRight,
  ArrowDownLeft,
  AlertTriangle,
  Receipt,
  Wallet,
  Calendar,
  Layers,
  ChevronRight,
  RefreshCw,
} from 'lucide-react';
import StatCard from '../components/common/StatCard';
import { dashboardService } from '../services';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr } from '../utils/formatters';

export default function Dashboard({ onNavigate, onQuickAction }) {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState({
    metrics: {
      totalAllStock: 0,
      totalStockValue: 0,
      totalReceivables: 0,
      totalPayables: 0,
      totalReceivedMonth: 0,
      totalPaidMonth: 0,
      netCashflow: 0,
      productCount: 0,
      customerCount: 0,
      supplierCount: 0,
    },
    warehouseStats: [],
    lowStockProducts: [],
    recentActivities: [],
    recentExports: [],
    recentImports: [],
    customers: [],
    suppliers: [],
  });

  const currentMonth = getCurrentMonthStr();

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      const result = await dashboardService.getDashboardData(currentMonth);
      setData(result);
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
  }, []);

  const { metrics, warehouseStats, lowStockProducts, recentExports, customers, suppliers } = data;

  return (
    <div>
      {/* Header with actions & Refresh */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <span>Bảng Điều Khiển Tổng Quan</span>
          </h1>
          <p className="page-subtitle">
            Theo dõi tình hình kinh doanh, kho hàng đa điểm và biến động công nợ trong tháng {currentMonth}
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadDashboardData} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Làm mới</span>
          </button>
          <button className="btn btn-primary" onClick={() => onQuickAction?.('new-export')}>
            <ArrowUpRight size={16} />
            <span>Lập phiếu xuất</span>
          </button>
        </div>
      </div>

      {/* Top Key Metrics */}
      <div className="stats-grid">
        <StatCard
          title="TỔNG TỒN KHO TOÀN HỆ THỐNG"
          value={formatNumber(metrics.totalAllStock)}
          subtitle={`${metrics.productCount} mã sản phẩm đang lưu kho`}
          icon={Boxes}
          color="primary"
          onClick={() => onNavigate?.('products')}
        />
        <StatCard
          title="ƯỚC TÍNH GIÁ TRỊ TỒN KHO"
          value={formatVND(metrics.totalStockValue)}
          subtitle="Tính theo đơn giá vốn nhập"
          icon={Layers}
          color="purple"
          onClick={() => onNavigate?.('reports')}
        />
        <StatCard
          title="CÔNG NỢ PHẢI THU"
          value={formatVND(metrics.totalReceivables)}
          subtitle={`${customers.filter((c) => Number(c.debt || 0) > 0).length} khách hàng còn nợ`}
          icon={TrendingUp}
          color="danger"
          onClick={() => onNavigate?.('customers')}
        />
        <StatCard
          title="CÔNG NỢ PHẢI TRẢ"
          value={formatVND(metrics.totalPayables)}
          subtitle={`${suppliers.filter((s) => Number(s.debt || 0) < 0).length} NCC cần thanh toán`}
          icon={Building}
          color="warning"
          onClick={() => onNavigate?.('suppliers')}
        />
      </div>

      {/* Cashflow & Warehouses Split Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.25rem', marginBottom: '1.75rem' }}>
        {/* Multi-Warehouse Status Card */}
        <div className="glass-card" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.25rem' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Boxes size={18} color="var(--primary)" />
              <span>Danh Mục Kho & Phân Bổ Tồn Kho</span>
            </h3>
            <button className="btn btn-ghost btn-sm" onClick={() => onNavigate?.('products:overview')}>
              <span>Xem chi tiết</span>
              <ChevronRight size={14} />
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {warehouseStats.map((wh, idx) => (
              <div
                key={wh.id}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '0.35rem',
                  cursor: 'pointer',
                  padding: '0.35rem',
                  borderRadius: 'var(--radius-sm)',
                  transition: 'background var(--transition-fast)',
                }}
                onClick={() => onNavigate?.(`products:${wh.id}`)}
                title={`Bấm để xem danh mục tồn kho ${wh.name}`}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>📦 {wh.name}</span>
                  <span className="mono" style={{ fontWeight: 700 }}>
                    {formatNumber(wh.stock)} ({wh.percent}%)
                  </span>
                </div>
                <div
                  style={{
                    height: '8px',
                    borderRadius: 'var(--radius-full)',
                    backgroundColor: 'var(--bg-tertiary)',
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      height: '100%',
                      width: `${wh.percent}%`,
                      backgroundColor:
                        idx === 0
                          ? 'var(--primary)'
                          : idx === 1
                          ? 'var(--info)'
                          : idx === 2
                          ? 'var(--purple)'
                          : 'var(--success)',
                      borderRadius: 'var(--radius-full)',
                      transition: 'width 0.5s ease',
                    }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Cashflow Summary Card */}
        <div className="glass-card" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.25rem' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Wallet size={18} color="var(--success)" />
              <span>Dòng Tiền Thu - Chi Trong Tháng</span>
            </h3>
            <button className="btn btn-ghost btn-sm" onClick={() => onNavigate?.('cashbook')}>
              <span>Xem Thu - Chi</span>
              <ChevronRight size={14} />
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div style={{ background: 'var(--bg-tertiary)', padding: '1rem', borderRadius: 'var(--radius-md)' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                TỔNG THU
              </div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--success)' }}>
                {formatVND(metrics.totalReceivedMonth)}
              </div>
            </div>
            <div style={{ background: 'var(--bg-tertiary)', padding: '1rem', borderRadius: 'var(--radius-md)' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                TỔNG CHI
              </div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--danger)' }}>
                {formatVND(metrics.totalPaidMonth)}
              </div>
            </div>
          </div>

          <div
            style={{
              padding: '0.875rem 1rem',
              borderRadius: 'var(--radius-md)',
              background: metrics.netCashflow >= 0 ? 'var(--success-light)' : 'var(--danger-light)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <span style={{ fontSize: '0.875rem', fontWeight: 600, color: metrics.netCashflow >= 0 ? 'var(--success-text)' : 'var(--danger-text)' }}>
              Chênh lệch dòng tiền ròng:
            </span>
            <span
              className="mono"
              style={{
                fontSize: '1.125rem',
                fontWeight: 800,
                color: metrics.netCashflow >= 0 ? 'var(--success-text)' : 'var(--danger-text)',
              }}
            >
              {metrics.netCashflow >= 0 ? `+${formatVND(metrics.netCashflow)}` : `-${formatVND(Math.abs(metrics.netCashflow))}`}
            </span>
          </div>
        </div>
      </div>

      {/* Two Columns: Low Stock Alert & Recent Activity */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '1.25rem' }}>
        {/* Low Stock Warning */}
        <div className="glass-card" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <AlertTriangle size={18} color="var(--warning)" />
              <span>Cảnh Báo Tồn Kho Dưới Mức An Toàn</span>
            </h3>
            <span className="badge badge-warning">{lowStockProducts.length} sản phẩm</span>
          </div>

          {lowStockProducts.length === 0 ? (
            <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', padding: '1.5rem 0', textAlign: 'center' }}>
              Tất cả sản phẩm đều đang đạt mức tồn kho an toàn.
            </p>
          ) : (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Mã SKU</th>
                    <th>Tên Sản Phẩm</th>
                    <th style={{ textAlign: 'right' }}>Hiện Có</th>
                    <th style={{ textAlign: 'right' }}>Định Mức</th>
                  </tr>
                </thead>
                <tbody>
                  {lowStockProducts.slice(0, 5).map((p) => (
                    <tr key={p.id}>
                      <td className="mono" style={{ fontWeight: 600, color: 'var(--primary)' }}>
                        {p.sku}
                      </td>
                      <td style={{ fontWeight: 500 }}>{p.name}</td>
                      <td style={{ textAlign: 'right' }}>
                        <span className="badge badge-danger mono">{formatNumber(p.totalStock)}</span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatNumber(p.reorderPoint)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Recent Sales & Exports */}
        <div className="glass-card" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <ArrowUpRight size={18} color="var(--primary)" />
              <span>Phiếu Xuất Gần Đây</span>
            </h3>
            <button className="btn btn-ghost btn-sm" onClick={() => onNavigate?.('exports')}>
              <span>Tất cả</span>
              <ChevronRight size={14} />
            </button>
          </div>

          {recentExports.length === 0 ? (
            <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', padding: '1.5rem 0', textAlign: 'center' }}>
              Chưa có phiếu xuất bán nào trong tháng này.
            </p>
          ) : (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Số Phiếu</th>
                    <th>Khách Hàng</th>
                    <th style={{ textAlign: 'right' }}>Tổng Tiền</th>
                    <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                  </tr>
                </thead>
                <tbody>
                  {recentExports.slice(0, 5).map((exp) => (
                    <tr key={exp.id}>
                      <td className="mono" style={{ fontWeight: 600 }}>{exp.voucherNumber}</td>
                      <td>{exp.customerName || `Khách hàng #${exp.customerId}`}</td>
                      <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                        {formatVND(exp.totalSale)}
                      </td>
                      <td style={{ textAlign: 'center' }}>
                        <span className={`badge badge-${exp.status === 'cancelled' ? 'danger' : 'success'}`}>
                          {exp.status === 'cancelled' ? 'Đã hủy' : 'Hoạt động'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

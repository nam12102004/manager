import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  TrendingUp,
  Package,
  Users,
  Building,
  ArrowDownLeft,
  ArrowUpRight,
  RefreshCw,
  Search,
  Filter,
  BarChart2,
  Calendar,
  Layers,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr } from '../../utils/formatters';
import { useNotification } from '../../context/NotificationContext';
import StatCard from '../common/StatCard';
import SearchBar from '../common/SearchBar';
import EmptyState from '../common/EmptyState';
import SortDropdown from '../common/SortDropdown';
import { reportService } from '../../services';

const SALES_SORT_OPTIONS = [
  { value: 'export_amount_desc', label: 'Tiền xuất: Cao nhất → Thấp nhất' },
  { value: 'export_amount_asc', label: 'Tiền xuất: Thấp nhất → Cao nhất' },
  { value: 'import_amount_desc', label: 'Tiền nhập: Cao nhất → Thấp nhất' },
  { value: 'import_amount_asc', label: 'Tiền nhập: Thấp nhất → Cao nhất' },
  { value: 'export_qty_desc', label: 'SL xuất: Nhiều nhất → Ít nhất' },
  { value: 'import_qty_desc', label: 'SL nhập: Nhiều nhất → Ít nhất' },
];

export default function WarehouseSalesTab({ selectedWarehouse = 'overview', warehouses = [] }) {
  const notify = useNotification();

  // Active subtab: 'products' | 'customers' | 'suppliers'
  const [activeCategory, setActiveCategory] = useState('products');
  const [currentWh, setCurrentWh] = useState(selectedWarehouse);

  // Time filters
  const [timePreset, setTimePreset] = useState('month'); // 'today' | 'week' | 'month' | 'custom'
  const [startDate, setStartDate] = useState(() => {
    const d = new Date();
    d.setDate(1);
    return d.toISOString().split('T')[0];
  });
  const [endDate, setEndDate] = useState(() => new Date().toISOString().split('T')[0]);

  // Sorting & Local search filter
  const [sortBy, setSortBy] = useState('export_amount_desc');
  const [searchTerm, setSearchTerm] = useState('');

  // Data state
  const [loading, setLoading] = useState(false);
  const [salesData, setSalesData] = useState({
    products: [],
    customers: [],
    suppliers: [],
    totals: {
      totalImportAmount: 0,
      totalExportAmount: 0,
      totalImportQty: 0,
      totalExportQty: 0,
    },
  });

  // Sync with selectedWarehouse prop from parent if changed
  useEffect(() => {
    if (selectedWarehouse) {
      setCurrentWh(selectedWarehouse);
    }
  }, [selectedWarehouse]);

  // Handle preset change
  const handlePresetChange = (preset) => {
    setTimePreset(preset);
    const now = new Date();
    if (preset === 'today') {
      const today = now.toISOString().split('T')[0];
      setStartDate(today);
      setEndDate(today);
    } else if (preset === 'week') {
      const dayOfWeek = now.getDay() || 7;
      const start = new Date(now);
      start.setDate(now.getDate() - dayOfWeek + 1);
      setStartDate(start.toISOString().split('T')[0]);
      setEndDate(now.toISOString().split('T')[0]);
    } else if (preset === 'month') {
      const start = new Date(now.getFullYear(), now.getMonth(), 1);
      setStartDate(start.toISOString().split('T')[0]);
      setEndDate(now.toISOString().split('T')[0]);
    }
  };

  // Fetch warehouse sales data
  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const res = await reportService.getWarehouseSales({
        warehouse: currentWh,
        startDate: startDate || undefined,
        endDate: endDate || undefined,
        sortBy,
      });

      if (res) {
        setSalesData({
          products: res.products || [],
          customers: res.customers || [],
          suppliers: res.suppliers || [],
          totals: res.totals || {
            totalImportAmount: 0,
            totalExportAmount: 0,
            totalImportQty: 0,
            totalExportQty: 0,
          },
        });
      }
    } catch (err) {
      notify.error(err.message || 'Không thể tải báo cáo doanh số kho');
    } finally {
      setLoading(false);
    }
  }, [currentWh, startDate, endDate, sortBy, notify]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Filtered lists based on search term
  const filteredProducts = useMemo(() => {
    if (!searchTerm.trim()) return salesData.products;
    const q = searchTerm.toLowerCase();
    return salesData.products.filter(
      (p) => (p.productName || '').toLowerCase().includes(q) || (p.sku || '').toLowerCase().includes(q)
    );
  }, [salesData.products, searchTerm]);

  const filteredCustomers = useMemo(() => {
    if (!searchTerm.trim()) return salesData.customers;
    const q = searchTerm.toLowerCase();
    return salesData.customers.filter(
      (c) => (c.customerName || '').toLowerCase().includes(q) || (c.customerCode || '').toLowerCase().includes(q) || (c.phone || '').includes(q)
    );
  }, [salesData.customers, searchTerm]);

  const filteredSuppliers = useMemo(() => {
    if (!searchTerm.trim()) return salesData.suppliers;
    const q = searchTerm.toLowerCase();
    return salesData.suppliers.filter(
      (s) => (s.supplierName || '').toLowerCase().includes(q) || (s.supplierCode || '').toLowerCase().includes(q) || (s.phone || '').includes(q)
    );
  }, [salesData.suppliers, searchTerm]);

  // Active warehouse name
  const whName = useMemo(() => {
    if (currentWh === 'overview' || !currentWh) return 'Tất cả kho hàng';
    const found = warehouses.find((w) => w.id === currentWh);
    return found ? found.name : currentWh;
  }, [currentWh, warehouses]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* Overview Stat Cards */}
      <div className="stat-grid">
        <StatCard
          icon={ArrowDownLeft}
          iconColor="#1d4ed8"
          title="Tổng tiền nhập kho"
          value={formatVND(salesData.totals.totalImportAmount)}
          subtitle={`Số lượng: ${formatNumber(salesData.totals.totalImportQty)}`}
        />
        <StatCard
          icon={ArrowUpRight}
          iconColor="#ea580c"
          title="Tổng doanh số xuất"
          value={formatVND(salesData.totals.totalExportAmount)}
          subtitle={`Số lượng: ${formatNumber(salesData.totals.totalExportQty)}`}
        />
        <StatCard
          icon={TrendingUp}
          iconColor={salesData.totals.totalExportAmount - salesData.totals.totalImportAmount >= 0 ? '#10b981' : '#ef4444'}
          title="Chênh lệch Xuất - Nhập"
          value={formatVND(salesData.totals.totalExportAmount - salesData.totals.totalImportAmount)}
          subtitle="Doanh số xuất trừ giá trị nhập"
        />
        <StatCard
          icon={Layers}
          iconColor="#8b5cf6"
          title="Kho đang xem"
          value={whName}
          subtitle={`Giai đoạn: ${formatDate(startDate)} - ${formatDate(endDate)}`}
        />
      </div>

      {/* Filter and Control Bar */}
      <div
        className="card"
        style={{
          padding: '1rem 1.25rem',
          display: 'flex',
          flexWrap: 'wrap',
          gap: '0.875rem',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem', alignItems: 'center' }}>
          {/* Warehouse Selector */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Kho:</span>
            <select
              className="form-control"
              style={{ width: 'auto', minWidth: '150px' }}
              value={currentWh}
              onChange={(e) => setCurrentWh(e.target.value)}
            >
              <option value="overview">Tất cả kho</option>
              {warehouses.map((w) => (
                <option key={w.id} value={w.id}>
                  {w.shortName || w.name}
                </option>
              ))}
            </select>
          </div>

          {/* Time Preset Buttons */}
          <div
            style={{
              display: 'inline-flex',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border-color)',
              overflow: 'hidden',
            }}
          >
            {[
              { id: 'today', label: 'Hôm nay' },
              { id: 'week', label: 'Tuần này' },
              { id: 'month', label: 'Tháng này' },
              { id: 'custom', label: 'Tùy chọn' },
            ].map((p) => (
              <button
                key={p.id}
                type="button"
                onClick={() => handlePresetChange(p.id)}
                style={{
                  padding: '0.45rem 0.75rem',
                  fontSize: '0.8125rem',
                  fontWeight: timePreset === p.id ? 700 : 500,
                  border: 'none',
                  borderRight: '1px solid var(--border-color)',
                  background: timePreset === p.id ? 'var(--primary)' : 'var(--bg-secondary)',
                  color: timePreset === p.id ? '#ffffff' : 'var(--text-primary)',
                  cursor: 'pointer',
                  transition: 'background 0.15s ease',
                }}
              >
                {p.label}
              </button>
            ))}
          </div>

          {/* Custom Date Pickers */}
          {timePreset === 'custom' && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
              <input
                type="date"
                className="form-control"
                style={{ width: '135px', padding: '0.35rem 0.5rem', fontSize: '0.8125rem' }}
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
              <span style={{ color: 'var(--text-muted)' }}>→</span>
              <input
                type="date"
                className="form-control"
                style={{ width: '135px', padding: '0.35rem 0.5rem', fontSize: '0.8125rem' }}
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
              />
            </div>
          )}

          {/* Sorting Dropdown */}
          <div style={{ width: '230px' }}>
            <SortDropdown
              options={SALES_SORT_OPTIONS}
              value={sortBy}
              onChange={(val) => setSortBy(val)}
            />
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flex: 1, justifyContent: 'flex-end', minWidth: '220px' }}>
          <div style={{ width: '220px' }}>
            <SearchBar
              value={searchTerm}
              onChange={(v) => setSearchTerm(v)}
              placeholder="Lọc tên, mã..."
            />
          </div>
          <button className="btn btn-outline" onClick={loadData} disabled={loading} title="Tải lại số liệu">
            <RefreshCw size={15} className={loading ? 'animate-spin' : ''} />
          </button>
        </div>
      </div>

      {/* Subtabs for SP / KH / NCC */}
      <div
        style={{
          display: 'flex',
          borderBottom: '2px solid var(--border-color)',
          gap: '0.5rem',
        }}
      >
        <button
          className="btn"
          onClick={() => setActiveCategory('products')}
          style={{
            padding: '0.65rem 1.25rem',
            border: 'none',
            borderRadius: 'var(--radius-sm) var(--radius-sm) 0 0',
            fontWeight: activeCategory === 'products' ? 700 : 500,
            background: activeCategory === 'products' ? 'var(--primary)' : 'transparent',
            color: activeCategory === 'products' ? '#ffffff' : 'var(--text-secondary)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
          }}
        >
          <Package size={16} />
          <span>Doanh số Sản Phẩm ({filteredProducts.length})</span>
        </button>

        <button
          className="btn"
          onClick={() => setActiveCategory('customers')}
          style={{
            padding: '0.65rem 1.25rem',
            border: 'none',
            borderRadius: 'var(--radius-sm) var(--radius-sm) 0 0',
            fontWeight: activeCategory === 'customers' ? 700 : 500,
            background: activeCategory === 'customers' ? 'var(--primary)' : 'transparent',
            color: activeCategory === 'customers' ? '#ffffff' : 'var(--text-secondary)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
          }}
        >
          <Users size={16} />
          <span>Doanh số Khách Hàng ({filteredCustomers.length})</span>
        </button>

        <button
          className="btn"
          onClick={() => setActiveCategory('suppliers')}
          style={{
            padding: '0.65rem 1.25rem',
            border: 'none',
            borderRadius: 'var(--radius-sm) var(--radius-sm) 0 0',
            fontWeight: activeCategory === 'suppliers' ? 700 : 500,
            background: activeCategory === 'suppliers' ? 'var(--primary)' : 'transparent',
            color: activeCategory === 'suppliers' ? '#ffffff' : 'var(--text-secondary)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
          }}
        >
          <Building size={16} />
          <span>Doanh số Nhà Cung Cấp ({filteredSuppliers.length})</span>
        </button>
      </div>

      {/* SUBTAB 1: DOANH SỐ SẢN PHẨM */}
      {activeCategory === 'products' && (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {filteredProducts.length === 0 && !loading ? (
            <EmptyState
              icon={Package}
              title="Không có dữ liệu doanh số sản phẩm"
              description={`Chưa có phát sinh nhập/xuất cho các sản phẩm trong giai đoạn ${formatDate(startDate)} đến ${formatDate(endDate)}.`}
            />
          ) : (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '45px', textAlign: 'center' }}>STT</th>
                    <th>Mã SKU</th>
                    <th>Tên Sản Phẩm</th>
                    <th style={{ textAlign: 'center' }}>ĐVT</th>
                    <th style={{ textAlign: 'right', color: '#1d4ed8' }}>SL Nhập</th>
                    <th style={{ textAlign: 'right', color: '#1d4ed8' }}>Tiền Nhập</th>
                    <th style={{ textAlign: 'right', color: '#ea580c' }}>SL Xuất</th>
                    <th style={{ textAlign: 'right', color: '#ea580c' }}>Tiền Xuất</th>
                    <th style={{ textAlign: 'right' }}>Chênh Lệch</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredProducts.map((p, idx) => {
                    const diff = Number(p.exportAmount || 0) - Number(p.importAmount || 0);
                    return (
                      <tr key={p.productId}>
                        <td style={{ textAlign: 'center', color: 'var(--text-muted)' }}>{idx + 1}</td>
                        <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                          {p.sku}
                        </td>
                        <td style={{ fontWeight: 600 }}>{p.productName}</td>
                        <td style={{ textAlign: 'center', color: 'var(--text-secondary)' }}>
                          {p.uom || 'Cái'}
                        </td>
                        <td style={{ textAlign: 'right' }} className="mono">
                          {formatNumber(p.importQty || 0)}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 600, color: '#1d4ed8' }} className="mono">
                          {formatVND(p.importAmount || 0)}
                        </td>
                        <td style={{ textAlign: 'right' }} className="mono">
                          {formatNumber(p.exportQty || 0)}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 600, color: '#ea580c' }} className="mono">
                          {formatVND(p.exportAmount || 0)}
                        </td>
                        <td
                          style={{
                            textAlign: 'right',
                            fontWeight: 700,
                            color: diff >= 0 ? 'var(--success)' : 'var(--danger)',
                          }}
                          className="mono"
                        >
                          {formatVND(diff)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
                <tfoot>
                  <tr style={{ background: 'var(--bg-secondary)', fontWeight: 800 }}>
                    <td colSpan={4} style={{ textAlign: 'center' }}>
                      TỔNG CỘNG ({filteredProducts.length} mặt hàng)
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(filteredProducts.reduce((s, p) => s + Number(p.importQty || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right', color: '#1d4ed8' }} className="mono">
                      {formatVND(filteredProducts.reduce((s, p) => s + Number(p.importAmount || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(filteredProducts.reduce((s, p) => s + Number(p.exportQty || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right', color: '#ea580c' }} className="mono">
                      {formatVND(filteredProducts.reduce((s, p) => s + Number(p.exportAmount || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(
                        filteredProducts.reduce(
                          (s, p) => s + (Number(p.exportAmount || 0) - Number(p.importAmount || 0)),
                          0
                        )
                      )}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          )}
        </div>
      )}

      {/* SUBTAB 2: DOANH SỐ KHÁCH HÀNG */}
      {activeCategory === 'customers' && (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {filteredCustomers.length === 0 && !loading ? (
            <EmptyState
              icon={Users}
              title="Không có dữ liệu doanh số khách hàng"
              description={`Chưa có phát sinh xuất/nhập hàng với khách hàng trong giai đoạn ${formatDate(startDate)} đến ${formatDate(endDate)}.`}
            />
          ) : (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '45px', textAlign: 'center' }}>STT</th>
                    <th>Mã KH</th>
                    <th>Tên Khách Hàng</th>
                    <th>Số Điện Thoại</th>
                    <th>Khu Vực</th>
                    <th style={{ textAlign: 'right', color: '#ea580c' }}>SL Xuất</th>
                    <th style={{ textAlign: 'right', color: '#ea580c' }}>Doanh Số Xuất</th>
                    <th style={{ textAlign: 'right', color: '#1d4ed8' }}>SL Nhập (Trả)</th>
                    <th style={{ textAlign: 'right', color: '#1d4ed8' }}>Tiền Nhập (Trả)</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredCustomers.map((c, idx) => (
                    <tr key={c.customerId}>
                      <td style={{ textAlign: 'center', color: 'var(--text-muted)' }}>{idx + 1}</td>
                      <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                        {c.customerCode}
                      </td>
                      <td style={{ fontWeight: 600 }}>{c.customerName}</td>
                      <td className="mono">{c.phone || '-'}</td>
                      <td>
                        <span className="badge badge-subtle">{c.region || 'Chưa phân vùng'}</span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatNumber(c.exportQty || 0)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 700, color: '#ea580c' }} className="mono">
                        {formatVND(c.exportAmount || 0)}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatNumber(c.importQty || 0)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 600, color: '#1d4ed8' }} className="mono">
                        {formatVND(c.importAmount || 0)}
                      </td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr style={{ background: 'var(--bg-secondary)', fontWeight: 800 }}>
                    <td colSpan={5} style={{ textAlign: 'center' }}>
                      TỔNG CỘNG ({filteredCustomers.length} khách hàng)
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(filteredCustomers.reduce((s, c) => s + Number(c.exportQty || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right', color: '#ea580c' }} className="mono">
                      {formatVND(filteredCustomers.reduce((s, c) => s + Number(c.exportAmount || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(filteredCustomers.reduce((s, c) => s + Number(c.importQty || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right', color: '#1d4ed8' }} className="mono">
                      {formatVND(filteredCustomers.reduce((s, c) => s + Number(c.importAmount || 0), 0))}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          )}
        </div>
      )}

      {/* SUBTAB 3: DOANH SỐ NHÀ CUNG CẤP */}
      {activeCategory === 'suppliers' && (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {filteredSuppliers.length === 0 && !loading ? (
            <EmptyState
              icon={Building}
              title="Không có dữ liệu doanh số nhà cung cấp"
              description={`Chưa có phát sinh nhập/xuất hàng với nhà cung ứng trong giai đoạn ${formatDate(startDate)} đến ${formatDate(endDate)}.`}
            />
          ) : (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '45px', textAlign: 'center' }}>STT</th>
                    <th>Mã NCC</th>
                    <th>Tên Nhà Cung Cấp</th>
                    <th>Số Điện Thoại</th>
                    <th style={{ textAlign: 'right', color: '#1d4ed8' }}>SL Nhập</th>
                    <th style={{ textAlign: 'right', color: '#1d4ed8' }}>Doanh Số Nhập</th>
                    <th style={{ textAlign: 'right', color: '#ea580c' }}>SL Xuất (Trả)</th>
                    <th style={{ textAlign: 'right', color: '#ea580c' }}>Tiền Xuất (Trả)</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredSuppliers.map((s, idx) => (
                    <tr key={s.supplierId}>
                      <td style={{ textAlign: 'center', color: 'var(--text-muted)' }}>{idx + 1}</td>
                      <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                        {s.supplierCode}
                      </td>
                      <td style={{ fontWeight: 600 }}>{s.supplierName}</td>
                      <td className="mono">{s.phone || '-'}</td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatNumber(s.importQty || 0)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 700, color: '#1d4ed8' }} className="mono">
                        {formatVND(s.importAmount || 0)}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatNumber(s.exportQty || 0)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 600, color: '#ea580c' }} className="mono">
                        {formatVND(s.exportAmount || 0)}
                      </td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr style={{ background: 'var(--bg-secondary)', fontWeight: 800 }}>
                    <td colSpan={4} style={{ textAlign: 'center' }}>
                      TỔNG CỘNG ({filteredSuppliers.length} nhà cung cấp)
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(filteredSuppliers.reduce((sum, s) => sum + Number(s.importQty || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right', color: '#1d4ed8' }} className="mono">
                      {formatVND(filteredSuppliers.reduce((sum, s) => sum + Number(s.importAmount || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(filteredSuppliers.reduce((sum, s) => sum + Number(s.exportQty || 0), 0))}
                    </td>
                    <td style={{ textAlign: 'right', color: '#ea580c' }} className="mono">
                      {formatVND(filteredSuppliers.reduce((sum, s) => sum + Number(s.exportAmount || 0), 0))}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

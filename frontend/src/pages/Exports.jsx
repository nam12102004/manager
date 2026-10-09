import React, { useState, useEffect } from 'react';
import {
  ArrowUpRight,
  Plus,
  Eye,
  XCircle,
  Printer,
  Trash2,
  Calendar,
  Search,
  RefreshCw,
  Building,
  CheckCircle,
  AlertCircle,
  Package,
  Filter,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr, getCurrentDateStr } from '../utils/formatters';
import { WAREHOUSES, WAREHOUSE_MAP } from '../utils/constants';
import { useNotification } from '../context/NotificationContext';
import Modal from '../components/common/Modal';
import ConfirmModal from '../components/common/ConfirmModal';
import EmptyState from '../components/common/EmptyState';
import SearchableSelect from '../components/common/SearchableSelect';
import TimeFilter from '../components/common/TimeFilter';
import { exportService, warehouseService } from '../services';
import { generateExportHtml, printInNewTab } from '../utils/printVoucher';

export default function Exports({ initialOpenCreate = false }) {
  const notify = useNotification();

  const [exportsList, setExportsList] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [products, setProducts] = useState([]);
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [ownerInfo, setOwnerInfo] = useState(null);
  const [loading, setLoading] = useState(false);

  // Time & Customer Filters
  const [selectedCustomerId, setSelectedCustomerId] = useState('');
  const [timeMode, setTimeMode] = useState('month'); // 'month' | 'day' | 'range' | 'all'
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonthStr());
  const [selectedDate, setSelectedDate] = useState(getCurrentDateStr());
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(initialOpenCreate);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isCancelConfirmOpen, setIsCancelConfirmOpen] = useState(false);

  const [selectedExport, setSelectedExport] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Helper to get stock of product for specific warehouse
  const getProductStockForWarehouse = (p, whId) => {
    if (!p) return 0;
    if (whId === 'warehouse1') return Number(p.stockWarehouse1 || 0);
    if (whId === 'warehouse2') return Number(p.stockWarehouse2 || 0);
    if (whId === 'warehouse3') return Number(p.stockWarehouse3 || 0);
    return Number(p.totalStock ?? ((p.stockWarehouse1 || 0) + (p.stockWarehouse2 || 0) + (p.stockWarehouse3 || 0)));
  };

  // Create Form State
  const [createForm, setCreateForm] = useState({
    customerId: '',
    warehouse: 'warehouse1',
    date: new Date().toISOString().slice(0, 10),
    discountType: 'amount', // 'percent' | 'amount'
    discountValue: 0,
    paidAmount: 0,
    notes: '',
    items: [],
  });

  // Load Exports via exportService
  const loadExports = async () => {
    setLoading(true);
    try {
      const params = {
        customerId: selectedCustomerId ? Number(selectedCustomerId) : null,
      };

      if (timeMode === 'month') {
        params.month = selectedMonth;
      } else if (timeMode === 'day') {
        params.date = selectedDate;
      } else if (timeMode === 'range') {
        params.fromDate = fromDate;
        params.toDate = toDate;
      }

      const data = await exportService.getAll(params);
      setExportsList(data || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách phiếu xuất');
    } finally {
      setLoading(false);
    }
  };

  // Load Customers & Products & Owner via exportService
  const loadDependencies = async () => {
    try {
      const [{ customers: custs, products: prods, ownerInfo: owner }, whList] = await Promise.all([
        exportService.getDependencies(),
        warehouseService.getWarehouses(),
      ]);
      setCustomers(custs || []);
      setProducts(prods || []);
      setOwnerInfo(owner || null);
      if (whList && Array.isArray(whList)) setWarehouses(whList);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    loadExports();
  }, [selectedCustomerId, timeMode, selectedMonth, selectedDate, fromDate, toDate]);

  useEffect(() => {
    loadDependencies();
  }, []);

  // Open Create
  const handleOpenCreate = () => {
    loadDependencies();
    setCreateForm({
      customerId: customers.length > 0 ? String(customers[0].id) : '',
      warehouse: 'warehouse1',
      date: new Date().toISOString().slice(0, 10),
      discountType: 'amount',
      discountValue: 0,
      paidAmount: 0,
      notes: '',
      items: [
        {
          productId: products.length > 0 ? products[0].id : '',
          quantity: 1,
          salePrice: products.length > 0 ? (products[0].retailPrice || products[0].salePrice || 0) : 0,
        },
      ],
    });
    setIsCreateOpen(true);
  };

  // Add Item Row
  const handleAddItem = () => {
    if (products.length === 0) return;
    setCreateForm((prev) => ({
      ...prev,
      items: [
        ...prev.items,
        {
          productId: products[0].id,
          quantity: 1,
          salePrice: products[0].retailPrice,
        },
      ],
    }));
  };

  // Remove Item Row
  const handleRemoveItem = (index) => {
    setCreateForm((prev) => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index),
    }));
  };

  // Update Item Row
  const handleUpdateItem = (index, field, value) => {
    setCreateForm((prev) => {
      const newItems = [...prev.items];
      const item = { ...newItems[index] };

      if (field === 'productId') {
        const prod = products.find((p) => p.id === Number(value));
        item.productId = Number(value);
        if (prod) {
          item.salePrice = prod.retailPrice;
        }
      } else {
        item[field] = Number(value);
      }

      newItems[index] = item;
      return { ...prev, items: newItems };
    });
  };

  // Financial calculations for creation
  // Calculate Totals via exportService
  const { subtotal, discountAmount, totalSale, unpaidAmount } = exportService.calculateExportTotals({
    items: createForm.items,
    discountType: createForm.discountType,
    discountValue: createForm.discountValue,
    paidAmount: createForm.paidAmount,
  });

  const selectedCustomerObj = customers.find((c) => c.id === Number(createForm.customerId));
  const currentCustDebt = Number(selectedCustomerObj?.debt || 0);
  const projectedCustDebt = currentCustDebt + unpaidAmount;

  // Submit Create Export via exportService
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const result = await exportService.create(createForm, products);
      notify.success(`Tạo phiếu xuất ${result.voucherNumber} thành công!`);
      setIsCreateOpen(false);
      loadExports();
      loadDependencies(); // refresh product stocks and customer debts
    } catch (err) {
      notify.error(err.message || 'Lỗi khi tạo phiếu xuất');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Details via exportService
  const handleOpenDetail = async (item) => {
    try {
      const full = await exportService.getById(item.id);
      setSelectedExport(full || item);
    } catch {
      setSelectedExport(item);
    }
    setIsDetailOpen(true);
  };

  // Open Cancel Confirm
  const handleOpenCancel = (item) => {
    setSelectedExport(item);
    setIsCancelConfirmOpen(true);
  };

  // Confirm Cancel Export via exportService
  const handleConfirmCancel = async () => {
    if (!selectedExport) return;
    setSubmitting(true);
    try {
      await exportService.updateStatus(selectedExport.id, 'cancel');
      notify.success(`Đã hủy phiếu xuất ${selectedExport.voucherNumber}`);
      setIsCancelConfirmOpen(false);
      loadExports();
      loadDependencies();
    } catch (err) {
      notify.error(err.message || 'Không thể hủy phiếu xuất');
    } finally {
      setSubmitting(false);
    }
  };

  const handlePrint = (item = null) => {
    const target = item || selectedExport;
    if (!target) return;
    const cust = customers.find((c) => c.id === target.customerId || c.name === target.customerName);
    const html = generateExportHtml({ exportData: target, ownerInfo, customer: cust });
    printInNewTab(html);
  };

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <ArrowUpRight size={28} color="var(--primary)" />
            <span>Xuất Kho</span>
          </h1>
          <p className="page-subtitle">
            Lập phiếu xuất hàng, trừ tồn kho đa điểm và ghi nhận công nợ khách hàng
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadExports} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Lập phiếu xuất mới</span>
          </button>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="filter-bar">
        <div style={{ minWidth: '260px' }}>
          <SearchableSelect
            options={customers.map((c) => ({
              id: c.id,
              value: c.id,
              label: c.name,
              code: c.code,
              phone: c.phone || '',
              subLabel: c.phone ? `SĐT: ${c.phone}` : '',
            }))}
            value={selectedCustomerId}
            onChange={(val) => setSelectedCustomerId(val)}
            placeholder="-- Tất cả khách hàng --"
            searchPlaceholder="Tìm theo tên, mã KH, SĐT..."
            searchFields={['label', 'code', 'phone']}
          />
        </div>

        <TimeFilter
          mode={timeMode}
          onModeChange={setTimeMode}
          month={selectedMonth}
          onMonthChange={setSelectedMonth}
          date={selectedDate}
          onDateChange={setSelectedDate}
          fromDate={fromDate}
          onFromDateChange={setFromDate}
          toDate={toDate}
          onToDateChange={setToDate}
        />
      </div>

      {/* Exports Table */}
      {exportsList.length === 0 && !loading ? (
        <EmptyState
          icon={ArrowUpRight}
          title="Không tìm thấy phiếu xuất nào"
          description={
            timeMode === 'day'
              ? `Chưa có phiếu xuất bán nào trong ngày ${selectedDate || ''} hoặc theo khách hàng đã chọn.`
              : timeMode === 'month'
              ? `Chưa có phiếu xuất bán nào trong tháng ${selectedMonth || ''} hoặc theo khách hàng đã chọn.`
              : 'Chưa có phiếu xuất bán nào phù hợp với điều kiện lọc.'
          }
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>Tạo phiếu xuất đầu tiên</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Số Phiếu</th>
                <th>Thời Gian Lập</th>
                <th>Khách Hàng</th>
                <th>Kho Xuất</th>
                <th style={{ textAlign: 'right' }}>Tiền Hàng</th>
                <th style={{ textAlign: 'right' }}>Chiết Khấu</th>
                <th style={{ textAlign: 'right' }}>Tổng Tiền</th>
                <th style={{ textAlign: 'right' }}>Đã Trả</th>
                <th style={{ textAlign: 'right' }}>Còn Nợ</th>
                <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {exportsList.map((exp) => (
                <tr key={exp.id}>
                  <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                    {exp.voucherNumber}
                  </td>
                  <td style={{ fontSize: '0.8125rem' }}>{formatDate(exp.createdAt || exp.date, true)}</td>
                  <td style={{ fontWeight: 600 }}>{exp.customerName}</td>
                  <td>
                    <span className="badge badge-neutral">{WAREHOUSE_MAP[exp.warehouse] || exp.warehouse}</span>
                  </td>
                  <td style={{ textAlign: 'right' }} className="mono">
                    {formatVND(exp.subtotalSale)}
                  </td>
                  <td style={{ textAlign: 'right' }} className="mono">
                    {formatVND(exp.discountAmount)}
                  </td>
                  <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                    {formatVND(exp.totalSale)}
                  </td>
                  <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                    {formatVND(exp.paidAmount)}
                  </td>
                  <td style={{ textAlign: 'right', color: exp.unpaidAmount > 0 ? 'var(--danger)' : 'var(--text-muted)' }} className="mono">
                    {formatVND(exp.unpaidAmount)}
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <span className={`badge badge-${exp.status === 'cancelled' ? 'danger' : 'success'}`}>
                      {exp.status === 'cancelled' ? 'Đã hủy' : 'Hoạt động'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                      <button
                        className="btn btn-outline btn-icon"
                        style={{ width: '32px', height: '32px' }}
                        title="Xem chi tiết"
                        onClick={() => handleOpenDetail(exp)}
                      >
                        <Eye size={15} />
                      </button>
                      <button
                        className="btn btn-outline btn-icon"
                        style={{ width: '32px', height: '32px' }}
                        title="In phiếu xuất kho (Tab mới)"
                        onClick={() => handlePrint(exp)}
                      >
                        <Printer size={15} />
                      </button>
                      {exp.status !== 'cancelled' && (
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--danger)' }}
                          title="Hủy phiếu xuất này"
                          onClick={() => handleOpenCancel(exp)}
                        >
                          <XCircle size={15} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal Lập Phiếu Xuất Mới (POS / Sales Invoice) */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Lập Phiếu Xuất Kho"
        size="xl"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Đóng
            </button>
            <button className="btn btn-primary" onClick={handleCreateSubmit} disabled={submitting}>
              {submitting ? 'Đang tạo phiếu...' : 'Hoàn tất & Xuất kho'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          {/* Top Row: Khách hàng, Kho, Ngày */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">
                Khách Hàng <span className="req">*</span>
              </label>
              <SearchableSelect
                options={customers.map((c) => ({
                  id: c.id,
                  value: c.id,
                  label: c.name,
                  code: c.code,
                  phone: c.phone || '',
                  debt: c.debt || 0,
                  subLabel: `Dư nợ: ${formatVND(c.debt)}`,
                }))}
                value={createForm.customerId}
                onChange={(val) => setCreateForm({ ...createForm, customerId: val })}
                placeholder="-- Chọn khách hàng --"
                searchPlaceholder="Tìm theo tên, mã KH, SĐT..."
                searchFields={['label', 'code', 'phone']}
                required
              />
              {selectedCustomerObj && (
                <div style={{ fontSize: '0.75rem', marginTop: '4px', color: 'var(--text-secondary)' }}>
                  Nợ hiện tại: <strong>{formatVND(selectedCustomerObj.debt)}</strong>
                </div>
              )}
            </div>

            <div className="form-group">
              <label className="form-label">
                Kho Xuất Hàng <span className="req">*</span>
              </label>
              <select
                className="form-select"
                value={createForm.warehouse}
                onChange={(e) => setCreateForm({ ...createForm, warehouse: e.target.value })}
                required
              >
                {warehouses.map((wh) => (
                  <option key={wh.id} value={wh.id}>
                    {wh.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Ngày Lập Phiếu</label>
              <input
                type="date"
                className="form-input mono"
                value={createForm.date}
                onChange={(e) => setCreateForm({ ...createForm, date: e.target.value })}
              />
            </div>
          </div>

          {/* Items Section */}
          <div style={{ marginBottom: '1.5rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
              <h4 style={{ fontSize: '0.9375rem', fontWeight: 700 }}>Danh Sách Mặt Hàng Xuất</h4>
              <button type="button" className="btn btn-outline btn-sm" onClick={handleAddItem}>
                <Plus size={14} />
                <span>Thêm dòng sản phẩm</span>
              </button>
            </div>

            <div className="table-responsive" style={{ overflow: 'visible' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '40%' }}>Sản Phẩm</th>
                    <th style={{ width: '15%', textAlign: 'center' }}>Tồn Tại Kho</th>
                    <th style={{ width: '15%', textAlign: 'right' }}>Số Lượng</th>
                    <th style={{ width: '20%', textAlign: 'right' }}>Đơn Giá Bán</th>
                    <th style={{ width: '15%', textAlign: 'right' }}>Thành Tiền</th>
                    <th style={{ width: '5%', textAlign: 'center' }}>Xóa</th>
                  </tr>
                </thead>
                <tbody>
                  {createForm.items.map((item, idx) => {
                    const prod = products.find((p) => p.id === Number(item.productId));
                    const currentWhStock = getProductStockForWarehouse(prod, createForm.warehouse);

                    const lineTotal = Number(item.quantity || 0) * Number(item.salePrice || 0);
                    const isOutOfStock = currentWhStock < Number(item.quantity || 0);

                    return (
                      <tr key={idx}>
                        <td>
                          <SearchableSelect
                            options={products.map((p) => {
                              const whStock = getProductStockForWarehouse(p, createForm.warehouse);
                              const total = Number(p.totalStock ?? ((p.stockWarehouse1 || 0) + (p.stockWarehouse2 || 0) + (p.stockWarehouse3 || 0)));
                              const targetWh = warehouses.find((w) => w.id === createForm.warehouse);
                              const whLabel = targetWh?.shortName || targetWh?.name || 'kho này';
                              return {
                                id: p.id,
                                value: p.id,
                                label: p.name,
                                code: p.sku || p.code,
                                uom: p.uom || 'ĐVT',
                                subLabel: `Tồn ${whLabel}: ${formatNumber(whStock)} (Tổng: ${formatNumber(total)}) | Giá bán: ${formatVND(p.retailPrice || p.salePrice || 0)}`,
                              };
                            })}
                            value={item.productId}
                            onChange={(val) => handleUpdateItem(idx, 'productId', val)}
                            placeholder="-- Chọn sản phẩm --"
                            searchPlaceholder="Tìm theo mã SKU, tên SP..."
                            searchFields={['label', 'code']}
                          />
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span className={`badge badge-${isOutOfStock ? 'danger' : 'neutral'} mono`}>
                            {formatNumber(currentWhStock)} {prod?.uom || ''}
                          </span>
                        </td>
                        <td>
                          <input
                            type="number"
                            min="0.001"
                            step="any"
                            className="form-input mono"
                            style={{ textAlign: 'right' }}
                            value={item.quantity}
                            onChange={(e) => handleUpdateItem(idx, 'quantity', e.target.value)}
                            required
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            min="0"
                            step="any"
                            className="form-input mono"
                            style={{ textAlign: 'right' }}
                            value={item.salePrice}
                            onChange={(e) => handleUpdateItem(idx, 'salePrice', e.target.value)}
                            required
                          />
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                          {formatVND(lineTotal)}
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <button
                            type="button"
                            className="btn btn-ghost btn-icon"
                            style={{ width: '28px', height: '28px', color: 'var(--danger)' }}
                            onClick={() => handleRemoveItem(idx)}
                            disabled={createForm.items.length <= 1}
                          >
                            <Trash2 size={15} />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* Financial Calculation Panel */}
          <div
            style={{
              background: 'var(--bg-tertiary)',
              padding: '1.25rem',
              borderRadius: 'var(--radius-lg)',
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
              gap: '1.25rem',
            }}
          >
            {/* Left: Notes & Discount selector */}
            <div>
              <div className="form-group">
                <label className="form-label">Chiết Khấu Đơn Hàng</label>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <select
                    className="form-select"
                    style={{ width: '130px' }}
                    value={createForm.discountType}
                    onChange={(e) => setCreateForm({ ...createForm, discountType: e.target.value })}
                  >
                    <option value="amount">Tiền mặt</option>
                    <option value="percent">Phần trăm</option>
                  </select>
                  <input
                    type="number"
                    min="0"
                    step="any"
                    className="form-input mono"
                    value={createForm.discountValue}
                    onChange={(e) => setCreateForm({ ...createForm, discountValue: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Ghi Chú Phiếu Xuất</label>
                <textarea
                  className="form-textarea"
                  rows={2}
                  placeholder="Ghi chú giao hàng, điều kiện thanh toán..."
                  value={createForm.notes}
                  onChange={(e) => setCreateForm({ ...createForm, notes: e.target.value })}
                />
              </div>
            </div>

            {/* Right: Summary numbers */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.625rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Tiền hàng tạm tính:</span>
                <span className="mono" style={{ fontWeight: 600 }}>{formatVND(subtotal)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Số tiền chiết khấu:</span>
                <span className="mono" style={{ color: 'var(--danger)' }}>-{formatVND(discountAmount)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.0625rem', fontWeight: 800 }}>
                <span>Tổng phải thanh toán:</span>
                <span className="mono" style={{ color: 'var(--primary)' }}>{formatVND(totalSale)}</span>
              </div>

              <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '0.25rem 0' }} />

              <div className="form-group" style={{ marginBottom: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                  <label className="form-label" style={{ marginBottom: 0 }}>
                    Khách Thanh Toán Ngay:
                  </label>
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    style={{ padding: '0 0.5rem', fontSize: '0.75rem' }}
                    onClick={() => setCreateForm({ ...createForm, paidAmount: totalSale })}
                  >
                    Trả đủ 100%
                  </button>
                </div>
                <input
                  type="number"
                  min="0"
                  step="any"
                  className="form-input mono"
                  style={{ textAlign: 'right', fontWeight: 700, fontSize: '1.0625rem' }}
                  value={createForm.paidAmount}
                  onChange={(e) => setCreateForm({ ...createForm, paidAmount: e.target.value })}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', fontWeight: 700 }}>
                <span style={{ color: unpaidAmount > 0 ? 'var(--danger)' : 'var(--success)' }}>
                  {unpaidAmount > 0 ? 'Ghi nợ vào sổ khách:' : 'Thanh toán hoàn tất:'}
                </span>
                <span className="mono" style={{ color: unpaidAmount > 0 ? 'var(--danger)' : 'var(--success)' }}>
                  {formatVND(unpaidAmount)}
                </span>
              </div>

              {unpaidAmount > 0 && selectedCustomerObj && (
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textAlign: 'right' }}>
                  Dư nợ mới dự kiến của khách: {formatVND(projectedCustDebt)}
                </div>
              )}
            </div>
          </div>
        </form>
      </Modal>

      {/* Modal Chi Tiết & In Phiếu Xuất Bán Hàng */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title={`Chi Tiết Phiếu Xuất: ${selectedExport?.voucherNumber || ''}`}
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => handlePrint(selectedExport)}>
              <Printer size={16} />
              <span>In Phiếu Xuất Kho</span>
            </button>
            <button className="btn btn-primary" onClick={() => setIsDetailOpen(false)}>
              Đóng
            </button>
          </>
        }
      >
        {selectedExport && (
          <div id="print-section" style={{ padding: '0.5rem' }}>
            {/* Header info */}
            <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '2px solid var(--border-color)', paddingBottom: '1rem', marginBottom: '1.25rem' }}>
              <div>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{ownerInfo?.info || 'CỬA HÀNG / KHO HÀNG'}</h3>
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>HÓA ĐƠN BÁN HÀNG KIÊM PHIẾU XUẤT KHO</p>
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>Mã phiếu: <strong>{selectedExport.voucherNumber}</strong></p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '0.8125rem' }}>Thời gian lập: <strong>{formatDate(selectedExport.createdAt || selectedExport.date, true)}</strong></p>
                <p style={{ fontSize: '0.8125rem' }}>Kho xuất: <strong>{WAREHOUSE_MAP[selectedExport.warehouse] || selectedExport.warehouse}</strong></p>
                <span className={`badge badge-${selectedExport.status === 'cancelled' ? 'danger' : 'success'}`}>
                  {selectedExport.status === 'cancelled' ? 'Đã hủy' : 'Hoạt động'}
                </span>
              </div>
            </div>

            {/* Customer Info */}
            <div style={{ marginBottom: '1.25rem', background: 'var(--bg-tertiary)', padding: '0.875rem 1rem', borderRadius: 'var(--radius-md)' }}>
              <p style={{ fontSize: '0.875rem' }}>
                Khách hàng: <strong>{selectedExport.customerName}</strong>
              </p>
              {selectedExport.notes && (
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  Ghi chú: {selectedExport.notes}
                </p>
              )}
            </div>

            {/* Item Table */}
            <div className="table-responsive" style={{ marginBottom: '1.25rem' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>STT</th>
                    <th>Tên Hàng Hóa</th>
                    <th style={{ textAlign: 'right' }}>Số Lượng</th>
                    <th style={{ textAlign: 'right' }}>Đơn Giá</th>
                    <th style={{ textAlign: 'right' }}>Thành Tiền</th>
                  </tr>
                </thead>
                <tbody>
                  {(selectedExport.items || []).map((it, idx) => (
                    <tr key={it.id || idx}>
                      <td style={{ textAlign: 'center' }}>{idx + 1}</td>
                      <td>
                        <strong>{it.productName || it.sku}</strong>
                        {it.sku && <span className="mono" style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginLeft: '6px' }}>({it.sku})</span>}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatNumber(it.quantity)}</td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatVND(it.salePrice)}</td>
                      <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">{formatVND(it.lineTotal)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Financial Summary */}
            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <div style={{ width: '320px', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span>Tiền hàng:</span>
                  <span className="mono">{formatVND(selectedExport.subtotalSale)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span>Chiết khấu:</span>
                  <span className="mono">-{formatVND(selectedExport.discountAmount)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1rem', fontWeight: 800 }}>
                  <span>Tổng tiền thanh toán:</span>
                  <span className="mono" style={{ color: 'var(--primary)' }}>{formatVND(selectedExport.totalSale)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', color: 'var(--success)' }}>
                  <span>Khách đã trả:</span>
                  <span className="mono">{formatVND(selectedExport.paidAmount)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', fontWeight: 700, color: selectedExport.unpaidAmount > 0 ? 'var(--danger)' : 'var(--text-muted)' }}>
                  <span>Còn nợ lại:</span>
                  <span className="mono">{formatVND(selectedExport.unpaidAmount)}</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </Modal>

      {/* Confirm Cancel Modal */}
      <ConfirmModal
        isOpen={isCancelConfirmOpen}
        onClose={() => setIsCancelConfirmOpen(false)}
        onConfirm={handleConfirmCancel}
        title="Xác nhận hủy phiếu xuất"
        message={`Bạn có chắc chắn muốn hủy phiếu xuất "${selectedExport?.voucherNumber}"? Tồn kho các sản phẩm sẽ được hoàn lại và công nợ khách hàng sẽ được trừ khoản nợ chưa thanh toán.`}
        confirmText="Hủy phiếu này"
        isDanger={true}
        isLoading={submitting}
      />
    </div>
  );
}

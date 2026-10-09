import React, { useState, useEffect } from 'react';
import {
  ArrowDownLeft,
  Plus,
  Eye,
  XCircle,
  Calendar,
  Search,
  RefreshCw,
  Building,
  Trash2,
  Printer,
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
import { importService, warehouseService } from '../services';
import { generateImportHtml, printInNewTab } from '../utils/printVoucher';

export default function Imports({ initialOpenCreate = false }) {
  const notify = useNotification();

  const [importsList, setImportsList] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [products, setProducts] = useState([]);
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [ownerInfo, setOwnerInfo] = useState(null);
  const [loading, setLoading] = useState(false);

  // Filters
  const [selectedSupplierId, setSelectedSupplierId] = useState('');
  const [timeMode, setTimeMode] = useState('month'); // 'month' | 'day' | 'range' | 'all'
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonthStr());
  const [selectedDate, setSelectedDate] = useState(getCurrentDateStr());
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(initialOpenCreate);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isCancelConfirmOpen, setIsCancelConfirmOpen] = useState(false);

  const [selectedImport, setSelectedImport] = useState(null);
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
    supplierId: '',
    warehouse: 'warehouse1',
    date: new Date().toISOString().slice(0, 10),
    discountAmount: 0,
    paidAmount: 0,
    notes: '',
    items: [],
  });

  // Load Imports via importService
  const loadImports = async () => {
    setLoading(true);
    try {
      const params = {
        supplierId: selectedSupplierId ? Number(selectedSupplierId) : null,
      };

      if (timeMode === 'month') {
        params.month = selectedMonth;
      } else if (timeMode === 'day') {
        params.date = selectedDate;
      } else if (timeMode === 'range') {
        params.fromDate = fromDate;
        params.toDate = toDate;
      }

      const data = await importService.getAll(params);
      setImportsList(data || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách phiếu nhập');
    } finally {
      setLoading(false);
    }
  };

  // Load Dependencies via importService & warehouseService
  const loadDependencies = async () => {
    try {
      const [{ suppliers: supps, products: prods, ownerInfo: owner }, whList] = await Promise.all([
        importService.getDependencies(),
        warehouseService.getWarehouses(),
      ]);
      setSuppliers(supps || []);
      setProducts(prods || []);
      setOwnerInfo(owner || null);
      if (whList && Array.isArray(whList)) setWarehouses(whList);
    } catch (err) {
      console.error(err);
    }
  };

  const handlePrint = (item = null) => {
    const target = item || selectedImport;
    if (!target) return;
    const supp = suppliers.find((s) => s.id === target.supplierId || s.name === target.supplierName);
    const html = generateImportHtml({ importData: target, ownerInfo, supplier: supp });
    printInNewTab(html);
  };

  useEffect(() => {
    loadImports();
  }, [selectedSupplierId, timeMode, selectedMonth, selectedDate, fromDate, toDate]);

  useEffect(() => {
    loadDependencies();
  }, []);

  // Open Create Modal
  const handleOpenCreate = () => {
    loadDependencies();
    setCreateForm({
      supplierId: suppliers.length > 0 ? String(suppliers[0].id) : '',
      warehouse: 'warehouse1',
      date: new Date().toISOString().slice(0, 10),
      discountAmount: 0,
      paidAmount: 0,
      notes: '',
      items: [
        {
          productId: products.length > 0 ? products[0].id : '',
          quantity: 10,
          unitPrice: products.length > 0 ? products[0].unitCost : 0,
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
          unitPrice: products[0].unitCost,
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
          item.unitPrice = prod.unitCost;
        }
      } else {
        item[field] = Number(value);
      }

      newItems[index] = item;
      return { ...prev, items: newItems };
    });
  };

  // Subtotal & Financials via importService
  const { subtotal, discountAmount, totalCost: totalAmount, unpaidAmount } = importService.calculateImportTotals({
    items: createForm.items.map((it) => ({ quantity: it.quantity, unitCost: it.unitPrice })),
    discountType: 'amount',
    discountValue: createForm.discountAmount,
    paidAmount: createForm.paidAmount,
  });

  const selectedSupplierObj = suppliers.find((s) => s.id === Number(createForm.supplierId));

  // Submit Create Import via importService
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const result = await importService.create({
        supplierId: createForm.supplierId,
        warehouse: createForm.warehouse,
        date: createForm.date,
        discountType: 'amount',
        discountValue: createForm.discountAmount,
        paidAmount: createForm.paidAmount,
        notes: createForm.notes,
        items: createForm.items.map((it) => ({
          productId: it.productId,
          quantity: it.quantity,
          unitCost: it.unitPrice,
        })),
      });

      notify.success(`Tạo phiếu nhập ${result.voucherNumber} thành công!`);
      setIsCreateOpen(false);
      loadImports();
      loadDependencies();
    } catch (err) {
      notify.error(err.message || 'Lỗi khi tạo phiếu nhập kho');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Details via importService
  const handleOpenDetail = async (item) => {
    try {
      const full = await importService.getById(item.id);
      setSelectedImport(full || item);
    } catch {
      setSelectedImport(item);
    }
    setIsDetailOpen(true);
  };

  // Open Cancel
  const handleOpenCancel = (item) => {
    setSelectedImport(item);
    setIsCancelConfirmOpen(true);
  };

  // Confirm Cancel via importService
  const handleConfirmCancel = async () => {
    if (!selectedImport) return;
    setSubmitting(true);
    try {
      await importService.updateStatus(selectedImport.id, 'cancel');
      notify.success(`Đã hủy phiếu nhập ${selectedImport.voucherNumber}`);
      setIsCancelConfirmOpen(false);
      loadImports();
      loadDependencies();
    } catch (err) {
      notify.error(err.message || 'Không thể hủy phiếu nhập');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <ArrowDownLeft size={28} color="var(--primary)" />
            <span>Nhập Kho</span>
          </h1>
          <p className="page-subtitle">
            Nhập hàng từ nhà cung cấp, tăng tồn kho đa điểm và ghi nhận công nợ phải trả
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadImports} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Lập phiếu nhập mới</span>
          </button>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="filter-bar">
        <div style={{ minWidth: '260px' }}>
          <SearchableSelect
            options={suppliers.map((s) => ({
              id: s.id,
              value: s.id,
              label: s.name,
              code: s.code,
              phone: s.phone || '',
              subLabel: s.phone ? `SĐT: ${s.phone}` : '',
            }))}
            value={selectedSupplierId}
            onChange={(val) => setSelectedSupplierId(val)}
            placeholder="-- Tất cả nhà cung cấp --"
            searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
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

      {/* Imports Table */}
      {importsList.length === 0 && !loading ? (
        <EmptyState
          icon={ArrowDownLeft}
          title="Không tìm thấy phiếu nhập nào"
          description={
            timeMode === 'day'
              ? `Chưa có phiếu nhập hàng nào trong ngày ${selectedDate || ''} hoặc theo nhà cung cấp đã chọn.`
              : timeMode === 'month'
              ? `Chưa có phiếu nhập hàng nào trong tháng ${selectedMonth || ''} hoặc theo nhà cung cấp đã chọn.`
              : 'Chưa có phiếu nhập hàng nào phù hợp với điều kiện lọc.'
          }
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>Tạo phiếu nhập đầu tiên</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Số Phiếu</th>
                <th>Thời Gian Nhập</th>
                <th>Nhà Cung Cấp</th>
                <th>Kho Nhận</th>
                <th style={{ textAlign: 'right' }}>Tiền Hàng</th>
                <th style={{ textAlign: 'right' }}>Chiết Khấu</th>
                <th style={{ textAlign: 'right' }}>Tổng Tiền</th>
                <th style={{ textAlign: 'right' }}>Đã Trả NCC</th>
                <th style={{ textAlign: 'right' }}>Còn Nợ NCC</th>
                <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {importsList.map((imp) => (
                <tr key={imp.id}>
                  <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                    {imp.voucherNumber}
                  </td>
                  <td style={{ fontSize: '0.8125rem' }}>{formatDate(imp.createdAt || imp.date, true)}</td>
                  <td style={{ fontWeight: 600 }}>{imp.supplierName}</td>
                  <td>
                    <span className="badge badge-neutral">{WAREHOUSE_MAP[imp.warehouse] || imp.warehouse}</span>
                  </td>
                  <td style={{ textAlign: 'right' }} className="mono">
                    {formatVND(imp.subtotalAmount)}
                  </td>
                  <td style={{ textAlign: 'right' }} className="mono">
                    {formatVND(imp.discountAmount)}
                  </td>
                  <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                    {formatVND(imp.totalAmount)}
                  </td>
                  <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                    {formatVND(imp.paidAmount)}
                  </td>
                  <td style={{ textAlign: 'right', color: imp.unpaidAmount > 0 ? 'var(--warning-text)' : 'var(--text-muted)' }} className="mono">
                    {formatVND(imp.unpaidAmount)}
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <span className={`badge badge-${imp.status === 'cancelled' ? 'danger' : 'info'}`}>
                      {imp.status === 'cancelled' ? 'Đã hủy' : 'Đã nhập kho'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                      <button
                        className="btn btn-outline btn-icon"
                        style={{ width: '32px', height: '32px' }}
                        title="Xem chi tiết phiếu nhập"
                        onClick={() => handleOpenDetail(imp)}
                      >
                        <Eye size={15} />
                      </button>
                      <button
                        className="btn btn-outline btn-icon"
                        style={{ width: '32px', height: '32px' }}
                        title="In phiếu nhập kho (Tab mới)"
                        onClick={() => handlePrint(imp)}
                      >
                        <Printer size={15} />
                      </button>
                      {imp.status !== 'cancelled' && (
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--danger)' }}
                          title="Hủy phiếu nhập"
                          onClick={() => handleOpenCancel(imp)}
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

      {/* Modal Lập Phiếu Nhập Kho */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Lập Phiếu Nhập Kho"
        size="xl"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Đóng
            </button>
            <button className="btn btn-primary" onClick={handleCreateSubmit} disabled={submitting}>
              {submitting ? 'Đang tạo phiếu...' : 'Hoàn tất & Nhập kho'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">
                Nhà Cung Cấp <span className="req">*</span>
              </label>
              <SearchableSelect
                options={suppliers.map((s) => ({
                  id: s.id,
                  value: s.id,
                  label: s.name,
                  code: s.code,
                  phone: s.phone || '',
                  debt: s.debt || 0,
                  subLabel: `Nợ: ${formatVND(s.debt)}`,
                }))}
                value={createForm.supplierId}
                onChange={(val) => {
                  if (val !== createForm.supplierId) {
                    setCreateForm({ 
                      ...createForm, 
                      supplierId: val,
                      items: [{ productId: '', quantity: 1, unitPrice: 0 }] 
                    });
                  }
                }}
                placeholder="-- Chọn nhà cung cấp --"
                searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                searchFields={['label', 'code', 'phone']}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">
                Kho Tiếp Nhận <span className="req">*</span>
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
              <label className="form-label">Ngày Nhập Kho</label>
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
              <h4 style={{ fontSize: '0.9375rem', fontWeight: 700 }}>Danh Sách Hàng Nhập Kho</h4>
              <button type="button" className="btn btn-outline btn-sm" onClick={handleAddItem}>
                <Plus size={14} />
                <span>Thêm dòng sản phẩm</span>
              </button>
            </div>

            <div className="table-responsive" style={{ overflow: 'visible' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '45%' }}>Sản Phẩm</th>
                    <th style={{ width: '20%', textAlign: 'right' }}>Số Lượng Nhập</th>
                    <th style={{ width: '20%', textAlign: 'right' }}>Đơn Giá Nhập</th>
                    <th style={{ width: '15%', textAlign: 'right' }}>Thành Tiền</th>
                    <th style={{ width: '5%', textAlign: 'center' }}>Xóa</th>
                  </tr>
                </thead>
                <tbody>
                  {createForm.items.map((item, idx) => {
                    const prod = products.find((p) => p.id === Number(item.productId));
                    const lineTotal = Number(item.quantity || 0) * Number(item.unitPrice || 0);

                    return (
                      <tr key={idx}>
                        <td>
                          <SearchableSelect
                            disabled={!createForm.supplierId}
                            options={products
                              .filter((p) => String(p.supplierId) === String(createForm.supplierId))
                              .map((p) => {
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
                                  subLabel: `ĐVT: ${p.uom || 'ĐVT'} | Tồn ${whLabel}: ${formatNumber(whStock)} (Tổng: ${formatNumber(total)}) | Giá nhập: ${formatVND(p.unitCost || 0)}`,
                                };
                              })}
                            value={item.productId}
                            onChange={(val) => handleUpdateItem(idx, 'productId', val)}
                            placeholder={createForm.supplierId ? "-- Chọn sản phẩm --" : "-- Vui lòng chọn Nhà CC --"}
                            searchPlaceholder="Tìm theo mã SKU, tên SP..."
                            searchFields={['label', 'code']}
                          />
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
                            value={item.unitPrice}
                            onChange={(e) => handleUpdateItem(idx, 'unitPrice', e.target.value)}
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
            <div>
              <div className="form-group">
                <label className="form-label">Chiết Khấu Từ NCC</label>
                <input
                  type="number"
                  min="0"
                  step="any"
                  className="form-input mono"
                  value={createForm.discountAmount}
                  onChange={(e) => setCreateForm({ ...createForm, discountAmount: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Ghi Chú Phiếu Nhập</label>
                <textarea
                  className="form-textarea"
                  rows={2}
                  placeholder="Ghi chú số hóa đơn đỏ NCC, lô hàng..."
                  value={createForm.notes}
                  onChange={(e) => setCreateForm({ ...createForm, notes: e.target.value })}
                />
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.625rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Tiền hàng tạm tính:</span>
                <span className="mono" style={{ fontWeight: 600 }}>{formatVND(subtotal)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Chiết khấu NCC:</span>
                <span className="mono" style={{ color: 'var(--danger)' }}>-{formatVND(discountAmount)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.0625rem', fontWeight: 800 }}>
                <span>Tổng tiền nhập hàng:</span>
                <span className="mono" style={{ color: 'var(--primary)' }}>{formatVND(totalAmount)}</span>
              </div>

              <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '0.25rem 0' }} />

              <div className="form-group" style={{ marginBottom: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                  <label className="form-label" style={{ marginBottom: 0 }}>
                    Tiền Chi Trả Ngay Cho NCC:
                  </label>
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    style={{ padding: '0 0.5rem', fontSize: '0.75rem' }}
                    onClick={() => setCreateForm({ ...createForm, paidAmount: totalAmount })}
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
                <span style={{ color: unpaidAmount > 0 ? 'var(--warning-text)' : 'var(--success)' }}>
                  {unpaidAmount > 0 ? 'Ghi nợ phải trả NCC:' : 'Thanh toán hoàn tất:'}
                </span>
                <span className="mono" style={{ color: unpaidAmount > 0 ? 'var(--warning-text)' : 'var(--success)' }}>
                  {formatVND(unpaidAmount)}
                </span>
              </div>
            </div>
          </div>
        </form>
      </Modal>

      {/* Modal Chi Tiết Phiếu Nhập */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title={`Chi Tiết Phiếu Nhập: ${selectedImport?.voucherNumber || ''}`}
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => handlePrint(selectedImport)}>
              <Printer size={16} />
              <span>In Phiếu Nhập</span>
            </button>
            <button className="btn btn-primary" onClick={() => setIsDetailOpen(false)}>
              Đóng
            </button>
          </>
        }
      >
        {selectedImport && (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '2px solid var(--border-color)', paddingBottom: '1rem', marginBottom: '1.25rem' }}>
              <div>
                <h3 style={{ fontSize: '1.1875rem', fontWeight: 800 }}>PHIẾU NHẬP KHO HÀNG HÓA</h3>
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>Mã phiếu: <strong>{selectedImport.voucherNumber}</strong></p>
                <p style={{ fontSize: '0.8125rem' }}>Nhà cung cấp: <strong>{selectedImport.supplierName}</strong></p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '0.8125rem' }}>Thời gian nhập: <strong>{formatDate(selectedImport.createdAt || selectedImport.date, true)}</strong></p>
                <p style={{ fontSize: '0.8125rem' }}>Kho nhận: <strong>{WAREHOUSE_MAP[selectedImport.warehouse] || selectedImport.warehouse}</strong></p>
                <span className={`badge badge-${selectedImport.status === 'cancelled' ? 'danger' : 'info'}`}>
                  {selectedImport.status === 'cancelled' ? 'Đã hủy' : 'Đã nhập kho'}
                </span>
              </div>
            </div>

            <div className="table-responsive" style={{ marginBottom: '1.25rem' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>STT</th>
                    <th>Tên Hàng Hóa</th>
                    <th style={{ textAlign: 'right' }}>Số Lượng</th>
                    <th style={{ textAlign: 'right' }}>Đơn Giá Nhập</th>
                    <th style={{ textAlign: 'right' }}>Thành Tiền</th>
                  </tr>
                </thead>
                <tbody>
                  {(selectedImport.items || []).map((it, idx) => (
                    <tr key={it.id || idx}>
                      <td style={{ textAlign: 'center' }}>{idx + 1}</td>
                      <td>
                        <strong>{it.productName || it.sku}</strong>
                        {it.sku && <span className="mono" style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginLeft: '6px' }}>({it.sku})</span>}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatNumber(it.quantity)}</td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatVND(it.unitPrice)}</td>
                      <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">{formatVND(it.lineTotal)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <div style={{ width: '320px', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span>Tiền hàng:</span>
                  <span className="mono">{formatVND(selectedImport.subtotalAmount)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span>Chiết khấu NCC:</span>
                  <span className="mono">-{formatVND(selectedImport.discountAmount)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1rem', fontWeight: 800 }}>
                  <span>Tổng tiền nhập:</span>
                  <span className="mono" style={{ color: 'var(--primary)' }}>{formatVND(selectedImport.totalAmount)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', color: 'var(--success)' }}>
                  <span>Đã trả NCC:</span>
                  <span className="mono">{formatVND(selectedImport.paidAmount)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', fontWeight: 700, color: selectedImport.unpaidAmount > 0 ? 'var(--warning-text)' : 'var(--text-muted)' }}>
                  <span>Còn nợ lại NCC:</span>
                  <span className="mono">{formatVND(selectedImport.unpaidAmount)}</span>
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
        title="Xác nhận hủy phiếu nhập"
        message={`Bạn có chắc chắn muốn hủy phiếu nhập "${selectedImport?.voucherNumber}"? Tồn kho các sản phẩm sẽ bị giảm trừ tương ứng và công nợ với NCC sẽ được khấu trừ lại.`}
        confirmText="Hủy phiếu nhập"
        isDanger={true}
        isLoading={submitting}
      />
    </div>
  );
}

import React, { useState, useEffect } from 'react';
import {
  Boxes,
  Plus,
  Edit2,
  Sliders,
  History,
  AlertTriangle,
  Search,
  Filter,
  RefreshCw,
  Building,
  CheckCircle2,
  Package,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr } from '../utils/formatters';
import { WAREHOUSES, WAREHOUSE_MAP, STOCK_ADJUST_REASONS } from '../utils/constants';
import { useNotification } from '../context/NotificationContext';
import SearchBar from '../components/common/SearchBar';
import Modal from '../components/common/Modal';
import Drawer from '../components/common/Drawer';
import EmptyState from '../components/common/EmptyState';
import { productService } from '../services';

export default function Products() {
  const notify = useNotification();

  const [products, setProducts] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(false);

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSupplierId, setSelectedSupplierId] = useState('');
  const [onlyLowStock, setOnlyLowStock] = useState(false);

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isAdjustOpen, setIsAdjustOpen] = useState(false);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);

  const [selectedProduct, setSelectedProduct] = useState(null);
  const [historyRecords, setHistoryRecords] = useState([]);
  const [historyMonth, setHistoryMonth] = useState(getCurrentMonthStr());
  const [historyLoading, setHistoryLoading] = useState(false);

  // Form states
  const [formData, setFormData] = useState({
    sku: '',
    name: '',
    category: '',
    uom: 'Cái',
    barcode: '',
    supplierId: '',
    unitCost: 0,
    wholesalePrice: 0,
    retailPrice: 0,
    stockWarehouse1: 0,
    stockWarehouse2: 0,
    stockWarehouse3: 0,
    reorderPoint: 5,
  });

  const [adjustData, setAdjustData] = useState({
    warehouse: 'warehouse1',
    mode: 'delta', // 'delta' or 'quantity'
    delta: 0,
    quantity: 0,
    reason: STOCK_ADJUST_REASONS[0],
    note: '',
  });

  const [submitting, setSubmitting] = useState(false);

  // Load products & suppliers via productService
  const loadData = async () => {
    setLoading(true);
    try {
      const [prods, depRes] = await Promise.all([
        productService.getAll({
          q: searchQuery,
          supplierId: selectedSupplierId ? Number(selectedSupplierId) : null,
        }),
        productService.getDependencies(),
      ]);
      setProducts(prods || []);
      setSuppliers(depRes.suppliers || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách sản phẩm');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [searchQuery, selectedSupplierId]);

  // Filtered products list via productService
  const filteredProducts = productService.filterProducts(products, { onlyLowStock });

  // Open Create Modal
  const handleOpenCreate = () => {
    setFormData({
      sku: '',
      name: '',
      category: '',
      uom: 'Cái',
      barcode: '',
      supplierId: '',
      unitCost: 0,
      wholesalePrice: 0,
      retailPrice: 0,
      stockWarehouse1: 0,
      stockWarehouse2: 0,
      stockWarehouse3: 0,
      reorderPoint: 5,
    });
    setIsCreateOpen(true);
  };

  // Open Edit Modal
  const handleOpenEdit = (product) => {
    setSelectedProduct(product);
    setFormData({
      sku: product.sku,
      name: product.name,
      category: product.category || '',
      uom: product.uom || 'Cái',
      barcode: product.barcode || '',
      supplierId: product.supplierId || '',
      unitCost: product.unitCost,
      wholesalePrice: product.wholesalePrice,
      retailPrice: product.retailPrice,
      reorderPoint: product.reorderPoint,
    });
    setIsEditOpen(true);
  };

  // Open Adjust Modal
  const handleOpenAdjust = (product) => {
    setSelectedProduct(product);
    setAdjustData({
      warehouse: 'warehouse1',
      mode: 'delta',
      delta: 0,
      quantity: product.stockWarehouse1 || 0,
      reason: STOCK_ADJUST_REASONS[0],
      note: '',
    });
    setIsAdjustOpen(true);
  };

  // Open History Drawer via productService
  const handleOpenHistory = async (product) => {
    setSelectedProduct(product);
    setIsHistoryOpen(true);
    loadStockHistory(product.id, historyMonth);
  };

  const loadStockHistory = async (productId, month) => {
    setHistoryLoading(true);
    try {
      const records = await productService.getStockHistory(productId, month);
      setHistoryRecords(records || []);
    } catch (err) {
      notify.error(err.message || 'Lỗi khi tải lịch sử sổ kho');
    } finally {
      setHistoryLoading(false);
    }
  };

  // Submit Create via productService
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await productService.create({
        ...formData,
        supplierId: formData.supplierId ? Number(formData.supplierId) : null,
        unitCost: Number(formData.unitCost || 0),
        wholesalePrice: Number(formData.wholesalePrice || 0),
        retailPrice: Number(formData.retailPrice || 0),
        stockWarehouse1: Number(formData.stockWarehouse1 || 0),
        stockWarehouse2: Number(formData.stockWarehouse2 || 0),
        stockWarehouse3: Number(formData.stockWarehouse3 || 0),
        reorderPoint: Number(formData.reorderPoint || 0),
      });
      notify.success('Thêm sản phẩm mới thành công!');
      setIsCreateOpen(false);
      loadData();
    } catch (err) {
      notify.error(err.message || 'Thêm sản phẩm thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Edit via productService
  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await productService.update(selectedProduct.id, {
        name: formData.name,
        category: formData.category,
        uom: formData.uom,
        barcode: formData.barcode,
        supplierId: formData.supplierId ? Number(formData.supplierId) : null,
        unitCost: Number(formData.unitCost || 0),
        wholesalePrice: Number(formData.wholesalePrice || 0),
        retailPrice: Number(formData.retailPrice || 0),
        reorderPoint: Number(formData.reorderPoint || 0),
      });
      notify.success('Cập nhật sản phẩm thành công!');
      setIsEditOpen(false);
      loadData();
    } catch (err) {
      notify.error(err.message || 'Cập nhật thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Stock Adjust via productService
  const handleAdjustSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const payload = {
        warehouse: adjustData.warehouse,
        reason: adjustData.reason,
        note: adjustData.note,
        changeDate: new Date().toISOString(),
      };

      if (adjustData.mode === 'delta') {
        payload.delta = Number(adjustData.delta || 0);
      } else {
        payload.quantity = Number(adjustData.quantity || 0);
      }

      await productService.adjustStock(selectedProduct.id, payload);
      notify.success('Điều chỉnh tồn kho thành công!');
      setIsAdjustOpen(false);
      loadData();
    } catch (err) {
      notify.error(err.message || 'Điều chỉnh tồn kho thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <Boxes size={28} color="var(--primary)" />
            <span>Quản Lý Sản Phẩm & Kho Đa Điểm</span>
          </h1>
          <p className="page-subtitle">
            Quản lý danh mục hàng hóa, đơn giá và phân bổ tồn kho trên Kho 1, Kho 2, Kho 3
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadData} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Thêm sản phẩm mới</span>
          </button>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên, mã SKU, barcode..."
          style={{ flex: 1, minWidth: '280px' }}
        />

        <div style={{ minWidth: '220px' }}>
          <select
            className="form-select"
            value={selectedSupplierId}
            onChange={(e) => setSelectedSupplierId(e.target.value)}
          >
            <option value="">-- Tất cả nhà cung cấp --</option>
            {suppliers.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name} ({s.code})
              </option>
            ))}
          </select>
        </div>

        <label
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            cursor: 'pointer',
            fontSize: '0.875rem',
            fontWeight: 600,
            color: onlyLowStock ? 'var(--warning-text)' : 'var(--text-secondary)',
            background: onlyLowStock ? 'var(--warning-light)' : 'transparent',
            padding: '0.4rem 0.75rem',
            borderRadius: 'var(--radius-md)',
            border: `1px solid ${onlyLowStock ? 'rgba(245, 158, 11, 0.3)' : 'transparent'}`,
          }}
        >
          <input
            type="checkbox"
            checked={onlyLowStock}
            onChange={(e) => setOnlyLowStock(e.target.checked)}
            style={{ width: '16px', height: '16px', cursor: 'pointer' }}
          />
          <span>Cảnh báo sắp hết hàng</span>
        </label>
      </div>

      {/* Products Table */}
      {filteredProducts.length === 0 && !loading ? (
        <EmptyState
          icon={Package}
          title="Không tìm thấy sản phẩm"
          description="Chưa có sản phẩm nào thỏa mãn điều kiện lọc hoặc danh mục đang trống."
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>Thêm sản phẩm ngay</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã SKU</th>
                <th>Tên Sản Phẩm</th>
                <th>ĐVT</th>
                <th style={{ textAlign: 'right' }}>Kho 1</th>
                <th style={{ textAlign: 'right' }}>Kho 2</th>
                <th style={{ textAlign: 'right' }}>Kho 3</th>
                <th style={{ textAlign: 'right' }}>Tổng Tồn</th>
                <th style={{ textAlign: 'right' }}>Giá Vốn</th>
                <th style={{ textAlign: 'right' }}>Giá Sỉ</th>
                <th style={{ textAlign: 'right' }}>Giá Lẻ</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredProducts.map((p) => {
                const isLow = Number(p.totalStock || 0) <= Number(p.reorderPoint || 0) && Number(p.reorderPoint || 0) > 0;
                return (
                  <tr key={p.id}>
                    <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                      {p.sku}
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{p.name}</div>
                      {p.category && (
                        <span className="badge badge-neutral" style={{ fontSize: '0.6875rem', marginTop: '2px' }}>
                          {p.category}
                        </span>
                      )}
                    </td>
                    <td>{p.uom || 'Cái'}</td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(p.stockWarehouse1)}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(p.stockWarehouse2)}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatNumber(p.stockWarehouse3)}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <span className={`badge badge-${isLow ? 'danger' : 'success'} mono`} style={{ fontWeight: 700 }}>
                        {formatNumber(p.totalStock)}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(p.unitCost)}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(p.wholesalePrice)}
                    </td>
                    <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">
                      {formatVND(p.retailPrice)}
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px' }}
                          title="Sửa thông tin sản phẩm"
                          onClick={() => handleOpenEdit(p)}
                        >
                          <Edit2 size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--warning-text)' }}
                          title="Điều chỉnh tồn kho"
                          onClick={() => handleOpenAdjust(p)}
                        >
                          <Sliders size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--info-text)' }}
                          title="Xem sổ kho / Lịch sử biến động"
                          onClick={() => handleOpenHistory(p)}
                        >
                          <History size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal Thêm Mới Sản Phẩm */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Thêm Mới Sản Phẩm & Khởi Tạo Kho"
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-primary" onClick={handleCreateSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Thêm sản phẩm'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">
                Mã SKU <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>(Tự sinh nếu bỏ trống)</span>
              </label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: SP001"
                value={formData.sku}
                onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">
                Tên Sản Phẩm <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Nước giặt cao cấp 3.8kg"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Danh mục</label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Hóa mỹ phẩm"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Đơn vị tính (ĐVT)</label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Chai, Can, Hộp..."
                value={formData.uom}
                onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Mã vạch (Barcode)</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 893500123456"
                value={formData.barcode}
                onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Nhà Cung Cấp Mặc Định</label>
              <select
                className="form-select"
                value={formData.supplierId}
                onChange={(e) => setFormData({ ...formData, supplierId: e.target.value })}
              >
                <option value="">-- Chọn nhà cung cấp (nếu có) --</option>
                {suppliers.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.name} ({s.code})
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.875rem' }}>
            Thiết Lập Giá Bán & Định Mức (VNĐ)
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">Giá Vốn (Nhập)</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.unitCost}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Bán Sỉ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.wholesalePrice}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Bán Lẻ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.retailPrice}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Định mức cảnh báo tồn tối thiểu</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.reorderPoint}
                onChange={(e) => setFormData({ ...formData, reorderPoint: e.target.value })}
              />
            </div>
          </div>

          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.875rem' }}>
            Tồn Kho Ban Đầu Cho Từng Kho
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Tồn Kho 1 (Mặc định)</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.stockWarehouse1}
                onChange={(e) => setFormData({ ...formData, stockWarehouse1: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Tồn Kho 2</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.stockWarehouse2}
                onChange={(e) => setFormData({ ...formData, stockWarehouse2: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Tồn Kho 3</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.stockWarehouse3}
                onChange={(e) => setFormData({ ...formData, stockWarehouse3: e.target.value })}
              />
            </div>
          </div>
        </form>
      </Modal>

      {/* Modal Chỉnh Sửa Sản Phẩm */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa Thông Tin: ${selectedProduct?.name || ''}`}
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsEditOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-primary" onClick={handleEditSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
            </button>
          </>
        }
      >
        <form onSubmit={handleEditSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">
                Tên Sản Phẩm <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Danh mục</label>
              <input
                type="text"
                className="form-input"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Đơn vị tính (ĐVT)</label>
              <input
                type="text"
                className="form-input"
                value={formData.uom}
                onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Mã vạch (Barcode)</label>
              <input
                type="text"
                className="form-input mono"
                value={formData.barcode}
                onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Nhà Cung Cấp</label>
              <select
                className="form-select"
                value={formData.supplierId}
                onChange={(e) => setFormData({ ...formData, supplierId: e.target.value })}
              >
                <option value="">-- Không có --</option>
                {suppliers.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.name} ({s.code})
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Giá Vốn</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.unitCost}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Sỉ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.wholesalePrice}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Lẻ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.retailPrice}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Định mức cảnh báo</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.reorderPoint}
                onChange={(e) => setFormData({ ...formData, reorderPoint: e.target.value })}
              />
            </div>
          </div>
        </form>
      </Modal>

      {/* Modal Điều Chỉnh Tồn Kho */}
      <Modal
        isOpen={isAdjustOpen}
        onClose={() => setIsAdjustOpen(false)}
        title={`Điều Chỉnh Tồn Kho: ${selectedProduct?.name || ''}`}
        size="md"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsAdjustOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-primary" onClick={handleAdjustSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Xác nhận điều chỉnh'}
            </button>
          </>
        }
      >
        <form onSubmit={handleAdjustSubmit}>
          <div className="form-group">
            <label className="form-label">Chọn Kho Cần Điều Chỉnh</label>
            <select
              className="form-select"
              value={adjustData.warehouse}
              onChange={(e) => setAdjustData({ ...adjustData, warehouse: e.target.value })}
            >
              {WAREHOUSES.map((wh) => (
                <option key={wh.id} value={wh.id}>
                  {wh.name} (Tồn hiện tại: {formatNumber(selectedProduct?.[`stock${wh.id.charAt(0).toUpperCase() + wh.id.slice(1)}`] || 0)})
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Cách Thức Điều Chỉnh</label>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="adjustMode"
                  value="delta"
                  checked={adjustData.mode === 'delta'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'delta' })}
                />
                <span>Tăng / Giảm độ lệch (+/-)</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="adjustMode"
                  value="quantity"
                  checked={adjustData.mode === 'quantity'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'quantity' })}
                />
                <span>Nhập số lượng thực tế mới</span>
              </label>
            </div>
          </div>

          {adjustData.mode === 'delta' ? (
            <div className="form-group">
              <label className="form-label">
                Số Lượng Chênh Lệch (+ nếu tăng, - nếu giảm)
              </label>
              <input
                type="number"
                step="any"
                className="form-input mono"
                placeholder="VD: 5 hoặc -3"
                value={adjustData.delta}
                onChange={(e) => setAdjustData({ ...adjustData, delta: e.target.value })}
                required
              />
            </div>
          ) : (
            <div className="form-group">
              <label className="form-label">Số Lượng Tồn Thực Tế Mới Tại Kho</label>
              <input
                type="number"
                step="any"
                min="0"
                className="form-input mono"
                value={adjustData.quantity}
                onChange={(e) => setAdjustData({ ...adjustData, quantity: e.target.value })}
                required
              />
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Lý Do Điều Chỉnh</label>
            <select
              className="form-select"
              value={adjustData.reason}
              onChange={(e) => setAdjustData({ ...adjustData, reason: e.target.value })}
            >
              {STOCK_ADJUST_REASONS.map((r, i) => (
                <option key={i} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi Chú Chi Tiết</label>
            <textarea
              className="form-textarea"
              rows={2}
              placeholder="VD: Kiểm kê kho cuối tháng 10..."
              value={adjustData.note}
              onChange={(e) => setAdjustData({ ...adjustData, note: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Drawer Xem Lịch Sử Sổ Kho */}
      <Drawer
        isOpen={isHistoryOpen}
        onClose={() => setIsHistoryOpen(false)}
        title={`Sổ Kho: ${selectedProduct?.name || ''}`}
        subtitle={`Mã SKU: ${selectedProduct?.sku || ''} | Tổng tồn: ${formatNumber(selectedProduct?.totalStock || 0)}`}
        width="680px"
      >
        <div style={{ marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <label style={{ fontSize: '0.875rem', fontWeight: 600 }}>Lọc theo tháng:</label>
          <input
            type="month"
            className="form-input mono"
            style={{ width: '180px' }}
            value={historyMonth}
            onChange={(e) => {
              setHistoryMonth(e.target.value);
              if (selectedProduct) {
                loadStockHistory(selectedProduct.id, e.target.value);
              }
            }}
          />
        </div>

        {historyLoading ? (
          <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
            Đang tải dữ liệu sổ kho...
          </p>
        ) : historyRecords.length === 0 ? (
          <EmptyState
            icon={History}
            title="Chưa có biến động kho"
            description="Không có bản ghi xuất/nhập/điều chỉnh kho nào trong tháng đã chọn."
          />
        ) : (
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Thời Gian</th>
                  <th>Kho</th>
                  <th>Nguồn</th>
                  <th style={{ textAlign: 'right' }}>Trước</th>
                  <th style={{ textAlign: 'right' }}>Biến Động</th>
                  <th style={{ textAlign: 'right' }}>Sau</th>
                  <th>Lý Do</th>
                </tr>
              </thead>
              <tbody>
                {historyRecords.map((r) => {
                  const isPositive = Number(r.delta || 0) > 0;
                  return (
                    <tr key={r.id}>
                      <td style={{ fontSize: '0.8125rem' }}>{formatDate(r.changeDate, true)}</td>
                      <td>
                        <span className="badge badge-neutral">{WAREHOUSE_MAP[r.warehouse] || r.warehouse}</span>
                      </td>
                      <td>
                        <span className="badge badge-primary">{r.sourceType}</span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatNumber(r.beforeWarehouseStock)}
                      </td>
                      <td
                        style={{
                          textAlign: 'right',
                          fontWeight: 700,
                          color: isPositive ? 'var(--success)' : 'var(--danger)',
                        }}
                        className="mono"
                      >
                        {isPositive ? `+${formatNumber(r.delta)}` : formatNumber(r.delta)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">
                        {formatNumber(r.afterWarehouseStock)}
                      </td>
                      <td style={{ fontSize: '0.8125rem' }}>{r.reason || r.note || '—'}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Drawer>
    </div>
  );
}

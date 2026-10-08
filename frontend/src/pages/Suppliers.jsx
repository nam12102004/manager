import React, { useState, useEffect } from 'react';
import {
  Truck,
  Plus,
  Edit2,
  Sliders,
  History,
  CreditCard,
  Search,
  RefreshCw,
  Phone,
  Mail,
  Building,
  AlertCircle,
  Printer,
} from 'lucide-react';
import { formatVND, formatDate, getDebtStatus, parseJsonList } from '../utils/formatters';
import { DEBT_ADJUST_REASONS, PAYMENT_METHODS } from '../utils/constants';
import { useNotification } from '../context/NotificationContext';
import SearchBar from '../components/common/SearchBar';
import Modal from '../components/common/Modal';
import Drawer from '../components/common/Drawer';
import EmptyState from '../components/common/EmptyState';
import PrintVoucherModal from '../components/common/PrintVoucherModal';
import { supplierService, cashBookService, settingService } from '../services';

export default function Suppliers() {
  const notify = useNotification();

  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isAdjustOpen, setIsAdjustOpen] = useState(false);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [isPaymentOpen, setIsPaymentOpen] = useState(false);
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false);
  const [printVoucher, setPrintVoucher] = useState(null);
  const [ownerInfo, setOwnerInfo] = useState(null);

  const [selectedSupplier, setSelectedSupplier] = useState(null);
  const [debtHistoryRecords, setDebtHistoryRecords] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(false);

  // Form states
  const [formData, setFormData] = useState({
    code: '',
    name: '',
    contactName: '',
    phone: '',
    email: '',
    address: '',
    bankAccount: '',
    taxNumber: '',
    initialDebt: 0,
    creditLimit: 0,
    notes: '',
  });

  const [adjustData, setAdjustData] = useState({
    mode: 'delta',
    delta: 0,
    newDebt: 0,
    reason: DEBT_ADJUST_REASONS[0],
    note: '',
  });

  const [paymentData, setPaymentData] = useState({
    amount: 0,
    method: 'bank_transfer',
    notes: '',
  });

  const [submitting, setSubmitting] = useState(false);

  // Load Suppliers
  // Load Suppliers via supplierService
  const loadSuppliers = async () => {
    setLoading(true);
    try {
      const data = await supplierService.getAll({ q: searchQuery });
      setSuppliers(data || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách nhà cung cấp');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSuppliers();
    settingService.getSettings().then((res) => setOwnerInfo(res)).catch(() => {});
  }, [searchQuery]);

  // Open Create
  const handleOpenCreate = () => {
    setFormData({
      code: '',
      name: '',
      contactName: '',
      phone: '',
      email: '',
      address: '',
      bankAccount: '',
      taxNumber: '',
      initialDebt: 0,
      creditLimit: 0,
      notes: '',
    });
    setIsCreateOpen(true);
  };

  // Open Edit
  const handleOpenEdit = (supplier) => {
    setSelectedSupplier(supplier);
    setFormData({
      name: supplier.name,
      contactName: supplier.contactName || '',
      phone: parseJsonList(supplier.phonesJson) || '',
      email: supplier.email || '',
      address: parseJsonList(supplier.addressesJson) || '',
      bankAccount: supplier.bankAccount || '',
      taxNumber: supplier.taxNumber || '',
      creditLimit: supplier.creditLimit || 0,
      notes: supplier.notes || '',
    });
    setIsEditOpen(true);
  };

  // Open Adjust
  const handleOpenAdjust = (supplier) => {
    setSelectedSupplier(supplier);
    setAdjustData({
      mode: 'delta',
      delta: 0,
      newDebt: supplier.debt || 0,
      reason: DEBT_ADJUST_REASONS[0],
      note: '',
    });
    setIsAdjustOpen(true);
  };

  // Open History via supplierService
  const handleOpenHistory = async (supplier) => {
    setSelectedSupplier(supplier);
    setIsHistoryOpen(true);
    setHistoryLoading(true);
    try {
      const records = await supplierService.getDebtHistory(supplier.id);
      setDebtHistoryRecords(records || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải lịch sử sổ nợ NCC');
    } finally {
      setHistoryLoading(false);
    }
  };

  // Open Quick Payment
  const handleOpenPayment = (supplier) => {
    setSelectedSupplier(supplier);
    setPaymentData({
      amount: supplier.debt < 0 ? Math.abs(supplier.debt) : 0,
      method: 'bank_transfer',
      notes: `Chi tiền thanh toán công nợ NCC: ${supplier.name}`,
    });
    setIsPaymentOpen(true);
  };

  // Submit Create via supplierService
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await supplierService.create({
        ...formData,
        phones: formData.phone.trim() ? [formData.phone.trim()] : [],
        addresses: formData.address.trim() ? [formData.address.trim()] : [],
      });
      notify.success('Thêm nhà cung cấp thành công!');
      setIsCreateOpen(false);
      loadSuppliers();
    } catch (err) {
      notify.error(err.message || 'Thêm NCC thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Edit via supplierService
  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await supplierService.update(selectedSupplier.id, {
        ...formData,
        phones: formData.phone.trim() ? [formData.phone.trim()] : [],
        addresses: formData.address.trim() ? [formData.address.trim()] : [],
      });
      notify.success('Cập nhật nhà cung cấp thành công!');
      setIsEditOpen(false);
      loadSuppliers();
    } catch (err) {
      notify.error(err.message || 'Cập nhật thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Adjust via supplierService
  const handleAdjustSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const payload = {
        reason: adjustData.reason,
        note: adjustData.note,
        delta: adjustData.mode === 'delta' ? Number(adjustData.delta || 0) : undefined,
        newDebt: adjustData.mode === 'newDebt' ? Number(adjustData.newDebt || 0) : undefined,
      };

      await supplierService.adjustDebt(selectedSupplier.id, payload);
      notify.success('Điều chỉnh công nợ NCC thành công!');
      setIsAdjustOpen(false);
      loadSuppliers();
    } catch (err) {
      notify.error(err.message || 'Điều chỉnh công nợ thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Payment via cashBookService
  const handlePaymentSubmit = async (e) => {
    e.preventDefault();
    if (Number(paymentData.amount || 0) <= 0) {
      notify.error('Số tiền chi phải lớn hơn 0');
      return;
    }

    setSubmitting(true);
    try {
      const created = await cashBookService.createPayment({
        partnerType: 'supplier',
        partnerId: selectedSupplier.id,
        supplierId: selectedSupplier.id,
        amount: Number(paymentData.amount),
        method: paymentData.method,
        notes: paymentData.notes,
        date: new Date().toISOString(),
      });
      notify.success('Lập phiếu chi tiền thành công!');
      setIsPaymentOpen(false);
      loadSuppliers();

      if (created) {
        setPrintVoucher({
          voucher: {
            ...created,
            supplierName: selectedSupplier.name,
            supplierAddress: parseJsonList(selectedSupplier.addressesJson),
          },
          type: 'payment',
        });
        setIsPrintModalOpen(true);
      }
    } catch (err) {
      notify.error(err.message || 'Lập phiếu chi thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Total Payables & Receivables via supplierService
  const { totalPayables, totalReceivables } = supplierService.calculateSupplierSummary(suppliers);

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <Truck size={28} color="var(--primary)" />
            <span>Quản Lý Nhà Cung Cấp</span>
          </h1>
          <p className="page-subtitle">
            Quản lý thông tin nhà cung ứng, số tài khoản ngân hàng, công nợ phải trả và tiền ứng trước
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadSuppliers} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Thêm nhà cung cấp</span>
          </button>
        </div>
      </div>

      {/* Filter Bar with 2-way Debt Totals */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên NCC, mã NCC, SĐT, STK ngân hàng, MST..."
          style={{ flex: 1, minWidth: '300px' }}
        />

        <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', marginLeft: 'auto', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải trả (Mình nợ NCC):</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--warning-text)' }}>
              {formatVND(totalPayables)}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải thu (Mình nộp trước):</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--info-text)' }}>
              {formatVND(totalReceivables)}
            </span>
          </div>
        </div>
      </div>

      {/* Suppliers Table */}
      {suppliers.length === 0 && !loading ? (
        <EmptyState
          icon={Truck}
          title="Không tìm thấy nhà cung cấp"
          description="Chưa có nhà cung cấp nào được lưu hoặc không có kết quả phù hợp với từ khóa tìm kiếm."
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>Thêm nhà cung cấp ngay</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã NCC</th>
                <th>Tên Nhà Cung Cấp</th>
                <th>Liên Hệ / SĐT</th>
                <th>Ngân Hàng & STK</th>
                <th>Mã Số Thuế</th>
                <th style={{ textAlign: 'right' }}>Phải Trả (Mình nợ NCC)</th>
                <th style={{ textAlign: 'right' }}>Phải Thu (Mình nộp trước)</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {suppliers.map((s) => {
                return (
                  <tr key={s.id}>
                    <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                      {s.code}
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{s.name}</div>
                      {s.email && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.25rem', marginTop: '2px' }}>
                          <Mail size={12} />
                          <span>{s.email}</span>
                        </div>
                      )}
                    </td>
                    <td>
                      <div>{s.contactName || '—'}</div>
                      {s.phonesJson && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.25rem', marginTop: '2px' }}>
                          <Phone size={12} />
                          <span>{parseJsonList(s.phonesJson)}</span>
                        </div>
                      )}
                    </td>
                    <td style={{ fontSize: '0.8125rem' }}>
                      {s.bankAccount ? (
                        <div className="mono" style={{ fontWeight: 600 }}>
                          {s.bankAccount}
                        </div>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="mono" style={{ fontSize: '0.8125rem' }}>
                      {s.taxNumber || '—'}
                    </td>
                    {/* Cột 1: Phải Trả (Mình nợ nhà cung cấp) */}
                    <td style={{ textAlign: 'right' }}>
                      {s.debt < 0 ? (
                        <div>
                          <span className="mono" style={{ fontWeight: 800, color: 'var(--warning-text)' }}>
                            {formatVND(Math.abs(s.debt))}
                          </span>
                          <div style={{ fontSize: '0.6875rem', color: 'var(--warning-text)', marginTop: '2px', fontWeight: 600 }}>
                            Cần thanh toán
                          </div>
                        </div>
                      ) : (
                        <span style={{ color: 'var(--text-muted)' }}>0 ₫</span>
                      )}
                    </td>
                    {/* Cột 2: Phải Thu (Cửa hàng nộp tiền trước để lấy hàng) */}
                    <td style={{ textAlign: 'right' }}>
                      {s.debt > 0 ? (
                        <div>
                          <span className="mono" style={{ fontWeight: 800, color: 'var(--info-text)' }}>
                            +{formatVND(s.debt)}
                          </span>
                          <div style={{ fontSize: '0.6875rem', color: 'var(--info-text)', marginTop: '2px', fontWeight: 600 }}>
                            Đã nộp trước
                          </div>
                        </div>
                      ) : (
                        <span style={{ color: 'var(--text-muted)' }}>0 ₫</span>
                      )}
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px' }}
                          title="Sửa thông tin NCC"
                          onClick={() => handleOpenEdit(s)}
                        >
                          <Edit2 size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--warning-text)' }}
                          title="Lập phiếu chi tiền trả NCC"
                          onClick={() => handleOpenPayment(s)}
                        >
                          <CreditCard size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px' }}
                          title="Điều chỉnh công nợ"
                          onClick={() => handleOpenAdjust(s)}
                        >
                          <Sliders size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--info-text)' }}
                          title="Xem sổ nợ NCC"
                          onClick={() => handleOpenHistory(s)}
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

      {/* Modal Thêm NCC */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Thêm Mới Nhà Cung Cấp"
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-primary" onClick={handleCreateSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Thêm nhà cung cấp'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">
                Mã NCC <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>(Tự sinh nếu bỏ trống)</span>
              </label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: NCC001"
                value={formData.code}
                onChange={(e) => setFormData({ ...formData, code: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">
                Tên Nhà Cung Cấp <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Tổng Kho Phân Phối Miền Nam"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Người liên hệ</label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Chị Thúy"
                value={formData.contactName}
                onChange={(e) => setFormData({ ...formData, contactName: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Số điện thoại</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 0912345678"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                type="email"
                className="form-input"
                placeholder="VD: supplier@example.com"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Số tài khoản ngân hàng</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 1903... Techcombank"
                value={formData.bankAccount}
                onChange={(e) => setFormData({ ...formData, bankAccount: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Mã số thuế</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 0312345678"
                value={formData.taxNumber}
                onChange={(e) => setFormData({ ...formData, taxNumber: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">Địa chỉ trụ sở / kho</label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Lô A4, KCN Tân Bình, TP.HCM"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Dư nợ ban đầu (- nếu mình nợ NCC, + nếu NCC nợ mình)</label>
              <input
                type="number"
                className="form-input mono"
                value={formData.initialDebt}
                onChange={(e) => setFormData({ ...formData, initialDebt: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Hạn mức nợ NCC cho phép (0 = không giới hạn)</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.creditLimit}
                onChange={(e) => setFormData({ ...formData, creditLimit: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi chú</label>
            <textarea
              className="form-textarea"
              rows={2}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Modal Chỉnh Sửa NCC */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa NCC: ${selectedSupplier?.name || ''}`}
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
                Tên Nhà Cung Cấp <span className="req">*</span>
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
              <label className="form-label">Người liên hệ</label>
              <input
                type="text"
                className="form-input"
                value={formData.contactName}
                onChange={(e) => setFormData({ ...formData, contactName: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Số điện thoại</label>
              <input
                type="text"
                className="form-input mono"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                type="email"
                className="form-input"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Tài khoản ngân hàng</label>
              <input
                type="text"
                className="form-input mono"
                value={formData.bankAccount}
                onChange={(e) => setFormData({ ...formData, bankAccount: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Mã số thuế</label>
              <input
                type="text"
                className="form-input mono"
                value={formData.taxNumber}
                onChange={(e) => setFormData({ ...formData, taxNumber: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Hạn mức nợ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.creditLimit}
                onChange={(e) => setFormData({ ...formData, creditLimit: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">Địa chỉ</label>
              <input
                type="text"
                className="form-input"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">Ghi chú</label>
              <textarea
                className="form-textarea"
                rows={2}
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              />
            </div>
          </div>
        </form>
      </Modal>

      {/* Modal Điều Chỉnh Công Nợ NCC */}
      <Modal
        isOpen={isAdjustOpen}
        onClose={() => setIsAdjustOpen(false)}
        title={`Điều Chỉnh Sổ Nợ NCC: ${selectedSupplier?.name || ''}`}
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
          <div
            style={{
              padding: '0.75rem 1rem',
              borderRadius: 'var(--radius-md)',
              background: 'var(--bg-tertiary)',
              marginBottom: '1rem',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}
          >
            <span style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>Dư nợ hiện tại:</span>
            <span className="mono" style={{ fontSize: '1.125rem', fontWeight: 800 }}>
              {selectedSupplier?.debt < 0 ? `Cần trả: ${formatVND(Math.abs(selectedSupplier?.debt))}` : formatVND(selectedSupplier?.debt || 0)}
            </span>
          </div>

          <div className="form-group">
            <label className="form-label">Cách thức điều chỉnh</label>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="suppDebtAdjustMode"
                  value="delta"
                  checked={adjustData.mode === 'delta'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'delta' })}
                />
                <span>Tăng / Giảm độ lệch (+/-)</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="suppDebtAdjustMode"
                  value="newDebt"
                  checked={adjustData.mode === 'newDebt'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'newDebt' })}
                />
                <span>Thiết lập số nợ mới</span>
              </label>
            </div>
          </div>

          {adjustData.mode === 'delta' ? (
            <div className="form-group">
              <label className="form-label">
                Độ lệch (+ làm giảm nợ phải trả về 0, - làm tăng nợ phải trả)
              </label>
              <input
                type="number"
                step="any"
                className="form-input mono"
                value={adjustData.delta}
                onChange={(e) => setAdjustData({ ...adjustData, delta: e.target.value })}
                required
              />
            </div>
          ) : (
            <div className="form-group">
              <label className="form-label">Số Nợ Mới Thiết Lập (VNĐ)</label>
              <input
                type="number"
                step="any"
                className="form-input mono"
                value={adjustData.newDebt}
                onChange={(e) => setAdjustData({ ...adjustData, newDebt: e.target.value })}
                required
              />
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Lý do điều chỉnh</label>
            <select
              className="form-select"
              value={adjustData.reason}
              onChange={(e) => setAdjustData({ ...adjustData, reason: e.target.value })}
            >
              {DEBT_ADJUST_REASONS.map((r, i) => (
                <option key={i} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi chú chi tiết</label>
            <textarea
              className="form-textarea"
              rows={2}
              value={adjustData.note}
              onChange={(e) => setAdjustData({ ...adjustData, note: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Modal Lập Phiếu Chi Nhanh */}
      <Modal
        isOpen={isPaymentOpen}
        onClose={() => setIsPaymentOpen(false)}
        title={`Lập Phiếu Chi Trả Tiền: ${selectedSupplier?.name || ''}`}
        size="md"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsPaymentOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-warning" onClick={handlePaymentSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Xác nhận chi tiền'}
            </button>
          </>
        }
      >
        <form onSubmit={handlePaymentSubmit}>
          <div
            style={{
              padding: '0.75rem 1rem',
              borderRadius: 'var(--radius-md)',
              background: 'var(--warning-light)',
              color: 'var(--warning-text)',
              marginBottom: '1rem',
              fontSize: '0.875rem',
            }}
          >
            Số nợ hiện tại cần trả: <strong>{formatVND(selectedSupplier?.debt < 0 ? Math.abs(selectedSupplier?.debt) : 0)}</strong>
          </div>

          <div className="form-group">
            <label className="form-label">
              Số Tiền Chi (VNĐ) <span className="req">*</span>
            </label>
            <input
              type="number"
              className="form-input mono"
              min="1"
              value={paymentData.amount}
              onChange={(e) => setPaymentData({ ...paymentData, amount: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Phương Thức Thanh Toán</label>
            <select
              className="form-select"
              value={paymentData.method}
              onChange={(e) => setPaymentData({ ...paymentData, method: e.target.value })}
            >
              {PAYMENT_METHODS.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.label}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi Chú Phiếu Chi</label>
            <textarea
              className="form-textarea"
              rows={2}
              value={paymentData.notes}
              onChange={(e) => setPaymentData({ ...paymentData, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Drawer Sổ Nợ NCC */}
      <Drawer
        isOpen={isHistoryOpen}
        onClose={() => setIsHistoryOpen(false)}
        title={`Sổ Nợ NCC: ${selectedSupplier?.name || ''}`}
        subtitle={`Mã NCC: ${selectedSupplier?.code || ''} | Dư nợ hiện tại: ${formatVND(selectedSupplier?.debt || 0)}`}
        width="680px"
      >
        {historyLoading ? (
          <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
            Đang tải dữ liệu sổ nợ NCC...
          </p>
        ) : debtHistoryRecords.length === 0 ? (
          <EmptyState
            icon={History}
            title="Chưa có lịch sử công nợ"
            description="Nhà cung cấp này chưa có giao dịch nhập nợ, thanh toán hoặc điều chỉnh nào."
          />
        ) : (
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Thời Gian</th>
                  <th>Nghiệp Vụ</th>
                  <th style={{ textAlign: 'right' }}>Nợ Trước</th>
                  <th style={{ textAlign: 'right' }}>Biến Động</th>
                  <th style={{ textAlign: 'right' }}>Nợ Sau</th>
                  <th>Lý Do / Ghi Chú</th>
                </tr>
              </thead>
              <tbody>
                {debtHistoryRecords.map((r) => {
                  return (
                    <tr key={r.id}>
                      <td style={{ fontSize: '0.8125rem' }}>{formatDate(r.createdAt, true)}</td>
                      <td>
                        <span className="badge badge-primary">
                          {r.sourceType === 'import'
                            ? 'Mua hàng (Nhập)'
                            : r.sourceType === 'payment'
                            ? 'Chi tiền'
                            : 'Điều chỉnh'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatVND(r.beforeDebt)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                        {Number(r.delta || 0) > 0 ? `+${formatVND(r.delta)}` : formatVND(r.delta)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">
                        {formatVND(r.afterDebt)}
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

      {/* Print Voucher Modal */}
      <PrintVoucherModal
        isOpen={isPrintModalOpen}
        onClose={() => {
          setIsPrintModalOpen(false);
          setPrintVoucher(null);
        }}
        voucher={printVoucher?.voucher}
        type={printVoucher?.type || 'payment'}
        ownerInfo={ownerInfo}
      />
    </div>
  );
}

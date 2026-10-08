import React, { useState, useEffect } from 'react';
import {
  Users,
  Plus,
  Edit2,
  Sliders,
  History,
  Receipt,
  Search,
  RefreshCw,
  Phone,
  Mail,
  MapPin,
  AlertCircle,
  TrendingUp,
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
import { customerService, cashBookService } from '../services';

export default function Customers({ onQuickAction }) {
  const notify = useNotification();

  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isAdjustOpen, setIsAdjustOpen] = useState(false);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [isReceiptOpen, setIsReceiptOpen] = useState(false);
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false);
  const [printVoucher, setPrintVoucher] = useState(null);
  const [ownerInfo, setOwnerInfo] = useState(null);

  const [selectedCustomer, setSelectedCustomer] = useState(null);
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
    initialDebt: 0,
    creditLimit: 0,
    notes: '',
  });

  const [adjustData, setAdjustData] = useState({
    mode: 'delta', // 'delta' or 'newDebt'
    delta: 0,
    newDebt: 0,
    reason: DEBT_ADJUST_REASONS[0],
    note: '',
  });

  const [receiptData, setReceiptData] = useState({
    amount: 0,
    method: 'cash',
    notes: '',
  });

  const [submitting, setSubmitting] = useState(false);

  // Load Customers via customerService
  const loadCustomers = async () => {
    setLoading(true);
    try {
      const data = await customerService.getAll({ q: searchQuery });
      setCustomers(data || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách khách hàng');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCustomers();
    ownersApi.get().then((res) => setOwnerInfo(res)).catch(() => {});
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
      initialDebt: 0,
      creditLimit: 0,
      notes: '',
    });
    setIsCreateOpen(true);
  };

  // Open Edit
  const handleOpenEdit = (customer) => {
    setSelectedCustomer(customer);
    setFormData({
      name: customer.name,
      contactName: customer.contactName || '',
      phone: parseJsonList(customer.phonesJson) || '',
      email: customer.email || '',
      address: parseJsonList(customer.addressesJson) || '',
      creditLimit: customer.creditLimit || 0,
      notes: customer.notes || '',
    });
    setIsEditOpen(true);
  };

  // Open Adjust
  const handleOpenAdjust = (customer) => {
    setSelectedCustomer(customer);
    setAdjustData({
      mode: 'delta',
      delta: 0,
      newDebt: customer.debt || 0,
      reason: DEBT_ADJUST_REASONS[0],
      note: '',
    });
    setIsAdjustOpen(true);
  };

  // Open Debt History via customerService
  const handleOpenHistory = async (customer) => {
    setSelectedCustomer(customer);
    setIsHistoryOpen(true);
    setHistoryLoading(true);
    try {
      const records = await customerService.getDebtHistory(customer.id);
      setDebtHistoryRecords(records || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải lịch sử sổ nợ');
    } finally {
      setHistoryLoading(false);
    }
  };

  // Open Quick Receipt
  const handleOpenReceipt = (customer) => {
    setSelectedCustomer(customer);
    setReceiptData({
      amount: customer.debt > 0 ? customer.debt : 0,
      method: 'cash',
      notes: `Thu tiền công nợ khách hàng: ${customer.name}`,
    });
    setIsReceiptOpen(true);
  };

  // Submit Create via customerService
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await customerService.create({
        ...formData,
        phones: formData.phone.trim() ? [formData.phone.trim()] : [],
        addresses: formData.address.trim() ? [formData.address.trim()] : [],
      });
      notify.success('Thêm khách hàng thành công!');
      setIsCreateOpen(false);
      loadCustomers();
    } catch (err) {
      notify.error(err.message || 'Thao tác thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Edit via customerService
  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await customerService.update(selectedCustomer.id, {
        ...formData,
        phones: formData.phone.trim() ? [formData.phone.trim()] : [],
        addresses: formData.address.trim() ? [formData.address.trim()] : [],
      });
      notify.success('Cập nhật khách hàng thành công!');
      setIsEditOpen(false);
      loadCustomers();
    } catch (err) {
      notify.error(err.message || 'Cập nhật thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Debt Adjust via customerService
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

      await customerService.adjustDebt(selectedCustomer.id, payload);
      notify.success('Điều chỉnh công nợ khách hàng thành công!');
      setIsAdjustOpen(false);
      loadCustomers();
    } catch (err) {
      notify.error(err.message || 'Điều chỉnh công nợ thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Quick Receipt via cashBookService
  const handleReceiptSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const created = await cashBookService.createReceipt({
        customerId: selectedCustomer.id,
        amount: Number(receiptData.amount),
        method: receiptData.method,
        notes: receiptData.notes,
        date: new Date().toISOString(),
      });
      notify.success('Lập phiếu thu tiền thành công!');
      setIsReceiptOpen(false);
      loadCustomers();

      if (created) {
        setPrintVoucher({
          voucher: {
            ...created,
            customerName: selectedCustomer.name,
            customerAddress: parseJsonList(selectedCustomer.addressesJson),
          },
          type: 'receipt',
        });
        setIsPrintModalOpen(true);
      }
    } catch (err) {
      notify.error(err.message || 'Lập phiếu thu thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Totals via Service Logic Layer
  // Totals via Service Logic Layer
  const { totalReceivables, totalPayables, debtCustomerCount, overLimitCount } = customerService.calculateCustomerSummary(customers);

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <Users size={28} color="var(--primary)" />
            <span>Quản Lý Khách Hàng & Công Nợ</span>
          </h1>
          <p className="page-subtitle">
            Theo dõi danh sách khách hàng, hạn mức tín dụng và sổ nợ hai chiều
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadCustomers} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Thêm khách hàng mới</span>
          </button>
        </div>
      </div>

      {/* Filter Bar with 2-way Debt Totals */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên khách, mã KH, số điện thoại, email..."
          style={{ flex: 1, minWidth: '300px' }}
        />

        <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', marginLeft: 'auto', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải thu (Khách nợ):</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--danger)' }}>
              {formatVND(totalReceivables)}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải trả (KH gửi trước):</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--success)' }}>
              {formatVND(totalPayables)}
            </span>
          </div>
        </div>
      </div>

      {/* Customers Table */}
      {customers.length === 0 && !loading ? (
        <EmptyState
          icon={Users}
          title="Không tìm thấy khách hàng"
          description="Chưa có khách hàng nào được tạo hoặc không có kết quả phù hợp với từ khóa tìm kiếm."
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>Thêm khách hàng ngay</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã KH</th>
                <th>Tên Khách Hàng</th>
                <th>Người Liên Hệ / SĐT</th>
                <th>Địa Chỉ</th>
                <th style={{ textAlign: 'right' }}>Phải Thu (Khách nợ)</th>
                <th style={{ textAlign: 'right' }}>Phải Trả (KH gửi trước)</th>
                <th style={{ textAlign: 'right' }}>Hạn Mức Nợ</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {customers.map((c) => {
                const isOverLimit = Number(c.creditLimit || 0) > 0 && Number(c.debt || 0) > Number(c.creditLimit || 0);

                return (
                  <tr key={c.id}>
                    <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                      {c.code}
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{c.name}</div>
                      {c.email && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.25rem', marginTop: '2px' }}>
                          <Mail size={12} />
                          <span>{c.email}</span>
                        </div>
                      )}
                    </td>
                    <td>
                      <div>{c.contactName || '—'}</div>
                      {c.phonesJson && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.25rem', marginTop: '2px' }}>
                          <Phone size={12} />
                          <span>{parseJsonList(c.phonesJson)}</span>
                        </div>
                      )}
                    </td>
                    <td style={{ fontSize: '0.8125rem', maxWidth: '240px' }}>
                      {c.addressesJson ? (
                        <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.25rem' }}>
                          <MapPin size={12} style={{ flexShrink: 0, marginTop: '3px' }} />
                          <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {parseJsonList(c.addressesJson)}
                          </span>
                        </div>
                      ) : (
                        '—'
                      )}
                    </td>
                    {/* Cột 1: Phải Thu (Khách nợ cửa hàng) */}
                    <td style={{ textAlign: 'right' }}>
                      {c.debt > 0 ? (
                        <div>
                          <span className="mono" style={{ fontWeight: 800, color: 'var(--danger)' }}>
                            +{formatVND(c.debt)}
                          </span>
                          {isOverLimit && (
                            <div>
                              <span className="badge badge-danger" style={{ fontSize: '0.6875rem', marginTop: '2px' }}>
                                Vượt hạn mức
                              </span>
                            </div>
                          )}
                        </div>
                      ) : (
                        <span style={{ color: 'var(--text-muted)' }}>0 ₫</span>
                      )}
                    </td>
                    {/* Cột 2: Phải Trả (Cửa hàng nợ khách / KH gửi tiền trước theo đợt) */}
                    <td style={{ textAlign: 'right' }}>
                      {c.debt < 0 ? (
                        <div>
                          <span className="mono" style={{ fontWeight: 800, color: 'var(--success)' }}>
                            {formatVND(Math.abs(c.debt))}
                          </span>
                          <div style={{ fontSize: '0.6875rem', color: 'var(--success)', marginTop: '2px', fontWeight: 600 }}>
                            KH gửi trước
                          </div>
                        </div>
                      ) : (
                        <span style={{ color: 'var(--text-muted)' }}>0 ₫</span>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {Number(c.creditLimit || 0) > 0 ? formatVND(c.creditLimit) : 'Không giới hạn'}
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px' }}
                          title="Sửa thông tin khách hàng"
                          onClick={() => handleOpenEdit(c)}
                        >
                          <Edit2 size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--success-text)' }}
                          title="Lập phiếu thu tiền"
                          onClick={() => handleOpenReceipt(c)}
                        >
                          <Receipt size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--warning-text)' }}
                          title="Điều chỉnh công nợ"
                          onClick={() => handleOpenAdjust(c)}
                        >
                          <Sliders size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--info-text)' }}
                          title="Xem sổ nợ / Lịch sử công nợ"
                          onClick={() => handleOpenHistory(c)}
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

      {/* Modal Thêm Khách Hàng */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Thêm Mới Khách Hàng"
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-primary" onClick={handleCreateSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Thêm khách hàng'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">
                Mã Khách Hàng <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>(Tự sinh nếu bỏ trống)</span>
              </label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: KH001"
                value={formData.code}
                onChange={(e) => setFormData({ ...formData, code: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">
                Tên Khách Hàng <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Công ty TNHH Hoàng Gia hoặc Nguyễn Văn A"
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
                placeholder="VD: Anh Minh"
                value={formData.contactName}
                onChange={(e) => setFormData({ ...formData, contactName: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Số điện thoại</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 0987654321"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                type="email"
                className="form-input"
                placeholder="VD: khachhang@gmail.com"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">Địa chỉ</label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: 123 Nguyễn Trãi, Quận 1, TP.HCM"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.875rem' }}>
            Thiết Lập Công Nợ Ban Đầu & Hạn Mức (VNĐ)
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Dư nợ ban đầu (+ nếu khách nợ, - nếu khách trả trước)</label>
              <input
                type="number"
                className="form-input mono"
                value={formData.initialDebt}
                onChange={(e) => setFormData({ ...formData, initialDebt: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Hạn mức nợ tối đa (0 = không giới hạn)</label>
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
            <label className="form-label">Ghi chú thêm</label>
            <textarea
              className="form-textarea"
              rows={2}
              placeholder="VD: Khách sỉ đại lý cấp 1..."
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Modal Chỉnh Sửa Khách Hàng */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa: ${selectedCustomer?.name || ''}`}
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
                Tên Khách Hàng <span className="req">*</span>
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
              <label className="form-label">Hạn mức nợ (0 = không giới hạn)</label>
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

      {/* Modal Điều Chỉnh Công Nợ */}
      <Modal
        isOpen={isAdjustOpen}
        onClose={() => setIsAdjustOpen(false)}
        title={`Điều Chỉnh Sổ Nợ: ${selectedCustomer?.name || ''}`}
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
            <span style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>Nợ hiện tại của khách:</span>
            <span className="mono" style={{ fontSize: '1.125rem', fontWeight: 800 }}>
              {formatVND(selectedCustomer?.debt || 0)}
            </span>
          </div>

          <div className="form-group">
            <label className="form-label">Phương thức điều chỉnh</label>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="custDebtAdjustMode"
                  value="delta"
                  checked={adjustData.mode === 'delta'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'delta' })}
                />
                <span>Tăng / Giảm độ lệch (+/-)</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="custDebtAdjustMode"
                  value="newDebt"
                  checked={adjustData.mode === 'newDebt'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'newDebt' })}
                />
                <span>Thiết lập số nợ mới cụ thể</span>
              </label>
            </div>
          </div>

          {adjustData.mode === 'delta' ? (
            <div className="form-group">
              <label className="form-label">
                Độ Lệch Công Nợ (+ nếu tăng nợ phải thu, - nếu giảm nợ)
              </label>
              <input
                type="number"
                step="any"
                className="form-input mono"
                placeholder="VD: 500000 hoặc -200000"
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
              placeholder="VD: Biên bản đối soát ngày 30/10..."
              value={adjustData.note}
              onChange={(e) => setAdjustData({ ...adjustData, note: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Modal Lập Phiếu Thu Nhanh */}
      <Modal
        isOpen={isReceiptOpen}
        onClose={() => setIsReceiptOpen(false)}
        title={`Lập Phiếu Thu Tiền: ${selectedCustomer?.name || ''}`}
        size="md"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsReceiptOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-success" onClick={handleReceiptSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Xác nhận thu tiền'}
            </button>
          </>
        }
      >
        <form onSubmit={handleReceiptSubmit}>
          <div
            style={{
              padding: '0.75rem 1rem',
              borderRadius: 'var(--radius-md)',
              background: 'var(--primary-light)',
              color: 'var(--primary)',
              marginBottom: '1rem',
              fontSize: '0.875rem',
            }}
          >
            Số nợ hiện tại cần thu: <strong>{formatVND(selectedCustomer?.debt || 0)}</strong>
          </div>

          <div className="form-group">
            <label className="form-label">
              Số Tiền Thu (VNĐ) <span className="req">*</span>
            </label>
            <input
              type="number"
              className="form-input mono"
              min="1"
              value={receiptData.amount}
              onChange={(e) => setReceiptData({ ...receiptData, amount: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Hình Thức Thanh Toán</label>
            <select
              className="form-select"
              value={receiptData.method}
              onChange={(e) => setReceiptData({ ...receiptData, method: e.target.value })}
            >
              {PAYMENT_METHODS.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.label}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi Chú Phiếu Thu</label>
            <textarea
              className="form-textarea"
              rows={2}
              value={receiptData.notes}
              onChange={(e) => setReceiptData({ ...receiptData, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Drawer Xem Lịch Sử Sổ Nợ Khách Hàng */}
      <Drawer
        isOpen={isHistoryOpen}
        onClose={() => setIsHistoryOpen(false)}
        title={`Sổ Nợ Khách Hàng: ${selectedCustomer?.name || ''}`}
        subtitle={`Mã KH: ${selectedCustomer?.code || ''} | Dư nợ hiện tại: ${formatVND(selectedCustomer?.debt || 0)}`}
        width="680px"
      >
        {historyLoading ? (
          <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
            Đang tải dữ liệu sổ nợ...
          </p>
        ) : debtHistoryRecords.length === 0 ? (
          <EmptyState
            icon={History}
            title="Chưa có lịch sử công nợ"
            description="Khách hàng này chưa có giao dịch mua nợ, thanh toán hoặc điều chỉnh nào."
          />
        ) : (
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Thời Gian</th>
                  <th>Nghiệp Vụ</th>
                  <th style={{ textAlign: 'right' }}>Nợ Trước</th>
                  <th style={{ textAlign: 'right' }}>Phát Sinh</th>
                  <th style={{ textAlign: 'right' }}>Nợ Sau</th>
                  <th>Lý Do / Ghi Chú</th>
                </tr>
              </thead>
              <tbody>
                {debtHistoryRecords.map((r) => {
                  const isIncrease = Number(r.delta || 0) > 0;
                  return (
                    <tr key={r.id}>
                      <td style={{ fontSize: '0.8125rem' }}>{formatDate(r.createdAt, true)}</td>
                      <td>
                        <span className={`badge badge-${isIncrease ? 'danger' : 'success'}`}>
                          {r.sourceType === 'export'
                            ? 'Bán hàng (Xuất)'
                            : r.sourceType === 'receipt'
                            ? 'Thu tiền'
                            : 'Điều chỉnh'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatVND(r.beforeDebt)}
                      </td>
                      <td
                        style={{
                          textAlign: 'right',
                          fontWeight: 700,
                          color: isIncrease ? 'var(--danger)' : 'var(--success)',
                        }}
                        className="mono"
                      >
                        {isIncrease ? `+${formatVND(r.delta)}` : formatVND(r.delta)}
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
        type={printVoucher?.type || 'receipt'}
        ownerInfo={ownerInfo}
      />
    </div>
  );
}

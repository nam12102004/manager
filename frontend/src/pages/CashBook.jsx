import React, { useState, useEffect } from 'react';
import {
  WalletCards,
  Plus,
  Trash2,
  XCircle,
  Receipt,
  CreditCard,
  Search,
  RefreshCw,
  Calendar,
  Building,
  Users,
  CheckCircle,
  DollarSign,
  Printer,
} from 'lucide-react';
import { formatVND, formatDate, getCurrentMonthStr } from '../utils/formatters';
import { PAYMENT_METHODS } from '../utils/constants';
import { useNotification } from '../context/NotificationContext';
import Modal from '../components/common/Modal';
import ConfirmModal from '../components/common/ConfirmModal';
import EmptyState from '../components/common/EmptyState';
import StatCard from '../components/common/StatCard';
import PrintVoucherModal from '../components/common/PrintVoucherModal';
import { cashBookService } from '../services';

export default function CashBook({ initialOpenReceipt = false, initialOpenPayment = false }) {
  const notify = useNotification();

  const [activeSubTab, setActiveSubTab] = useState('receipts'); // 'receipts' | 'payments'
  const [receipts, setReceipts] = useState([]);
  const [payments, setPayments] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [ownerInfo, setOwnerInfo] = useState(null);
  const [loading, setLoading] = useState(false);

  const [searchQuery, setSearchQuery] = useState('');

  // Modals state
  const [isCreateReceiptOpen, setIsCreateReceiptOpen] = useState(initialOpenReceipt);
  const [isCreatePaymentOpen, setIsCreatePaymentOpen] = useState(initialOpenPayment);
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false);
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false);
  const [printVoucher, setPrintVoucher] = useState(null);

  const [targetItem, setTargetItem] = useState(null);
  const [targetType, setTargetType] = useState('receipt'); // 'receipt' | 'payment'
  const [submitting, setSubmitting] = useState(false);

  // Form state - Receipt
  const [receiptForm, setReceiptForm] = useState({
    partnerType: 'customer', // 'customer' | 'supplier'
    partnerId: '',
    amount: '',
    method: 'cash',
    notes: '',
  });

  // Form state - Payment
  const [paymentForm, setPaymentForm] = useState({
    partnerType: 'supplier', // 'supplier' | 'customer'
    partnerId: '',
    amount: '',
    method: 'bank_transfer',
    notes: '',
  });

  // Load Data via cashBookService
  const loadData = async () => {
    setLoading(true);
    try {
      const [rRes, pRes, deps] = await Promise.all([
        cashBookService.getReceipts({ q: searchQuery }),
        cashBookService.getPayments({ q: searchQuery }),
        cashBookService.getDependencies(),
      ]);

      setReceipts(rRes || []);
      setPayments(pRes || []);
      setCustomers(deps?.customers || []);
      setSuppliers(deps?.suppliers || []);
      setOwnerInfo(deps?.ownerInfo || null);
    } catch (err) {
      notify.error(err.message || 'Không thể tải sổ quỹ');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [searchQuery]);

  // Compute Cashflow Totals via Service Logic Layer
  const { totalReceipts, totalPayments, netFund } = cashBookService.calculateCashFlowStats(receipts, payments);

  // Open Create Receipt
  const handleOpenCreateReceipt = () => {
    setReceiptForm({
      partnerType: 'customer',
      partnerId: customers.length > 0 ? String(customers[0].id) : '',
      amount: '',
      method: 'cash',
      notes: '',
    });
    setIsCreateReceiptOpen(true);
  };

  // Open Create Payment
  const handleOpenCreatePayment = () => {
    setPaymentForm({
      partnerType: 'supplier',
      partnerId: suppliers.length > 0 ? String(suppliers[0].id) : '',
      amount: '',
      method: 'bank_transfer',
      notes: '',
    });
    setIsCreatePaymentOpen(true);
  };

  // Submit Receipt via cashBookService
  const handleCreateReceiptSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const created = await cashBookService.createReceipt(receiptForm);
      notify.success('Lập phiếu thu thành công!');
      setIsCreateReceiptOpen(false);
      loadData();

      // Mở modal xem trước & in phiếu ngay lập tức một cách mượt mà
      if (created) {
        setPrintVoucher({ voucher: created, type: 'receipt' });
        setIsPrintModalOpen(true);
      }
    } catch (err) {
      notify.error(err.message || 'Lỗi khi lập phiếu thu');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Payment via cashBookService
  const handleCreatePaymentSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const created = await cashBookService.createPayment(paymentForm);
      notify.success('Lập phiếu chi thành công!');
      setIsCreatePaymentOpen(false);
      loadData();

      // Mở modal xem trước & in phiếu ngay lập tức một cách mượt mà
      if (created) {
        setPrintVoucher({ voucher: created, type: 'payment' });
        setIsPrintModalOpen(true);
      }
    } catch (err) {
      notify.error(err.message || 'Lỗi khi lập phiếu chi');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Delete Confirm
  const handleOpenDelete = (item, type) => {
    setTargetItem(item);
    setTargetType(type);
    setIsDeleteConfirmOpen(true);
  };

  // Confirm Delete via cashBookService
  const handleConfirmDelete = async () => {
    if (!targetItem) return;
    setSubmitting(true);
    try {
      if (targetType === 'receipt') {
        await cashBookService.deleteReceipt(targetItem.id);
        notify.success(`Đã xóa phiếu thu ${targetItem.receiptNumber}`);
      } else {
        await cashBookService.deletePayment(targetItem.id);
        notify.success(`Đã xóa phiếu chi ${targetItem.paymentNumber}`);
      }
      setIsDeleteConfirmOpen(false);
      loadData();
    } catch (err) {
      notify.error(err.message || 'Xóa phiếu thất bại');
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
            <WalletCards size={28} color="var(--primary)" />
            <span>Sổ Quỹ Thu - Chi (Cash Book)</span>
          </h1>
          <p className="page-subtitle">
            Theo dõi dòng tiền thu tiền khách, chi trả nhà cung cấp và tồn quỹ tiền mặt/ngân hàng
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadData} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-success" onClick={handleOpenCreateReceipt}>
            <Receipt size={16} />
            <span>Lập phiếu thu</span>
          </button>
          <button className="btn btn-warning" onClick={handleOpenCreatePayment}>
            <CreditCard size={16} />
            <span>Lập phiếu chi</span>
          </button>
        </div>
      </div>

      {/* Top Cashflow Stats */}
      <div className="stats-grid">
        <StatCard
          title="TỔNG THU TIỀN VÀO QUỸ"
          value={formatVND(totalReceipts)}
          subtitle={`${receipts.length} lượt phiếu thu`}
          icon={Receipt}
          color="success"
        />
        <StatCard
          title="TỔNG CHI TIỀN TỪ QUỸ"
          value={formatVND(totalPayments)}
          subtitle={`${payments.filter((p) => p.status !== 'cancelled').length} lượt phiếu chi`}
          icon={CreditCard}
          color="danger"
        />
        <StatCard
          title="TỒN QUỸ RÒNG HIỆN TẠI"
          value={formatVND(netFund)}
          subtitle={netFund >= 0 ? 'Dòng tiền dương' : 'Dòng tiền âm'}
          icon={WalletCards}
          color={netFund >= 0 ? 'primary' : 'warning'}
        />
      </div>

      {/* Sub Tabs Toggle */}
      <div style={{ display: 'flex', gap: '0.75rem', marginBottom: '1.25rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '0.75rem' }}>
        <button
          className={`btn ${activeSubTab === 'receipts' ? 'btn-primary' : 'btn-outline'}`}
          onClick={() => setActiveSubTab('receipts')}
        >
          <Receipt size={16} />
          <span>Phiếu Thu ({receipts.length})</span>
        </button>
        <button
          className={`btn ${activeSubTab === 'payments' ? 'btn-primary' : 'btn-outline'}`}
          onClick={() => setActiveSubTab('payments')}
        >
          <CreditCard size={16} />
          <span>Phiếu Chi ({payments.length})</span>
        </button>
      </div>

      {/* Content based on subTab */}
      {activeSubTab === 'receipts' ? (
        receipts.length === 0 && !loading ? (
          <EmptyState
            icon={Receipt}
            title="Chưa có phiếu thu nào"
            description="Lập phiếu thu khi khách hàng thanh toán tiền nợ hoặc hoàn tiền."
            action={
              <button className="btn btn-success btn-sm" onClick={handleOpenCreateReceipt}>
                <Plus size={15} />
                <span>Lập phiếu thu đầu tiên</span>
              </button>
            }
          />
        ) : (
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Số Phiếu Thu</th>
                  <th>Ngày Thu</th>
                  <th>Người Nộp Tiền</th>
                  <th>Phương Thức</th>
                  <th style={{ textAlign: 'right' }}>Số Tiền Thu</th>
                  <th>Ghi Chú</th>
                  <th style={{ textAlign: 'center' }}>Thao Tác</th>
                </tr>
              </thead>
              <tbody>
                {receipts.map((r) => {
                  const partnerName = r.customerName
                    ? `Khách: ${r.customerName}`
                    : r.supplierName
                    ? `NCC: ${r.supplierName}`
                    : 'Khách vãng lai';
                  const methodObj = PAYMENT_METHODS.find((m) => m.id === r.method);

                  return (
                    <tr key={r.id}>
                      <td className="mono" style={{ fontWeight: 700, color: 'var(--success)' }}>
                        {r.receiptNumber}
                      </td>
                      <td style={{ fontSize: '0.8125rem' }}>{formatDate(r.date, true)}</td>
                      <td style={{ fontWeight: 600 }}>{partnerName}</td>
                      <td>
                        <span className="badge badge-neutral">{methodObj?.label || r.method || 'Tiền mặt'}</span>
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 800, color: 'var(--success)' }} className="mono">
                        +{formatVND(r.amount)}
                      </td>
                      <td style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>{r.notes || '—'}</td>
                      <td style={{ textAlign: 'center', whiteSpace: 'nowrap' }}>
                        <button
                          className="btn btn-ghost btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--primary)', marginRight: '4px' }}
                          title="Xem trước & In phiếu thu này"
                          onClick={() => {
                            setPrintVoucher({ voucher: r, type: 'receipt' });
                            setIsPrintModalOpen(true);
                          }}
                        >
                          <Printer size={15} />
                        </button>
                        <button
                          className="btn btn-ghost btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--danger)' }}
                          title="Xóa phiếu thu này (hoàn trả nợ)"
                          onClick={() => handleOpenDelete(r, 'receipt')}
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
        )
      ) : (
        payments.length === 0 && !loading ? (
          <EmptyState
            icon={CreditCard}
            title="Chưa có phiếu chi nào"
            description="Lập phiếu chi khi thanh toán tiền nợ cho nhà cung cấp hoặc hoàn tiền khách hàng."
            action={
              <button className="btn btn-warning btn-sm" onClick={handleOpenCreatePayment}>
                <Plus size={15} />
                <span>Lập phiếu chi đầu tiên</span>
              </button>
            }
          />
        ) : (
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Số Phiếu Chi</th>
                  <th>Ngày Chi</th>
                  <th>Người Nhận Tiền</th>
                  <th>Phương Thức</th>
                  <th style={{ textAlign: 'right' }}>Số Tiền Chi</th>
                  <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                  <th>Ghi Chú</th>
                  <th style={{ textAlign: 'center' }}>Thao Tác</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((p) => {
                  const partnerName = p.supplierName
                    ? `NCC: ${p.supplierName}`
                    : p.customerName
                    ? `Khách: ${p.customerName}`
                    : 'Khác';
                  const methodObj = PAYMENT_METHODS.find((m) => m.id === p.method);

                  return (
                    <tr key={p.id}>
                      <td className="mono" style={{ fontWeight: 700, color: 'var(--danger)' }}>
                        {p.paymentNumber}
                      </td>
                      <td style={{ fontSize: '0.8125rem' }}>{formatDate(p.date, true)}</td>
                      <td style={{ fontWeight: 600 }}>{partnerName}</td>
                      <td>
                        <span className="badge badge-neutral">{methodObj?.label || p.method || 'Tiền mặt'}</span>
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 800, color: 'var(--danger)' }} className="mono">
                        -{formatVND(p.amount)}
                      </td>
                      <td style={{ textAlign: 'center' }}>
                        <span className={`badge badge-${p.status === 'cancelled' ? 'danger' : 'info'}`}>
                          {p.status === 'cancelled' ? 'Đã hủy' : 'Đã chi'}
                        </span>
                      </td>
                      <td style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>{p.notes || '—'}</td>
                      <td style={{ textAlign: 'center', whiteSpace: 'nowrap' }}>
                        <button
                          className="btn btn-ghost btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--primary)', marginRight: '4px' }}
                          title="Xem trước & In phiếu chi này"
                          onClick={() => {
                            setPrintVoucher({ voucher: p, type: 'payment' });
                            setIsPrintModalOpen(true);
                          }}
                        >
                          <Printer size={15} />
                        </button>
                        <button
                          className="btn btn-ghost btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--danger)' }}
                          title="Xóa phiếu chi này"
                          onClick={() => handleOpenDelete(p, 'payment')}
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
        )
      )}

      {/* Modal Lập Phiếu Thu */}
      <Modal
        isOpen={isCreateReceiptOpen}
        onClose={() => setIsCreateReceiptOpen(false)}
        title="Lập Phiếu Thu Tiền Vào Quỹ"
        size="md"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreateReceiptOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-success" onClick={handleCreateReceiptSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Hoàn tất thu tiền'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateReceiptSubmit}>
          <div className="form-group">
            <label className="form-label">Thu Tiền Từ Đối Tượng</label>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="rcptPartnerType"
                  value="customer"
                  checked={receiptForm.partnerType === 'customer'}
                  onChange={() => setReceiptForm({ ...receiptForm, partnerType: 'customer', partnerId: customers[0]?.id || '' })}
                />
                <span>Khách Hàng</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="rcptPartnerType"
                  value="supplier"
                  checked={receiptForm.partnerType === 'supplier'}
                  onChange={() => setReceiptForm({ ...receiptForm, partnerType: 'supplier', partnerId: suppliers[0]?.id || '' })}
                />
                <span>Nhà Cung Cấp (Hoàn tiền)</span>
              </label>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">
              Chọn {receiptForm.partnerType === 'customer' ? 'Khách Hàng' : 'Nhà Cung Cấp'} <span className="req">*</span>
            </label>
            <select
              className="form-select"
              value={receiptForm.partnerId}
              onChange={(e) => setReceiptForm({ ...receiptForm, partnerId: e.target.value })}
              required
            >
              {receiptForm.partnerType === 'customer'
                ? customers.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name} ({c.code}) - Nợ: {formatVND(c.debt)}
                    </option>
                  ))
                : suppliers.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.name} ({s.code})
                    </option>
                  ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">
              Số Tiền Thu (VNĐ) <span className="req">*</span>
            </label>
            <input
              type="number"
              min="1"
              step="any"
              className="form-input mono"
              placeholder="VD: 1000000"
              value={receiptForm.amount}
              onChange={(e) => setReceiptForm({ ...receiptForm, amount: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Hình Thức Thu Tiền</label>
            <select
              className="form-select"
              value={receiptForm.method}
              onChange={(e) => setReceiptForm({ ...receiptForm, method: e.target.value })}
            >
              {PAYMENT_METHODS.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.label}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi Chú</label>
            <textarea
              className="form-textarea"
              rows={2}
              placeholder="Lý do thu tiền..."
              value={receiptForm.notes}
              onChange={(e) => setReceiptForm({ ...receiptForm, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Modal Lập Phiếu Chi */}
      <Modal
        isOpen={isCreatePaymentOpen}
        onClose={() => setIsCreatePaymentOpen(false)}
        title="Lập Phiếu Chi Tiền Từ Quỹ"
        size="md"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreatePaymentOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-warning" onClick={handleCreatePaymentSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Hoàn tất chi tiền'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreatePaymentSubmit}>
          <div className="form-group">
            <label className="form-label">Chi Tiền Cho Đối Tượng</label>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="pmtPartnerType"
                  value="supplier"
                  checked={paymentForm.partnerType === 'supplier'}
                  onChange={() => setPaymentForm({ ...paymentForm, partnerType: 'supplier', partnerId: suppliers[0]?.id || '' })}
                />
                <span>Nhà Cung Cấp</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="pmtPartnerType"
                  value="customer"
                  checked={paymentForm.partnerType === 'customer'}
                  onChange={() => setPaymentForm({ ...paymentForm, partnerType: 'customer', partnerId: customers[0]?.id || '' })}
                />
                <span>Khách Hàng (Hoàn tiền)</span>
              </label>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">
              Chọn {paymentForm.partnerType === 'supplier' ? 'Nhà Cung Cấp' : 'Khách Hàng'} <span className="req">*</span>
            </label>
            <select
              className="form-select"
              value={paymentForm.partnerId}
              onChange={(e) => setPaymentForm({ ...paymentForm, partnerId: e.target.value })}
              required
            >
              {paymentForm.partnerType === 'supplier'
                ? suppliers.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.name} ({s.code}) - Nợ cần trả: {formatVND(s.debt < 0 ? Math.abs(s.debt) : 0)}
                    </option>
                  ))
                : customers.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name} ({c.code})
                    </option>
                  ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">
              Số Tiền Chi (VNĐ) <span className="req">*</span>
            </label>
            <input
              type="number"
              min="1"
              step="any"
              className="form-input mono"
              placeholder="VD: 500000"
              value={paymentForm.amount}
              onChange={(e) => setPaymentForm({ ...paymentForm, amount: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Hình Thức Chi Tiền</label>
            <select
              className="form-select"
              value={paymentForm.method}
              onChange={(e) => setPaymentForm({ ...paymentForm, method: e.target.value })}
            >
              {PAYMENT_METHODS.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.label}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi Chú</label>
            <textarea
              className="form-textarea"
              rows={2}
              placeholder="Lý do chi tiền..."
              value={paymentForm.notes}
              onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Confirm Delete */}
      <ConfirmModal
        isOpen={isDeleteConfirmOpen}
        onClose={() => setIsDeleteConfirmOpen(false)}
        onConfirm={handleConfirmDelete}
        title="Xác nhận xóa phiếu"
        message={`Bạn có chắc chắn muốn xóa phiếu này? Số tiền sẽ được hoàn trả lại vào sổ công nợ tương ứng.`}
        confirmText="Xóa phiếu"
        isDanger={true}
        isLoading={submitting}
      />

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

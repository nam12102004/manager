import React, { useState, useEffect, useMemo, useRef } from 'react';
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
  Menu,
  ChevronLeft,
  ChevronRight,
  MapPin,
  MapPinned,
} from 'lucide-react';
import { formatVND, formatDate, getDebtStatus, parseJsonList, normalizeText, getCurrentMonthStr, getCurrentDateStr } from '../utils/formatters';
import { DEBT_ADJUST_REASONS, PAYMENT_METHODS } from '../utils/constants';
import { useNotification } from '../context/NotificationContext';
import SearchBar from '../components/common/SearchBar';
import SearchableSelect from '../components/common/SearchableSelect';
import SortDropdown from '../components/common/SortDropdown';
import TimeFilter from '../components/common/TimeFilter';
import Modal from '../components/common/Modal';
import Drawer from '../components/common/Drawer';
import EmptyState from '../components/common/EmptyState';
import PrintVoucherModal from '../components/common/PrintVoucherModal';
import { supplierService, cashBookService, settingService } from '../services';

const SUPPLIER_SORT_OPTIONS = [
  { value: 'default', label: 'Sắp xếp: Mặc định' },
  { value: 'payable_desc', label: 'Phải trả (Nợ NCC): Nhiều nhất → Ít nhất' },
  { value: 'payable_asc', label: 'Phải trả (Nợ NCC): Ít nhất → Nhiều nhất' },
  { value: 'receivable_desc', label: 'Phải thu (Ứng trước): Nhiều nhất → Ít nhất' },
  { value: 'receivable_asc', label: 'Phải thu (Ứng trước): Ít nhất → Nhiều nhất' },
];

export default function Suppliers() {
  const notify = useNotification();

  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRegion, setSelectedRegion] = useState('ALL');
  const [sortBy, setSortBy] = useState('default');
  const regionTabsRef = useRef(null);

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
  const [historyTimeMode, setHistoryTimeMode] = useState('month'); // 'month' | 'day'
  const [historyMonth, setHistoryMonth] = useState(getCurrentMonthStr());
  const [historyDate, setHistoryDate] = useState(getCurrentDateStr());
  const [historyLoading, setHistoryLoading] = useState(false);

  // Form states
  const [formData, setFormData] = useState({
    code: '',
    name: '',
    contactName: '',
    phone: '',
    email: '',
    address: '',
    region: '',
    bankAccount: '',
    taxNumber: '',
    initialDebt: 0,
    notes: '',
  });

  // Extract unique regions list
  const regionOptions = useMemo(() => {
    const set = new Set();
    suppliers.forEach((s) => {
      if (s.region && s.region.trim()) set.add(s.region.trim());
    });
    return Array.from(set).map((r) => ({ id: r, value: r, label: r }));
  }, [suppliers]);

  const allRegions = useMemo(() => {
    const set = new Set();
    suppliers.forEach((s) => {
      if (s.region && s.region.trim()) set.add(s.region.trim());
    });
    return Array.from(set);
  }, [suppliers]);

  // Filter suppliers by selected region & real-time search query
  const filteredSuppliers = useMemo(() => {
    let list = suppliers;
    if (selectedRegion === 'NONE') {
      list = list.filter((s) => !s.region || !s.region.trim());
    } else if (selectedRegion !== 'ALL') {
      list = list.filter((s) => (s.region || '').trim().toLowerCase() === selectedRegion.trim().toLowerCase());
    }

    if (searchQuery && searchQuery.trim()) {
      const q = normalizeText(searchQuery.trim());
      list = list.filter((s) => {
        const name = normalizeText(s.name || '');
        const code = normalizeText(s.code || '');
        const contact = normalizeText(s.contactName || '');
        const phone = normalizeText(parseJsonList(s.phonesJson) || '');
        const email = normalizeText(s.email || '');
        const address = normalizeText(parseJsonList(s.addressesJson) || '');
        const region = normalizeText(s.region || '');
        const bankAccount = normalizeText(s.bankAccount || '');
        return (
          name.includes(q) ||
          code.includes(q) ||
          contact.includes(q) ||
          phone.includes(q) ||
          email.includes(q) ||
          address.includes(q) ||
          region.includes(q) ||
          bankAccount.includes(q)
        );
      });
    }

    return list;
  }, [suppliers, selectedRegion, searchQuery]);

  // Sort filtered suppliers based on selected numeric debt metric
  const sortedSuppliers = useMemo(() => {
    let list = [...filteredSuppliers];
    if (sortBy === 'payable_desc') {
      list.sort((a, b) => {
        const payA = Number(a.debt || 0) < 0 ? Math.abs(Number(a.debt || 0)) : 0;
        const payB = Number(b.debt || 0) < 0 ? Math.abs(Number(b.debt || 0)) : 0;
        return payB - payA;
      });
    } else if (sortBy === 'payable_asc') {
      list.sort((a, b) => {
        const payA = Number(a.debt || 0) < 0 ? Math.abs(Number(a.debt || 0)) : 0;
        const payB = Number(b.debt || 0) < 0 ? Math.abs(Number(b.debt || 0)) : 0;
        return payA - payB;
      });
    } else if (sortBy === 'receivable_desc') {
      list.sort((a, b) => {
        const recA = Number(a.debt || 0) > 0 ? Number(a.debt || 0) : 0;
        const recB = Number(b.debt || 0) > 0 ? Number(b.debt || 0) : 0;
        return recB - recA;
      });
    } else if (sortBy === 'receivable_asc') {
      list.sort((a, b) => {
        const recA = Number(a.debt || 0) > 0 ? Number(a.debt || 0) : 0;
        const recB = Number(b.debt || 0) > 0 ? Number(b.debt || 0) : 0;
        return recA - recB;
      });
    }
    return list;
  }, [filteredSuppliers, sortBy]);

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

  // Load Suppliers via supplierService
  const loadSuppliers = async () => {
    setLoading(true);
    try {
      const data = await supplierService.getAll();
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
  }, []);

  // Open Create
  const handleOpenCreate = () => {
    setFormData({
      code: '',
      name: '',
      contactName: '',
      phone: '',
      email: '',
      address: '',
      region: '',
      bankAccount: '',
      taxNumber: '',
      initialDebt: 0,
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
      region: supplier.region || '',
      bankAccount: supplier.bankAccount || '',
      taxNumber: supplier.taxNumber || '',
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
    const targetPeriod = historyTimeMode === 'day' ? historyDate : historyMonth;
    loadDebtHistory(supplier.id, targetPeriod);
  };

  const loadDebtHistory = async (supplierId, period) => {
    setHistoryLoading(true);
    try {
      const records = await supplierService.getDebtHistory(supplierId, period);
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
      const phoneList = formData.phone ? formData.phone.split(/[,;/\n]+/).map((p) => p.trim()).filter(Boolean) : [];
      await supplierService.create({
        ...formData,
        phones: phoneList,
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
      const phoneList = formData.phone ? formData.phone.split(/[,;/\n]+/).map((p) => p.trim()).filter(Boolean) : [];
      await supplierService.update(selectedSupplier.id, {
        ...formData,
        phones: phoneList,
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

  // Total Payables & Receivables via supplierService from filteredSuppliers
  const { totalPayables, totalReceivables } = useMemo(() => {
    return supplierService.calculateSupplierSummary(filteredSuppliers);
  }, [filteredSuppliers]);

  const scrollTabs = (direction) => {
    if (regionTabsRef.current) {
      const scrollAmount = direction === 'left' ? -220 : 220;
      regionTabsRef.current.scrollBy({ left: scrollAmount, behavior: 'smooth' });
    }
  };

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

      {/* Filter Bar with 2-way Debt Totals & Sorting */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên NCC, mã NCC, SĐT, STK ngân hàng..."
          style={{ flex: 1, minWidth: '280px' }}
        />

        <SortDropdown
          value={sortBy}
          onChange={setSortBy}
          options={SUPPLIER_SORT_OPTIONS}
          style={{ minWidth: '240px' }}
        />

        <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', marginLeft: 'auto', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải trả:</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--warning-text)' }}>
              {formatVND(totalPayables)}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải thu:</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--info-text)' }}>
              {formatVND(totalReceivables)}
            </span>
          </div>
        </div>
      </div>

      {/* Region Tabs Strip (Excel-like Sheet Tabs Bar) */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          backgroundColor: '#f8fafc',
          border: '1px solid var(--border-color, #e2e8f0)',
          borderRadius: 'var(--radius, 8px) var(--radius, 8px) 0 0',
          marginBottom: 0,
          position: 'relative',
          userSelect: 'none',
        }}
      >
        {/* Left Menu / Hamburger Icon */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0.6rem 0.75rem',
            color: 'var(--text-muted, #64748b)',
            borderRight: '1px solid var(--border-color, #e2e8f0)',
            backgroundColor: '#ffffff',
            flexShrink: 0,
          }}
          title="Danh sách khu vực"
        >
          <Menu size={16} />
        </div>

        {/* Scroll Left Button */}
        <button
          type="button"
          onClick={() => scrollTabs('left')}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '28px',
            height: '100%',
            border: 'none',
            background: 'none',
            cursor: 'pointer',
            color: 'var(--text-muted, #64748b)',
            padding: '0 4px',
            flexShrink: 0,
          }}
          title="Cuộn sang trái"
        >
          <ChevronLeft size={16} />
        </button>

        {/* Scrollable Tabs Container */}
        <div
          ref={regionTabsRef}
          style={{
            display: 'flex',
            alignItems: 'center',
            overflowX: 'auto',
            whiteSpace: 'nowrap',
            scrollbarWidth: 'thin',
            WebkitOverflowScrolling: 'touch',
            flex: 1,
            gap: '2px',
          }}
          onWheel={(e) => {
            if (regionTabsRef.current && e.deltaY !== 0) {
              regionTabsRef.current.scrollLeft += e.deltaY;
            }
          }}
        >
          {/* Tab 1: Tổng */}
          <button
            type="button"
            onClick={() => setSelectedRegion('ALL')}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              padding: '0.65rem 1rem',
              fontSize: '0.875rem',
              fontWeight: selectedRegion === 'ALL' ? 700 : 500,
              color: selectedRegion === 'ALL' ? '#0f172a' : '#64748b',
              backgroundColor: selectedRegion === 'ALL' ? '#ffffff' : 'transparent',
              border: 'none',
              cursor: 'pointer',
              borderBottom: selectedRegion === 'ALL' ? '3px solid #16a34a' : '3px solid transparent',
              transition: 'all 0.15s ease',
              flexShrink: 0,
            }}
          >
            <span>Tổng</span>
            <span
              style={{
                fontSize: '0.75rem',
                padding: '1px 6px',
                borderRadius: '10px',
                backgroundColor: selectedRegion === 'ALL' ? '#dcfce7' : '#e2e8f0',
                color: selectedRegion === 'ALL' ? '#166534' : '#475569',
                fontWeight: 600,
              }}
            >
              {suppliers.length}
            </span>
          </button>

          {/* Dynamic Region Tabs */}
          {allRegions.map((region) => {
            const count = suppliers.filter((s) => (s.region || '').trim() === region.trim()).length;
            const isSelected = selectedRegion === region;
            return (
              <button
                key={region}
                type="button"
                onClick={() => setSelectedRegion(region)}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '0.65rem 1rem',
                  fontSize: '0.875rem',
                  fontWeight: isSelected ? 700 : 500,
                  color: isSelected ? '#0f172a' : '#475569',
                  backgroundColor: isSelected ? '#ffffff' : 'transparent',
                  border: 'none',
                  cursor: 'pointer',
                  borderBottom: isSelected ? '3px solid #16a34a' : '3px solid transparent',
                  transition: 'all 0.15s ease',
                  flexShrink: 0,
                  textTransform: 'uppercase',
                }}
              >
                <span>{region}</span>
                <span
                  style={{
                    fontSize: '0.75rem',
                    padding: '1px 6px',
                    borderRadius: '10px',
                    backgroundColor: isSelected ? '#dcfce7' : '#e2e8f0',
                    color: isSelected ? '#166534' : '#475569',
                    fontWeight: 600,
                  }}
                >
                  {count}
                </span>
              </button>
            );
          })}

          {/* Tab for suppliers without region if any */}
          {suppliers.some((s) => !s.region || !s.region.trim()) && (
            <button
              type="button"
              onClick={() => setSelectedRegion('NONE')}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '0.65rem 1rem',
                fontSize: '0.875rem',
                fontWeight: selectedRegion === 'NONE' ? 700 : 500,
                color: selectedRegion === 'NONE' ? '#0f172a' : '#64748b',
                backgroundColor: selectedRegion === 'NONE' ? '#ffffff' : 'transparent',
                border: 'none',
                cursor: 'pointer',
                borderBottom: selectedRegion === 'NONE' ? '3px solid #16a34a' : '3px solid transparent',
                transition: 'all 0.15s ease',
                flexShrink: 0,
                fontStyle: 'italic',
              }}
            >
              <span>Chưa phân khu vực</span>
              <span
                style={{
                  fontSize: '0.75rem',
                  padding: '1px 6px',
                  borderRadius: '10px',
                  backgroundColor: selectedRegion === 'NONE' ? '#dcfce7' : '#e2e8f0',
                  color: selectedRegion === 'NONE' ? '#166534' : '#475569',
                  fontWeight: 600,
                }}
              >
                {suppliers.filter((s) => !s.region || !s.region.trim()).length}
              </span>
            </button>
          )}
        </div>

        {/* Scroll Right Button */}
        <button
          type="button"
          onClick={() => scrollTabs('right')}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '28px',
            height: '100%',
            border: 'none',
            background: 'none',
            cursor: 'pointer',
            color: 'var(--text-muted, #64748b)',
            padding: '0 4px',
            flexShrink: 0,
          }}
          title="Cuộn sang phải"
        >
          <ChevronRight size={16} />
        </button>
      </div>

      {/* Suppliers Table */}
      {sortedSuppliers.length === 0 && !loading ? (
        <EmptyState
          icon={Truck}
          title={selectedRegion !== 'ALL' ? `Không có nhà cung cấp thuộc khu vực "${selectedRegion}"` : "Không tìm thấy nhà cung cấp"}
          description={selectedRegion !== 'ALL' ? 'Bạn có thể chọn khu vực khác hoặc chuyển về "Tổng".' : "Chưa có nhà cung cấp nào được lưu hoặc không có kết quả phù hợp với từ khóa tìm kiếm."}
          action={
            selectedRegion !== 'ALL' ? (
              <button className="btn btn-outline btn-sm" onClick={() => setSelectedRegion('ALL')}>
                <span>Xem tất cả khu vực</span>
              </button>
            ) : (
              <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
                <Plus size={15} />
                <span>Thêm nhà cung cấp ngay</span>
              </button>
            )
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã NCC</th>
                <th>Tên Nhà Cung Cấp</th>
                <th>Khu Vực</th>
                <th>Số Điện Thoại</th>
                <th>Ngân Hàng & STK</th>
                <th style={{ textAlign: 'right' }}>Phải Trả</th>
                <th style={{ textAlign: 'right' }}>Phải Thu</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {sortedSuppliers.map((s) => {
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
                      {s.region ? (
                        <span
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            padding: '3px 8px',
                            borderRadius: '4px',
                            backgroundColor: '#f1f5f9',
                            color: '#334155',
                            fontSize: '0.8125rem',
                            fontWeight: 600,
                          }}
                        >
                          <MapPin size={12} color="var(--primary)" />
                          <span>{s.region}</span>
                        </span>
                      ) : (
                        <span style={{ color: 'var(--text-muted)', fontSize: '0.8125rem' }}>—</span>
                      )}
                    </td>
                    <td>
                      {s.phonesJson ? (
                        <div style={{ fontSize: '0.8125rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                          <Phone size={13} color="var(--primary)" />
                          <span className="mono">{parseJsonList(s.phonesJson)}</span>
                        </div>
                      ) : (
                        '—'
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
                            {formatVND(s.debt)}
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
                Mã NCC
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

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">Số điện thoại (Nhập nhiều số cách nhau bởi phẩy hoặc /)</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 0912345678, 0987654321"
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
              <label className="form-label">Khu Vực</label>
              <SearchableSelect
                allowCustom={true}
                options={regionOptions}
                value={formData.region}
                onChange={(val) => setFormData({ ...formData, region: val })}
                placeholder="-- Chọn hoặc gõ khu vực mới --"
                searchPlaceholder="Tìm hoặc gõ khu vực mới..."
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

          <div className="form-group" style={{ marginBottom: '1rem' }}>
            <label className="form-label">Dư nợ ban đầu</label>
            <input
              type="number"
              className="form-input mono"
              value={formData.initialDebt}
              onChange={(e) => setFormData({ ...formData, initialDebt: e.target.value })}
            />
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

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">Số điện thoại (Nhập nhiều số cách nhau bởi phẩy hoặc /)</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 0912345678, 0987654321"
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
              <label className="form-label">Khu Vực</label>
              <SearchableSelect
                allowCustom={true}
                options={regionOptions}
                value={formData.region}
                onChange={(val) => setFormData({ ...formData, region: val })}
                placeholder="-- Chọn hoặc gõ khu vực mới --"
                searchPlaceholder="Tìm hoặc gõ khu vực mới..."
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
                <span>Tăng / Giảm độ lệch</span>
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
                Độ lệch
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
              <label className="form-label">Số Nợ Mới Thiết Lập</label>
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
              Số Tiền Chi <span className="req">*</span>
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
        <div style={{ marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
          <TimeFilter
            mode={historyTimeMode}
            onModeChange={(newMode) => {
              setHistoryTimeMode(newMode);
              if (selectedSupplier) {
                const p = newMode === 'day' ? historyDate : historyMonth;
                loadDebtHistory(selectedSupplier.id, p);
              }
            }}
            month={historyMonth}
            onMonthChange={(m) => {
              setHistoryMonth(m);
              if (selectedSupplier) loadDebtHistory(selectedSupplier.id, m);
            }}
            date={historyDate}
            onDateChange={(d) => {
              setHistoryDate(d);
              if (selectedSupplier) loadDebtHistory(selectedSupplier.id, d);
            }}
            showAll={false}
            showRange={false}
          />
        </div>

        {historyLoading ? (
          <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
            Đang tải dữ liệu sổ nợ NCC...
          </p>
        ) : debtHistoryRecords.length === 0 ? (
          <EmptyState
            icon={History}
            title="Chưa có lịch sử công nợ"
            description={
              historyTimeMode === 'day'
                ? `Không có giao dịch công nợ nào trong ngày ${historyDate}.`
                : `Không có giao dịch công nợ nào trong tháng ${historyMonth}.`
            }
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
                            ? 'Nhập'
                            : r.sourceType === 'payment'
                            ? 'Chi tiền'
                            : 'Điều chỉnh'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatVND(Math.abs(r.beforeDebt))}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                        {formatVND(Math.abs(r.delta))}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">
                        {formatVND(Math.abs(r.afterDebt))}
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

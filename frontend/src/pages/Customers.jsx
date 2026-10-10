import React, { useState, useEffect, useMemo, useRef, useCallback } from 'react';
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
  Menu,
  ChevronLeft,
  ChevronRight,
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
import Pagination from '../components/common/Pagination';
import { customerService, cashBookService, settingService } from '../services';

const CUSTOMER_SORT_OPTIONS = [
  { value: 'default', label: 'Sắp xếp: Mặc định' },
  { value: 'debt_desc', label: 'Công nợ: Nợ nhiều nhất → Ít nhất' },
  { value: 'debt_asc', label: 'Công nợ: Nợ ít nhất → Nhiều nhất' },
];

export default function Customers({ onQuickAction }) {
  const notify = useNotification();

  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRegion, setSelectedRegion] = useState('ALL'); // 'ALL' or specific region string
  const [sortBy, setSortBy] = useState('default');
  const regionTabsRef = useRef(null);

  // Pagination states (15 items per page)
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [totalReceivables, setTotalReceivables] = useState(0);
  const [totalPayables, setTotalPayables] = useState(0);
  const [allRegions, setAllRegions] = useState([]);
  const isFirstFilterChange = useRef(true);

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
    initialDebt: 0,
    notes: '',
  });

  // Extract unique regions list
  const regionOptions = useMemo(() => {
    return allRegions.map((r) => ({ id: r, value: r, label: r }));
  }, [allRegions]);

  const filteredCustomers = customers;
  const sortedCustomers = customers;

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

  const loadRegions = async () => {
    try {
      const regions = await customerService.getRegions();
      if (Array.isArray(regions)) {
        setAllRegions(regions);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Load Customers with server-side pagination (15 items/page)
  const loadCustomers = useCallback(async (page = currentPage) => {
    setLoading(true);
    try {
      const res = await customerService.getAll({
        page,
        pageSize: 15,
        q: searchQuery || undefined,
        region: selectedRegion !== 'ALL' ? selectedRegion : undefined,
        sortBy: sortBy !== 'default' ? sortBy : undefined,
      });

      if (res && res.items) {
        setCustomers(res.items);
        setCurrentPage(res.page || page);
        setTotalPages(res.totalPages || 1);
        setTotalCount(res.totalCount || 0);
        setTotalReceivables(res.totalReceivables || 0);
        setTotalPayables(res.totalPayables || 0);
      } else if (Array.isArray(res)) {
        setCustomers(res);
        setTotalCount(res.length);
        setTotalPages(Math.ceil(res.length / 15) || 1);
      }
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách khách hàng');
    } finally {
      setLoading(false);
    }
  }, [currentPage, searchQuery, selectedRegion, sortBy, notify]);

  // Initial load
  useEffect(() => {
    loadRegions();
    settingService.getSettings().then((res) => setOwnerInfo(res)).catch(() => {});
  }, []);

  // Fetch when page changes
  useEffect(() => {
    loadCustomers(currentPage);
  }, [currentPage]);

  // Reset to page 1 when filters or search change
  useEffect(() => {
    if (isFirstFilterChange.current) {
      isFirstFilterChange.current = false;
      return;
    }
    if (currentPage === 1) {
      loadCustomers(1);
    } else {
      setCurrentPage(1);
    }
  }, [selectedRegion, sortBy, searchQuery]);

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
      initialDebt: 0,
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
      region: customer.region || '',
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
    const targetPeriod = historyTimeMode === 'day' ? historyDate : historyMonth;
    loadDebtHistory(customer.id, targetPeriod);
  };

  const loadDebtHistory = async (customerId, period) => {
    setHistoryLoading(true);
    try {
      const records = await customerService.getDebtHistory(customerId, period);
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
      const phoneList = formData.phone ? formData.phone.split(/[,;/\n]+/).map((p) => p.trim()).filter(Boolean) : [];
      await customerService.create({
        ...formData,
        phones: phoneList,
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
      const phoneList = formData.phone ? formData.phone.split(/[,;/\n]+/).map((p) => p.trim()).filter(Boolean) : [];
      await customerService.update(selectedCustomer.id, {
        ...formData,
        phones: phoneList,
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
            <Users size={28} color="var(--primary)" />
            <span>Quản Lý Khách Hàng & Công Nợ</span>
          </h1>
          <p className="page-subtitle">
            Theo dõi danh sách khách hàng và sổ nợ hai chiều
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

      {/* Filter Bar with 2-way Debt Totals & Sorting */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên khách, mã KH, số điện thoại, email..."
          style={{ flex: 1, minWidth: '280px' }}
        />

        <SortDropdown
          value={sortBy}
          onChange={setSortBy}
          options={CUSTOMER_SORT_OPTIONS}
          style={{ minWidth: '240px' }}
        />

        <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', marginLeft: 'auto', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải thu:</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--danger)' }}>
              {formatVND(totalReceivables)}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>Phải trả:</span>
            <span className="mono" style={{ fontSize: '1.0625rem', fontWeight: 800, color: 'var(--success)' }}>
              {formatVND(totalPayables)}
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
          {/* Tab 1: Công nợ tổng (Tất cả) */}
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
              {totalCount}
            </span>
          </button>

          {/* Dynamic Region Tabs */}
          {allRegions.map((region) => {
            const isSelected = selectedRegion === region;
            const count = selectedRegion === 'ALL'
              ? customers.filter((c) => (c.region || '').trim() === region.trim()).length
              : isSelected
              ? totalCount
              : 0;
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

          {/* Tab for customers without region if any */}
          {(selectedRegion === 'NONE' || customers.some((c) => !c.region || !c.region.trim())) && (
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
                {selectedRegion === 'NONE' ? totalCount : 0}
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

      {/* Customers Table */}
      {sortedCustomers.length === 0 && !loading ? (
        <EmptyState
          icon={Users}
          title={selectedRegion !== 'ALL' ? `Không có khách hàng thuộc khu vực "${selectedRegion}"` : "Không tìm thấy khách hàng"}
          description={selectedRegion !== 'ALL' ? 'Bạn có thể chọn khu vực khác hoặc chuyển về "Công nợ tổng".' : "Chưa có khách hàng nào được tạo hoặc không có kết quả phù hợp."}
          action={
            selectedRegion !== 'ALL' ? (
              <button className="btn btn-outline btn-sm" onClick={() => setSelectedRegion('ALL')}>
                <span>Xem tất cả khu vực</span>
              </button>
            ) : (
              <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
                <Plus size={15} />
                <span>Thêm khách hàng ngay</span>
              </button>
            )
          }
        />
      ) : (
        <div className="table-responsive" style={{ borderTop: 'none', borderRadius: '0 0 var(--radius, 8px) var(--radius, 8px)' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã KH</th>
                <th>Tên Khách Hàng</th>
                <th>Khu Vực</th>
                <th>Số Điện Thoại</th>
                <th>Địa Chỉ</th>
                <th style={{ textAlign: 'right' }}>Phải Thu</th>
                <th style={{ textAlign: 'right' }}>Phải Trả</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {sortedCustomers.map((c) => {
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
                      {c.region ? (
                        <span
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            padding: '2px 8px',
                            fontSize: '0.75rem',
                            fontWeight: 600,
                            borderRadius: '4px',
                            backgroundColor: '#eff6ff',
                            color: '#1e40af',
                            border: '1px solid #bfdbfe',
                          }}
                        >
                          <MapPinned size={11} />
                          <span>{c.region}</span>
                        </span>
                      ) : (
                        <span style={{ color: 'var(--text-muted)', fontSize: '0.8125rem' }}>—</span>
                      )}
                    </td>
                    <td>
                      {c.phonesJson ? (
                        <div style={{ fontSize: '0.8125rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                          <Phone size={13} color="var(--primary)" />
                          <span className="mono">{parseJsonList(c.phonesJson)}</span>
                        </div>
                      ) : (
                        '—'
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
                            {formatVND(c.debt)}
                          </span>
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

      {/* Pagination (15 items per page) */}
      <Pagination
        currentPage={currentPage}
        totalPages={totalPages}
        totalCount={totalCount}
        pageSize={15}
        onPageChange={(p) => setCurrentPage(p)}
        disabled={loading}
        itemLabel="khách hàng"
      />

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
                Mã Khách Hàng
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
              <label className="form-label">Số điện thoại (Nhập nhiều số cách nhau bởi phẩy hoặc /)</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 0987654321, 0912345678"
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
                placeholder="VD: 123 Nguyễn Trãi, Quận 1, TP.HCM"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.875rem' }}>
            Thiết Lập Công Nợ Ban Đầu
          </h4>

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

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">Số điện thoại (Nhập nhiều số cách nhau bởi phẩy hoặc /)</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 0987654321, 0912345678"
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
              {formatVND(Math.abs(selectedCustomer?.debt || 0))}
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
                <span>Tăng / Giảm độ lệch</span>
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
                Độ Lệch Công Nợ
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
            Số nợ hiện tại cần thu: <strong>{formatVND(Math.abs(selectedCustomer?.debt || 0))}</strong>
          </div>

          <div className="form-group">
            <label className="form-label">
              Số Tiền Thu <span className="req">*</span>
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
        <div style={{ marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
          <TimeFilter
            mode={historyTimeMode}
            onModeChange={(newMode) => {
              setHistoryTimeMode(newMode);
              if (selectedCustomer) {
                const p = newMode === 'day' ? historyDate : historyMonth;
                loadDebtHistory(selectedCustomer.id, p);
              }
            }}
            month={historyMonth}
            onMonthChange={(m) => {
              setHistoryMonth(m);
              if (selectedCustomer) loadDebtHistory(selectedCustomer.id, m);
            }}
            date={historyDate}
            onDateChange={(d) => {
              setHistoryDate(d);
              if (selectedCustomer) loadDebtHistory(selectedCustomer.id, d);
            }}
            showAll={false}
            showRange={false}
          />
        </div>

        {historyLoading ? (
          <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
            Đang tải dữ liệu sổ nợ...
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
                            ? 'Xuất'
                            : r.sourceType === 'receipt'
                            ? 'Thu tiền'
                            : 'Điều chỉnh'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatVND(Math.abs(r.beforeDebt))}
                      </td>
                      <td
                        style={{
                          textAlign: 'right',
                          fontWeight: 700,
                          color: isIncrease ? 'var(--danger)' : 'var(--success)',
                        }}
                        className="mono"
                      >
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
        type={printVoucher?.type || 'receipt'}
        ownerInfo={ownerInfo}
      />
    </div>
  );
}

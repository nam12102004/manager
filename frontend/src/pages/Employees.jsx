import React, { useState, useEffect, useCallback } from 'react';
import {
  UserCheck,
  Plus,
  Trash2,
  RefreshCw,
  Eye,
  Printer,
  FileText,
  FileSpreadsheet,
  Download,
  Phone,
  Calendar,
  ArrowUpRight,
} from 'lucide-react';
import {
  formatVND,
  formatNumber,
  formatDate,
  getCurrentMonthStr,
  getCurrentDateStr,
} from '../utils/formatters';
import { useNotification } from '../context/NotificationContext';
import SearchBar from '../components/common/SearchBar';
import TimeFilter from '../components/common/TimeFilter';
import Modal from '../components/common/Modal';
import ConfirmModal from '../components/common/ConfirmModal';
import EmptyState from '../components/common/EmptyState';
import { employeeService, exportService, warehouseService, settingService } from '../services';
import { generateExportHtml, printInNewTab } from '../utils/printVoucher';

export default function Employees() {
  const notify = useNotification();

  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(false);
  const [exportingExcel, setExportingExcel] = useState(false);
  const [modalExportingExcel, setModalExportingExcel] = useState(false);
  const [rowExportingId, setRowExportingId] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');

  // Page-level Time Filter
  const [timeMode, setTimeMode] = useState('month'); // 'month' | 'day' | 'range' | 'all'
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonthStr());
  const [selectedDate, setSelectedDate] = useState(getCurrentDateStr());
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  // Create & Delete Modals
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const [createForm, setCreateForm] = useState({
    name: '',
    phone: '',
    notes: '',
  });

  // Employee Exports Modal state (when clicking on employee name)
  const [isExportsModalOpen, setIsExportsModalOpen] = useState(false);
  const [modalEmployee, setModalEmployee] = useState(null);
  const [employeeExports, setEmployeeExports] = useState([]);
  const [exportsLoading, setExportsLoading] = useState(false);

  // Modal-level Time Filter (independent filter inside the employee exports modal)
  const [modalTimeMode, setModalTimeMode] = useState('month');
  const [modalMonth, setModalMonth] = useState(getCurrentMonthStr());
  const [modalDate, setModalDate] = useState(getCurrentDateStr());
  const [modalFromDate, setModalFromDate] = useState('');
  const [modalToDate, setModalToDate] = useState('');

  // Voucher Detail Modal (when clicking a voucher inside the employee modal)
  const [selectedVoucher, setSelectedVoucher] = useState(null);
  const [isVoucherDetailOpen, setIsVoucherDetailOpen] = useState(false);
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [ownerInfo, setOwnerInfo] = useState(null);

  useEffect(() => {
    warehouseService.getWarehouses().then((res) => {
      if (Array.isArray(res)) setWarehouses(res);
    });
    settingService
      .getSettings()
      .then((res) => setOwnerInfo(res))
      .catch(() => {});
  }, []);

  // Build time query params helper
  const buildTimeParams = (mode, month, date, from, to) => {
    const params = {};
    if (mode === 'month' && month) {
      params.month = month;
    } else if (mode === 'day' && date) {
      params.date = date;
    } else if (mode === 'range') {
      if (from) params.fromDate = from;
      if (to) params.toDate = to;
    }
    return params;
  };

  // Load Employees list with stats filtered by page time filter
  const loadEmployees = useCallback(async () => {
    setLoading(true);
    try {
      const params = {
        q: searchQuery.trim() || undefined,
        ...buildTimeParams(timeMode, selectedMonth, selectedDate, fromDate, toDate),
      };
      const data = await employeeService.getAll(params);
      setEmployees(Array.isArray(data) ? data : []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách nhân viên');
    } finally {
      setLoading(false);
    }
  }, [searchQuery, timeMode, selectedMonth, selectedDate, fromDate, toDate, notify]);

  useEffect(() => {
    loadEmployees();
  }, [loadEmployees]);

  // Load Export Vouchers for the selected employee in the modal
  const loadEmployeeExports = useCallback(
    async (empId, mode, month, date, from, to) => {
      if (!empId) return;
      setExportsLoading(true);
      try {
        const params = {
          employeeId: empId,
          all: true,
          ...buildTimeParams(mode, month, date, from, to),
        };
        const res = await exportService.getAll(params);
        if (Array.isArray(res)) {
          setEmployeeExports(res);
        } else if (res && Array.isArray(res.items)) {
          setEmployeeExports(res.items);
        } else {
          setEmployeeExports([]);
        }
      } catch (err) {
        notify.error(err.message || 'Không thể tải danh sách phiếu xuất của nhân viên');
      } finally {
        setExportsLoading(false);
      }
    },
    [notify]
  );

  // Reload modal exports whenever modal time filter changes
  useEffect(() => {
    if (isExportsModalOpen && modalEmployee) {
      loadEmployeeExports(
        modalEmployee.id,
        modalTimeMode,
        modalMonth,
        modalDate,
        modalFromDate,
        modalToDate
      );
    }
  }, [
    isExportsModalOpen,
    modalEmployee,
    modalTimeMode,
    modalMonth,
    modalDate,
    modalFromDate,
    modalToDate,
    loadEmployeeExports,
  ]);

  // Open Create Employee Modal
  const handleOpenCreate = () => {
    setCreateForm({
      name: '',
      phone: '',
      notes: '',
    });
    setIsCreateOpen(true);
  };

  // Submit Create Employee
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    if (!createForm.name.trim()) {
      notify.warning('Vui lòng nhập tên nhân viên');
      return;
    }
    setSubmitting(true);
    try {
      const created = await employeeService.create(createForm);
      notify.success(`Đã thêm nhân viên "${created.name}" thành công!`);
      setIsCreateOpen(false);
      loadEmployees();
    } catch (err) {
      notify.error(err.message || 'Thêm nhân viên thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Delete Confirm Modal
  const handleOpenDelete = (emp) => {
    setSelectedEmployee(emp);
    setIsDeleteOpen(true);
  };

  // Confirm Delete Employee
  const handleConfirmDelete = async () => {
    if (!selectedEmployee) return;
    setSubmitting(true);
    try {
      await employeeService.delete(selectedEmployee.id, selectedEmployee.name);
      notify.success(`Đã xóa nhân viên "${selectedEmployee.name}"`);
      setIsDeleteOpen(false);
      setSelectedEmployee(null);
      loadEmployees();
    } catch (err) {
      notify.error(err.message || 'Xóa nhân viên thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Exports Modal when clicking on Employee Name
  const handleOpenEmployeeExports = (emp) => {
    setModalEmployee(emp);
    // Sync initial modal time filter with current page time filter
    setModalTimeMode(timeMode);
    setModalMonth(selectedMonth);
    setModalDate(selectedDate);
    setModalFromDate(fromDate);
    setModalToDate(toDate);
    setIsExportsModalOpen(true);
  };

  // View details of a single export voucher
  const handleOpenVoucherDetail = async (voucher) => {
    try {
      const full = await exportService.getById(voucher.id);
      setSelectedVoucher(full || voucher);
    } catch {
      setSelectedVoucher(voucher);
    }
    setIsVoucherDetailOpen(true);
  };

  // Print export voucher
  const handlePrintVoucher = (voucher) => {
    if (!voucher) return;
    const html = generateExportHtml({ exportData: voucher, ownerInfo });
    printInNewTab(html);
  };

  // Export Excel for ALL employees (from page header)
  const handleExportAllExcel = async () => {
    setExportingExcel(true);
    try {
      const params = {
        ...buildTimeParams(timeMode, selectedMonth, selectedDate, fromDate, toDate),
      };
      const filename = await employeeService.exportExcel(params, 'BaoCao_DoanhSo_NhanVien.xlsx');
      notify.success(`Đã xuất báo cáo doanh số Excel "${filename}" thành công!`);
    } catch (err) {
      notify.error(err.message || 'Xuất Excel thất bại');
    } finally {
      setExportingExcel(false);
    }
  };

  // Export Excel for a SINGLE employee from modal
  const handleExportModalEmployeeExcel = async () => {
    if (!modalEmployee) return;
    setModalExportingExcel(true);
    try {
      const params = {
        employeeId: modalEmployee.id,
        ...buildTimeParams(modalTimeMode, modalMonth, modalDate, modalFromDate, modalToDate),
      };
      const defaultName = `DoanhSo_SP_${modalEmployee.name.replace(/\s+/g, '_')}.xlsx`;
      const filename = await employeeService.exportExcel(params, defaultName);
      notify.success(`Đã xuất Excel doanh số & sản phẩm của nhân viên "${modalEmployee.name}"!`);
    } catch (err) {
      notify.error(err.message || 'Xuất Excel nhân viên thất bại');
    } finally {
      setModalExportingExcel(false);
    }
  };

  // Quick Export Excel for a SINGLE employee from table row
  const handleExportRowEmployeeExcel = async (emp) => {
    setRowExportingId(emp.id);
    try {
      const params = {
        employeeId: emp.id,
        ...buildTimeParams(timeMode, selectedMonth, selectedDate, fromDate, toDate),
      };
      const defaultName = `DoanhSo_SP_${emp.name.replace(/\s+/g, '_')}.xlsx`;
      const filename = await employeeService.exportExcel(params, defaultName);
      notify.success(`Đã xuất Excel doanh số & sản phẩm của "${emp.name}"!`);
    } catch (err) {
      notify.error(err.message || 'Xuất Excel nhân viên thất bại');
    } finally {
      setRowExportingId(null);
    }
  };

  // Page-level summary metrics
  const totalEmployees = employees.length;
  const totalPageExports = employees.reduce((sum, e) => sum + Number(e.exportCount || 0), 0);
  const totalPageValue = employees.reduce((sum, e) => sum + Number(e.totalExportValue || 0), 0);

  // Modal-level summary metrics (active vouchers vs all)
  const activeModalExports = employeeExports.filter((v) => v.status !== 'cancelled');
  const modalSubtotal = activeModalExports.reduce((sum, v) => sum + Number(v.subtotalSale || 0), 0);
  const modalDiscount = activeModalExports.reduce((sum, v) => sum + Number(v.discountAmount || 0), 0);
  const modalTotalSale = activeModalExports.reduce((sum, v) => sum + Number(v.totalSale || 0), 0);
  const modalTotalPaid = activeModalExports.reduce((sum, v) => sum + Number(v.paidAmount || 0), 0);
  const modalTotalUnpaid = activeModalExports.reduce((sum, v) => sum + Number(v.unpaidAmount || 0), 0);

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <UserCheck size={28} color="var(--primary)" />
            <span>Nhân Viên</span>
          </h1>
          <p className="page-subtitle">
            Quản lý nhân viên, xuất Excel doanh số & sản phẩm bán ra theo từng nhân viên hoặc toàn bộ
          </p>
        </div>
        <div className="page-actions">
          <button
            className="btn btn-outline"
            style={{
              gap: '6px',
              borderColor: '#10b981',
              color: '#059669',
              background: 'rgba(16, 185, 129, 0.06)',
            }}
            onClick={handleExportAllExcel}
            disabled={exportingExcel || employees.length === 0}
            title="Xuất file Excel tổng hợp doanh số và sản phẩm bán ra của tất cả nhân viên"
          >
            {exportingExcel ? (
              <RefreshCw size={16} className="animate-spin" />
            ) : (
              <FileSpreadsheet size={16} />
            )}
            <span>{exportingExcel ? 'Đang xuất Excel...' : 'Xuất Excel Doanh Số'}</span>
          </button>
          <button className="btn btn-outline" onClick={loadEmployees} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Thêm nhân viên</span>
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="stats-grid" style={{ marginBottom: '1.25rem' }}>
        <div className="stat-card">
          <div className="stat-content">
            <div className="stat-label">Tổng số nhân viên</div>
            <div className="stat-value">{totalEmployees}</div>
            <div className="stat-sub">Nhân sự trong hệ thống</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <div className="stat-label">Số phiếu xuất (theo kỳ lọc)</div>
            <div className="stat-value" style={{ color: 'var(--primary)' }}>
              {formatNumber(totalPageExports)}
            </div>
            <div className="stat-sub">Tổng phiếu xuất gán nhân viên</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <div className="stat-label">Tổng giá trị xuất (theo kỳ lọc)</div>
            <div className="stat-value mono" style={{ color: 'var(--success)' }}>
              {formatVND(totalPageValue)}
            </div>
            <div className="stat-sub">Doanh số bán ra các phiếu hợp lệ</div>
          </div>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên nhân viên, số điện thoại, ghi chú..."
          style={{ flex: 1, minWidth: '260px' }}
        />

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

      {/* Employees Table */}
      {employees.length === 0 && !loading ? (
        <EmptyState
          icon={UserCheck}
          title="Chưa có nhân viên nào"
          description="Hãy thêm nhân viên mới để gán vào phiếu xuất hàng và theo dõi tổng giá trị xuất kho."
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>Thêm nhân viên đầu tiên</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                <th>Tên Nhân Viên (Ấn để xem phiếu & sản phẩm)</th>
                <th>Số Điện Thoại</th>
                <th>Ghi Chú</th>
                <th style={{ textAlign: 'center' }}>Số Phiếu Xuất</th>
                <th style={{ textAlign: 'right' }}>Tổng Doanh Số</th>
                <th>Ngày Tạo</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {employees.map((emp, idx) => (
                <tr key={emp.id}>
                  <td style={{ textAlign: 'center', color: 'var(--text-muted)' }} className="mono">
                    {idx + 1}
                  </td>
                  <td>
                    <div
                      onClick={() => handleOpenEmployeeExports(emp)}
                      title="Bấm để xem chi tiết phiếu xuất hàng, doanh số và sản phẩm bán ra của nhân viên này"
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.625rem',
                        cursor: 'pointer',
                        padding: '0.2rem 0',
                      }}
                    >
                      <div
                        style={{
                          width: '34px',
                          height: '34px',
                          borderRadius: '50%',
                          background: 'rgba(37, 99, 235, 0.15)',
                          color: 'var(--primary)',
                          border: '1px solid rgba(37, 99, 235, 0.3)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          fontSize: '0.875rem',
                          flexShrink: 0,
                        }}
                      >
                        {emp.name ? emp.name.charAt(0).toUpperCase() : 'N'}
                      </div>
                      <div>
                        <span
                          style={{
                            fontWeight: 700,
                            fontSize: '0.9375rem',
                            color: 'var(--primary)',
                            textDecoration: 'underline',
                          }}
                        >
                          {emp.name}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td className="mono" style={{ fontSize: '0.875rem' }}>
                    {emp.phone || <span style={{ color: 'var(--text-muted)' }}>—</span>}
                  </td>
                  <td style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
                    {emp.notes || <span style={{ color: 'var(--text-muted)' }}>—</span>}
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <span
                      className={`badge ${emp.exportCount > 0 ? 'badge-primary' : 'badge-neutral'} mono`}
                      style={{ cursor: 'pointer' }}
                      onClick={() => handleOpenEmployeeExports(emp)}
                      title="Bấm để xem danh sách phiếu xuất"
                    >
                      {formatNumber(emp.exportCount || 0)} phiếu
                    </span>
                  </td>
                  <td
                    style={{
                      textAlign: 'right',
                      fontWeight: 700,
                      color: emp.totalExportValue > 0 ? 'var(--primary)' : 'var(--text-muted)',
                      cursor: 'pointer',
                    }}
                    className="mono"
                    onClick={() => handleOpenEmployeeExports(emp)}
                    title="Bấm để xem chi tiết doanh số & mặt hàng"
                  >
                    {formatVND(emp.totalExportValue || 0)}
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
                    {formatDate(emp.createdAt, true)}
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                      <button
                        className="btn btn-outline btn-sm"
                        style={{ fontSize: '0.75rem', padding: '4px 8px', gap: '4px' }}
                        title="Xem phiếu xuất & sản phẩm bán ra"
                        onClick={() => handleOpenEmployeeExports(emp)}
                      >
                        <FileText size={14} />
                        <span>Xem chi tiết</span>
                      </button>
                      <button
                        className="btn btn-outline btn-icon"
                        style={{ width: '30px', height: '30px', color: '#059669', borderColor: '#10b981' }}
                        title="Xuất Excel doanh số & sản phẩm của nhân viên này"
                        onClick={() => handleExportRowEmployeeExcel(emp)}
                        disabled={rowExportingId === emp.id}
                      >
                        {rowExportingId === emp.id ? (
                          <RefreshCw size={14} className="animate-spin" />
                        ) : (
                          <FileSpreadsheet size={15} />
                        )}
                      </button>
                      <button
                        className="btn btn-outline btn-icon"
                        style={{ width: '30px', height: '30px', color: 'var(--danger)' }}
                        title="Xóa nhân viên"
                        onClick={() => handleOpenDelete(emp)}
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal Tạo Nhân Viên Mới */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Thêm Nhân Viên Mới"
        maxWidth="480px"
        footer={
          <>
            <button
              type="button"
              className="btn btn-outline"
              onClick={() => setIsCreateOpen(false)}
              disabled={submitting}
            >
              Hủy
            </button>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleCreateSubmit}
              disabled={submitting}
            >
              {submitting ? 'Đang tạo...' : 'Tạo nhân viên'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div className="form-group" style={{ marginBottom: '1rem' }}>
            <label className="form-label">
              Tên Nhân Viên <span className="req">*</span>
            </label>
            <input
              type="text"
              className="form-control"
              placeholder="VD: Nguyễn Văn A..."
              value={createForm.name}
              onChange={(e) => setCreateForm({ ...createForm, name: e.target.value })}
              required
              autoFocus
            />
          </div>

          <div className="form-group" style={{ marginBottom: '1rem' }}>
            <label className="form-label">Số Điện Thoại (Không bắt buộc)</label>
            <input
              type="text"
              className="form-control mono"
              placeholder="VD: 0901234567"
              value={createForm.phone}
              onChange={(e) => setCreateForm({ ...createForm, phone: e.target.value })}
            />
          </div>

          <div className="form-group" style={{ marginBottom: '0.5rem' }}>
            <label className="form-label">Ghi Chú (Không bắt buộc)</label>
            <textarea
              className="form-textarea"
              rows={2}
              placeholder="Ghi chú chức vụ, khu vực phụ trách..."
              value={createForm.notes}
              onChange={(e) => setCreateForm({ ...createForm, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Modal Xác Nhận Xóa Nhân Viên */}
      <ConfirmModal
        isOpen={isDeleteOpen}
        onClose={() => setIsDeleteOpen(false)}
        onConfirm={handleConfirmDelete}
        title="Xác nhận xóa nhân viên"
        message={`Bạn có chắc chắn muốn xóa nhân viên "${selectedEmployee?.name}"? Các phiếu xuất đã lập trước đó vẫn sẽ giữ nguyên tên nhân viên trên hóa đơn.`}
        confirmText="Xác nhận xóa"
        confirmType="danger"
        isDanger={true}
        loading={submitting}
        isLoading={submitting}
      />

      {/* Modal Hiển Thị Phiếu Xuất Hàng & Tổng Giá Trị & Xuất Excel Khi Ấn Vào Tên Nhân Viên */}
      <Modal
        isOpen={isExportsModalOpen}
        onClose={() => setIsExportsModalOpen(false)}
        title={`Phiếu Xuất Hàng & Doanh Số - Nhân Viên: ${modalEmployee?.name || ''}`}
        size="xl"
        footer={
          <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center' }}>
            <button
              type="button"
              className="btn btn-outline"
              style={{
                gap: '6px',
                borderColor: '#10b981',
                color: '#059669',
                background: 'rgba(16, 185, 129, 0.08)',
                fontWeight: 600,
              }}
              onClick={handleExportModalEmployeeExcel}
              disabled={modalExportingExcel || employeeExports.length === 0}
            >
              {modalExportingExcel ? (
                <RefreshCw size={15} className="animate-spin" />
              ) : (
                <FileSpreadsheet size={15} />
              )}
              <span>
                {modalExportingExcel
                  ? 'Đang tạo Excel...'
                  : `Xuất Excel Doanh Số & SP (${modalEmployee?.name || ''})`}
              </span>
            </button>

            <button className="btn btn-primary" onClick={() => setIsExportsModalOpen(false)}>
              Đóng
            </button>
          </div>
        }
      >
        {modalEmployee && (
          <div>
            {/* Filter Bar inside Modal */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: '0.75rem',
                padding: '0.875rem 1rem',
                background: 'var(--bg-tertiary)',
                borderRadius: 'var(--radius-md)',
                marginBottom: '1rem',
                border: '1px solid var(--border-color)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                <span style={{ fontWeight: 700, fontSize: '0.875rem' }}>Lọc theo thời gian:</span>
                <TimeFilter
                  mode={modalTimeMode}
                  onModeChange={setModalTimeMode}
                  month={modalMonth}
                  onMonthChange={setModalMonth}
                  date={modalDate}
                  onDateChange={setModalDate}
                  fromDate={modalFromDate}
                  onFromDateChange={setModalFromDate}
                  toDate={modalToDate}
                  onToDateChange={setModalToDate}
                />
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  style={{
                    gap: '4px',
                    borderColor: '#10b981',
                    color: '#059669',
                  }}
                  onClick={handleExportModalEmployeeExcel}
                  disabled={modalExportingExcel || employeeExports.length === 0}
                  title="Xuất file Excel gồm 3 Sheet: Doanh số phiếu xuất, Sản phẩm bán ra, Chi tiết từng mặt hàng"
                >
                  {modalExportingExcel ? (
                    <RefreshCw size={14} className="animate-spin" />
                  ) : (
                    <FileSpreadsheet size={14} />
                  )}
                  <span>Xuất Excel</span>
                </button>

                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={() =>
                    loadEmployeeExports(
                      modalEmployee.id,
                      modalTimeMode,
                      modalMonth,
                      modalDate,
                      modalFromDate,
                      modalToDate
                    )
                  }
                  disabled={exportsLoading}
                >
                  <RefreshCw size={14} className={exportsLoading ? 'animate-spin' : ''} />
                  <span>Làm mới</span>
                </button>
              </div>
            </div>

            {/* Summary Totals Banner inside Modal */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                gap: '0.875rem',
                marginBottom: '1.25rem',
              }}
            >
              <div
                style={{
                  padding: '0.875rem 1rem',
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border-color)',
                }}
              >
                <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
                  Số phiếu xuất hợp lệ
                </div>
                <div style={{ fontSize: '1.25rem', fontWeight: 800, marginTop: '0.25rem' }} className="mono">
                  {formatNumber(activeModalExports.length)}{' '}
                  <span style={{ fontSize: '0.8125rem', fontWeight: 500, color: 'var(--text-muted)' }}>
                    / {formatNumber(employeeExports.length)} phiếu
                  </span>
                </div>
              </div>

              <div
                style={{
                  padding: '0.875rem 1rem',
                  borderRadius: 'var(--radius-md)',
                  background: 'rgba(37, 99, 235, 0.08)',
                  border: '1px solid rgba(37, 99, 235, 0.3)',
                }}
              >
                <div style={{ fontSize: '0.75rem', color: 'var(--primary)', fontWeight: 700, textTransform: 'uppercase' }}>
                  Tổng Giá Trị Xuất Hàng
                </div>
                <div
                  style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--primary)', marginTop: '0.25rem' }}
                  className="mono"
                >
                  {formatVND(modalTotalSale)}
                </div>
              </div>

              <div
                style={{
                  padding: '0.875rem 1rem',
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border-color)',
                }}
              >
                <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
                  Khách đã trả
                </div>
                <div
                  style={{ fontSize: '1.15rem', fontWeight: 700, color: 'var(--success)', marginTop: '0.25rem' }}
                  className="mono"
                >
                  {formatVND(modalTotalPaid)}
                </div>
              </div>

              <div
                style={{
                  padding: '0.875rem 1rem',
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border-color)',
                }}
              >
                <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
                  Khách còn nợ
                </div>
                <div
                  style={{
                    fontSize: '1.15rem',
                    fontWeight: 700,
                    color: modalTotalUnpaid > 0 ? 'var(--danger)' : 'var(--text-muted)',
                    marginTop: '0.25rem',
                  }}
                  className="mono"
                >
                  {formatVND(modalTotalUnpaid)}
                </div>
              </div>
            </div>

            {/* Exports List Table */}
            {exportsLoading ? (
              <div style={{ padding: '2.5rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                Đang tải danh sách phiếu xuất hàng...
              </div>
            ) : employeeExports.length === 0 ? (
              <EmptyState
                icon={ArrowUpRight}
                title="Không có phiếu xuất hàng nào"
                description="Nhân viên này chưa có phiếu xuất hàng nào trong khoảng thời gian đã chọn."
              />
            ) : (
              <div className="table-responsive" style={{ maxHeight: '440px', overflowY: 'auto' }}>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Số Phiếu</th>
                      <th>Thời Gian Lập</th>
                      <th>Khách Hàng</th>
                      <th>Kho Xuất</th>
                      <th style={{ textAlign: 'right' }}>Tiền Hàng</th>
                      <th style={{ textAlign: 'right' }}>Chiết Khấu</th>
                      <th style={{ textAlign: 'right' }}>Tổng Giá Trị</th>
                      <th style={{ textAlign: 'right' }}>Đã Trả</th>
                      <th style={{ textAlign: 'right' }}>Còn Nợ</th>
                      <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                      <th style={{ textAlign: 'center' }}>Thao Tác</th>
                    </tr>
                  </thead>
                  <tbody>
                    {employeeExports.map((exp) => (
                      <tr
                        key={exp.id}
                        style={{
                          opacity: exp.status === 'cancelled' ? 0.6 : 1,
                        }}
                      >
                        <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                          {exp.voucherNumber}
                        </td>
                        <td style={{ fontSize: '0.8125rem' }}>{formatDate(exp.date || exp.createdAt, true)}</td>
                        <td style={{ fontWeight: 600 }}>{exp.customerName}</td>
                        <td>
                          <span className="badge badge-neutral">
                            {warehouseService.getWarehouseName(exp.warehouse, warehouses)}
                          </span>
                        </td>
                        <td style={{ textAlign: 'right' }} className="mono">
                          {formatVND(exp.subtotalSale)}
                        </td>
                        <td style={{ textAlign: 'right' }} className="mono">
                          {formatVND(exp.discountAmount)}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 700, color: 'var(--primary)' }} className="mono">
                          {formatVND(exp.totalSale)}
                        </td>
                        <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                          {formatVND(exp.paidAmount)}
                        </td>
                        <td
                          style={{
                            textAlign: 'right',
                            color: exp.unpaidAmount > 0 ? 'var(--danger)' : 'var(--text-muted)',
                          }}
                          className="mono"
                        >
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
                              style={{ width: '30px', height: '30px' }}
                              title="Xem chi tiết mặt hàng phiếu xuất"
                              onClick={() => handleOpenVoucherDetail(exp)}
                            >
                              <Eye size={14} />
                            </button>
                            <button
                              className="btn btn-outline btn-icon"
                              style={{ width: '30px', height: '30px' }}
                              title="In phiếu xuất"
                              onClick={() => handlePrintVoucher(exp)}
                            >
                              <Printer size={14} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr
                      style={{
                        background: 'var(--bg-tertiary)',
                        fontWeight: 800,
                        borderTop: '2px solid var(--border-color)',
                      }}
                    >
                      <td colSpan={4} style={{ textAlign: 'right', padding: '0.75rem 1rem' }}>
                        TỔNG CỘNG ({activeModalExports.length} phiếu hoạt động):
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatVND(modalSubtotal)}
                      </td>
                      <td style={{ textAlign: 'right', color: 'var(--danger)' }} className="mono">
                        -{formatVND(modalDiscount)}
                      </td>
                      <td style={{ textAlign: 'right', color: 'var(--primary)', fontSize: '0.95rem' }} className="mono">
                        {formatVND(modalTotalSale)}
                      </td>
                      <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                        {formatVND(modalTotalPaid)}
                      </td>
                      <td
                        style={{
                          textAlign: 'right',
                          color: modalTotalUnpaid > 0 ? 'var(--danger)' : 'var(--text-muted)',
                        }}
                        className="mono"
                      >
                        {formatVND(modalTotalUnpaid)}
                      </td>
                      <td colSpan={2} />
                    </tr>
                  </tfoot>
                </table>
              </div>
            )}
          </div>
        )}
      </Modal>

      {/* Modal Chi Tiết Phiếu Xuất (khi ấn xem 1 phiếu trong modal nhân viên) */}
      <Modal
        isOpen={isVoucherDetailOpen}
        onClose={() => setIsVoucherDetailOpen(false)}
        title={`Chi Tiết Phiếu Xuất: ${selectedVoucher?.voucherNumber || ''}`}
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => handlePrintVoucher(selectedVoucher)}>
              <Printer size={16} />
              <span>In Phiếu Xuất Kho</span>
            </button>
            <button className="btn btn-primary" onClick={() => setIsVoucherDetailOpen(false)}>
              Đóng
            </button>
          </>
        }
      >
        {selectedVoucher && (
          <div style={{ padding: '0.5rem' }}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                borderBottom: '2px solid var(--border-color)',
                paddingBottom: '1rem',
                marginBottom: '1.25rem',
              }}
            >
              <div>
                <h3 style={{ fontSize: '1.15rem', fontWeight: 800 }}>
                  {ownerInfo?.info || 'CỬA HÀNG / KHO HÀNG'}
                </h3>
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                  Mã phiếu: <strong>{selectedVoucher.voucherNumber}</strong>
                </p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '0.8125rem' }}>
                  Thời gian lập:{' '}
                  <strong>{formatDate(selectedVoucher.date || selectedVoucher.createdAt, true)}</strong>
                </p>
                <p style={{ fontSize: '0.8125rem' }}>
                  Kho xuất:{' '}
                  <strong>{warehouseService.getWarehouseName(selectedVoucher.warehouse, warehouses)}</strong>
                </p>
                <span className={`badge badge-${selectedVoucher.status === 'cancelled' ? 'danger' : 'success'}`}>
                  {selectedVoucher.status === 'cancelled' ? 'Đã hủy' : 'Hoạt động'}
                </span>
              </div>
            </div>

            <div
              style={{
                marginBottom: '1.25rem',
                background: 'var(--bg-tertiary)',
                padding: '0.875rem 1rem',
                borderRadius: 'var(--radius-md)',
              }}
            >
              <p style={{ fontSize: '0.875rem' }}>
                Khách hàng: <strong>{selectedVoucher.customerName}</strong>
              </p>
              {selectedVoucher.employeeName && (
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  Nhân viên phụ trách: <strong>{selectedVoucher.employeeName}</strong>
                </p>
              )}
              {selectedVoucher.notes && (
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  Ghi chú: {selectedVoucher.notes}
                </p>
              )}
            </div>

            <div className="table-responsive" style={{ marginBottom: '1.25rem' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>STT</th>
                    <th>Tên Hàng Hóa</th>
                    <th style={{ textAlign: 'center' }}>ĐVT</th>
                    <th style={{ textAlign: 'right' }}>Số Lượng</th>
                    <th style={{ textAlign: 'right' }}>Đơn Giá</th>
                    <th style={{ textAlign: 'right' }}>Thành Tiền</th>
                  </tr>
                </thead>
                <tbody>
                  {(selectedVoucher.items || []).map((it, idx) => (
                    <tr key={it.id || idx}>
                      <td style={{ textAlign: 'center' }}>{idx + 1}</td>
                      <td>
                        <strong>{it.productName || it.sku}</strong>
                        {it.sku && (
                          <span
                            className="mono"
                            style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginLeft: '6px' }}
                          >
                            ({it.sku})
                          </span>
                        )}
                      </td>
                      <td style={{ textAlign: 'center' }}>
                        <span className="badge badge-neutral">{it.uom || '—'}</span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatNumber(it.quantity)}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        {formatVND(it.salePrice)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">
                        {formatVND(it.lineTotal)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <div style={{ width: '320px', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span>Tiền hàng:</span>
                  <span className="mono">{formatVND(selectedVoucher.subtotalSale)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span>Chiết khấu:</span>
                  <span className="mono">-{formatVND(selectedVoucher.discountAmount)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1rem', fontWeight: 800 }}>
                  <span>Tổng tiền thanh toán:</span>
                  <span className="mono" style={{ color: 'var(--primary)' }}>
                    {formatVND(selectedVoucher.totalSale)}
                  </span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    fontSize: '0.875rem',
                    color: 'var(--success)',
                  }}
                >
                  <span>Khách đã trả:</span>
                  <span className="mono">{formatVND(selectedVoucher.paidAmount)}</span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    fontSize: '0.875rem',
                    fontWeight: 700,
                    color: selectedVoucher.unpaidAmount > 0 ? 'var(--danger)' : 'var(--text-muted)',
                  }}
                >
                  <span>Còn nợ lại đơn này:</span>
                  <span className="mono">{formatVND(selectedVoucher.unpaidAmount)}</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

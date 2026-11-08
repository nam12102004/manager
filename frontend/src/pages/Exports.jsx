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
  FileSpreadsheet,
  UserCheck,
  Pencil,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr, getCurrentDateStr } from '../utils/formatters';
import { useNotification } from '../context/NotificationContext';
import { useExport } from '../context/ExportContext';
import Modal from '../components/common/Modal';
import ConfirmModal from '../components/common/ConfirmModal';
import EmptyState from '../components/common/EmptyState';
import SearchBar from '../components/common/SearchBar';
import SearchableSelect from '../components/common/SearchableSelect';
import TimeFilter from '../components/common/TimeFilter';
import Pagination from '../components/common/Pagination';
import { exportService, warehouseService, getProductStockForWarehouse } from '../services';
import { generateExportHtml, printInNewTab } from '../utils/printVoucher';
import EntityTransactionLedger from '../components/common/EntityTransactionLedger';
import useDragScroll from '../hooks/useDragScroll';
import TableScrollContainer from '../components/common/TableScrollContainer';
import { getProductUnits, getPrimaryDisplayUnit, formatStockDisplay, getStockInUnit } from '../utils/uomHelper';

export default function Exports({ initialOpenCreate = false }) {
  const tableContainerRef = useDragScroll();
  const notify = useNotification();
  const { openExportModal } = useExport();

  const [ledgerCustomer, setLedgerCustomer] = useState(null);
  const [exportsList, setExportsList] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [employees, setEmployees] = useState([]);
  const [products, setProducts] = useState([]);
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [ownerInfo, setOwnerInfo] = useState(null);
  const [loading, setLoading] = useState(false);

  // Pagination states (15 items per page)
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const isFirstFilterChange = React.useRef(true);

  // Time & Customer & Employee & Warehouse Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCustomerId, setSelectedCustomerId] = useState('');
  const [selectedEmployeeId, setSelectedEmployeeId] = useState('');
  const [selectedWarehouse, setSelectedWarehouse] = useState('');
  const [timeMode, setTimeMode] = useState('month'); // 'month' | 'day' | 'range' | 'all'
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonthStr());
  const [selectedDate, setSelectedDate] = useState(getCurrentDateStr());
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  // Column visibility toggles (default false / unchecked)
  const [showPaid, setShowPaid] = useState(false);
  const [showDebt, setShowDebt] = useState(false);

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(initialOpenCreate);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isCancelConfirmOpen, setIsCancelConfirmOpen] = useState(false);

  const [selectedExport, setSelectedExport] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Create Form State
  const [createForm, setCreateForm] = useState({
    partnerType: 'customer', // 'customer' | 'supplier'
    customerId: '',
    supplierId: '',
    employeeId: '',
    warehouse: 'warehouse1',
    date: new Date().toISOString().slice(0, 10),
    discountType: 'amount', // 'percent' | 'amount'
    discountValue: '',
    paidAmount: '',
    notes: '',
    items: [],
  });

  // Edit Form State
  const [editForm, setEditForm] = useState({
    id: null,
    voucherNumber: '',
    partnerType: 'customer',
    customerId: '',
    supplierId: '',
    employeeId: '',
    warehouse: 'warehouse1',
    date: new Date().toISOString().slice(0, 10),
    discountType: 'amount',
    discountValue: '',
    paidAmount: '',
    notes: '',
    items: [],
  });

  // Load Exports via exportService with server-side pagination (15 items/page)
  const loadExports = React.useCallback(async (page = currentPage) => {
    setLoading(true);
    try {
      const params = {
        page,
        pageSize: 15,
        customerId: selectedCustomerId ? Number(selectedCustomerId) : null,
        employeeId: selectedEmployeeId ? Number(selectedEmployeeId) : null,
        warehouse: selectedWarehouse || undefined,
        q: searchQuery.trim() || undefined,
      };

      if (timeMode === 'month') {
        params.month = selectedMonth;
      } else if (timeMode === 'day') {
        params.date = selectedDate;
      } else if (timeMode === 'range') {
        params.fromDate = fromDate;
        params.toDate = toDate;
      }

      const res = await exportService.getAll(params);
      if (res && res.items) {
        setExportsList(res.items);
        setCurrentPage(res.page || page);
        setTotalPages(res.totalPages || 1);
        setTotalCount(res.totalCount || 0);
      } else if (Array.isArray(res)) {
        setExportsList(res);
        setTotalCount(res.length);
        setTotalPages(Math.ceil(res.length / 15) || 1);
      }
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách phiếu xuất');
    } finally {
      setLoading(false);
    }
  }, [currentPage, searchQuery, selectedCustomerId, selectedEmployeeId, selectedWarehouse, timeMode, selectedMonth, selectedDate, fromDate, toDate, notify]);

  // Load Customers & Products & Employees & Owner via exportService
  const loadDependencies = async () => {
    try {
      const [{ customers: custs, suppliers: supps, products: prods, employees: emps, ownerInfo: owner }, whList] = await Promise.all([
        exportService.getDependencies(),
        warehouseService.getWarehouses(),
      ]);
      setCustomers(custs || []);
      setSuppliers(supps || []);
      setProducts(prods || []);
      setEmployees(emps || []);
      setOwnerInfo(owner || null);
      if (whList && Array.isArray(whList)) setWarehouses(whList);
    } catch (err) {
      console.error(err);
    }
  };

  // Fetch when currentPage changes
  useEffect(() => {
    loadExports(currentPage);
  }, [currentPage]);

  // Reset to page 1 on filter changes
  useEffect(() => {
    if (isFirstFilterChange.current) {
      isFirstFilterChange.current = false;
      return;
    }
    if (currentPage === 1) {
      loadExports(1);
    } else {
      setCurrentPage(1);
    }
  }, [searchQuery, selectedCustomerId, selectedEmployeeId, selectedWarehouse, timeMode, selectedMonth, selectedDate, fromDate, toDate]);

  useEffect(() => {
    loadDependencies();
    const handleWarehousesUpdated = () => {
      setWarehouses(warehouseService.getWarehousesSync());
    };
    window.addEventListener('warehouses-updated', handleWarehousesUpdated);
    return () => window.removeEventListener('warehouses-updated', handleWarehousesUpdated);
  }, []);

  // Open Create
  const handleOpenCreate = () => {
    loadDependencies();
    const currentWhs = warehouseService.getWarehousesSync();
    const firstP = products.length > 0 ? products[0] : null;
    const units = firstP ? getProductUnits(firstP) : [];
    const defUnit = (firstP ? getPrimaryDisplayUnit(firstP) : null) || units.find((u) => u.isBaseUnit) || units[0];
    const conv = Number(defUnit?.conversionRate || 1);
    const initialPrice = conv > 1
      ? (defUnit?.retailPrice || (firstP?.retailPrice || 0) * conv)
      : (firstP?.retailPrice || firstP?.salePrice || '');

    setCreateForm({
      partnerType: 'customer',
      customerId: customers.length > 0 ? String(customers[0].id) : '',
      supplierId: '',
      employeeId: '',
      warehouse: currentWhs[0]?.id || 'warehouse1',
      date: new Date().toISOString().slice(0, 10),
      discountType: 'amount',
      discountValue: '',
      paidAmount: '',
      notes: '',
      items: [
        {
          productId: firstP ? firstP.id : '',
          quantity: '',
          unitName: defUnit?.unitName || firstP?.uom || 'Cái',
          conversionRate: conv,
          salePrice: initialPrice || '',
        },
      ],
    });
    setIsCreateOpen(true);
  };

  // Add Item Row
  const handleAddItem = () => {
    if (products.length === 0) return;
    const firstP = products[0];
    const units = getProductUnits(firstP);
    const defUnit = getPrimaryDisplayUnit(firstP) || units.find((u) => u.isBaseUnit) || units[0];
    const conv = Number(defUnit?.conversionRate || 1);
    const initialPrice = conv > 1
      ? (defUnit?.retailPrice || (firstP?.retailPrice || 0) * conv)
      : (firstP?.retailPrice || firstP?.salePrice || '');

    setCreateForm((prev) => ({
      ...prev,
      items: [
        ...prev.items,
        {
          productId: firstP.id,
          quantity: '',
          unitName: defUnit?.unitName || firstP.uom || 'Cái',
          conversionRate: conv,
          salePrice: initialPrice || '',
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
          const units = getProductUnits(prod);
          const defUnit = getPrimaryDisplayUnit(prod) || units.find((u) => u.isBaseUnit) || units[0];
          const conv = Number(defUnit?.conversionRate || 1);
          item.unitName = defUnit?.unitName || prod.uom || 'Cái';
          item.conversionRate = conv;
          const price = conv > 1
            ? (defUnit.retailPrice || (prod.retailPrice || 0) * conv)
            : (prod.retailPrice || prod.salePrice || 0);
          item.salePrice = price || '';
        }
      } else if (field === 'quantity' || field === 'salePrice') {
        item[field] = value === '' ? '' : (isNaN(value) ? value : Number(value));
      } else {
        item[field] = value;
      }

      newItems[index] = item;
      return { ...prev, items: newItems };
    });
  };

  // Financial calculations for creation
  const { subtotal, discountAmount, totalSale, unpaidAmount } = exportService.calculateExportTotals({
    items: createForm.items.map((it) => ({ ...it, quantity: Number(it.quantity || 0), salePrice: Number(it.salePrice || 0) })),
    discountType: createForm.discountType,
    discountValue: Number(createForm.discountValue || 0),
    paidAmount: Number(createForm.paidAmount || 0),
  });

  const selectedCustomerObj = customers.find((c) => c.id === Number(createForm.customerId));
  const currentCustDebt = Number(selectedCustomerObj?.debt || 0);
  const projectedCustDebt = currentCustDebt + unpaidAmount;

  // Submit Create Export via exportService
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      // Cumulative stock validation across all rows in base units
      const requestedBaseByProduct = {};
      for (const item of createForm.items) {
        if (!item.productId) continue;
        const pid = Number(item.productId);
        const convRate = Number(item.conversionRate || 1);
        const qty = Number(item.quantity || 0);
        requestedBaseByProduct[pid] = (requestedBaseByProduct[pid] || 0) + (qty * convRate);
      }

      for (const item of createForm.items) {
        if (!item.productId) continue;
        const pid = Number(item.productId);
        const prod = products.find((p) => p.id === pid);
        if (!prod) continue;
        const whStock = getProductStockForWarehouse(prod, createForm.warehouse);
        const convRate = Number(item.conversionRate || 1);
        const baseQty = Number(item.quantity || 0) * convRate;
        const totalRequestedBase = requestedBaseByProduct[pid] || baseQty;

        if (totalRequestedBase > whStock) {
          const stockInCurrentUnit = getStockInUnit(whStock, convRate);
          const unitLabel = item.unitName || prod.uom || 'ĐVT';
          const stockBreakdownStr = formatStockDisplay(whStock, prod.units, prod.uom);
          notify.error(
            `Sản phẩm "${prod.name}" chỉ còn ${stockBreakdownStr} (tối đa ${stockInCurrentUnit} ${unitLabel}), không đủ để xuất tổng cộng ${totalRequestedBase} ${prod.uom || 'ĐVT'}`
          );
          setSubmitting(false);
          return;
        }
      }
      
      const result = await exportService.create(createForm, products);
      notify.success(`Tạo phiếu xuất ${result.voucherNumber} thành công!`);
      setIsCreateOpen(false);
      loadExports();
      loadDependencies(); // refresh product stocks and partner debts
    } catch (err) {
      notify.error(err.message || 'Lỗi khi tạo phiếu xuất');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Edit Modal
  const handleOpenEdit = async (item) => {
    try {
      const full = await exportService.getById(item.id);
      const target = full || item;
      const pType = target.partnerType || (target.supplierId ? 'supplier' : 'customer');
      setEditForm({
        id: target.id,
        voucherNumber: target.voucherNumber,
        partnerType: pType,
        customerId: target.customerId ? String(target.customerId) : '',
        supplierId: target.supplierId ? String(target.supplierId) : '',
        employeeId: target.employeeId ? String(target.employeeId) : '',
        warehouse: target.warehouse || 'warehouse1',
        date: target.date ? target.date.slice(0, 10) : new Date().toISOString().slice(0, 10),
        discountType: target.discountPercent ? 'percent' : 'amount',
        discountValue: target.discountPercent || target.discountValue || '',
        paidAmount: target.paidAmount || '',
        notes: target.notes || '',
        items: (target.items || []).map((it) => {
          const p = products.find((prod) => prod.id === it.productId);
          return {
            productId: it.productId,
            quantity: it.quantity,
            unitName: it.unitName || p?.uom || 'Cái',
            conversionRate: it.conversionRate || 1,
            salePrice: it.salePrice,
          };
        }),
      });
      setIsEditOpen(true);
    } catch (err) {
      notify.error(err.message || 'Không thể tải chi tiết phiếu xuất để chỉnh sửa');
    }
  };

  const handleAddEditItem = () => {
    if (products.length === 0) return;
    const firstP = products[0];
    const units = getProductUnits(firstP);
    const defUnit = getPrimaryDisplayUnit(firstP) || units.find((u) => u.isBaseUnit) || units[0];
    const conv = Number(defUnit?.conversionRate || 1);
    const initialPrice = conv > 1
      ? (defUnit?.retailPrice || (firstP?.retailPrice || 0) * conv)
      : (firstP?.retailPrice || firstP?.salePrice || '');

    setEditForm((prev) => ({
      ...prev,
      items: [
        ...prev.items,
        {
          productId: firstP.id,
          quantity: '',
          unitName: defUnit?.unitName || firstP.uom || 'Cái',
          conversionRate: conv,
          salePrice: initialPrice || '',
        },
      ],
    }));
  };

  const handleRemoveEditItem = (index) => {
    setEditForm((prev) => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index),
    }));
  };

  const handleUpdateEditItem = (index, field, value) => {
    setEditForm((prev) => {
      const newItems = [...prev.items];
      const item = { ...newItems[index] };

      if (field === 'productId') {
        const prod = products.find((p) => p.id === Number(value));
        item.productId = Number(value);
        if (prod) {
          const units = getProductUnits(prod);
          const defUnit = getPrimaryDisplayUnit(prod) || units.find((u) => u.isBaseUnit) || units[0];
          const conv = Number(defUnit?.conversionRate || 1);
          item.unitName = defUnit?.unitName || prod.uom || 'Cái';
          item.conversionRate = conv;
          const price = conv > 1
            ? (defUnit.retailPrice || (prod.retailPrice || 0) * conv)
            : (prod.retailPrice || prod.salePrice || 0);
          item.salePrice = price || '';
        }
      } else if (field === 'quantity' || field === 'salePrice') {
        item[field] = value === '' ? '' : (isNaN(value) ? value : Number(value));
      } else {
        item[field] = value;
      }

      newItems[index] = item;
      return { ...prev, items: newItems };
    });
  };

  const { subtotal: editSubtotal, discountAmount: editDiscountAmount, totalSale: editTotalSale, unpaidAmount: editUnpaidAmount } = exportService.calculateExportTotals({
    items: editForm.items.map((it) => ({ ...it, quantity: Number(it.quantity || 0), salePrice: Number(it.salePrice || 0) })),
    discountType: editForm.discountType,
    discountValue: Number(editForm.discountValue || 0),
    paidAmount: Number(editForm.paidAmount || 0),
  });

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const result = await exportService.update(editForm.id, editForm, products);
      notify.success(`Cập nhật phiếu xuất ${result.voucherNumber || editForm.voucherNumber} thành công! Công nợ và tồn kho đã được đồng bộ.`);
      setIsEditOpen(false);
      if (isDetailOpen) {
        setSelectedExport(result);
      }
      loadExports();
      loadDependencies();
    } catch (err) {
      notify.error(err.message || 'Lỗi khi cập nhật phiếu xuất');
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
    const partner = target.partnerType === 'supplier'
      ? suppliers.find((s) => s.id === target.supplierId || s.name === target.supplierName)
      : customers.find((c) => c.id === target.customerId || c.name === target.customerName);
    const html = generateExportHtml({ exportData: target, ownerInfo, customer: partner });
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
          <button
            className="btn btn-outline"
            onClick={() =>
              openExportModal({
                tab: 'matrix',
                customerId: selectedCustomerId,
                month: timeMode === 'month' ? selectedMonth : null,
              })
            }
            style={{ gap: '6px' }}
          >
            <FileSpreadsheet size={16} />
            <span>Xuất Excel Ma Trận</span>
          </button>
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
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo số phiếu, KH, NV, tên SP, mã SP (SKU)..."
          style={{ flex: 1, minWidth: '260px' }}
        />

        <div style={{ minWidth: '200px' }}>
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

        <div style={{ minWidth: '180px' }}>
          <SearchableSelect
            options={employees.map((emp) => ({
              id: emp.id,
              value: emp.id,
              label: emp.name,
              phone: emp.phone || '',
              subLabel: emp.phone ? `SĐT: ${emp.phone}` : '',
            }))}
            value={selectedEmployeeId}
            onChange={(val) => setSelectedEmployeeId(val)}
            placeholder="-- Tất cả nhân viên --"
            searchPlaceholder="Tìm nhân viên..."
            searchFields={['label', 'phone']}
          />
        </div>

        <div style={{ minWidth: '160px' }}>
          <select
            className="form-control"
            value={selectedWarehouse}
            onChange={(e) => setSelectedWarehouse(e.target.value)}
            style={{ height: '38px', fontSize: '0.875rem' }}
          >
            <option value="">-- Tất cả kho --</option>
            {warehouses.map((wh) => (
              <option key={wh.id} value={wh.id}>
                {wh.name || wh.shortName || wh.id}
              </option>
            ))}
          </select>
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

      {/* Column Visibility Options */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-start',
        gap: '1rem',
        margin: '0.5rem 0 1rem 0',
      }}>
        <div style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '1.25rem',
          padding: '0.45rem 0.85rem',
          backgroundColor: 'var(--bg-card)',
          borderRadius: 'var(--radius-md)',
          border: '1px solid var(--border-color)',
          fontSize: '0.8125rem',
        }}>
          <span style={{ fontWeight: 600, color: 'var(--text-muted)' }}>Hiển thị cột:</span>
          <label style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', cursor: 'pointer', userSelect: 'none' }}>
            <input
              type="checkbox"
              checked={showPaid}
              onChange={(e) => setShowPaid(e.target.checked)}
              style={{ cursor: 'pointer', accentColor: 'var(--primary)', width: '15px', height: '15px' }}
            />
            <span style={{ fontWeight: showPaid ? 600 : 400, color: showPaid ? 'var(--text-primary)' : 'var(--text-secondary)' }}>
              Đã trả
            </span>
          </label>
          <label style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', cursor: 'pointer', userSelect: 'none' }}>
            <input
              type="checkbox"
              checked={showDebt}
              onChange={(e) => setShowDebt(e.target.checked)}
              style={{ cursor: 'pointer', accentColor: 'var(--primary)', width: '15px', height: '15px' }}
            />
            <span style={{ fontWeight: showDebt ? 600 : 400, color: showDebt ? 'var(--text-primary)' : 'var(--text-secondary)' }}>
              Còn nợ
            </span>
          </label>
        </div>
      </div>

      {/* Exports Table */}
      {exportsList.length === 0 && !loading ? (
        <EmptyState
          icon={ArrowUpRight}
          title="Không tìm thấy phiếu xuất nào"
          description={
            searchQuery
              ? `Không tìm thấy phiếu xuất bán nào phù hợp với từ khóa "${searchQuery}".`
              : timeMode === 'day'
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
        <TableScrollContainer targetRef={tableContainerRef} className="table-scroll-wide">
        <div ref={tableContainerRef} className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Số Phiếu</th>
                <th>Thời Gian Lập</th>
                <th>Đối Tác (KH / NCC)</th>
                <th>Nhân Viên</th>
                <th>Kho Xuất</th>
                <th style={{ textAlign: 'right' }}>Tiền Hàng</th>
                <th style={{ textAlign: 'right' }}>Chiết Khấu</th>
                <th style={{ textAlign: 'right' }}>Tổng Tiền</th>
                {showPaid && <th style={{ textAlign: 'right' }}>Đã Trả</th>}
                {showDebt && <th style={{ textAlign: 'right' }}>Còn Nợ</th>}
                <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {exportsList.map((exp) => (
                <tr key={exp.id}>
                  <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                    <div>{exp.voucherNumber}</div>
                    {exp.items && exp.items.length > 0 && (
                      <div
                        style={{
                          fontSize: '0.725rem',
                          color: 'var(--text-secondary)',
                          fontWeight: 400,
                          maxWidth: '180px',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                          marginTop: '2px',
                        }}
                        title={exp.items.map((i) => `${i.productName} (${i.sku || ''})`).join(', ')}
                      >
                        {exp.items.map((i) => i.productName).join(', ')}
                      </div>
                    )}
                  </td>
                  <td style={{ fontSize: '0.8125rem' }}>{formatDate(exp.date || exp.createdAt, true)}</td>
                  <td
                    style={{ fontWeight: 600, color: 'var(--primary)', cursor: exp.customerId ? 'pointer' : 'default', textDecoration: exp.customerId ? 'underline' : 'none' }}
                    title={exp.customerId ? "Bấm để xem sổ chi tiết" : ""}
                    onClick={() => {
                      if (exp.customerId) {
                        const c = customers.find((x) => x.id === exp.customerId);
                        setLedgerCustomer({
                          id: exp.customerId,
                          name: exp.customerName || exp.partnerName,
                          code: c?.code || `KH_${exp.customerId}`,
                        });
                      }
                    }}
                  >
                    <div>{exp.partnerName || (exp.partnerType === 'supplier' ? exp.supplierName : exp.customerName) || 'Khách lẻ'}</div>
                    <span className="badge badge-neutral" style={{ fontSize: '0.6875rem', marginTop: '2px' }}>
                      {exp.partnerType === 'supplier' ? 'Nhà cung cấp' : 'Khách hàng'}
                    </span>
                  </td>
                  <td>
                    {exp.employeeName ? (
                      <span
                        className="badge"
                        style={{
                          background: 'rgba(37, 99, 235, 0.1)',
                          color: 'var(--primary)',
                          border: '1px solid rgba(37, 99, 235, 0.25)',
                          fontWeight: 600,
                        }}
                      >
                        {exp.employeeName}
                      </span>
                    ) : (
                      <span style={{ color: 'var(--text-muted)', fontSize: '0.8125rem' }}>—</span>
                    )}
                  </td>
                  <td>
                    <span className="badge badge-neutral">{warehouseService.getWarehouseName(exp.warehouse, warehouses)}</span>
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
                  {showPaid && (
                    <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                      {formatVND(exp.paidAmount)}
                    </td>
                  )}
                  {showDebt && (
                    <td style={{ textAlign: 'right', color: exp.unpaidAmount > 0 ? 'var(--danger)' : 'var(--text-muted)' }} className="mono">
                      {formatVND(exp.unpaidAmount)}
                    </td>
                  )}
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
                          style={{ width: '32px', height: '32px', color: 'var(--primary)' }}
                          title="Chỉnh sửa phiếu xuất (giá, sản phẩm, số lượng, chiết khấu...)"
                          onClick={() => handleOpenEdit(exp)}
                        >
                          <Pencil size={15} />
                        </button>
                      )}
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
        </TableScrollContainer>
      )}

      {/* Pagination (15 items per page) */}
      <Pagination
        currentPage={currentPage}
        totalPages={totalPages}
        totalCount={totalCount}
        pageSize={15}
        onPageChange={(p) => setCurrentPage(p)}
        disabled={loading}
        itemLabel="phiếu xuất"
      />

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
          {/* Top Row: Khách hàng, Nhân viên (không bắt buộc), Kho, Ngày */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">
                Đối Tác <span className="req">*</span>
              </label>
              <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem', marginBottom: '0.45rem' }}>
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="createExportPartnerType"
                    checked={createForm.partnerType === 'customer'}
                    onChange={() => {
                      const firstC = customers[0]?.id ? String(customers[0].id) : '';
                      setCreateForm({
                        ...createForm,
                        partnerType: 'customer',
                        customerId: firstC,
                        supplierId: '',
                      });
                    }}
                  />
                  <span>Khách hàng</span>
                </label>
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="createExportPartnerType"
                    checked={createForm.partnerType === 'supplier'}
                    onChange={() => {
                      const firstS = suppliers[0]?.id ? String(suppliers[0].id) : '';
                      setCreateForm({
                        ...createForm,
                        partnerType: 'supplier',
                        supplierId: firstS,
                        customerId: '',
                      });
                    }}
                  />
                  <span>Nhà cung cấp</span>
                </label>
              </div>

              {createForm.partnerType === 'customer' ? (
                <>
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
                </>
              ) : (
                <>
                  <SearchableSelect
                    options={suppliers.map((s) => ({
                      id: s.id,
                      value: s.id,
                      label: s.name,
                      code: s.code,
                      phone: s.phone || '',
                      debt: s.debt || 0,
                      subLabel: `Nợ NCC: ${formatVND(s.debt)}`,
                    }))}
                    value={createForm.supplierId}
                    onChange={(val) => setCreateForm({ ...createForm, supplierId: val })}
                    placeholder="-- Chọn nhà cung cấp --"
                    searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                    searchFields={['label', 'code', 'phone']}
                    required
                  />
                  {suppliers.find((s) => s.id === Number(createForm.supplierId)) && (
                    <div style={{ fontSize: '0.75rem', marginTop: '4px', color: 'var(--text-secondary)' }}>
                      Nợ NCC hiện tại: <strong>{formatVND(suppliers.find((s) => s.id === Number(createForm.supplierId))?.debt || 0)}</strong>
                    </div>
                  )}
                </>
              )}
            </div>

            <div className="form-group">
              <label className="form-label">
                Nhân Viên Phụ Trách <span style={{ fontWeight: 400, color: 'var(--text-muted)', fontSize: '0.75rem' }}>(Không bắt buộc)</span>
              </label>
              <SearchableSelect
                options={employees.map((emp) => ({
                  id: emp.id,
                  value: emp.id,
                  label: emp.name,
                  phone: emp.phone || '',
                  subLabel: emp.phone ? `SĐT: ${emp.phone}` : (emp.notes || ''),
                }))}
                value={createForm.employeeId}
                onChange={(val, opt) =>
                  setCreateForm({
                    ...createForm,
                    employeeId: val || '',
                    employeeName: opt?.label || '',
                  })
                }
                placeholder="-- Chọn nhân viên (Tùy chọn) --"
                searchPlaceholder="Tìm theo tên, SĐT nhân viên..."
                searchFields={['label', 'phone']}
                allowClear={true}
              />
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
                    <th style={{ width: '30%' }}>Sản Phẩm</th>
                    <th style={{ width: '12%' }}>ĐVT Xuất</th>
                    <th style={{ width: '14%', textAlign: 'center' }}>Tồn Tại Kho</th>
                    <th style={{ width: '12%', textAlign: 'right' }}>Số Lượng</th>
                    <th style={{ width: '15%', textAlign: 'right' }}>Đơn Giá Bán</th>
                    <th style={{ width: '12%', textAlign: 'right' }}>Thành Tiền</th>
                    <th style={{ width: '5%', textAlign: 'center' }}>Xóa</th>
                  </tr>
                </thead>
                <tbody>
                  {createForm.items.map((item, idx) => {
                    const prod = products.find((p) => p.id === Number(item.productId));
                    const currentWhStock = getProductStockForWarehouse(prod, createForm.warehouse);

                    const convRate = Number(item.conversionRate || 1);
                    const currentUnitStock = getStockInUnit(currentWhStock, convRate);
                    const lineTotal = Number(item.quantity || 0) * Number(item.salePrice || 0);
                    const isOutOfStock = currentWhStock < (Number(item.quantity || 0) * convRate);

                    return (
                      <tr key={idx}>
                        <td>
                          <SearchableSelect
                            options={products.map((p) => {
                              const whStock = getProductStockForWarehouse(p, createForm.warehouse);
                              const targetWh = warehouses.find((w) => w.id === createForm.warehouse);
                              const whLabel = targetWh?.shortName || targetWh?.name || 'kho này';
                              return {
                                id: p.id,
                                value: p.id,
                                label: p.name,
                                code: p.sku || p.code,
                                uom: p.uom || 'ĐVT',
                                subLabel: `Tồn ${whLabel}: ${formatStockDisplay(whStock, p.units, p.uom)} | Giá bán: ${formatVND(p.retailPrice || p.salePrice || 0)}`,
                              };
                            })}
                            value={item.productId}
                            onChange={(val) => handleUpdateItem(idx, 'productId', val)}
                            placeholder="-- Chọn sản phẩm --"
                            searchPlaceholder="Tìm theo mã SKU, tên SP..."
                            searchFields={['label', 'code']}
                          />
                        </td>
                        <td>
                          <select
                            className="form-select"
                            value={item.unitName || prod?.uom || 'Cái'}
                            onChange={(e) => {
                              const uName = e.target.value;
                              const uList = getProductUnits(prod);
                              const targetU = uList.find((u) => u.unitName === uName) || uList[0];
                              const conv = Number(targetU?.conversionRate || 1);
                              const price = conv > 1
                                ? (targetU.retailPrice || (prod?.retailPrice || 0) * conv)
                                : (prod?.retailPrice || prod?.salePrice || 0);
                              setCreateForm((prev) => {
                                const nextItems = [...prev.items];
                                nextItems[idx] = {
                                  ...nextItems[idx],
                                  unitName: targetU?.unitName || uName,
                                  conversionRate: conv,
                                  salePrice: price || nextItems[idx].salePrice
                                };
                                return { ...prev, items: nextItems };
                              });
                            }}
                          >
                            {getProductUnits(prod).map((u) => (
                              <option key={u.unitName} value={u.unitName}>
                                {u.unitName} {u.conversionRate > 1 ? `(x${u.conversionRate})` : ''}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span className={`badge badge-${isOutOfStock ? 'danger' : 'neutral'} mono`}>
                            {formatNumber(currentUnitStock)} {item.unitName || prod?.uom || ''}
                          </span>
                          {prod && prod.units && prod.units.length > 1 && (
                            <div style={{ fontSize: '0.6875rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                              {formatStockDisplay(currentWhStock, prod.units, prod.uom)}
                            </div>
                          )}
                        </td>
                        <td>
                          <input
                            type="number"
                            min="0.001"
                            step="any"
                            className="form-input mono"
                            style={{ textAlign: 'right' }}
                            placeholder="0"
                            value={item.quantity ?? ''}
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
                            placeholder="0"
                            value={item.salePrice ?? ''}
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
                    placeholder="0"
                    value={createForm.discountValue ?? ''}
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
                  placeholder="0"
                  value={createForm.paidAmount ?? ''}
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

      {/* Modal Chỉnh Sửa Phiếu Xuất Kho */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa Phiếu Xuất: ${editForm.voucherNumber || ''}`}
        size="xl"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsEditOpen(false)} disabled={submitting}>
              Hủy bỏ
            </button>
            <button className="btn btn-primary" onClick={handleEditSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu thay đổi...' : 'Lưu Thay Đổi & Cập Nhật'}
            </button>
          </>
        }
      >
        <form onSubmit={handleEditSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">
                Đối Tác <span className="req">*</span>
              </label>
              <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem', marginBottom: '0.45rem' }}>
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="editExportPartnerType"
                    checked={editForm.partnerType === 'customer'}
                    onChange={() => {
                      const firstC = customers[0]?.id ? String(customers[0].id) : '';
                      setEditForm((prev) => ({
                        ...prev,
                        partnerType: 'customer',
                        customerId: firstC,
                        supplierId: '',
                      }));
                    }}
                  />
                  <span>Khách hàng</span>
                </label>
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="editExportPartnerType"
                    checked={editForm.partnerType === 'supplier'}
                    onChange={() => {
                      const firstS = suppliers[0]?.id ? String(suppliers[0].id) : '';
                      setEditForm((prev) => ({
                        ...prev,
                        partnerType: 'supplier',
                        supplierId: firstS,
                        customerId: '',
                      }));
                    }}
                  />
                  <span>Nhà cung cấp</span>
                </label>
              </div>

              {editForm.partnerType === 'customer' ? (
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
                  value={editForm.customerId}
                  onChange={(val) => setEditForm({ ...editForm, customerId: val })}
                  placeholder="-- Chọn khách hàng --"
                  searchPlaceholder="Tìm theo tên, mã KH, SĐT..."
                  searchFields={['label', 'code', 'phone']}
                  required
                />
              ) : (
                <SearchableSelect
                  options={suppliers.map((s) => ({
                    id: s.id,
                    value: s.id,
                    label: s.name,
                    code: s.code,
                    phone: s.phone || '',
                    debt: s.debt || 0,
                    subLabel: `Nợ NCC: ${formatVND(s.debt)}`,
                  }))}
                  value={editForm.supplierId}
                  onChange={(val) => setEditForm({ ...editForm, supplierId: val })}
                  placeholder="-- Chọn nhà cung cấp --"
                  searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                  searchFields={['label', 'code', 'phone']}
                  required
                />
              )}
            </div>

            <div className="form-group">
              <label className="form-label">
                Nhân Viên Phụ Trách <span style={{ fontWeight: 400, color: 'var(--text-muted)', fontSize: '0.75rem' }}>(Không bắt buộc)</span>
              </label>
              <SearchableSelect
                options={employees.map((emp) => ({
                  id: emp.id,
                  value: emp.id,
                  label: emp.name,
                  phone: emp.phone || '',
                  subLabel: emp.phone ? `SĐT: ${emp.phone}` : (emp.notes || ''),
                }))}
                value={editForm.employeeId}
                onChange={(val, opt) =>
                  setEditForm({
                    ...editForm,
                    employeeId: val,
                    employeeName: opt?.label || '',
                  })
                }
                placeholder="-- Chọn nhân viên bán hàng --"
                searchPlaceholder="Tìm theo tên nhân viên, SĐT..."
                searchFields={['label', 'phone']}
              />
            </div>

            <div className="form-group">
              <label className="form-label">
                Kho Xuất Hàng <span className="req">*</span>
              </label>
              <select
                className="form-select"
                value={editForm.warehouse}
                onChange={(e) => setEditForm({ ...editForm, warehouse: e.target.value })}
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
                value={editForm.date}
                onChange={(e) => setEditForm({ ...editForm, date: e.target.value })}
              />
            </div>
          </div>

          {/* Items Section */}
          <div style={{ marginBottom: '1.5rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
              <h4 style={{ fontSize: '0.9375rem', fontWeight: 700 }}>Danh Sách Hàng Hóa Xuất Kho</h4>
              <button type="button" className="btn btn-outline btn-sm" onClick={handleAddEditItem}>
                <Plus size={14} />
                <span>Thêm dòng hàng</span>
              </button>
            </div>

            <div className="table-responsive" style={{ overflow: 'visible' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '30%' }}>Sản Phẩm</th>
                    <th style={{ width: '12%' }}>ĐVT Xuất</th>
                    <th style={{ width: '14%', textAlign: 'center' }}>Tồn Tại Kho</th>
                    <th style={{ width: '12%', textAlign: 'right' }}>Số Lượng</th>
                    <th style={{ width: '15%', textAlign: 'right' }}>Đơn Giá Bán</th>
                    <th style={{ width: '12%', textAlign: 'right' }}>Thành Tiền</th>
                    <th style={{ width: '5%', textAlign: 'center' }}>Xóa</th>
                  </tr>
                </thead>
                <tbody>
                  {editForm.items.map((item, idx) => {
                    const prod = products.find((p) => p.id === Number(item.productId));
                    const currentWhStock = getProductStockForWarehouse(prod, editForm.warehouse);
                    const convRate = Number(item.conversionRate || 1);
                    const currentUnitStock = getStockInUnit(currentWhStock, convRate);
                    const lineTotal = Number(item.quantity || 0) * Number(item.salePrice || 0);

                    return (
                      <tr key={idx}>
                        <td>
                          {/* Note: NO filter on products for export vouchers as requested */}
                          <SearchableSelect
                            options={products.map((p) => {
                              const whStock = getProductStockForWarehouse(p, editForm.warehouse);
                              const targetWh = warehouses.find((w) => w.id === editForm.warehouse);
                              const whLabel = targetWh?.shortName || targetWh?.name || 'kho này';
                              return {
                                id: p.id,
                                value: p.id,
                                label: p.name,
                                code: p.sku || p.code,
                                uom: p.uom || 'ĐVT',
                                subLabel: `ĐVT: ${p.uom || 'ĐVT'} | Tồn ${whLabel}: ${formatStockDisplay(whStock, p.units, p.uom)} | Giá bán: ${formatVND(p.retailPrice || p.salePrice || 0)}`,
                              };
                            })}
                            value={item.productId}
                            onChange={(val) => handleUpdateEditItem(idx, 'productId', val)}
                            placeholder="-- Chọn sản phẩm --"
                            searchPlaceholder="Tìm theo mã SKU, tên SP..."
                            searchFields={['label', 'code']}
                          />
                        </td>
                        <td>
                          <select
                            className="form-select"
                            value={item.unitName || prod?.uom || 'Cái'}
                            onChange={(e) => {
                              const uName = e.target.value;
                              const uList = getProductUnits(prod);
                              const targetU = uList.find((u) => u.unitName === uName) || uList[0];
                              const conv = Number(targetU?.conversionRate || 1);
                              const price = conv > 1
                                ? (targetU?.retailPrice || (prod?.retailPrice || 0) * conv)
                                : (prod?.retailPrice || prod?.salePrice || 0);
                              setEditForm((prev) => {
                                const nextItems = [...prev.items];
                                nextItems[idx] = {
                                  ...nextItems[idx],
                                  unitName: targetU?.unitName || uName,
                                  conversionRate: conv,
                                  salePrice: price || nextItems[idx].salePrice,
                                };
                                return { ...prev, items: nextItems };
                              });
                            }}
                          >
                            {getProductUnits(prod).map((u) => (
                              <option key={u.unitName} value={u.unitName}>
                                {u.unitName} {u.conversionRate > 1 ? `(x${u.conversionRate})` : ''}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span className="badge badge-neutral mono">
                            {formatNumber(currentUnitStock)} {item.unitName || prod?.uom || ''}
                          </span>
                          {prod && prod.units && prod.units.length > 1 && (
                            <div style={{ fontSize: '0.6875rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                              {formatStockDisplay(currentWhStock, prod.units, prod.uom)}
                            </div>
                          )}
                        </td>
                        <td>
                          <input
                            type="number"
                            min="0.001"
                            step="any"
                            className="form-input mono"
                            style={{ textAlign: 'right' }}
                            placeholder="0"
                            value={item.quantity ?? ''}
                            onChange={(e) => handleUpdateEditItem(idx, 'quantity', e.target.value)}
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
                            placeholder="0"
                            value={item.salePrice ?? ''}
                            onChange={(e) => handleUpdateEditItem(idx, 'salePrice', e.target.value)}
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
                            onClick={() => handleRemoveEditItem(idx)}
                            disabled={editForm.items.length <= 1}
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
                <label className="form-label">Chiết Khấu Đơn Hàng</label>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <select
                    className="form-select"
                    style={{ width: '130px' }}
                    value={editForm.discountType}
                    onChange={(e) => setEditForm({ ...editForm, discountType: e.target.value })}
                  >
                    <option value="amount">Tiền mặt</option>
                    <option value="percent">Phần trăm</option>
                  </select>
                  <input
                    type="number"
                    min="0"
                    step="any"
                    className="form-input mono"
                    placeholder="0"
                    value={editForm.discountValue ?? ''}
                    onChange={(e) => setEditForm({ ...editForm, discountValue: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Ghi Chú Phiếu Xuất</label>
                <textarea
                  className="form-textarea"
                  rows={2}
                  placeholder="Ghi chú điều chỉnh..."
                  value={editForm.notes}
                  onChange={(e) => setEditForm({ ...editForm, notes: e.target.value })}
                />
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.625rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Tiền hàng tạm tính:</span>
                <span className="mono" style={{ fontWeight: 600 }}>{formatVND(editSubtotal)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Số tiền chiết khấu:</span>
                <span className="mono" style={{ color: 'var(--danger)' }}>-{formatVND(editDiscountAmount)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.0625rem', fontWeight: 800 }}>
                <span>Tổng phải thanh toán:</span>
                <span className="mono" style={{ color: 'var(--primary)' }}>{formatVND(editTotalSale)}</span>
              </div>

              <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '0.25rem 0' }} />

              <div className="form-group" style={{ marginBottom: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                  <label className="form-label" style={{ marginBottom: 0 }}>
                    Thanh Toán Ngay:
                  </label>
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    style={{ padding: '0 0.5rem', fontSize: '0.75rem' }}
                    onClick={() => setEditForm({ ...editForm, paidAmount: editTotalSale })}
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
                  placeholder="0"
                  value={editForm.paidAmount ?? ''}
                  onChange={(e) => setEditForm({ ...editForm, paidAmount: e.target.value })}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', fontWeight: 700 }}>
                <span style={{ color: editUnpaidAmount > 0 ? 'var(--danger)' : 'var(--success)' }}>
                  {editUnpaidAmount > 0 ? 'Ghi nợ đối tác:' : 'Thanh toán hoàn tất:'}
                </span>
                <span className="mono" style={{ color: editUnpaidAmount > 0 ? 'var(--danger)' : 'var(--success)' }}>
                  {formatVND(editUnpaidAmount)}
                </span>
              </div>
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
            {selectedExport?.status !== 'cancelled' && (
              <button
                className="btn btn-outline"
                style={{ color: 'var(--primary)' }}
                onClick={() => {
                  setIsDetailOpen(false);
                  handleOpenEdit(selectedExport);
                }}
              >
                <Pencil size={16} />
                <span>Chỉnh Sửa Phiếu</span>
              </button>
            )}
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
                <p style={{ fontSize: '0.8125rem' }}>Thời gian lập: <strong>{formatDate(selectedExport.date || selectedExport.createdAt, true)}</strong></p>
                <p style={{ fontSize: '0.8125rem' }}>Kho xuất: <strong>{warehouseService.getWarehouseName(selectedExport.warehouse, warehouses)}</strong></p>
                {selectedExport.employeeName && (
                  <p style={{ fontSize: '0.8125rem' }}>Nhân viên: <strong>{selectedExport.employeeName}</strong></p>
                )}
                <span className={`badge badge-${selectedExport.status === 'cancelled' ? 'danger' : 'success'}`}>
                  {selectedExport.status === 'cancelled' ? 'Đã hủy' : 'Hoạt động'}
                </span>
              </div>
            </div>

            {/* Customer Info */}
            <div style={{ marginBottom: '1.25rem', background: 'var(--bg-tertiary)', padding: '0.875rem 1rem', borderRadius: 'var(--radius-md)' }}>
              <p style={{ fontSize: '0.875rem' }}>
                Đối tác: <strong>{selectedExport.partnerName || (selectedExport.partnerType === 'supplier' ? selectedExport.supplierName : selectedExport.customerName) || 'Khách lẻ'}</strong>
                <span className="badge badge-neutral" style={{ marginLeft: '6px', fontSize: '0.6875rem' }}>
                  {selectedExport.partnerType === 'supplier' ? 'Nhà cung cấp' : 'Khách hàng'}
                </span>
              </p>
              {selectedExport.employeeName && (
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  Nhân viên phụ trách: <strong>{selectedExport.employeeName}</strong>
                </p>
              )}
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
                    <th style={{ textAlign: 'center' }}>ĐVT</th>
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
                      <td style={{ textAlign: 'center' }}>
                        <span className="badge badge-neutral">{it.uom || '—'}</span>
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
                  <span>Còn nợ lại đơn này:</span>
                  <span className="mono">{formatVND(selectedExport.unpaidAmount)}</span>
                </div>
                {(() => {
                  const cust = customers.find((c) => c.id === selectedExport.customerId || c.name === selectedExport.customerName);
                  let totalDebt = null;
                  if (cust?.totalDebt != null) totalDebt = Number(cust.totalDebt);
                  else if (cust?.warehouseDebts && typeof cust.warehouseDebts === 'object') {
                    const vals = Object.values(cust.warehouseDebts);
                    if (vals.length > 0) totalDebt = vals.reduce((sum, v) => sum + Number(v || 0), 0);
                  }
                  if (totalDebt == null && cust?.debt != null) totalDebt = Number(cust.debt);
                  if (totalDebt == null && selectedExport.customerDebt != null) totalDebt = Number(selectedExport.customerDebt);
                  if (totalDebt == null) return null;

                  const isNeg = totalDebt < 0;
                  const label = isNeg ? 'Tổng công nợ còn lại (Cửa hàng nợ khách):' : 'Tổng công nợ còn lại của quý khách:';
                  return (
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', fontWeight: 700, borderTop: '1px dashed var(--border-color)', paddingTop: '0.4rem', marginTop: '0.2rem' }}>
                      <span>{label}</span>
                      <span className="mono" style={{ color: isNeg ? 'var(--info)' : (totalDebt > 0 ? 'var(--danger)' : 'var(--text-muted)') }}>
                        {formatVND(totalDebt)}
                      </span>
                    </div>
                  );
                })()}
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

      {/* Sổ Chi Tiết Nhập / Xuất / Thu / Chi Khách Hàng (Modal) */}
      {ledgerCustomer && (
        <EntityTransactionLedger
          entityType="customer"
          entityId={ledgerCustomer.id}
          entityName={ledgerCustomer.name}
          entityCode={ledgerCustomer.code}
          asModal={true}
          onClose={() => setLedgerCustomer(null)}
        />
      )}
    </div>
  );
}

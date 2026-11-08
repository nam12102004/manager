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
  FileSpreadsheet,
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
import { importService, warehouseService, getProductStockForWarehouse } from '../services';
import { generateImportHtml, printInNewTab } from '../utils/printVoucher';
import EntityTransactionLedger from '../components/common/EntityTransactionLedger';
import useDragScroll from '../hooks/useDragScroll';
import TableScrollContainer from '../components/common/TableScrollContainer';
import { getProductUnits, getPrimaryDisplayUnit, formatStockDisplay, getStockInUnit } from '../utils/uomHelper';

export default function Imports({ initialOpenCreate = false }) {
  const tableContainerRef = useDragScroll();
  const notify = useNotification();
  const { openExportModal } = useExport();

  const [ledgerSupplier, setLedgerSupplier] = useState(null);
  const [importsList, setImportsList] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [products, setProducts] = useState([]);
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [ownerInfo, setOwnerInfo] = useState(null);
  const [loading, setLoading] = useState(false);

  // Pagination states (15 items per page)
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const isFirstFilterChange = React.useRef(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSupplierId, setSelectedSupplierId] = useState('');
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

  const [selectedImport, setSelectedImport] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Create Form State
  const [createForm, setCreateForm] = useState({
    partnerType: 'supplier', // 'supplier' | 'customer'
    supplierId: '',
    customerId: '',
    warehouse: 'warehouse1',
    date: new Date().toISOString().slice(0, 10),
    discountAmount: '',
    paidAmount: '',
    notes: '',
    items: [],
  });

  // Edit Form State
  const [editForm, setEditForm] = useState({
    id: null,
    voucherNumber: '',
    partnerType: 'supplier',
    supplierId: '',
    customerId: '',
    warehouse: 'warehouse1',
    date: new Date().toISOString().slice(0, 10),
    discountAmount: '',
    paidAmount: '',
    notes: '',
    items: [],
  });

  // Load Imports via importService with server-side pagination (15 items/page)
  const loadImports = React.useCallback(async (page = currentPage) => {
    setLoading(true);
    try {
      const params = {
        page,
        pageSize: 15,
        supplierId: selectedSupplierId ? Number(selectedSupplierId) : null,
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

      const res = await importService.getAll(params);
      if (res && res.items) {
        setImportsList(res.items);
        setCurrentPage(res.page || page);
        setTotalPages(res.totalPages || 1);
        setTotalCount(res.totalCount || 0);
      } else if (Array.isArray(res)) {
        setImportsList(res);
        setTotalCount(res.length);
        setTotalPages(Math.ceil(res.length / 15) || 1);
      }
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách phiếu nhập');
    } finally {
      setLoading(false);
    }
  }, [currentPage, searchQuery, selectedSupplierId, selectedWarehouse, timeMode, selectedMonth, selectedDate, fromDate, toDate, notify]);

  // Load Dependencies via importService & warehouseService
  const loadDependencies = async () => {
    try {
      const [{ suppliers: supps, customers: custs, products: prods, ownerInfo: owner }, whList] = await Promise.all([
        importService.getDependencies(),
        warehouseService.getWarehouses(),
      ]);
      setSuppliers(supps || []);
      setCustomers(custs || []);
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
    const supp = target.partnerType === 'customer'
      ? customers.find((c) => Number(c.id) === Number(target.customerId) || c.name === target.customerName)
      : suppliers.find((s) => Number(s.id) === Number(target.supplierId) || s.name === target.supplierName);
    const html = generateImportHtml({ importData: target, ownerInfo, supplier: supp });
    printInNewTab(html);
  };

  // Fetch when currentPage changes
  useEffect(() => {
    loadImports(currentPage);
  }, [currentPage]);

  // Reset to page 1 on filter changes
  useEffect(() => {
    if (isFirstFilterChange.current) {
      isFirstFilterChange.current = false;
      return;
    }
    if (currentPage === 1) {
      loadImports(1);
    } else {
      setCurrentPage(1);
    }
  }, [searchQuery, selectedSupplierId, selectedWarehouse, timeMode, selectedMonth, selectedDate, fromDate, toDate]);

  useEffect(() => {
    loadDependencies();
    const handleWarehousesUpdated = () => {
      setWarehouses(warehouseService.getWarehousesSync());
    };
    window.addEventListener('warehouses-updated', handleWarehousesUpdated);
    return () => window.removeEventListener('warehouses-updated', handleWarehousesUpdated);
  }, []);

  const getAvailableProducts = (partnerType, supplierId) => {
    if (partnerType === 'customer') {
      return products;
    }
    if (supplierId) {
      return products.filter((p) => String(p.supplierId) === String(supplierId));
    }
    return products;
  };

  // Open Create Modal
  const handleOpenCreate = () => {
    loadDependencies();
    const currentWhs = warehouseService.getWarehousesSync();
    const firstSupplierId = suppliers.length > 0 ? String(suppliers[0].id) : '';
    const suppProds = firstSupplierId
      ? products.filter((p) => String(p.supplierId) === String(firstSupplierId))
      : products;
    const firstP = suppProds.length > 0 ? suppProds[0] : null;
    const units = firstP ? getProductUnits(firstP) : [];
    const defUnit = (firstP ? getPrimaryDisplayUnit(firstP) : null) || units.find((u) => u.isBaseUnit) || units[0];
    const conv = Number(defUnit?.conversionRate || 1);
    const cost = conv > 1
      ? (firstP?.unitCost || 0) * conv
      : (firstP?.unitCost || '');

    setCreateForm({
      partnerType: 'supplier',
      supplierId: firstSupplierId,
      customerId: '',
      warehouse: currentWhs[0]?.id || 'warehouse1',
      date: new Date().toISOString().slice(0, 10),
      discountAmount: '',
      paidAmount: '',
      notes: '',
      items: [
        {
          productId: firstP ? firstP.id : '',
          quantity: '',
          unitName: defUnit?.unitName || firstP?.uom || 'Cái',
          conversionRate: conv,
          unitPrice: cost || '',
        },
      ],
    });
    setIsCreateOpen(true);
  };

  // Add Item Row
  const handleAddItem = () => {
    const availProds = getAvailableProducts(createForm.partnerType, createForm.supplierId);
    if (availProds.length === 0 && products.length === 0) return;
    const firstP = availProds.length > 0 ? availProds[0] : products[0];
    const units = firstP ? getProductUnits(firstP) : [];
    const defUnit = (firstP ? getPrimaryDisplayUnit(firstP) : null) || units.find((u) => u.isBaseUnit) || units[0];
    const conv = Number(defUnit?.conversionRate || 1);
    const cost = conv > 1
      ? (firstP?.unitCost || 0) * conv
      : (firstP?.unitCost || '');
    setCreateForm((prev) => ({
      ...prev,
      items: [
        ...prev.items,
        {
          productId: firstP ? firstP.id : '',
          quantity: '',
          unitName: defUnit?.unitName || firstP?.uom || 'Cái',
          conversionRate: conv,
          unitPrice: cost || '',
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
          const cost = conv > 1 ? (prod.unitCost || 0) * conv : (prod.unitCost || 0);
          item.unitPrice = cost || '';
        }
      } else if (field === 'quantity' || field === 'unitPrice') {
        item[field] = value === '' ? '' : (isNaN(value) ? value : Number(value));
      } else {
        item[field] = value;
      }

      newItems[index] = item;
      return { ...prev, items: newItems };
    });
  };

  // Subtotal & Financials via importService
  const { subtotal, discountAmount, totalCost: totalAmount, unpaidAmount } = importService.calculateImportTotals({
    items: createForm.items.map((it) => ({ quantity: Number(it.quantity || 0), unitCost: Number(it.unitPrice || 0) })),
    discountType: 'amount',
    discountValue: Number(createForm.discountAmount || 0),
    paidAmount: Number(createForm.paidAmount || 0),
  });

  // Submit Create Import via importService
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const result = await importService.create({
        partnerType: createForm.partnerType,
        supplierId: createForm.partnerType === 'supplier' ? createForm.supplierId : undefined,
        customerId: createForm.partnerType === 'customer' ? createForm.customerId : undefined,
        warehouse: createForm.warehouse,
        date: createForm.date,
        discountType: 'amount',
        discountValue: createForm.discountAmount,
        paidAmount: createForm.paidAmount,
        notes: createForm.notes,
        items: createForm.items.map((it) => ({
          productId: it.productId,
          quantity: Number(it.quantity || 0),
          unitCost: Number(it.unitPrice || 0),
          unitName: it.unitName,
          conversionRate: Number(it.conversionRate || 1),
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

  // Open Edit Modal
  const handleOpenEdit = async (item) => {
    try {
      const full = await importService.getById(item.id);
      const target = full || item;
      const pType = target.partnerType || (target.customerId ? 'customer' : 'supplier');
      setEditForm({
        id: target.id,
        voucherNumber: target.voucherNumber,
        partnerType: pType,
        supplierId: target.supplierId ? String(target.supplierId) : '',
        customerId: target.customerId ? String(target.customerId) : '',
        warehouse: target.warehouse || 'warehouse1',
        date: target.date ? target.date.slice(0, 10) : new Date().toISOString().slice(0, 10),
        discountAmount: target.discountValue || target.discountAmount || '',
        paidAmount: target.paidAmount || '',
        notes: target.notes || '',
        items: (target.items || []).map((it) => {
          const p = products.find((prod) => prod.id === it.productId);
          return {
            productId: it.productId,
            quantity: it.quantity,
            unitName: it.unitName || p?.uom || 'Cái',
            conversionRate: it.conversionRate || 1,
            unitPrice: it.unitPrice || 0,
          };
        }),
      });
      setIsEditOpen(true);
    } catch (err) {
      notify.error(err.message || 'Không thể tải chi tiết phiếu nhập để chỉnh sửa');
    }
  };

  // Add Item in Edit Modal
  const handleAddEditItem = () => {
    const availProds = getAvailableProducts(editForm.partnerType, editForm.supplierId);
    if (availProds.length === 0 && products.length === 0) return;
    const firstP = availProds.length > 0 ? availProds[0] : products[0];
    const units = firstP ? getProductUnits(firstP) : [];
    const defUnit = (firstP ? getPrimaryDisplayUnit(firstP) : null) || units.find((u) => u.isBaseUnit) || units[0];
    const conv = Number(defUnit?.conversionRate || 1);
    const cost = conv > 1 ? (firstP?.unitCost || 0) * conv : (firstP?.unitCost || '');
    setEditForm((prev) => ({
      ...prev,
      items: [
        ...prev.items,
        {
          productId: firstP ? firstP.id : '',
          quantity: '',
          unitName: defUnit?.unitName || firstP?.uom || 'Cái',
          conversionRate: conv,
          unitPrice: cost || '',
        },
      ],
    }));
  };

  // Remove Item in Edit Modal
  const handleRemoveEditItem = (index) => {
    setEditForm((prev) => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index),
    }));
  };

  // Update Item in Edit Modal
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
          const cost = conv > 1 ? (prod.unitCost || 0) * conv : (prod.unitCost || 0);
          item.unitPrice = cost || '';
        }
      } else if (field === 'quantity' || field === 'unitPrice') {
        item[field] = value === '' ? '' : (isNaN(value) ? value : Number(value));
      } else {
        item[field] = value;
      }

      newItems[index] = item;
      return { ...prev, items: newItems };
    });
  };

  // Subtotal & Financials for Edit Form
  const { subtotal: editSubtotal, discountAmount: editDiscountAmount, totalCost: editTotalAmount, unpaidAmount: editUnpaidAmount } = importService.calculateImportTotals({
    items: editForm.items.map((it) => ({ quantity: Number(it.quantity || 0), unitCost: Number(it.unitPrice || 0) })),
    discountType: 'amount',
    discountValue: Number(editForm.discountAmount || 0),
    paidAmount: Number(editForm.paidAmount || 0),
  });

  // Submit Edit Import
  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const result = await importService.update(editForm.id, {
        partnerType: editForm.partnerType,
        supplierId: editForm.partnerType === 'supplier' ? editForm.supplierId : undefined,
        customerId: editForm.partnerType === 'customer' ? editForm.customerId : undefined,
        warehouse: editForm.warehouse,
        date: editForm.date,
        discountType: 'amount',
        discountValue: editForm.discountAmount,
        paidAmount: editForm.paidAmount,
        notes: editForm.notes,
        items: editForm.items.map((it) => ({
          productId: it.productId,
          quantity: Number(it.quantity || 0),
          unitCost: Number(it.unitPrice || 0),
          unitName: it.unitName,
          conversionRate: Number(it.conversionRate || 1),
        })),
      });

      notify.success(`Cập nhật phiếu nhập ${result.voucherNumber || editForm.voucherNumber} thành công! Công nợ và tồn kho đã được đồng bộ.`);
      setIsEditOpen(false);
      if (isDetailOpen) {
        setSelectedImport(result);
      }
      loadImports();
      loadDependencies();
    } catch (err) {
      notify.error(err.message || 'Lỗi khi cập nhật phiếu nhập kho');
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
          <button
            className="btn btn-outline"
            onClick={() =>
              openExportModal({
                tab: 'matrix',
                partnerType: 'supplier',
                supplierId: selectedSupplierId,
                month: timeMode === 'month' ? selectedMonth : null,
                warehouse: selectedWarehouse,
              })
            }
            style={{ gap: '6px' }}
          >
            <FileSpreadsheet size={16} />
            <span>Xuất Excel Ma Trận</span>
          </button>
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
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo số phiếu, NCC, tên SP, mã SP (SKU)..."
          style={{ flex: 1, minWidth: '260px' }}
        />

        <div style={{ minWidth: '220px' }}>
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

        <div style={{ minWidth: '170px' }}>
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
              Đã trả NCC
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
              Còn nợ NCC
            </span>
          </label>
        </div>
      </div>

      {/* Imports Table */}
      {importsList.length === 0 && !loading ? (
        <EmptyState
          icon={ArrowDownLeft}
          title="Không tìm thấy phiếu nhập nào"
          description={
            searchQuery
              ? `Không tìm thấy phiếu nhập nào phù hợp với từ khóa "${searchQuery}".`
              : timeMode === 'day'
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
        <TableScrollContainer targetRef={tableContainerRef}>
        <div ref={tableContainerRef} className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Số Phiếu</th>
                <th>Thời Gian Nhập</th>
                <th>Đối Tác (NCC / KH)</th>
                <th>Kho Nhận</th>
                <th style={{ textAlign: 'right' }}>Tiền Hàng</th>
                <th style={{ textAlign: 'right' }}>Chiết Khấu</th>
                <th style={{ textAlign: 'right' }}>Tổng Tiền</th>
                {showPaid && <th style={{ textAlign: 'right' }}>Đã Thanh Toán</th>}
                {showDebt && <th style={{ textAlign: 'right' }}>Còn Nợ</th>}
                <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {importsList.map((imp) => (
                <tr key={imp.id}>
                  <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                    <div>{imp.voucherNumber}</div>
                    {imp.items && imp.items.length > 0 && (
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
                        title={imp.items.map((i) => `${i.productName} (${i.sku || ''})`).join(', ')}
                      >
                        {imp.items.map((i) => i.productName).join(', ')}
                      </div>
                    )}
                  </td>
                  <td style={{ fontSize: '0.8125rem' }}>{formatDate(imp.date || imp.createdAt, true)}</td>
                  <td
                    style={{ fontWeight: 600, color: 'var(--primary)', cursor: imp.supplierId ? 'pointer' : 'default', textDecoration: imp.supplierId ? 'underline' : 'none' }}
                    title={imp.supplierId ? "Bấm để xem sổ chi tiết" : ""}
                    onClick={() => {
                      if (imp.supplierId) {
                        const s = suppliers.find((x) => x.id === imp.supplierId);
                        setLedgerSupplier({
                          id: imp.supplierId,
                          name: imp.supplierName || imp.partnerName,
                          code: s?.code || `NCC_${imp.supplierId}`,
                        });
                      }
                    }}
                  >
                    <div>{imp.partnerName || (imp.partnerType === 'customer' ? imp.customerName : imp.supplierName) || '—'}</div>
                    <span className="badge badge-neutral" style={{ fontSize: '0.6875rem', marginTop: '2px' }}>
                      {imp.partnerType === 'customer' ? 'Khách hàng' : 'Nhà cung cấp'}
                    </span>
                  </td>
                  <td>
                    <span className="badge badge-neutral">{warehouseService.getWarehouseName(imp.warehouse, warehouses)}</span>
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
                  {showPaid && (
                    <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                      {formatVND(imp.paidAmount)}
                    </td>
                  )}
                  {showDebt && (
                    <td style={{ textAlign: 'right', color: imp.unpaidAmount > 0 ? 'var(--warning-text)' : 'var(--text-muted)' }} className="mono">
                      {formatVND(imp.unpaidAmount)}
                    </td>
                  )}
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
                          style={{ width: '32px', height: '32px', color: 'var(--primary)' }}
                          title="Chỉnh sửa phiếu nhập (giá, sản phẩm, số lượng, chiết khấu...)"
                          onClick={() => handleOpenEdit(imp)}
                        >
                          <Pencil size={15} />
                        </button>
                      )}
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
        itemLabel="phiếu nhập"
      />

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
                Đối Tác <span className="req">*</span>
              </label>
              <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem', marginBottom: '0.45rem' }}>
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="createPartnerType"
                    checked={createForm.partnerType === 'supplier'}
                    onChange={() => {
                      const firstS = suppliers[0]?.id ? String(suppliers[0].id) : '';
                      const suppProds = firstS ? products.filter((p) => String(p.supplierId) === String(firstS)) : products;
                      const firstP = suppProds[0] || null;
                      const units = firstP ? getProductUnits(firstP) : [];
                      const defUnit = (firstP ? getPrimaryDisplayUnit(firstP) : null) || units.find((u) => u.isBaseUnit) || units[0];
                      const conv = Number(defUnit?.conversionRate || 1);
                      const cost = conv > 1 ? (firstP?.unitCost || 0) * conv : (firstP?.unitCost || '');
                      setCreateForm({
                        ...createForm,
                        partnerType: 'supplier',
                        supplierId: firstS,
                        customerId: '',
                        items: [{
                          productId: firstP ? firstP.id : '',
                          quantity: '',
                          unitName: defUnit?.unitName || firstP?.uom || 'Cái',
                          conversionRate: conv,
                          unitPrice: cost || '',
                        }],
                      });
                    }}
                  />
                  <span>Nhà cung cấp</span>
                </label>
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="createPartnerType"
                    checked={createForm.partnerType === 'customer'}
                    onChange={() => {
                      const firstC = customers[0]?.id ? String(customers[0].id) : '';
                      // Khi chọn Khách hàng, xóa bộ lọc NCC với sản phẩm -> hiện toàn bộ sản phẩm
                      const firstP = products[0] || null;
                      const units = firstP ? getProductUnits(firstP) : [];
                      const defUnit = (firstP ? getPrimaryDisplayUnit(firstP) : null) || units.find((u) => u.isBaseUnit) || units[0];
                      const conv = Number(defUnit?.conversionRate || 1);
                      const cost = conv > 1 ? (firstP?.unitCost || 0) * conv : (firstP?.unitCost || '');
                      setCreateForm({
                        ...createForm,
                        partnerType: 'customer',
                        customerId: firstC,
                        supplierId: '',
                        items: [{
                          productId: firstP ? firstP.id : '',
                          quantity: '',
                          unitName: defUnit?.unitName || firstP?.uom || 'Cái',
                          conversionRate: conv,
                          unitPrice: cost || '',
                        }],
                      });
                    }}
                  />
                  <span>Khách hàng</span>
                </label>
              </div>

              {createForm.partnerType === 'supplier' ? (
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
                      const suppProds = products.filter((p) => String(p.supplierId) === String(val));
                      const firstP = suppProds.length > 0 ? suppProds[0] : null;
                      const units = firstP ? getProductUnits(firstP) : [];
                      const defUnit = (firstP ? getPrimaryDisplayUnit(firstP) : null) || units.find((u) => u.isBaseUnit) || units[0];
                      const conv = Number(defUnit?.conversionRate || 1);
                      const cost = conv > 1
                        ? (firstP?.unitCost || 0) * conv
                        : (firstP?.unitCost || '');
                      setCreateForm({ 
                        ...createForm, 
                        supplierId: val,
                        items: [{
                          productId: firstP ? firstP.id : '',
                          quantity: '',
                          unitName: defUnit?.unitName || firstP?.uom || 'Cái',
                          conversionRate: conv,
                          unitPrice: cost || '',
                        }] 
                      });
                    }
                  }}
                  placeholder="-- Chọn nhà cung cấp --"
                  searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                  searchFields={['label', 'code', 'phone']}
                  required
                />
              ) : (
                <SearchableSelect
                  options={customers.map((c) => ({
                    id: c.id,
                    value: c.id,
                    label: c.name,
                    code: c.code,
                    phone: c.phone || '',
                    debt: c.debt || 0,
                    subLabel: `Nợ: ${formatVND(c.debt)}`,
                  }))}
                  value={createForm.customerId}
                  onChange={(val) => setCreateForm({ ...createForm, customerId: val })}
                  placeholder="-- Chọn khách hàng --"
                  searchPlaceholder="Tìm theo tên, mã KH, SĐT..."
                  searchFields={['label', 'code', 'phone']}
                  required
                />
              )}
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
                    <th style={{ width: '30%' }}>Sản Phẩm</th>
                    <th style={{ width: '12%' }}>ĐVT Nhập</th>
                    <th style={{ width: '14%', textAlign: 'center' }}>Tồn Tại Kho</th>
                    <th style={{ width: '12%', textAlign: 'right' }}>Số Lượng Nhập</th>
                    <th style={{ width: '15%', textAlign: 'right' }}>Đơn Giá Nhập</th>
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
                    const lineTotal = Number(item.quantity || 0) * Number(item.unitPrice || 0);

                    return (
                      <tr key={idx}>
                        <td>
                          <SearchableSelect
                            disabled={createForm.partnerType === 'supplier' && !createForm.supplierId}
                            options={getAvailableProducts(createForm.partnerType, createForm.supplierId)
                              .map((p) => {
                                const whStock = getProductStockForWarehouse(p, createForm.warehouse);
                                const total = Number(p.totalStock ?? 0);
                                const targetWh = warehouses.find((w) => w.id === createForm.warehouse);
                                const whLabel = targetWh?.shortName || targetWh?.name || 'kho này';
                                return {
                                  id: p.id,
                                  value: p.id,
                                  label: p.name,
                                  code: p.sku || p.code,
                                  uom: p.uom || 'ĐVT',
                                  subLabel: `ĐVT: ${p.uom || 'ĐVT'} | Tồn ${whLabel}: ${formatStockDisplay(whStock, p.units, p.uom)} | Giá nhập: ${formatVND(p.unitCost || 0)}`,
                                };
                              })}
                            value={item.productId}
                            onChange={(val) => handleUpdateItem(idx, 'productId', val)}
                            placeholder={createForm.partnerType === 'supplier' && !createForm.supplierId ? "-- Vui lòng chọn Nhà CC --" : "-- Chọn sản phẩm --"}
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
                              const cost = Number(prod?.unitCost || 0) * conv;
                              setCreateForm((prev) => {
                                const nextItems = [...prev.items];
                                nextItems[idx] = {
                                  ...nextItems[idx],
                                  unitName: targetU?.unitName || uName,
                                  conversionRate: conv,
                                  unitPrice: cost || nextItems[idx].unitPrice
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
                            value={item.unitPrice ?? ''}
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
                  placeholder="0"
                  value={createForm.discountAmount ?? ''}
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
                  placeholder="0"
                  value={createForm.paidAmount ?? ''}
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

      {/* Modal Chỉnh Sửa Phiếu Nhập */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa Phiếu Nhập: ${editForm.voucherNumber || ''}`}
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
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">
                Đối Tác <span className="req">*</span>
              </label>
              <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem', marginBottom: '0.45rem' }}>
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="editPartnerType"
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
                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                  <input
                    type="radio"
                    name="editPartnerType"
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
              </div>

              {editForm.partnerType === 'supplier' ? (
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
                  value={editForm.supplierId}
                  onChange={(val) => setEditForm({ ...editForm, supplierId: val })}
                  placeholder="-- Chọn nhà cung cấp --"
                  searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                  searchFields={['label', 'code', 'phone']}
                  required
                />
              ) : (
                <SearchableSelect
                  options={customers.map((c) => ({
                    id: c.id,
                    value: c.id,
                    label: c.name,
                    code: c.code,
                    phone: c.phone || '',
                    debt: c.debt || 0,
                    subLabel: `Nợ: ${formatVND(c.debt)}`,
                  }))}
                  value={editForm.customerId}
                  onChange={(val) => setEditForm({ ...editForm, customerId: val })}
                  placeholder="-- Chọn khách hàng --"
                  searchPlaceholder="Tìm theo tên, mã KH, SĐT..."
                  searchFields={['label', 'code', 'phone']}
                  required
                />
              )}
            </div>

            <div className="form-group">
              <label className="form-label">
                Kho Tiếp Nhận <span className="req">*</span>
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
              <label className="form-label">Ngày Nhập Kho</label>
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
              <h4 style={{ fontSize: '0.9375rem', fontWeight: 700 }}>Danh Sách Hàng Nhập Kho</h4>
              <button type="button" className="btn btn-outline btn-sm" onClick={handleAddEditItem}>
                <Plus size={14} />
                <span>Thêm dòng sản phẩm</span>
              </button>
            </div>

            <div className="table-responsive" style={{ overflow: 'visible' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '30%' }}>Sản Phẩm</th>
                    <th style={{ width: '12%' }}>ĐVT Nhập</th>
                    <th style={{ width: '14%', textAlign: 'center' }}>Tồn Tại Kho</th>
                    <th style={{ width: '12%', textAlign: 'right' }}>Số Lượng Nhập</th>
                    <th style={{ width: '15%', textAlign: 'right' }}>Đơn Giá Nhập</th>
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
                    const lineTotal = Number(item.quantity || 0) * Number(item.unitPrice || 0);

                    return (
                      <tr key={idx}>
                        <td>
                          <SearchableSelect
                            disabled={editForm.partnerType === 'supplier' && !editForm.supplierId}
                            options={getAvailableProducts(editForm.partnerType, editForm.supplierId)
                              .map((p) => {
                                const whStock = getProductStockForWarehouse(p, editForm.warehouse);
                                const targetWh = warehouses.find((w) => w.id === editForm.warehouse);
                                const whLabel = targetWh?.shortName || targetWh?.name || 'kho này';
                                return {
                                  id: p.id,
                                  value: p.id,
                                  label: p.name,
                                  code: p.sku || p.code,
                                  uom: p.uom || 'ĐVT',
                                  subLabel: `ĐVT: ${p.uom || 'ĐVT'} | Tồn ${whLabel}: ${formatStockDisplay(whStock, p.units, p.uom)} | Giá nhập: ${formatVND(p.unitCost || 0)}`,
                                };
                              })}
                            value={item.productId}
                            onChange={(val) => handleUpdateEditItem(idx, 'productId', val)}
                            placeholder={editForm.partnerType === 'supplier' && !editForm.supplierId ? "-- Vui lòng chọn Nhà CC --" : "-- Chọn sản phẩm --"}
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
                              const cost = Number(prod?.unitCost || 0) * conv;
                              setEditForm((prev) => {
                                const nextItems = [...prev.items];
                                nextItems[idx] = {
                                  ...nextItems[idx],
                                  unitName: targetU?.unitName || uName,
                                  conversionRate: conv,
                                  unitPrice: cost || nextItems[idx].unitPrice
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
                            value={item.unitPrice ?? ''}
                            onChange={(e) => handleUpdateEditItem(idx, 'unitPrice', e.target.value)}
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
                <label className="form-label">Chiết Khấu</label>
                <input
                  type="number"
                  min="0"
                  step="any"
                  className="form-input mono"
                  placeholder="0"
                  value={editForm.discountAmount ?? ''}
                  onChange={(e) => setEditForm({ ...editForm, discountAmount: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Ghi Chú Phiếu Nhập</label>
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
                <span style={{ color: 'var(--text-secondary)' }}>Chiết khấu:</span>
                <span className="mono" style={{ color: 'var(--danger)' }}>-{formatVND(editDiscountAmount)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.0625rem', fontWeight: 800 }}>
                <span>Tổng tiền nhập hàng:</span>
                <span className="mono" style={{ color: 'var(--primary)' }}>{formatVND(editTotalAmount)}</span>
              </div>

              <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '0.25rem 0' }} />

              <div className="form-group" style={{ marginBottom: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                  <label className="form-label" style={{ marginBottom: 0 }}>
                    Tiền Chi Trả Ngay:
                  </label>
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    style={{ padding: '0 0.5rem', fontSize: '0.75rem' }}
                    onClick={() => setEditForm({ ...editForm, paidAmount: editTotalAmount })}
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
                <span style={{ color: editUnpaidAmount > 0 ? 'var(--warning-text)' : 'var(--success)' }}>
                  {editUnpaidAmount > 0 ? 'Ghi nợ phát sinh:' : 'Thanh toán hoàn tất:'}
                </span>
                <span className="mono" style={{ color: editUnpaidAmount > 0 ? 'var(--warning-text)' : 'var(--success)' }}>
                  {formatVND(editUnpaidAmount)}
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
            {selectedImport?.status !== 'cancelled' && (
              <button
                className="btn btn-outline"
                style={{ color: 'var(--primary)' }}
                onClick={() => {
                  setIsDetailOpen(false);
                  handleOpenEdit(selectedImport);
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
        {selectedImport && (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '2px solid var(--border-color)', paddingBottom: '1rem', marginBottom: '1.25rem' }}>
              <div>
                <h3 style={{ fontSize: '1.1875rem', fontWeight: 800 }}>PHIẾU NHẬP KHO HÀNG HÓA</h3>
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>Mã phiếu: <strong>{selectedImport.voucherNumber}</strong></p>
                <p style={{ fontSize: '0.8125rem' }}>
                  Đối tác: <strong>{selectedImport.partnerName || (selectedImport.partnerType === 'customer' ? selectedImport.customerName : selectedImport.supplierName) || '—'}</strong>
                  <span className="badge badge-neutral" style={{ marginLeft: '6px', fontSize: '0.6875rem' }}>
                    {selectedImport.partnerType === 'customer' ? 'Khách hàng' : 'Nhà cung cấp'}
                  </span>
                </p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '0.8125rem' }}>Thời gian nhập: <strong>{formatDate(selectedImport.date || selectedImport.createdAt, true)}</strong></p>
                <p style={{ fontSize: '0.8125rem' }}>Kho nhận: <strong>{warehouseService.getWarehouseName(selectedImport.warehouse, warehouses)}</strong></p>
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
                    <th style={{ textAlign: 'center' }}>ĐVT</th>
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
                      <td style={{ textAlign: 'center' }}>
                        <span className="badge badge-neutral">{it.uom || '—'}</span>
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

      {/* Sổ Chi Tiết Nhập / Xuất / Thu / Chi Nhà Cung Cấp (Modal) */}
      {ledgerSupplier && (
        <EntityTransactionLedger
          entityType="supplier"
          entityId={ledgerSupplier.id}
          entityName={ledgerSupplier.name}
          entityCode={ledgerSupplier.code}
          asModal={true}
          onClose={() => setLedgerSupplier(null)}
        />
      )}
    </div>
  );
}

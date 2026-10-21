import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Package,
  Plus,
  Edit2,
  Trash2,
  Search,
  Filter,
  RefreshCw,
  Boxes,
  DollarSign,
  Layers,
  ChevronLeft,
  ChevronRight,
  Menu,
  ReceiptText,
  Truck,
} from 'lucide-react';
import { formatVND, formatNumber } from '../utils/formatters';
import { useNotification } from '../context/NotificationContext';
import SearchBar from '../components/common/SearchBar';
import StatCard from '../components/common/StatCard';
import Modal from '../components/common/Modal';
import EmptyState from '../components/common/EmptyState';
import SearchableSelect from '../components/common/SearchableSelect';
import SortDropdown from '../components/common/SortDropdown';
import ConfirmModal from '../components/common/ConfirmModal';
import Pagination from '../components/common/Pagination';
import EntityTransactionLedger from '../components/common/EntityTransactionLedger';
import WarehouseMetricCheckboxes, { loadSavedMetrics, getMetricTimeParams } from '../components/common/WarehouseMetricCheckboxes';
import { productService, warehouseService } from '../services';

const PRODUCT_SORT_OPTIONS = [
  { value: 'default', label: 'Sắp xếp: Mặc định' },
  { value: 'stock_desc', label: 'Tồn kho: Nhiều nhất → Ít nhất' },
  { value: 'stock_asc', label: 'Tồn kho: Ít nhất → Nhiều nhất' },
  { value: 'cost_desc', label: 'Giá vốn: Cao nhất → Thấp nhất' },
  { value: 'cost_asc', label: 'Giá vốn: Thấp nhất → Cao nhất' },
  { value: 'wholesale_desc', label: 'Giá sỉ: Cao nhất → Thấp nhất' },
  { value: 'wholesale_asc', label: 'Giá sỉ: Thấp nhất → Cao nhất' },
  { value: 'retail_desc', label: 'Giá lẻ: Cao nhất → Thấp nhất' },
  { value: 'retail_asc', label: 'Giá lẻ: Thấp nhất → Cao nhất' },
];

export default function ProductCatalog() {
  const notify = useNotification();

  const [products, setProducts] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [categories, setCategories] = useState([]);
  const [categoryCounts, setCategoryCounts] = useState({});
  const [supplierCounts, setSupplierCounts] = useState({});
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [loading, setLoading] = useState(false);

  // Pagination states (15 items per page)
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [serverSummary, setServerSummary] = useState({
    totalStockQty: 0,
    totalCostVal: 0,
    totalWholesaleVal: 0,
    totalRetailVal: 0,
    totalImportAmount: 0,
    totalExportAmount: 0,
    totalReceiptAmount: 0,
    totalPaymentAmount: 0,
  });

  // Filters & Sorting
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSupplierId, setSelectedSupplierId] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');
  const [sortBy, setSortBy] = useState('default');
  const isFirstFilterChange = useRef(true);
  const isFirstTimeChange = useRef(true);
  const categoryTabsRef = useRef(null);
  const supplierTabsRef = useRef(null);

  // Checkbox metrics visibility (saved in localStorage, default all unticked)
  const [visibleMetrics, setVisibleMetrics] = useState(() =>
    loadSavedMetrics('dm_catalog_metrics_v3')
  );

  // Ledger state: selected product to show ledger below table
  const [ledgerProduct, setLedgerProduct] = useState(null);

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Form data for Create/Edit
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
    reorderPoint: 5,
  });

  // Load suppliers, categories & warehouses
  useEffect(() => {
    warehouseService.getWarehouses().then((res) => {
      if (Array.isArray(res) && res.length > 0) setWarehouses(res);
    }).catch(() => {});

    productService.getDependencies().then((res) => {
      if (res?.suppliers) setSuppliers(res.suppliers);
    }).catch(() => {});

    productService.getCategories().then((res) => {
      if (Array.isArray(res)) setCategories(res);
    }).catch(() => {});
  }, []);

  // Load products with pagination
  const loadProducts = useCallback(async (page = currentPage) => {
    setLoading(true);
    try {
      const timeParams = getMetricTimeParams(visibleMetrics);
      const parsedSupplierId =
        selectedSupplierId === 'NONE'
          ? -1
          : selectedSupplierId
          ? Number(selectedSupplierId)
          : undefined;

      const res = await productService.getAll({
        page,
        pageSize: 15,
        q: searchQuery || undefined,
        supplierId: parsedSupplierId,
        sortBy: sortBy !== 'default' ? sortBy : undefined,
        category: selectedCategory !== 'ALL' ? selectedCategory : undefined,
        fromDate: timeParams.fromDate,
        toDate: timeParams.toDate,
      });

      if (res && res.items) {
        setProducts(res.items);
        setCurrentPage(res.page || page);
        setTotalPages(res.totalPages || 1);
        setTotalCount(res.totalCount || 0);
        setCategoryCounts(res.categoryCounts || {});
        setSupplierCounts(res.supplierCounts || {});
        setServerSummary({
          totalStockQty: res.totalStockQty || 0,
          totalCostVal: res.totalCostVal || 0,
          totalWholesaleVal: res.totalWholesaleVal || 0,
          totalRetailVal: res.totalRetailVal || 0,
          totalImportAmount: res.totalImportAmount || 0,
          totalExportAmount: res.totalExportAmount || 0,
          totalReceiptAmount: res.totalReceiptAmount || 0,
          totalPaymentAmount: res.totalPaymentAmount || 0,
        });
      } else if (Array.isArray(res)) {
        setProducts(res);
        setTotalCount(res.length);
        setTotalPages(Math.ceil(res.length / 15) || 1);
      }
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách sản phẩm');
    } finally {
      setLoading(false);
    }
  }, [currentPage, searchQuery, selectedSupplierId, sortBy, selectedCategory, visibleMetrics.timeMode, visibleMetrics.timeDate, visibleMetrics.timeMonth, notify]);

  useEffect(() => {
    loadProducts(currentPage);
  }, [currentPage]);

  useEffect(() => {
    if (isFirstTimeChange.current) {
      isFirstTimeChange.current = false;
      return;
    }
    loadProducts(currentPage);
  }, [visibleMetrics.timeMode, visibleMetrics.timeDate, visibleMetrics.timeMonth]);

  useEffect(() => {
    if (isFirstFilterChange.current) {
      isFirstFilterChange.current = false;
      return;
    }
    if (currentPage === 1) {
      loadProducts(1);
    } else {
      setCurrentPage(1);
    }
  }, [searchQuery, selectedSupplierId, sortBy, selectedCategory]);

  const loadData = () => {
    productService.getCategories().then((res) => {
      if (Array.isArray(res)) setCategories(res);
    }).catch(() => {});
    return loadProducts(currentPage);
  };

  const scrollCategoryTabs = (direction) => {
    if (categoryTabsRef.current) {
      const offset = direction === 'left' ? -220 : 220;
      categoryTabsRef.current.scrollBy({ left: offset, behavior: 'smooth' });
    }
  };

  const scrollSupplierTabs = (direction) => {
    if (supplierTabsRef.current) {
      const offset = direction === 'left' ? -220 : 220;
      supplierTabsRef.current.scrollBy({ left: offset, behavior: 'smooth' });
    }
  };

  const allSuppliersCount = Object.values(supplierCounts).reduce((sum, n) => sum + Number(n || 0), 0);
  const allCategoriesCount = Object.values(categoryCounts).reduce((sum, n) => sum + Number(n || 0), 0);

  // Create Product Handlers
  const handleOpenCreate = () => {
    const randomSku = 'SP' + Math.floor(1000 + Math.random() * 9000);
    setFormData({
      sku: randomSku,
      name: '',
      category: categories[0] || 'Mặc định',
      uom: 'Cái',
      barcode: '',
      supplierId: suppliers[0]?.id ? String(suppliers[0].id) : '',
      unitCost: 0,
      wholesalePrice: 0,
      retailPrice: 0,
      reorderPoint: 5,
    });
    setIsCreateOpen(true);
  };

  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      notify.warning('Vui lòng nhập tên sản phẩm');
      return;
    }
    setSubmitting(true);
    try {
      await productService.create({
        sku: formData.sku.trim(),
        name: formData.name.trim(),
        category: formData.category.trim(),
        uom: formData.uom.trim() || 'Cái',
        barcode: formData.barcode.trim(),
        supplierId: formData.supplierId ? Number(formData.supplierId) : null,
        unitCost: Number(formData.unitCost || 0),
        wholesalePrice: Number(formData.wholesalePrice || 0),
        retailPrice: Number(formData.retailPrice || 0),
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

  // Edit Product Handlers
  const handleOpenEdit = (p) => {
    setSelectedProduct(p);
    setFormData({
      sku: p.sku || '',
      name: p.name || '',
      category: p.category || '',
      uom: p.uom || 'Cái',
      barcode: p.barcode || '',
      supplierId: p.supplierId ? String(p.supplierId) : '',
      unitCost: p.unitCost || 0,
      wholesalePrice: p.wholesalePrice || 0,
      retailPrice: p.retailPrice || 0,
      reorderPoint: p.reorderPoint || 0,
    });
    setIsEditOpen(true);
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      notify.warning('Vui lòng nhập tên sản phẩm');
      return;
    }
    setSubmitting(true);
    try {
      await productService.update(selectedProduct.id, {
        name: formData.name.trim(),
        category: formData.category.trim(),
        uom: formData.uom.trim() || 'Cái',
        barcode: formData.barcode.trim(),
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

  const handleOpenDelete = (p) => {
    setProductToDelete(p);
    setIsDeleteConfirmOpen(true);
  };

  const handleDeleteSubmit = async () => {
    if (!productToDelete) return;
    setSubmitting(true);
    try {
      await productService.delete(productToDelete.id);
      notify.success(`Đã xóa sản phẩm "${productToDelete.name}" thành công!`);
      setIsDeleteConfirmOpen(false);
      setProductToDelete(null);
      if (ledgerProduct?.id === productToDelete.id) {
        setLedgerProduct(null);
      }
      loadData();
    } catch (err) {
      notify.error(err.message || 'Không thể xóa sản phẩm');
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
            <span>Danh Mục Sản Phẩm</span>
          </h1>
          <p className="page-subtitle">
            Quản lý mã hàng hóa, phân loại, giá bán và xem sổ chi tiết giao dịch từng sản phẩm
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

      {/* Summary Stat Cards */}
      <div className="stat-grid" style={{ marginBottom: '1.25rem' }}>
        <StatCard
          icon={Package}
          iconColor="#3b82f6"
          title="Tổng mặt hàng"
          value={formatNumber(totalCount)}
          subtitle="Sản phẩm trong danh mục"
        />
        <StatCard
          icon={Boxes}
          iconColor="#10b981"
          title="Tổng tồn kho"
          value={formatNumber(serverSummary.totalStockQty)}
          subtitle="Số lượng hiện có"
        />
        <StatCard
          icon={DollarSign}
          iconColor="#f59e0b"
          title="Tổng giá trị vốn"
          value={formatVND(serverSummary.totalCostVal)}
          subtitle="Ước tính theo giá vốn"
        />
        <StatCard
          icon={Layers}
          iconColor="#8b5cf6"
          title="Giá trị bán sỉ / lẻ"
          value={formatVND(serverSummary.totalRetailVal)}
          subtitle={`Sỉ: ${formatVND(serverSummary.totalWholesaleVal)}`}
        />
      </div>

      {/* Search, Filter & Metrics Bar */}
      <div
        className="card"
        style={{
          padding: '0.875rem 1.25rem',
          marginBottom: '1rem',
          display: 'flex',
          flexWrap: 'wrap',
          gap: '0.75rem',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem', alignItems: 'center', flex: 1, minWidth: '300px' }}>
          <div style={{ width: '280px', maxWidth: '100%' }}>
            <SearchBar
              value={searchQuery}
              onChange={(val) => setSearchQuery(val)}
              placeholder="Tìm theo mã SKU, tên, mã vạch..."
            />
          </div>

          <div style={{ width: '200px' }}>
            <SearchableSelect
              options={[
                { value: '', label: 'Tất cả Nhà Cung Cấp' },
                ...suppliers.map((s) => ({ value: String(s.id), label: `${s.name} (${s.code || ''})` })),
              ]}
              value={selectedSupplierId}
              onChange={(val) => setSelectedSupplierId(val)}
              placeholder="Lọc theo NCC..."
            />
          </div>

          <div style={{ width: '220px' }}>
            <SortDropdown
              options={PRODUCT_SORT_OPTIONS}
              value={sortBy}
              onChange={(val) => setSortBy(val)}
            />
          </div>
        </div>

        {/* Metrics Checkbox Group */}
        <WarehouseMetricCheckboxes
          warehouses={warehouses}
          visibleMetrics={visibleMetrics}
          onChange={setVisibleMetrics}
          showCashBook={true}
          primaryDirection="export"
          storageKey="dm_catalog_metrics_v3"
        />
      </div>

      {/* Horizontal Supplier (NCC) Filter Strip */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          backgroundColor: '#f8fafc',
          border: '1px solid var(--border-color, #e2e8f0)',
          borderBottom: 'none',
          borderRadius: 'var(--radius, 8px) var(--radius, 8px) 0 0',
          marginBottom: 0,
          position: 'relative',
          userSelect: 'none',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '5px',
            padding: '0.55rem 0.75rem',
            color: '#0f172a',
            fontWeight: 700,
            fontSize: '0.78rem',
            borderRight: '1px solid var(--border-color, #e2e8f0)',
            backgroundColor: '#ffffff',
            flexShrink: 0,
          }}
          title="Lọc ngang theo Nhà cung cấp (NCC)"
        >
          <Truck size={15} color="#2563eb" />
          <span>NCC:</span>
        </div>

        <button
          type="button"
          onClick={() => scrollSupplierTabs('left')}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0.55rem 0.45rem',
            color: '#64748b',
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            flexShrink: 0,
          }}
          title="Cuộn sang trái"
        >
          <ChevronLeft size={16} />
        </button>

        <div
          ref={supplierTabsRef}
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
            if (supplierTabsRef.current && e.deltaY !== 0) {
              supplierTabsRef.current.scrollLeft += e.deltaY;
            }
          }}
        >
          <button
            type="button"
            onClick={() => setSelectedSupplierId('')}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              padding: '0.55rem 0.9rem',
              fontSize: '0.84rem',
              fontWeight: selectedSupplierId === '' ? 700 : 500,
              color: selectedSupplierId === '' ? '#0f172a' : '#64748b',
              backgroundColor: selectedSupplierId === '' ? '#ffffff' : 'transparent',
              border: 'none',
              cursor: 'pointer',
              borderBottom: selectedSupplierId === '' ? '3px solid #2563eb' : '3px solid transparent',
              transition: 'all 0.15s ease',
              flexShrink: 0,
            }}
          >
            <span>Tất cả NCC</span>
            <span
              style={{
                fontSize: '0.72rem',
                padding: '1px 6px',
                borderRadius: '10px',
                backgroundColor: selectedSupplierId === '' ? '#dbeafe' : '#e2e8f0',
                color: selectedSupplierId === '' ? '#1e40af' : '#475569',
                fontWeight: 600,
              }}
            >
              {allSuppliersCount || totalCount}
            </span>
          </button>

          {suppliers.map((sup) => {
            const supKey = String(sup.id);
            const isSelected = String(selectedSupplierId) === supKey;
            const count = supplierCounts[supKey] || 0;
            return (
              <button
                key={sup.id}
                type="button"
                onClick={() => setSelectedSupplierId(supKey)}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '0.55rem 0.9rem',
                  fontSize: '0.84rem',
                  fontWeight: isSelected ? 700 : 500,
                  color: isSelected ? '#0f172a' : '#475569',
                  backgroundColor: isSelected ? '#ffffff' : 'transparent',
                  border: 'none',
                  cursor: 'pointer',
                  borderBottom: isSelected ? '3px solid #2563eb' : '3px solid transparent',
                  transition: 'all 0.15s ease',
                  flexShrink: 0,
                }}
              >
                <span>{sup.name}</span>
                <span
                  style={{
                    fontSize: '0.72rem',
                    padding: '1px 6px',
                    borderRadius: '10px',
                    backgroundColor: isSelected ? '#dbeafe' : '#e2e8f0',
                    color: isSelected ? '#1e40af' : '#475569',
                    fontWeight: 600,
                  }}
                >
                  {count}
                </span>
              </button>
            );
          })}

          {(supplierCounts.NONE || 0) > 0 && (
            <button
              type="button"
              onClick={() => setSelectedSupplierId('NONE')}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '0.55rem 0.9rem',
                fontSize: '0.84rem',
                fontWeight: selectedSupplierId === 'NONE' ? 700 : 500,
                color: selectedSupplierId === 'NONE' ? '#0f172a' : '#64748b',
                backgroundColor: selectedSupplierId === 'NONE' ? '#ffffff' : 'transparent',
                border: 'none',
                cursor: 'pointer',
                borderBottom: selectedSupplierId === 'NONE' ? '3px solid #2563eb' : '3px solid transparent',
                transition: 'all 0.15s ease',
                flexShrink: 0,
                fontStyle: 'italic',
              }}
            >
              <span>Chưa gán NCC</span>
              <span
                style={{
                  fontSize: '0.72rem',
                  padding: '1px 6px',
                  borderRadius: '10px',
                  backgroundColor: selectedSupplierId === 'NONE' ? '#dbeafe' : '#e2e8f0',
                  color: selectedSupplierId === 'NONE' ? '#1e40af' : '#475569',
                  fontWeight: 600,
                }}
              >
                {supplierCounts.NONE}
              </span>
            </button>
          )}
        </div>

        <button
          type="button"
          onClick={() => scrollSupplierTabs('right')}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0.55rem 0.45rem',
            color: '#64748b',
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            flexShrink: 0,
          }}
          title="Cuộn sang phải"
        >
          <ChevronRight size={16} />
        </button>
      </div>

      {/* Category Tabs Strip */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          backgroundColor: '#f8fafc',
          border: '1px solid var(--border-color, #e2e8f0)',
          borderRadius: '0',
          marginBottom: 0,
          position: 'relative',
          userSelect: 'none',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '5px',
            padding: '0.6rem 0.75rem',
            color: 'var(--text-muted, #64748b)',
            fontWeight: 700,
            fontSize: '0.78rem',
            borderRight: '1px solid var(--border-color, #e2e8f0)',
            backgroundColor: '#ffffff',
            flexShrink: 0,
          }}
          title="Danh mục sản phẩm"
        >
          <Menu size={15} />
          <span>Loại:</span>
        </div>

        <button
          type="button"
          onClick={() => scrollCategoryTabs('left')}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0.6rem 0.5rem',
            color: '#64748b',
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            flexShrink: 0,
          }}
          title="Cuộn sang trái"
        >
          <ChevronLeft size={16} />
        </button>

        <div
          ref={categoryTabsRef}
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
        >
          <button
            type="button"
            onClick={() => setSelectedCategory('ALL')}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              padding: '0.65rem 1rem',
              fontSize: '0.875rem',
              fontWeight: selectedCategory === 'ALL' ? 700 : 500,
              color: selectedCategory === 'ALL' ? '#0f172a' : '#64748b',
              backgroundColor: selectedCategory === 'ALL' ? '#ffffff' : 'transparent',
              border: 'none',
              cursor: 'pointer',
              borderBottom: selectedCategory === 'ALL' ? '3px solid #16a34a' : '3px solid transparent',
              transition: 'all 0.15s ease',
              flexShrink: 0,
            }}
          >
            <span>Tất cả danh mục</span>
            <span
              style={{
                fontSize: '0.75rem',
                padding: '1px 6px',
                borderRadius: '10px',
                backgroundColor: selectedCategory === 'ALL' ? '#dcfce7' : '#e2e8f0',
                color: selectedCategory === 'ALL' ? '#166534' : '#475569',
                fontWeight: 600,
              }}
            >
              {allCategoriesCount || totalCount}
            </span>
          </button>

          {categories.map((cat) => {
            const isSelected = selectedCategory === cat;
            const count = categoryCounts[cat] || 0;
            return (
              <button
                key={cat}
                type="button"
                onClick={() => setSelectedCategory(cat)}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '0.65rem 1rem',
                  fontSize: '0.875rem',
                  fontWeight: isSelected ? 700 : 500,
                  color: isSelected ? '#0f172a' : '#64748b',
                  backgroundColor: isSelected ? '#ffffff' : 'transparent',
                  border: 'none',
                  cursor: 'pointer',
                  borderBottom: isSelected ? '3px solid #16a34a' : '3px solid transparent',
                  transition: 'all 0.15s ease',
                  flexShrink: 0,
                }}
              >
                <span>{cat}</span>
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
        </div>

        <button
          type="button"
          onClick={() => scrollCategoryTabs('right')}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0.6rem 0.5rem',
            color: '#64748b',
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            flexShrink: 0,
          }}
          title="Cuộn sang phải"
        >
          <ChevronRight size={16} />
        </button>
      </div>

      {/* Product Table */}
      {products.length === 0 && !loading ? (
        <EmptyState
          icon={Package}
          title="Không tìm thấy sản phẩm"
          description="Chưa có sản phẩm nào hoặc không khớp với bộ lọc hiện tại."
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>Thêm sản phẩm ngay</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive" style={{ borderTop: 'none', borderRadius: '0 0 var(--radius, 8px) var(--radius, 8px)' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã SKU</th>
                <th>Tên Sản Phẩm</th>
                <th>Danh Mục</th>
                <th style={{ textAlign: 'center' }}>ĐVT</th>
                <th style={{ textAlign: 'right' }}>Giá Vốn</th>
                <th style={{ textAlign: 'right' }}>Giá Sỉ</th>
                <th style={{ textAlign: 'right' }}>Giá Lẻ</th>
                <th style={{ textAlign: 'right' }}>Tồn Kho</th>
                {/* Cột Xuất theo từng kho & Tổng */}
                {warehouses.map((wh) =>
                  visibleMetrics.exportWarehouses?.[wh.id] ? (
                    <th key={`th-cat-exp-${wh.id}`} style={{ textAlign: 'right', color: '#ea580c' }}>
                      Xuất {wh.shortName || wh.name}
                    </th>
                  ) : null
                )}
                {visibleMetrics.exportTotal && (
                  <th style={{ textAlign: 'right', color: '#ea580c', fontWeight: 800 }}>Tổng Xuất</th>
                )}
                {/* Cột Nhập theo từng kho & Tổng */}
                {warehouses.map((wh) =>
                  visibleMetrics.importWarehouses?.[wh.id] ? (
                    <th key={`th-cat-imp-${wh.id}`} style={{ textAlign: 'right', color: '#1d4ed8' }}>
                      Nhập {wh.shortName || wh.name}
                    </th>
                  ) : null
                )}
                {visibleMetrics.importTotal && (
                  <th style={{ textAlign: 'right', color: '#1d4ed8', fontWeight: 800 }}>Tổng Nhập</th>
                )}
                {visibleMetrics.receipt && <th style={{ textAlign: 'right', color: '#16a34a' }}>Đã Thu</th>}
                {visibleMetrics.payment && <th style={{ textAlign: 'right', color: '#dc2626' }}>Đã Chi</th>}
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => {
                const isSelected = ledgerProduct?.id === p.id;
                const totalStock = Number(p.totalStock ?? p.currentStock ?? 0);

                return (
                  <tr
                    key={p.id}
                    onClick={() => setLedgerProduct(isSelected ? null : p)}
                    style={{
                      cursor: 'pointer',
                      backgroundColor: isSelected ? 'rgba(37, 99, 235, 0.08)' : undefined,
                      transition: 'background-color 0.15s ease',
                    }}
                    title="Bấm vào để xem sổ chi tiết Nhập / Xuất / Thu / Chi"
                  >
                    <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                      {p.sku}
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{p.name}</div>
                      {p.barcode && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                          Barcode: {p.barcode}
                        </div>
                      )}
                    </td>
                    <td>
                      <span className="badge badge-subtle">{p.category || 'Mặc định'}</span>
                    </td>
                    <td style={{ textAlign: 'center', color: 'var(--text-secondary)' }}>
                      {p.uom || 'Cái'}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(p.unitCost)}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(p.wholesalePrice)}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(p.retailPrice)}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      <span
                        style={{
                          fontWeight: 700,
                          color: totalStock <= (p.reorderPoint || 0) ? 'var(--danger)' : 'var(--text-primary)',
                        }}
                      >
                        {formatNumber(totalStock)}
                      </span>
                    </td>

                    {/* Xuất theo từng kho: hiển thị cả SL & Thành tiền */}
                    {warehouses.map((wh) => {
                      if (!visibleMetrics.exportWarehouses?.[wh.id]) return null;
                      const metric = p.warehouseMetrics?.[wh.id] || p.warehouseMetrics?.[wh.id.toLowerCase()];
                      const exportQty = metric?.exportQty || 0;
                      const exportAmount = metric?.exportAmount || 0;
                      return (
                        <td key={`td-cat-exp-${wh.id}`} style={{ textAlign: 'right' }} className="mono">
                          <div style={{ fontWeight: 700, color: exportQty > 0 ? '#ea580c' : 'var(--text-muted)' }}>
                            SL: {formatNumber(exportQty)} {p.uom || ''}
                          </div>
                          <div style={{ fontSize: '0.75rem', color: exportAmount > 0 ? '#c2410c' : 'var(--text-muted)' }}>
                            {formatVND(exportAmount)}
                          </div>
                        </td>
                      );
                    })}

                    {/* Tổng Xuất: hiển thị cả SL & Thành tiền */}
                    {visibleMetrics.exportTotal && (
                      <td style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: 800, color: (p.totalExportQty || 0) > 0 ? '#ea580c' : 'var(--text-muted)' }}>
                          SL: {formatNumber(p.totalExportQty || 0)} {p.uom || ''}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: (p.totalExportAmount || 0) > 0 ? '#c2410c' : 'var(--text-muted)' }}>
                          {formatVND(p.totalExportAmount || 0)}
                        </div>
                      </td>
                    )}

                    {/* Nhập theo từng kho: hiển thị cả SL & Thành tiền */}
                    {warehouses.map((wh) => {
                      if (!visibleMetrics.importWarehouses?.[wh.id]) return null;
                      const metric = p.warehouseMetrics?.[wh.id] || p.warehouseMetrics?.[wh.id.toLowerCase()];
                      const importQty = metric?.importQty || 0;
                      const importAmount = metric?.importAmount || 0;
                      return (
                        <td key={`td-cat-imp-${wh.id}`} style={{ textAlign: 'right' }} className="mono">
                          <div style={{ fontWeight: 700, color: importQty > 0 ? '#1d4ed8' : 'var(--text-muted)' }}>
                            SL: {formatNumber(importQty)} {p.uom || ''}
                          </div>
                          <div style={{ fontSize: '0.75rem', color: importAmount > 0 ? '#1e40af' : 'var(--text-muted)' }}>
                            {formatVND(importAmount)}
                          </div>
                        </td>
                      );
                    })}

                    {/* Tổng Nhập: hiển thị cả SL & Thành tiền */}
                    {visibleMetrics.importTotal && (
                      <td style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: 800, color: (p.totalImportQty || 0) > 0 ? '#1d4ed8' : 'var(--text-muted)' }}>
                          SL: {formatNumber(p.totalImportQty || 0)} {p.uom || ''}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: (p.totalImportAmount || 0) > 0 ? '#1e40af' : 'var(--text-muted)' }}>
                          {formatVND(p.totalImportAmount || 0)}
                        </div>
                      </td>
                    )}

                    {/* Metric: Thu */}
                    {visibleMetrics.receipt && (
                      <td style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: 700, color: (p.totalReceiptAmount || 0) > 0 ? '#16a34a' : 'var(--text-muted)' }}>
                          {formatVND(p.totalReceiptAmount || 0)}
                        </div>
                      </td>
                    )}

                    {/* Metric: Chi */}
                    {visibleMetrics.payment && (
                      <td style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: 700, color: (p.totalPaymentAmount || 0) > 0 ? '#dc2626' : 'var(--text-muted)' }}>
                          {formatVND(p.totalPaymentAmount || 0)}
                        </div>
                      </td>
                    )}

                    {/* Actions */}
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                      <div style={{ display: 'inline-flex', gap: '4px' }}>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: '#2563eb', borderColor: '#bfdbfe', backgroundColor: '#eff6ff' }}
                          title="Xem sổ chi tiết Nhập / Xuất / Thu / Chi (4 cột)"
                          onClick={() => setLedgerProduct(p)}
                        >
                          <ReceiptText size={15} />
                        </button>
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
                          style={{ width: '32px', height: '32px', color: 'var(--danger)' }}
                          title="Xóa sản phẩm"
                          onClick={() => handleOpenDelete(p)}
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
            {products.length > 0 && (
              <tfoot>
                <tr style={{ background: 'var(--bg-tertiary)', fontWeight: 700, borderTop: '2px solid var(--border-color)' }}>
                  <td colSpan={7} style={{ textAlign: 'left', fontWeight: 800 }}>
                    TỔNG CỘNG ({products.length} mặt hàng trên trang):
                  </td>
                  <td style={{ textAlign: 'right' }} className="mono">
                    <span className="badge badge-primary mono" style={{ fontWeight: 800 }}>
                      {formatNumber(serverSummary.totalStockQty)}
                    </span>
                  </td>
                  {warehouses.map((wh) => {
                    if (!visibleMetrics.exportWarehouses?.[wh.id]) return null;
                    const totQty = products.reduce((s, p) => {
                      const m = p.warehouseMetrics?.[wh.id] || p.warehouseMetrics?.[wh.id.toLowerCase()];
                      return s + (Number(m?.exportQty) || 0);
                    }, 0);
                    const totAmt = products.reduce((s, p) => {
                      const m = p.warehouseMetrics?.[wh.id] || p.warehouseMetrics?.[wh.id.toLowerCase()];
                      return s + (Number(m?.exportAmount) || 0);
                    }, 0);
                    return (
                      <td key={`tf-cat-exp-${wh.id}`} style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: 800, color: '#ea580c' }}>SL: {formatNumber(totQty)}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{formatVND(totAmt)}</div>
                      </td>
                    );
                  })}
                  {visibleMetrics.exportTotal && (
                    <td style={{ textAlign: 'right' }} className="mono">
                      <div style={{ fontWeight: 800, color: '#ea580c' }}>
                        SL: {formatNumber(products.reduce((s, p) => s + (Number(p.totalExportQty) || 0), 0))}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        {formatVND(products.reduce((s, p) => s + (Number(p.totalExportAmount) || 0), 0))}
                      </div>
                    </td>
                  )}
                  {warehouses.map((wh) => {
                    if (!visibleMetrics.importWarehouses?.[wh.id]) return null;
                    const totQty = products.reduce((s, p) => {
                      const m = p.warehouseMetrics?.[wh.id] || p.warehouseMetrics?.[wh.id.toLowerCase()];
                      return s + (Number(m?.importQty) || 0);
                    }, 0);
                    const totAmt = products.reduce((s, p) => {
                      const m = p.warehouseMetrics?.[wh.id] || p.warehouseMetrics?.[wh.id.toLowerCase()];
                      return s + (Number(m?.importAmount) || 0);
                    }, 0);
                    return (
                      <td key={`tf-cat-imp-${wh.id}`} style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: 800, color: '#1d4ed8' }}>SL: {formatNumber(totQty)}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{formatVND(totAmt)}</div>
                      </td>
                    );
                  })}
                  {visibleMetrics.importTotal && (
                    <td style={{ textAlign: 'right' }} className="mono">
                      <div style={{ fontWeight: 800, color: '#1d4ed8' }}>
                        SL: {formatNumber(products.reduce((s, p) => s + (Number(p.totalImportQty) || 0), 0))}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        {formatVND(products.reduce((s, p) => s + (Number(p.totalImportAmount) || 0), 0))}
                      </div>
                    </td>
                  )}
                  {visibleMetrics.receipt && (
                    <td style={{ textAlign: 'right', fontWeight: 800, color: '#16a34a' }} className="mono">
                      {formatVND(products.reduce((s, p) => s + (Number(p.totalReceiptAmount) || 0), 0))}
                    </td>
                  )}
                  {visibleMetrics.payment && (
                    <td style={{ textAlign: 'right', fontWeight: 800, color: '#dc2626' }} className="mono">
                      {formatVND(products.reduce((s, p) => s + (Number(p.totalPaymentAmount) || 0), 0))}
                    </td>
                  )}
                  <td style={{ textAlign: 'center' }}>-</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}

      {/* Modal Sổ Chi Tiết Nhập / Xuất / Thu / Chi Sản Phẩm */}
      {ledgerProduct && (
        <EntityTransactionLedger
          entityType="product"
          entityId={ledgerProduct.id}
          entityName={ledgerProduct.name}
          entityCode={ledgerProduct.sku}
          asModal={true}
          onClose={() => setLedgerProduct(null)}
        />
      )}

      {/* Pagination (15 items per page) */}
      <Pagination
        currentPage={currentPage}
        totalPages={totalPages}
        totalCount={totalCount}
        pageSize={15}
        onPageChange={(p) => setCurrentPage(p)}
        disabled={loading}
        itemLabel="sản phẩm"
      />

      {/* MODAL: Tạo sản phẩm mới */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Thêm Sản Phẩm Mới"
        maxWidth="650px"
      >
        <form onSubmit={handleCreateSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div className="form-row">
            <div className="form-group flex-1">
              <label className="form-label">Mã SKU <span className="text-danger">*</span></label>
              <input
                type="text"
                className="form-control mono"
                required
                value={formData.sku}
                onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
                placeholder="VD: SP001"
              />
            </div>
            <div className="form-group flex-2">
              <label className="form-label">Tên Sản Phẩm <span className="text-danger">*</span></label>
              <input
                type="text"
                className="form-control"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="Nhập tên hàng hóa, quy cách..."
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group flex-1">
              <label className="form-label">Danh Mục</label>
              <input
                type="text"
                className="form-control"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                placeholder="VD: Đồ uống, Bánh kẹo..."
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Đơn Vị Tính (ĐVT)</label>
              <input
                type="text"
                className="form-control"
                value={formData.uom}
                onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
                placeholder="Cái, Thùng, Hộp..."
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Mã Vạch (Barcode)</label>
              <input
                type="text"
                className="form-control mono"
                value={formData.barcode}
                onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
                placeholder="Quét hoặc nhập mã vạch"
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Nhà Cung Cấp Mặc Định</label>
            <SearchableSelect
              options={[
                { value: '', label: '-- Không chọn nhà cung cấp --' },
                ...suppliers.map((s) => ({ value: String(s.id), label: `${s.name} (${s.code || ''})` })),
              ]}
              value={formData.supplierId}
              onChange={(val) => setFormData({ ...formData, supplierId: val })}
              placeholder="Chọn nhà cung cấp chính..."
            />
          </div>

          <div className="form-row">
            <div className="form-group flex-1">
              <label className="form-label">Giá Vốn (VNĐ)</label>
              <input
                type="number"
                className="form-control mono"
                min="0"
                value={formData.unitCost}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Giá Sỉ (VNĐ)</label>
              <input
                type="number"
                className="form-control mono"
                min="0"
                value={formData.wholesalePrice}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Giá Lẻ (VNĐ)</label>
              <input
                type="number"
                className="form-control mono"
                min="0"
                value={formData.retailPrice}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Định mức tồn tối thiểu (Cảnh báo hết hàng)</label>
            <input
              type="number"
              className="form-control mono"
              min="0"
              value={formData.reorderPoint}
              onChange={(e) => setFormData({ ...formData, reorderPoint: e.target.value })}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1rem' }}>
            <button type="button" className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Hủy bỏ
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Thêm sản phẩm'}
            </button>
          </div>
        </form>
      </Modal>

      {/* MODAL: Sửa sản phẩm */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa Sản Phẩm: ${selectedProduct?.name || ''}`}
        maxWidth="650px"
      >
        <form onSubmit={handleEditSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div className="form-row">
            <div className="form-group flex-1">
              <label className="form-label">Mã SKU</label>
              <input
                type="text"
                className="form-control mono"
                disabled
                value={formData.sku}
              />
            </div>
            <div className="form-group flex-2">
              <label className="form-label">Tên Sản Phẩm <span className="text-danger">*</span></label>
              <input
                type="text"
                className="form-control"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group flex-1">
              <label className="form-label">Danh Mục</label>
              <input
                type="text"
                className="form-control"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Đơn Vị Tính (ĐVT)</label>
              <input
                type="text"
                className="form-control"
                value={formData.uom}
                onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Mã Vạch (Barcode)</label>
              <input
                type="text"
                className="form-control mono"
                value={formData.barcode}
                onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Nhà Cung Cấp Mặc Định</label>
            <SearchableSelect
              options={[
                { value: '', label: '-- Không chọn nhà cung cấp --' },
                ...suppliers.map((s) => ({ value: String(s.id), label: `${s.name} (${s.code || ''})` })),
              ]}
              value={formData.supplierId}
              onChange={(val) => setFormData({ ...formData, supplierId: val })}
            />
          </div>

          <div className="form-row">
            <div className="form-group flex-1">
              <label className="form-label">Giá Vốn (VNĐ)</label>
              <input
                type="number"
                className="form-control mono"
                min="0"
                value={formData.unitCost}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Giá Sỉ (VNĐ)</label>
              <input
                type="number"
                className="form-control mono"
                min="0"
                value={formData.wholesalePrice}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>
            <div className="form-group flex-1">
              <label className="form-label">Giá Lẻ (VNĐ)</label>
              <input
                type="number"
                className="form-control mono"
                min="0"
                value={formData.retailPrice}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Định mức tồn tối thiểu (Cảnh báo hết hàng)</label>
            <input
              type="number"
              className="form-control mono"
              min="0"
              value={formData.reorderPoint}
              onChange={(e) => setFormData({ ...formData, reorderPoint: e.target.value })}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1rem' }}>
            <button type="button" className="btn btn-outline" onClick={() => setIsEditOpen(false)} disabled={submitting}>
              Hủy bỏ
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting}>
              {submitting ? 'Đang cập nhật...' : 'Lưu thay đổi'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Confirm Delete Modal */}
      <ConfirmModal
        isOpen={isDeleteConfirmOpen}
        onClose={() => setIsDeleteConfirmOpen(false)}
        onConfirm={handleDeleteSubmit}
        title="Xác nhận xóa sản phẩm"
        message={`Bạn có chắc chắn muốn xóa sản phẩm "${productToDelete?.name}" (${productToDelete?.sku})? Thao tác này không thể hoàn tác nếu sản phẩm chưa phát sinh đơn hàng.`}
        confirmText="Xác nhận xóa"
        confirmVariant="danger"
        isLoading={submitting}
      />
    </div>
  );
}

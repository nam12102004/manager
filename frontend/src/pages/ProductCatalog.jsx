import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
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
import useDragScroll from '../hooks/useDragScroll';
import TableScrollContainer from '../components/common/TableScrollContainer';
import SubUnitsEditor from '../components/common/SubUnitsEditor';
import {
  getProductUnits,
  getBaseUnit,
  getPrimaryDisplayUnit,
  saveDisplayUnitForProduct,
  loadDisplayUnitsMap,
  convertQtyToDisplayUnit,
  getDisplayPrices,
  formatStockDisplay,
} from '../utils/uomHelper';

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
  const tableContainerRef = useDragScroll();
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
  const [isSubUnitOpen, setIsSubUnitOpen] = useState(false);
  const [productUnits, setProductUnits] = useState([]);
  const [displayUnitOverrides, setDisplayUnitOverrides] = useState(() => loadDisplayUnitsMap());
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
    unitCost: '',
    wholesalePrice: '',
    retailPrice: '',
    reorderPoint: '',
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
  }, [currentPage, searchQuery, selectedSupplierId, sortBy, selectedCategory, visibleMetrics.timeMode, visibleMetrics.timeDate, visibleMetrics.timeMonth, visibleMetrics.timeFromDate, visibleMetrics.timeToDate, notify]);

  useEffect(() => {
    loadProducts(currentPage);
  }, [currentPage]);

  useEffect(() => {
    if (isFirstTimeChange.current) {
      isFirstTimeChange.current = false;
      return;
    }
    loadProducts(currentPage);
  }, [visibleMetrics.timeMode, visibleMetrics.timeDate, visibleMetrics.timeMonth, visibleMetrics.timeFromDate, visibleMetrics.timeToDate]);

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

  // Cascading horizontal filter logic:
  // When category is selected, filter suppliers to only those with count > 0 (or selected).
  // When unselected (ALL), restore all suppliers.
  const visibleSuppliers = useMemo(() => {
    if (selectedCategory === 'ALL') {
      return suppliers;
    }
    return suppliers.filter((sup) => {
      const supKey = String(sup.id);
      const count = supplierCounts[supKey] || 0;
      const isSelected = String(selectedSupplierId) === supKey;
      return count > 0 || isSelected;
    });
  }, [suppliers, selectedCategory, supplierCounts, selectedSupplierId]);

  const showNoneSupplier = selectedCategory !== 'ALL'
    ? (supplierCounts.NONE || 0) > 0 || selectedSupplierId === 'NONE'
    : (supplierCounts.NONE || 0) > 0;

  // When supplier is selected, filter categories to only those with count > 0 (or selected).
  // When unselected (''), restore all categories.
  const visibleCategories = useMemo(() => {
    if (!selectedSupplierId) {
      return categories;
    }
    return categories.filter((cat) => {
      const count = categoryCounts[cat.trim()] ?? categoryCounts[cat] ?? 0;
      const isSelected = selectedCategory === cat || (selectedCategory && selectedCategory.trim() === cat.trim());
      return count > 0 || isSelected;
    });
  }, [categories, selectedSupplierId, categoryCounts, selectedCategory]);

  const showNoneCategory = Boolean(selectedSupplierId)
    ? (categoryCounts.NONE || 0) > 0 || selectedCategory === 'NONE'
    : (categoryCounts.NONE || 0) > 0;

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
      unitCost: '',
      wholesalePrice: '',
      retailPrice: '',
      reorderPoint: '',
    });
    setProductUnits([{ unitName: 'Cái', conversionRate: 1, isBaseUnit: true }]);
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
      const chosenUom = formData.uom.trim() || 'Cái';
      const created = await productService.create({
        sku: formData.sku.trim(),
        name: formData.name.trim(),
        category: formData.category.trim(),
        uom: chosenUom,
        barcode: formData.barcode.trim(),
        supplierId: formData.supplierId ? Number(formData.supplierId) : null,
        unitCost: Number(formData.unitCost || 0),
        wholesalePrice: Number(formData.wholesalePrice || 0),
        retailPrice: Number(formData.retailPrice || 0),
        reorderPoint: Number(formData.reorderPoint || 0),
        units: productUnits,
      });

      if (created?.id) {
        saveDisplayUnitForProduct(created.id, chosenUom);
        setDisplayUnitOverrides(loadDisplayUnitsMap());
      }

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
    const primaryUnit = getPrimaryDisplayUnit(p, displayUnitOverrides[String(p.id)]);
    setFormData({
      sku: p.sku || '',
      name: p.name || '',
      category: p.category || '',
      uom: primaryUnit?.unitName || p.uom || 'Cái',
      barcode: p.barcode || '',
      supplierId: p.supplierId ? String(p.supplierId) : '',
      unitCost: p.unitCost || 0,
      wholesalePrice: p.wholesalePrice || 0,
      retailPrice: p.retailPrice || 0,
      reorderPoint: p.reorderPoint || 0,
    });
    setProductUnits(
      p.units && p.units.length > 0
        ? p.units
        : [{ unitName: p.uom || 'Cái', conversionRate: 1, isBaseUnit: true }]
    );
    setIsEditOpen(true);
  };

  const handleOpenSubUnits = (p) => {
    setSelectedProduct(p);
    const primaryUnit = getPrimaryDisplayUnit(p, displayUnitOverrides[String(p.id)]);
    setFormData((prev) => ({
      ...prev,
      uom: primaryUnit?.unitName || p.uom || 'Cái',
    }));
    setProductUnits(
      p.units && p.units.length > 0
        ? p.units
        : [{ unitName: p.uom || 'Cái', conversionRate: 1, isBaseUnit: true }]
    );
    setIsSubUnitOpen(true);
  };

  const handleSaveSubUnits = async () => {
    if (!selectedProduct) return;
    setSubmitting(true);
    try {
      const chosenUom = formData.uom?.trim() || selectedProduct.uom || 'Cái';
      await productService.update(selectedProduct.id, {
        sku: selectedProduct.sku,
        name: selectedProduct.name,
        category: selectedProduct.category,
        uom: chosenUom,
        barcode: selectedProduct.barcode,
        supplierId: selectedProduct.supplierId ? Number(selectedProduct.supplierId) : null,
        unitCost: Number(selectedProduct.unitCost || 0),
        wholesalePrice: Number(selectedProduct.wholesalePrice || 0),
        retailPrice: Number(selectedProduct.retailPrice || 0),
        reorderPoint: Number(selectedProduct.reorderPoint || 0),
        units: productUnits,
      });
      saveDisplayUnitForProduct(selectedProduct.id, chosenUom);
      setDisplayUnitOverrides(loadDisplayUnitsMap());
      notify.success('Cập nhật đơn vị tính & đơn vị hiển thị chính thành công!');
      setIsSubUnitOpen(false);
      loadData();
    } catch (err) {
      notify.error(err.message || 'Cập nhật đơn vị tính thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const handleChangeProductDisplayUnit = async (product, newUnitName) => {
    if (!product || !newUnitName) return;
    saveDisplayUnitForProduct(product.id, newUnitName);
    setDisplayUnitOverrides((prev) => ({
      ...prev,
      [String(product.id)]: newUnitName,
    }));
    setProducts((prev) =>
      prev.map((item) => (item.id === product.id ? { ...item, uom: newUnitName } : item))
    );
    try {
      await productService.update(product.id, {
        sku: product.sku,
        name: product.name,
        category: product.category,
        uom: newUnitName,
        barcode: product.barcode,
        supplierId: product.supplierId ? Number(product.supplierId) : null,
        unitCost: Number(product.unitCost || 0),
        wholesalePrice: Number(product.wholesalePrice || 0),
        retailPrice: Number(product.retailPrice || 0),
        reorderPoint: Number(product.reorderPoint || 0),
        units: product.units && product.units.length > 0 ? product.units : undefined,
      });
    } catch {
      // Lựa chọn vẫn được giữ trong localStorage nếu mất kết nối tạm thời
    }
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    if (!formData.sku || !formData.sku.trim()) {
      notify.warning('Vui lòng nhập mã SKU sản phẩm');
      return;
    }
    if (!formData.name.trim()) {
      notify.warning('Vui lòng nhập tên sản phẩm');
      return;
    }
    setSubmitting(true);
    try {
      const chosenUom = formData.uom.trim() || 'Cái';
      const updated = await productService.update(selectedProduct.id, {
        sku: formData.sku.trim(),
        name: formData.name.trim(),
        category: formData.category.trim(),
        uom: chosenUom,
        barcode: formData.barcode.trim(),
        supplierId: formData.supplierId ? Number(formData.supplierId) : null,
        unitCost: Number(formData.unitCost || 0),
        wholesalePrice: Number(formData.wholesalePrice || 0),
        retailPrice: Number(formData.retailPrice || 0),
        reorderPoint: Number(formData.reorderPoint || 0),
        units: productUnits,
      });
      saveDisplayUnitForProduct(selectedProduct.id, chosenUom);
      setDisplayUnitOverrides(loadDisplayUnitsMap());

      if (ledgerProduct?.id === selectedProduct.id) {
        setLedgerProduct((prev) =>
          prev
            ? {
                ...prev,
                sku: updated?.sku || formData.sku.trim(),
                name: updated?.name || formData.name.trim(),
              }
            : prev
        );
      }

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
                ...visibleSuppliers.map((s) => ({ value: String(s.id), label: `${s.name} (${s.code || ''})` })),
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

          {(searchQuery || selectedSupplierId || sortBy !== 'default' || selectedCategory !== 'ALL') && (
            <button
              className="btn btn-outline btn-sm"
              onClick={() => {
                setSearchQuery('');
                setSelectedSupplierId('');
                setSortBy('default');
                setSelectedCategory('ALL');
              }}
              title="Xóa bộ lọc để xem toàn bộ danh sách"
              style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}
            >
              <Filter size={14} />
              <span>Xóa lọc</span>
            </button>
          )}
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

          {visibleSuppliers.map((sup) => {
            const supKey = String(sup.id);
            const isSelected = String(selectedSupplierId) === supKey;
            const count = supplierCounts[supKey] || 0;
            return (
              <button
                key={sup.id}
                type="button"
                onClick={() => setSelectedSupplierId(isSelected ? '' : supKey)}
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

          {showNoneSupplier && (
            <button
              type="button"
              onClick={() => setSelectedSupplierId(selectedSupplierId === 'NONE' ? '' : 'NONE')}
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

          {visibleCategories.map((cat) => {
            const isSelected = selectedCategory === cat || (selectedCategory && selectedCategory.trim() === cat.trim());
            const count = categoryCounts[cat.trim()] ?? categoryCounts[cat] ?? 0;
            return (
              <button
                key={cat}
                type="button"
                onClick={() => setSelectedCategory(isSelected ? 'ALL' : cat)}
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
          {showNoneCategory && (
            <button
              type="button"
              onClick={() => setSelectedCategory(selectedCategory === 'NONE' ? 'ALL' : 'NONE')}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '0.65rem 1rem',
                fontSize: '0.875rem',
                fontWeight: selectedCategory === 'NONE' ? 700 : 500,
                color: selectedCategory === 'NONE' ? '#0f172a' : '#64748b',
                backgroundColor: selectedCategory === 'NONE' ? '#ffffff' : 'transparent',
                border: 'none',
                cursor: 'pointer',
                borderBottom: selectedCategory === 'NONE' ? '3px solid #16a34a' : '3px solid transparent',
                transition: 'all 0.15s ease',
                flexShrink: 0,
                fontStyle: 'italic',
              }}
            >
              <span>Chưa phân danh mục</span>
              <span
                style={{
                  fontSize: '0.75rem',
                  padding: '1px 6px',
                  borderRadius: '10px',
                  backgroundColor: selectedCategory === 'NONE' ? '#dcfce7' : '#e2e8f0',
                  color: selectedCategory === 'NONE' ? '#166534' : '#475569',
                  fontWeight: 600,
                }}
              >
                {categoryCounts.NONE || 0}
              </span>
            </button>
          )}
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
        <TableScrollContainer targetRef={tableContainerRef}>
        <div ref={tableContainerRef} className="table-responsive" style={{ borderTop: 'none', borderRadius: '0 0 var(--radius, 8px) var(--radius, 8px)' }}>
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

                const allUnits = getProductUnits(p);
                const baseUnit = getBaseUnit(p);
                const displayUnit = getPrimaryDisplayUnit(p, displayUnitOverrides[String(p.id)]);
                const displayUnitName = displayUnit?.unitName || p.uom || 'Cái';
                const displayPrices = getDisplayPrices(p, displayUnit);
                const displayTotalStock = convertQtyToDisplayUnit(totalStock, displayUnit);

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
                    <td style={{ textAlign: 'center', color: 'var(--text-secondary)' }} onClick={(e) => e.stopPropagation()}>
                      <div style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: '3px', minWidth: '105px' }}>
                        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                          {allUnits.length > 1 ? (
                            <select
                              className="form-select"
                              style={{
                                padding: '2px 22px 2px 6px',
                                fontSize: '0.78rem',
                                fontWeight: 700,
                                height: '26px',
                                minWidth: '82px',
                                color: 'var(--primary)',
                                borderColor: 'rgba(37, 99, 235, 0.35)',
                                backgroundColor: '#eff6ff',
                              }}
                              value={displayUnitName}
                              onChange={(e) => handleChangeProductDisplayUnit(p, e.target.value)}
                              title="Chọn đơn vị hiển thị chính cho sản phẩm này"
                            >
                              {allUnits.map((u) => (
                                <option key={u.unitName} value={u.unitName}>
                                  {u.unitName} {Number(u.conversionRate) > 1 ? `(x${u.conversionRate} ${baseUnit.unitName})` : ''}
                                </option>
                              ))}
                            </select>
                          ) : (
                            <span style={{ fontWeight: 600 }}>{displayUnitName}</span>
                          )}
                          <button
                            type="button"
                            className="btn btn-ghost btn-icon"
                            style={{ width: '24px', height: '24px', color: 'var(--primary)', flexShrink: 0 }}
                            title="Cấu hình đơn vị quy đổi (Thêm Hộp / Viên / Thùng...)"
                            onClick={() => handleOpenSubUnits(p)}
                          >
                            <Layers size={13} />
                          </button>
                        </div>
                        {allUnits.length > 1 && (
                          <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: '2px' }}>
                            {allUnits
                              .filter((u) => Number(u.conversionRate) > 1)
                              .map((u) => (
                                <span
                                  key={u.id || u.unitName}
                                  className="badge badge-neutral mono"
                                  style={{ fontSize: '0.65rem', padding: '1px 5px' }}
                                >
                                  1 {u.unitName} = {u.conversionRate} {baseUnit.unitName}
                                </span>
                              ))}
                          </div>
                        )}
                      </div>
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      <div>{formatVND(displayPrices.unitCost)}</div>
                      {allUnits.length > 1 && (
                        <div style={{ fontSize: '0.68rem', color: 'var(--text-muted)' }}>/{displayUnitName}</div>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      <div>{formatVND(displayPrices.wholesalePrice)}</div>
                      {allUnits.length > 1 && (
                        <div style={{ fontSize: '0.68rem', color: 'var(--text-muted)' }}>/{displayUnitName}</div>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      <div>{formatVND(displayPrices.retailPrice)}</div>
                      {allUnits.length > 1 && (
                        <div style={{ fontSize: '0.68rem', color: 'var(--text-muted)' }}>/{displayUnitName}</div>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      <span
                        style={{
                          fontWeight: 700,
                          color: totalStock <= (p.reorderPoint || 0) ? 'var(--danger)' : 'var(--text-primary)',
                        }}
                      >
                        {formatNumber(displayTotalStock)} {displayUnitName}
                      </span>
                      {allUnits.length > 1 && (
                        <div style={{ fontSize: '0.6875rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                          {formatStockDisplay(totalStock, allUnits, baseUnit.unitName)}
                        </div>
                      )}
                    </td>

                    {/* Xuất theo từng kho: hiển thị cả SL & Thành tiền */}
                    {warehouses.map((wh) => {
                      if (!visibleMetrics.exportWarehouses?.[wh.id]) return null;
                      const metric = p.warehouseMetrics?.[wh.id] || p.warehouseMetrics?.[wh.id.toLowerCase()];
                      const exportQty = convertQtyToDisplayUnit(metric?.exportQty || 0, displayUnit);
                      const exportAmount = metric?.exportAmount || 0;
                      return (
                        <td key={`td-cat-exp-${wh.id}`} style={{ textAlign: 'right' }} className="mono">
                          <div style={{ fontWeight: 700, color: exportQty > 0 ? '#ea580c' : 'var(--text-muted)' }}>
                            SL: {formatNumber(exportQty)} {displayUnitName}
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
                          SL: {formatNumber(convertQtyToDisplayUnit(p.totalExportQty || 0, displayUnit))} {displayUnitName}
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
                      const importQty = convertQtyToDisplayUnit(metric?.importQty || 0, displayUnit);
                      const importAmount = metric?.importAmount || 0;
                      return (
                        <td key={`td-cat-imp-${wh.id}`} style={{ textAlign: 'right' }} className="mono">
                          <div style={{ fontWeight: 700, color: importQty > 0 ? '#1d4ed8' : 'var(--text-muted)' }}>
                            SL: {formatNumber(importQty)} {displayUnitName}
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
                          SL: {formatNumber(convertQtyToDisplayUnit(p.totalImportQty || 0, displayUnit))} {displayUnitName}
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
        </TableScrollContainer>
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
        title="Thêm Mới Sản Phẩm"
        size="lg"
        footer={
          <>
            <button type="button" className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button type="button" className="btn btn-primary" onClick={handleCreateSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Thêm sản phẩm'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">
                Mã SKU <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input mono"
                required
                value={formData.sku}
                onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
                placeholder="VD: SP001"
              />
            </div>
            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">
                Tên Sản Phẩm <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="VD: Nước giặt cao cấp 3.8kg"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Danh mục</label>
              <input
                type="text"
                className="form-input"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                placeholder="VD: Hóa mỹ phẩm"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Đơn vị tính</label>
              <input
                type="text"
                className="form-input"
                value={formData.uom}
                onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
                placeholder="VD: Chai, Can, Hộp..."
              />
            </div>
            <div className="form-group">
              <label className="form-label">Mã vạch</label>
              <input
                type="text"
                className="form-input mono"
                value={formData.barcode}
                onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
                placeholder="VD: 893500123456"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Nhà Cung Cấp Mặc Định</label>
              <SearchableSelect
                options={[
                  { value: '', label: '-- Không chọn nhà cung cấp --' },
                  ...suppliers.map((s) => ({
                    id: s.id,
                    value: String(s.id),
                    label: s.name,
                    code: s.code,
                    phone: s.phone || '',
                    subLabel: s.phone ? `SĐT: ${s.phone}` : '',
                  })),
                ]}
                value={formData.supplierId}
                onChange={(val) => setFormData({ ...formData, supplierId: val })}
                placeholder="-- Chọn nhà cung cấp --"
                searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                searchFields={['label', 'code', 'phone']}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.875rem' }}>
            Thiết Lập Giá Bán
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">Giá Vốn</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="0"
                value={formData.unitCost ?? ''}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Giá Bán Sỉ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="0"
                value={formData.wholesalePrice ?? ''}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Giá Bán Lẻ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="0"
                value={formData.retailPrice ?? ''}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Định mức tồn tối thiểu</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="Cảnh báo khi dưới mức này"
                value={formData.reorderPoint ?? ''}
                onChange={(e) => setFormData({ ...formData, reorderPoint: e.target.value })}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <SubUnitsEditor
            baseUom={formData.uom}
            onBaseUomChange={(newUom) => setFormData((prev) => ({ ...prev, uom: newUom }))}
            units={productUnits}
            onChange={setProductUnits}
            disabled={submitting}
          />
        </form>
      </Modal>

      {/* MODAL: Sửa sản phẩm */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa Thông Tin: ${selectedProduct?.name || ''}`}
        size="lg"
        footer={
          <>
            <button type="button" className="btn btn-outline" onClick={() => setIsEditOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button type="button" className="btn btn-primary" onClick={handleEditSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
            </button>
          </>
        }
      >
        <form onSubmit={handleEditSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">
                Mã SKU <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input mono"
                required
                value={formData.sku}
                onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
                placeholder="VD: SP001"
              />
            </div>
            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">
                Tên Sản Phẩm <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
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
              <label className="form-label">Đơn vị tính hiển thị chính</label>
              <input
                type="text"
                className="form-input"
                value={formData.uom}
                onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Mã vạch</label>
              <input
                type="text"
                className="form-input mono"
                value={formData.barcode}
                onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Nhà Cung Cấp Mặc Định</label>
              <SearchableSelect
                options={[
                  { value: '', label: '-- Không chọn nhà cung cấp --' },
                  ...suppliers.map((s) => ({
                    id: s.id,
                    value: String(s.id),
                    label: s.name,
                    code: s.code,
                    phone: s.phone || '',
                    subLabel: s.phone ? `SĐT: ${s.phone}` : '',
                  })),
                ]}
                value={formData.supplierId}
                onChange={(val) => setFormData({ ...formData, supplierId: val })}
                placeholder="-- Không có / Chọn NCC --"
                searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                searchFields={['label', 'code', 'phone']}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.875rem' }}>
            Thiết Lập Giá Bán
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group">
              <label className="form-label">Giá Vốn (Theo ĐV bé nhất)</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="0"
                value={formData.unitCost ?? ''}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Giá Sỉ (Theo ĐV bé nhất)</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="0"
                value={formData.wholesalePrice ?? ''}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Giá Lẻ (Theo ĐV bé nhất)</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="0"
                value={formData.retailPrice ?? ''}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Định mức tồn tối thiểu</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                placeholder="Cảnh báo khi dưới mức này"
                value={formData.reorderPoint ?? ''}
                onChange={(e) => setFormData({ ...formData, reorderPoint: e.target.value })}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <SubUnitsEditor
            baseUom={formData.uom}
            onBaseUomChange={(newUom) => setFormData((prev) => ({ ...prev, uom: newUom }))}
            units={productUnits}
            onChange={setProductUnits}
            disabled={submitting}
          />
        </form>
      </Modal>

      {/* Modal Quản Lý Đơn Vị Tính Quy Đổi */}
      <Modal
        isOpen={isSubUnitOpen}
        onClose={() => setIsSubUnitOpen(false)}
        title={`Đơn Vị Tính & Đơn Vị Hiển Thị Chính: ${selectedProduct?.name || ''}`}
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsSubUnitOpen(false)} disabled={submitting}>
              Đóng
            </button>
            <button className="btn btn-primary" onClick={handleSaveSubUnits} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
            </button>
          </>
        }
      >
        <SubUnitsEditor
          baseUom={formData.uom || selectedProduct?.uom}
          onBaseUomChange={(newUom) => setFormData((prev) => ({ ...prev, uom: newUom }))}
          units={productUnits}
          onChange={setProductUnits}
          disabled={submitting}
        />
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

import React, { useState, useEffect } from 'react';
import {
  Boxes,
  Plus,
  Edit2,
  Edit3,
  Sliders,
  History,
  AlertTriangle,
  Search,
  Filter,
  RefreshCw,
  Building,
  CheckCircle2,
  Package,
  ArrowRightLeft,
  ArrowDownLeft,
  ArrowUpRight,
  ShieldAlert,
  Layers,
  Warehouse as WarehouseIcon,
  ChevronRight,
  Info,
  Coins,
  DollarSign,
  X,
  Trash2,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr, getCurrentDateStr } from '../utils/formatters';
import { STOCK_ADJUST_REASONS } from '../utils/constants';
import { useNotification } from '../context/NotificationContext';
import SearchBar from '../components/common/SearchBar';
import StatCard from '../components/common/StatCard';
import TimeFilter from '../components/common/TimeFilter';
import Modal from '../components/common/Modal';
import Drawer from '../components/common/Drawer';
import EmptyState from '../components/common/EmptyState';
import SearchableSelect from '../components/common/SearchableSelect';
import SortDropdown from '../components/common/SortDropdown';
import ConfirmModal from '../components/common/ConfirmModal';
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

export default function Products({ initialWarehouse = 'overview', onWarehouseChange }) {
  const notify = useNotification();

  const [products, setProducts] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(false);

  // Warehouses list
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [selectedWarehouse, setSelectedWarehouse] = useState(initialWarehouse || 'overview');

  // Filters & Sorting
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSupplierId, setSelectedSupplierId] = useState('');
  const [sortBy, setSortBy] = useState('default');

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isAdjustOpen, setIsAdjustOpen] = useState(false);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);

  // Warehouse Management Modals
  const [isAddWarehouseOpen, setIsAddWarehouseOpen] = useState(false);
  const [addWarehouseData, setAddWarehouseData] = useState({
    name: '',
    shortName: '',
    color: 'primary',
    address: '',
    note: '',
  });

  const [isRenameWarehouseOpen, setIsRenameWarehouseOpen] = useState(false);
  const [renameWarehouseData, setRenameWarehouseData] = useState({
    id: '',
    name: '',
    shortName: '',
    color: 'primary',
    address: '',
    note: '',
  });

  const [isDeleteWhConfirmOpen, setIsDeleteWhConfirmOpen] = useState(false);
  const [warehouseToDelete, setWarehouseToDelete] = useState(null);

  const [selectedProduct, setSelectedProduct] = useState(null);
  const [historyRecords, setHistoryRecords] = useState([]);
  const [historyTimeMode, setHistoryTimeMode] = useState('month'); // 'month' | 'day'
  const [historyMonth, setHistoryMonth] = useState(getCurrentMonthStr());
  const [historyDate, setHistoryDate] = useState(getCurrentDateStr());
  const [historyLoading, setHistoryLoading] = useState(false);

  // Form states
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
    warehouseStocks: {},
    stockWarehouse1: 0,
    stockWarehouse2: 0,
    stockWarehouse3: 0,
    reorderPoint: 5,
  });

  const [adjustData, setAdjustData] = useState({
    warehouse: 'warehouse1',
    mode: 'delta', // 'delta' or 'quantity'
    delta: 0,
    quantity: 0,
    reason: STOCK_ADJUST_REASONS[0],
    note: '',
  });

  const [submitting, setSubmitting] = useState(false);

  // Synchronize with parent initialWarehouse prop if changed
  useEffect(() => {
    if (initialWarehouse && initialWarehouse !== selectedWarehouse) {
      setSelectedWarehouse(initialWarehouse);
    }
  }, [initialWarehouse]);

  // Load warehouses from warehouseService
  useEffect(() => {
    warehouseService.getWarehouses().then((res) => {
      if (res && Array.isArray(res)) setWarehouses(res);
    });

    const handleWhUpdate = (e) => {
      if (e.detail && Array.isArray(e.detail)) {
        setWarehouses(e.detail);
      } else {
        warehouseService.getWarehouses().then((res) => setWarehouses(res));
      }
    };

    window.addEventListener('warehouses-updated', handleWhUpdate);
    return () => window.removeEventListener('warehouses-updated', handleWhUpdate);
  }, []);

  // Load products & suppliers via productService
  const loadData = async () => {
    setLoading(true);
    try {
      const [prods, depRes, whRes] = await Promise.all([
        productService.getAll(),
        productService.getDependencies(),
        warehouseService.getWarehouses(),
      ]);
      setProducts(prods || []);
      setSuppliers(depRes.suppliers || []);
      if (whRes && Array.isArray(whRes)) setWarehouses(whRes);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách sản phẩm');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Filter products continuously based on supplier and search query
  const filteredProducts = React.useMemo(() => {
    let result = products;

    if (selectedSupplierId) {
      const suppId = Number(selectedSupplierId);
      result = result.filter((p) => Number(p.supplierId) === suppId);
    }

    if (searchQuery && searchQuery.trim()) {
      const q = searchQuery.trim().toLowerCase();
      result = result.filter(
        (p) =>
          (p.name && p.name.toLowerCase().includes(q)) ||
          (p.sku && p.sku.toLowerCase().includes(q)) ||
          (p.category && p.category.toLowerCase().includes(q)) ||
          (p.barcode && p.barcode.toLowerCase().includes(q)) ||
          (p.supplierName && p.supplierName.toLowerCase().includes(q))
      );
    }

    return result;
  }, [products, searchQuery, selectedSupplierId]);

  // Current active warehouse object if in specific warehouse mode
  const currentWarehouseObj = warehouses.find((w) => w.id === selectedWarehouse);
  const isOverview = selectedWarehouse === 'overview';

  // Helper to get stock of product for a specific warehouse
  const getProductStockForWarehouse = (product, whId) => {
    if (!product) return 0;
    if (product.warehouseStocks && product.warehouseStocks[whId] !== undefined) {
      return Number(product.warehouseStocks[whId] || 0);
    }
    if (whId === 'warehouse1') return Number(product.stockWarehouse1 || 0);
    if (whId === 'warehouse2') return Number(product.stockWarehouse2 || 0);
    if (whId === 'warehouse3') return Number(product.stockWarehouse3 || 0);
    return 0;
  };

  // When viewing a specific warehouse: ONLY show products that have stock > 0 in THIS warehouse
  // (hide out-of-stock products in specific warehouse view; keep all in overview)
  const displayedProducts = React.useMemo(() => {
    if (isOverview) {
      return filteredProducts;
    }
    return filteredProducts.filter((p) => {
      const stock = getProductStockForWarehouse(p, selectedWarehouse);
      return stock > 0;
    });
  }, [filteredProducts, isOverview, selectedWarehouse]);

  // Sort displayed products based on selected numeric metric
  const sortedAndDisplayedProducts = React.useMemo(() => {
    let list = [...displayedProducts];
    if (sortBy === 'stock_desc') {
      list.sort((a, b) => {
        const stockA = isOverview ? Number(a.totalStock || 0) : getProductStockForWarehouse(a, selectedWarehouse);
        const stockB = isOverview ? Number(b.totalStock || 0) : getProductStockForWarehouse(b, selectedWarehouse);
        return stockB - stockA;
      });
    } else if (sortBy === 'stock_asc') {
      list.sort((a, b) => {
        const stockA = isOverview ? Number(a.totalStock || 0) : getProductStockForWarehouse(a, selectedWarehouse);
        const stockB = isOverview ? Number(b.totalStock || 0) : getProductStockForWarehouse(b, selectedWarehouse);
        return stockA - stockB;
      });
    } else if (sortBy === 'cost_desc') {
      list.sort((a, b) => Number(b.unitCost || 0) - Number(a.unitCost || 0));
    } else if (sortBy === 'cost_asc') {
      list.sort((a, b) => Number(a.unitCost || 0) - Number(b.unitCost || 0));
    } else if (sortBy === 'wholesale_desc') {
      list.sort((a, b) => Number(b.wholesalePrice || 0) - Number(a.wholesalePrice || 0));
    } else if (sortBy === 'wholesale_asc') {
      list.sort((a, b) => Number(a.wholesalePrice || 0) - Number(b.wholesalePrice || 0));
    } else if (sortBy === 'retail_desc') {
      list.sort((a, b) => Number(b.retailPrice || 0) - Number(a.retailPrice || 0));
    } else if (sortBy === 'retail_asc') {
      list.sort((a, b) => Number(a.retailPrice || 0) - Number(b.retailPrice || 0));
    }
    return list;
  }, [displayedProducts, sortBy, isOverview, selectedWarehouse]);

  // Dynamic Totals Summary (Continuously updates on search / filter)
  const summary = React.useMemo(() => {
    let totalStockQty = 0;
    let totalCostVal = 0;
    let totalWholesaleVal = 0;
    let totalRetailVal = 0;

    displayedProducts.forEach((p) => {
      const stock = isOverview ? Number(p.totalStock || 0) : getProductStockForWarehouse(p, selectedWarehouse);
      const cost = Number(p.unitCost || 0);
      const wholesale = Number(p.wholesalePrice || 0);
      const retail = Number(p.retailPrice || 0);

      totalStockQty += stock;
      totalCostVal += stock * cost;
      totalWholesaleVal += stock * wholesale;
      totalRetailVal += stock * retail;
    });

    return {
      totalItems: displayedProducts.length,
      totalStockQty,
      totalCostVal,
      totalWholesaleVal,
      totalRetailVal,
    };
  }, [displayedProducts, isOverview, selectedWarehouse]);

  const handleTabSelect = (tabId) => {
    setSelectedWarehouse(tabId);
    onWarehouseChange?.(tabId);
  };

  // Open Create Modal
  const handleOpenCreate = () => {
    const initialStocks = {};
    warehouses.forEach((w) => {
      initialStocks[w.id] = 0;
    });

    setFormData({
      sku: '',
      name: '',
      category: '',
      uom: 'Cái',
      barcode: '',
      supplierId: '',
      unitCost: 0,
      wholesalePrice: 0,
      retailPrice: 0,
      warehouseStocks: initialStocks,
      stockWarehouse1: 0,
      stockWarehouse2: 0,
      stockWarehouse3: 0,
      reorderPoint: 5,
    });
    setIsCreateOpen(true);
  };

  // Open Edit Modal
  const handleOpenEdit = (product) => {
    setSelectedProduct(product);
    setFormData({
      sku: product.sku,
      name: product.name,
      category: product.category || '',
      uom: product.uom || 'Cái',
      barcode: product.barcode || '',
      supplierId: product.supplierId || '',
      unitCost: product.unitCost,
      wholesalePrice: product.wholesalePrice,
      retailPrice: product.retailPrice,
      reorderPoint: product.reorderPoint,
    });
    setIsEditOpen(true);
  };

  // Open Adjust Modal
  const handleOpenAdjust = (product) => {
    setSelectedProduct(product);
    const targetWhId = !isOverview && currentWarehouseObj ? currentWarehouseObj.id : (warehouses[0]?.id || 'warehouse1');
    const currentWhStock = getProductStockForWarehouse(product, targetWhId);

    setAdjustData({
      warehouse: targetWhId,
      mode: 'delta',
      delta: 0,
      quantity: currentWhStock,
      reason: STOCK_ADJUST_REASONS[0],
      note: '',
    });
    setIsAdjustOpen(true);
  };

  // Open History Drawer via productService
  const handleOpenHistory = async (product) => {
    setSelectedProduct(product);
    setIsHistoryOpen(true);
    const targetPeriod = historyTimeMode === 'day' ? historyDate : historyMonth;
    loadStockHistory(product.id, targetPeriod);
  };

  const loadStockHistory = async (productId, period) => {
    setHistoryLoading(true);
    try {
      const records = await productService.getStockHistory(productId, period);
      setHistoryRecords(records || []);
    } catch (err) {
      notify.error(err.message || 'Lỗi khi tải lịch sử sổ kho');
    } finally {
      setHistoryLoading(false);
    }
  };

  // Open Add Warehouse Modal
  const handleOpenAddWarehouse = () => {
    setAddWarehouseData({
      name: '',
      shortName: '',
      color: 'primary',
      address: '',
      note: '',
    });
    setIsAddWarehouseOpen(true);
  };

  // Submit Add Warehouse
  const handleAddWarehouseSubmit = async (e) => {
    e.preventDefault();
    if (!addWarehouseData.name.trim()) {
      notify.error('Tên kho không được để trống');
      return;
    }
    setSubmitting(true);
    try {
      const updated = await warehouseService.addWarehouse(addWarehouseData);
      setWarehouses(updated);
      const newWh = updated[updated.length - 1];
      notify.success(`Thêm mới kho hàng "${newWh.name}" thành công!`);
      setIsAddWarehouseOpen(false);
      handleTabSelect(newWh.id);
    } catch (err) {
      notify.error(err.message || 'Thêm kho hàng thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Rename Warehouse Modal
  const handleOpenRenameWarehouse = (wh) => {
    setRenameWarehouseData({
      id: wh.id,
      name: wh.name,
      shortName: wh.shortName || wh.name,
      color: wh.color || 'primary',
      address: wh.address || '',
      note: wh.note || '',
    });
    setIsRenameWarehouseOpen(true);
  };

  // Submit Rename Warehouse
  const handleRenameWarehouseSubmit = async (e) => {
    e.preventDefault();
    if (!renameWarehouseData.name.trim()) {
      notify.error('Tên kho không được để trống');
      return;
    }
    setSubmitting(true);
    try {
      const updated = await warehouseService.renameWarehouse(
        renameWarehouseData.id,
        renameWarehouseData.name,
        renameWarehouseData.shortName,
        renameWarehouseData.color,
        renameWarehouseData.address,
        renameWarehouseData.note
      );
      setWarehouses(updated);
      notify.success('Cập nhật thông tin kho thành công!');
      setIsRenameWarehouseOpen(false);
    } catch (err) {
      notify.error(err.message || 'Cập nhật kho thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Delete Warehouse Modal
  const handleOpenDeleteWarehouse = (wh) => {
    if (wh.id === 'warehouse1') {
      notify.error('Không thể xóa kho chính mặc định của hệ thống');
      return;
    }
    setWarehouseToDelete(wh);
    setIsDeleteWhConfirmOpen(true);
  };

  // Confirm Delete Warehouse
  const handleConfirmDeleteWarehouse = async () => {
    if (!warehouseToDelete) return;
    setSubmitting(true);
    try {
      const updated = await warehouseService.deleteWarehouse(warehouseToDelete.id);
      setWarehouses(updated);
      notify.success(`Đã xóa kho hàng "${warehouseToDelete.name}" thành công!`);
      setIsDeleteWhConfirmOpen(false);
      setWarehouseToDelete(null);
      handleTabSelect('overview');
    } catch (err) {
      notify.error(err.message || 'Xóa kho thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Create Product
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const stocks = {};
      warehouses.forEach((wh) => {
        stocks[wh.id] = Number(formData.warehouseStocks?.[wh.id] || 0);
      });

      if (!isOverview && currentWarehouseObj) {
        warehouses.forEach((wh) => {
          stocks[wh.id] = wh.id === currentWarehouseObj.id ? Number(formData.warehouseStocks?.[wh.id] || 0) : 0;
        });
      }

      await productService.create({
        ...formData,
        supplierId: formData.supplierId ? Number(formData.supplierId) : null,
        unitCost: Number(formData.unitCost || 0),
        wholesalePrice: Number(formData.wholesalePrice || 0),
        retailPrice: Number(formData.retailPrice || 0),
        stockWarehouse1: stocks.warehouse1 || 0,
        stockWarehouse2: stocks.warehouse2 || 0,
        stockWarehouse3: stocks.warehouse3 || 0,
        warehouseStocks: stocks,
        reorderPoint: Number(formData.reorderPoint || 0),
      });

      notify.success(
        !isOverview && currentWarehouseObj
          ? `Thêm sản phẩm mới vào ${currentWarehouseObj.name} thành công!`
          : 'Thêm sản phẩm mới thành công!'
      );
      setIsCreateOpen(false);
      loadData();
    } catch (err) {
      notify.error(err.message || 'Thêm sản phẩm thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Submit Edit Product
  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await productService.update(selectedProduct.id, {
        name: formData.name,
        category: formData.category,
        uom: formData.uom,
        barcode: formData.barcode,
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

  // Submit Stock Adjust
  const handleAdjustSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const targetWh = !isOverview && currentWarehouseObj ? currentWarehouseObj.id : adjustData.warehouse;

      const payload = {
        warehouse: targetWh,
        reason: adjustData.reason,
        note: adjustData.note,
        changeDate: new Date().toISOString(),
      };

      if (adjustData.mode === 'delta') {
        payload.delta = Number(adjustData.delta || 0);
      } else {
        payload.quantity = Number(adjustData.quantity || 0);
      }

      await productService.adjustStock(selectedProduct.id, payload);
      notify.success('Điều chỉnh tồn kho thành công!');
      setIsAdjustOpen(false);
      loadData();
    } catch (err) {
      notify.error(err.message || 'Điều chỉnh tồn kho thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Compute Warehouse Stats for Overview Cards (computed on filteredProducts)
  const getWarehouseStats = (whId) => {
    let count = 0;
    let totalStock = 0;
    let totalVal = 0;

    filteredProducts.forEach((p) => {
      const s = getProductStockForWarehouse(p, whId);
      if (s > 0) count++;
      totalStock += s;
      totalVal += s * Number(p.unitCost || 0);
    });

    return { count, totalStock, totalVal };
  };

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <span>{isOverview ? 'Quản Lý Sản Phẩm & Kho Đa Điểm' : `Chi Tiết Kho: ${currentWarehouseObj?.name || 'Kho'}`}</span>
          </h1>
          <p className="page-subtitle">
            {isOverview
              ? 'Xem tổng quan tồn kho, quản lý danh mục hàng hóa và đổi tên các kho'
              : `Quản lý danh sách hàng hóa và điều chỉnh số lượng tồn kho riêng tại ${currentWarehouseObj?.name || 'Kho'}`}
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadData} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>{isOverview ? 'Thêm sản phẩm mới' : `Thêm sản phẩm vào ${currentWarehouseObj?.shortName || 'Kho'}`}</span>
          </button>
        </div>
      </div>

      {/* Warehouse Navigation Tabs */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '0.5rem',
          overflowX: 'auto',
          paddingBottom: '0.75rem',
          marginBottom: '1.25rem',
          borderBottom: '1px solid var(--border-color)',
        }}
      >
        <button
          className={`btn ${isOverview ? 'btn-primary' : 'btn-outline'}`}
          style={{ padding: '0.55rem 1rem', borderRadius: 'var(--radius-full)', fontSize: '0.875rem' }}
          onClick={() => handleTabSelect('overview')}
        >
          <span>Tổng quan (Tất cả kho)</span>
        </button>

        {warehouses.map((wh) => {
          const isActive = selectedWarehouse === wh.id;
          return (
            <button
              key={wh.id}
              className={`btn ${isActive ? 'btn-primary' : 'btn-outline'}`}
              style={{
                padding: '0.55rem 1rem',
                borderRadius: 'var(--radius-full)',
                fontSize: '0.875rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
              }}
              onClick={() => handleTabSelect(wh.id)}
            >
              <span>{wh.shortName || wh.name}</span>
            </button>
          );
        })}
      </div>

      {/* OVERVIEW MODE: Warehouse Summary Cards */}
      {isOverview && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem', marginBottom: '1.5rem' }}>
          {warehouses.map((wh) => {
            const stats = getWarehouseStats(wh.id);
            return (
              <div
                key={wh.id}
                className="glass-card"
                style={{
                  padding: '1.25rem',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  border: '1px solid var(--border-color)',
                  position: 'relative',
                }}
              >
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.9375rem', color: 'var(--text-primary)' }}>
                        {wh.name}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Mã: {wh.id}</div>
                    </div>

                    <button
                      className="btn btn-ghost btn-icon"
                      style={{ width: '28px', height: '28px', color: 'var(--text-muted)' }}
                      title={`Đổi tên ${wh.name}`}
                      onClick={() => handleOpenRenameWarehouse(wh)}
                    >
                      <Edit3 size={14} />
                    </button>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem', marginTop: '0.75rem', background: 'var(--bg-tertiary)', padding: '0.75rem', borderRadius: 'var(--radius-md)' }}>
                    <div>
                      <div style={{ fontSize: '0.6875rem', color: 'var(--text-muted)' }}>MẶT HÀNG TỒN</div>
                      <div className="mono" style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--text-primary)' }}>
                        {stats.count} mã
                      </div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.6875rem', color: 'var(--text-muted)' }}>TỔNG SỐ LƯỢNG</div>
                      <div className="mono" style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--primary)' }}>
                        {formatNumber(stats.totalStock)}
                      </div>
                    </div>
                  </div>
                </div>

                <div style={{ marginTop: '0.875rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-light)', paddingTop: '0.75rem' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    Ước tính giá trị: <strong style={{ color: 'var(--text-primary)' }}>{formatVND(stats.totalVal)}</strong>
                  </div>
                  <button
                    className="btn btn-ghost btn-sm"
                    style={{ padding: '0.2rem 0.5rem', fontSize: '0.75rem' }}
                    onClick={() => handleTabSelect(wh.id)}
                  >
                    <span>Vào kho</span>
                    <ChevronRight size={13} />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* SPECIFIC WAREHOUSE MODE: Banner Alert */}
      {!isOverview && currentWarehouseObj && (
        <div
          style={{
            padding: '1rem 1.25rem',
            borderRadius: 'var(--radius-md)',
            background: 'var(--primary-light)',
            border: '1px solid rgba(37, 99, 235, 0.25)',
            marginBottom: '1.25rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '0.75rem',
          }}
        >
          <div>
            <div style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--primary)' }}>
              Đang quản lý: {currentWarehouseObj.name}
            </div>
            <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
              Mọi thao tác thêm sản phẩm và điều chỉnh số lượng ở màn hình này chỉ tác động lên <strong>{currentWarehouseObj.shortName || currentWarehouseObj.name}</strong>.
            </div>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button
              className="btn btn-outline btn-sm"
              onClick={() => handleOpenRenameWarehouse(currentWarehouseObj)}
            >
              <Edit3 size={14} />
              <span>Đổi tên kho này</span>
            </button>
            <button
              className="btn btn-outline btn-sm"
              onClick={() => handleTabSelect('overview')}
            >
              <span>Xem tất cả kho</span>
            </button>
          </div>
        </div>
      )}

      {/* Dynamic Summary Stat Cards (Updates continuously on search / filter) */}
      <div className="stats-grid" style={{ marginBottom: '1.25rem' }}>
        <StatCard
          title="TỔNG GIÁ TRỊ VỐN"
          value={formatVND(summary.totalCostVal)}
          subtitle={
            isOverview
              ? `∑ (Tồn kho × Giá vốn) ${searchQuery || selectedSupplierId ? 'theo kết quả lọc' : 'toàn bộ kho'}`
              : `Giá trị vốn tại ${currentWarehouseObj?.shortName || currentWarehouseObj?.name || 'kho'}`
          }
          icon={Layers}
          color="primary"
        />
        <StatCard
          title="TỔNG GIÁ TRỊ BÁN SỈ"
          value={formatVND(summary.totalWholesaleVal)}
          subtitle="Doanh thu dự kiến theo giá sỉ"
          icon={Building}
          color="warning"
        />
        <StatCard
          title="TỔNG GIÁ TRỊ BÁN LẺ"
          value={formatVND(summary.totalRetailVal)}
          subtitle="Doanh thu dự kiến theo giá bán lẻ"
          icon={Coins}
          color="success"
        />
        <StatCard
          title="TỔNG LƯỢNG TỒN KHO"
          value={formatNumber(summary.totalStockQty)}
          subtitle={`${summary.totalItems} mặt hàng ${searchQuery || selectedSupplierId ? 'phù hợp tìm kiếm' : 'trong danh sách'}`}
          icon={Boxes}
          color="info"
        />
      </div>

      {/* Filter Bar */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên, mã SKU, barcode, danh mục, nhà cung cấp..."
          debounceMs={0}
          style={{ flex: 1, minWidth: '280px' }}
        />

        <div style={{ minWidth: '240px' }}>
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

        <SortDropdown
          value={sortBy}
          onChange={setSortBy}
          options={PRODUCT_SORT_OPTIONS}
          style={{ minWidth: '240px' }}
        />

        {(searchQuery || selectedSupplierId || sortBy !== 'default') && (
          <button
            className="btn btn-outline btn-sm"
            onClick={() => {
              setSearchQuery('');
              setSelectedSupplierId('');
              setSortBy('default');
            }}
            title="Xóa bộ lọc & sắp xếp để xem toàn bộ danh sách"
            style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}
          >
            <X size={14} />
            <span>Xóa lọc</span>
          </button>
        )}
      </div>

      {/* Products Table */}
      {sortedAndDisplayedProducts.length === 0 && !loading ? (
        <EmptyState
          icon={Package}
          title={isOverview ? 'Không tìm thấy sản phẩm' : `Không có sản phẩm còn hàng tại ${currentWarehouseObj?.name || 'kho này'}`}
          description={
            isOverview
              ? 'Chưa có sản phẩm nào thỏa mãn điều kiện lọc hoặc danh mục đang trống.'
              : `Kho ${currentWarehouseObj?.shortName || currentWarehouseObj?.name || ''} hiện không có sản phẩm nào còn tồn kho (> 0). Các sản phẩm hết hàng đã được tự động ẩn.`
          }
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <Plus size={15} />
              <span>{isOverview ? 'Thêm sản phẩm ngay' : `Thêm sản phẩm vào ${currentWarehouseObj?.shortName || 'kho'} ngay`}</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã SKU</th>
                <th>Tên Sản Phẩm</th>
                <th>ĐVT</th>
                {isOverview ? (
                  <>
                    {warehouses.map((wh) => (
                      <th key={wh.id} style={{ textAlign: 'right' }}>
                        {wh.shortName || wh.name}
                      </th>
                    ))}
                    <th style={{ textAlign: 'right' }}>Tổng Tồn</th>
                  </>
                ) : (
                  <>
                    <th style={{ textAlign: 'right', color: 'var(--primary)', fontWeight: 800 }}>
                      Tồn {currentWarehouseObj?.shortName || currentWarehouseObj?.name}
                    </th>
                    <th style={{ textAlign: 'center' }}>Trạng Thái Kho Này</th>
                  </>
                )}
                <th style={{ textAlign: 'right' }}>Giá Vốn</th>
                <th style={{ textAlign: 'right' }}>Giá Sỉ</th>
                <th style={{ textAlign: 'right' }}>Giá Lẻ</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {sortedAndDisplayedProducts.map((p) => {
                const whStock = !isOverview && currentWarehouseObj ? getProductStockForWarehouse(p, currentWarehouseObj.id) : 0;

                return (
                  <tr key={p.id}>
                    <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                      {p.sku}
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{p.name}</div>
                      {p.category && (
                        <span className="badge badge-neutral" style={{ fontSize: '0.6875rem', marginTop: '2px' }}>
                          {p.category}
                        </span>
                      )}
                    </td>
                    <td>{p.uom || 'Cái'}</td>

                    {isOverview ? (
                      <>
                        {warehouses.map((wh) => {
                          const stock = getProductStockForWarehouse(p, wh.id);
                          return (
                            <td key={wh.id} style={{ textAlign: 'right' }} className="mono">
                              {formatNumber(stock)}
                            </td>
                          );
                        })}
                        <td style={{ textAlign: 'right' }}>
                          <span className={`badge badge-${Number(p.totalStock) <= 0 ? 'danger' : 'success'} mono`} style={{ fontWeight: 700 }}>
                            {formatNumber(p.totalStock)}
                          </span>
                        </td>
                      </>
                    ) : (
                      <>
                        <td style={{ textAlign: 'right' }} className="mono">
                          <span
                            className={`badge badge-${whStock <= 0 ? 'danger' : 'success'} mono`}
                            style={{ fontWeight: 800, fontSize: '0.875rem' }}
                          >
                            {formatNumber(whStock)}
                          </span>
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          {whStock <= 0 ? (
                            <span className="badge badge-danger">Hết hàng</span>
                          ) : (
                            <span className="badge badge-success">Đủ hàng</span>
                          )}
                        </td>
                      </>
                    )}

                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(p.unitCost)}
                    </td>
                    <td style={{ textAlign: 'right' }} className="mono">
                      {formatVND(p.wholesalePrice)}
                    </td>
                    <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">
                      {formatVND(p.retailPrice)}
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
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
                          style={{ width: '32px', height: '32px', color: 'var(--warning-text)' }}
                          title={!isOverview && currentWarehouseObj ? `Điều chỉnh tồn ${currentWarehouseObj.name}` : 'Điều chỉnh tồn kho'}
                          onClick={() => handleOpenAdjust(p)}
                        >
                          <Sliders size={15} />
                        </button>
                        <button
                          className="btn btn-outline btn-icon"
                          style={{ width: '32px', height: '32px', color: 'var(--info-text)' }}
                          title="Xem sổ kho / Lịch sử biến động"
                          onClick={() => handleOpenHistory(p)}
                        >
                          <History size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
            {displayedProducts.length > 0 && (
              <tfoot>
                <tr style={{ background: 'var(--bg-tertiary)', fontWeight: 700, borderTop: '2px solid var(--border-color)' }}>
                  <td colSpan={3} style={{ textAlign: 'left', fontWeight: 800 }}>
                    TỔNG CỘNG ({displayedProducts.length} mặt hàng):
                  </td>
                  {isOverview ? (
                    <>
                      {warehouses.map((wh) => {
                        const whTotal = displayedProducts.reduce(
                          (sum, p) => sum + getProductStockForWarehouse(p, wh.id),
                          0
                        );
                        return (
                          <td key={wh.id} style={{ textAlign: 'right' }} className="mono">
                            {formatNumber(whTotal)}
                          </td>
                        );
                      })}
                      <td style={{ textAlign: 'right' }} className="mono">
                        <span className="badge badge-primary mono" style={{ fontWeight: 800 }}>
                          {formatNumber(summary.totalStockQty)}
                        </span>
                      </td>
                    </>
                  ) : (
                    <>
                      <td style={{ textAlign: 'right' }} className="mono">
                        <span className="badge badge-primary mono" style={{ fontWeight: 800 }}>
                          {formatNumber(summary.totalStockQty)}
                        </span>
                      </td>
                      <td style={{ textAlign: 'center' }}>-</td>
                    </>
                  )}
                  <td style={{ textAlign: 'right' }} className="mono" title="Tổng giá trị vốn = ∑(Tồn kho × Giá vốn)">
                    <span style={{ color: 'var(--primary)', fontWeight: 800 }}>{formatVND(summary.totalCostVal)}</span>
                  </td>
                  <td style={{ textAlign: 'right' }} className="mono" title="Tổng giá trị sỉ = ∑(Tồn kho × Giá sỉ)">
                    <span style={{ color: 'var(--warning-text)', fontWeight: 800 }}>{formatVND(summary.totalWholesaleVal)}</span>
                  </td>
                  <td style={{ textAlign: 'right' }} className="mono" title="Tổng giá trị lẻ = ∑(Tồn kho × Giá lẻ)">
                    <span style={{ color: 'var(--success-text)', fontWeight: 800 }}>{formatVND(summary.totalRetailVal)}</span>
                  </td>
                  <td style={{ textAlign: 'center' }}>-</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}

      {/* Modal Thêm Mới Sản Phẩm */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title={!isOverview && currentWarehouseObj ? `Thêm Mới Sản Phẩm Vào ${currentWarehouseObj.name}` : 'Thêm Mới Sản Phẩm & Khởi Tạo Kho'}
        size="lg"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-primary" onClick={handleCreateSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Thêm sản phẩm'}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">
                Mã SKU
              </label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: SP001"
                value={formData.sku}
                onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ gridColumn: 'span 2' }}>
              <label className="form-label">
                Tên Sản Phẩm <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Nước giặt cao cấp 3.8kg"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Danh mục</label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Hóa mỹ phẩm"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Đơn vị tính</label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Chai, Can, Hộp..."
                value={formData.uom}
                onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Mã vạch</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 893500123456"
                value={formData.barcode}
                onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Nhà Cung Cấp Mặc Định</label>
              <SearchableSelect
                options={suppliers.map((s) => ({
                  id: s.id,
                  value: s.id,
                  label: s.name,
                  code: s.code,
                  phone: s.phone || '',
                  subLabel: s.phone ? `SĐT: ${s.phone}` : '',
                }))}
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
                value={formData.unitCost}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Bán Sỉ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.wholesalePrice}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Bán Lẻ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.retailPrice}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>
          </div>

          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.875rem' }}>
            {isOverview ? 'Tồn Kho Ban Đầu Cho Từng Kho' : `Tồn Kho Ban Đầu Tại ${currentWarehouseObj?.name}`}
          </h4>

          {!isOverview && currentWarehouseObj ? (
            <div
              style={{
                background: 'var(--bg-tertiary)',
                padding: '1rem',
                borderRadius: 'var(--radius-md)',
                marginBottom: '0.5rem',
              }}
            >
              <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                <Info size={14} color="var(--primary)" />
                <span>Bạn đang thêm sản phẩm vào <strong>{currentWarehouseObj.name}</strong>. Tồn kho ban đầu chỉ được nhập cho kho này, không nhập cho các kho khác.</span>
              </div>

              <div className="form-group">
                <label className="form-label" style={{ fontWeight: 700 }}>
                  Số Lượng Tồn Ban Đầu Tại {currentWarehouseObj.shortName || currentWarehouseObj.name}
                </label>
                <input
                  type="number"
                  className="form-input mono"
                  min="0"
                  placeholder="0"
                  value={
                    currentWarehouseObj.id === 'warehouse2'
                      ? formData.stockWarehouse2
                      : currentWarehouseObj.id === 'warehouse3'
                      ? formData.stockWarehouse3
                      : formData.stockWarehouse1
                  }
                  onChange={(e) => {
                    const val = e.target.value;
                    if (currentWarehouseObj.id === 'warehouse2') {
                      setFormData({ ...formData, stockWarehouse2: val });
                    } else if (currentWarehouseObj.id === 'warehouse3') {
                      setFormData({ ...formData, stockWarehouse3: val });
                    } else {
                      setFormData({ ...formData, stockWarehouse1: val });
                    }
                  }}
                />
              </div>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem' }}>
              <div className="form-group">
                <label className="form-label">{warehouses[0]?.name || 'Kho 1'}</label>
                <input
                  type="number"
                  className="form-input mono"
                  min="0"
                  value={formData.stockWarehouse1}
                  onChange={(e) => setFormData({ ...formData, stockWarehouse1: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">{warehouses[1]?.name || 'Kho 2'}</label>
                <input
                  type="number"
                  className="form-input mono"
                  min="0"
                  value={formData.stockWarehouse2}
                  onChange={(e) => setFormData({ ...formData, stockWarehouse2: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">{warehouses[2]?.name || 'Kho 3'}</label>
                <input
                  type="number"
                  className="form-input mono"
                  min="0"
                  value={formData.stockWarehouse3}
                  onChange={(e) => setFormData({ ...formData, stockWarehouse3: e.target.value })}
                />
              </div>
            </div>
          )}
        </form>
      </Modal>

      {/* Modal Chỉnh Sửa Sản Phẩm */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={`Chỉnh Sửa Thông Tin: ${selectedProduct?.name || ''}`}
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
                Tên Sản Phẩm <span className="req">*</span>
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
              <label className="form-label">Danh mục</label>
              <input
                type="text"
                className="form-input"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Đơn vị tính</label>
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
              <label className="form-label">Nhà Cung Cấp</label>
              <SearchableSelect
                options={suppliers.map((s) => ({
                  id: s.id,
                  value: s.id,
                  label: s.name,
                  code: s.code,
                  phone: s.phone || '',
                  subLabel: s.phone ? `SĐT: ${s.phone}` : '',
                }))}
                value={formData.supplierId}
                onChange={(val) => setFormData({ ...formData, supplierId: val })}
                placeholder="-- Không có / Chọn NCC --"
                searchPlaceholder="Tìm theo tên, mã NCC, SĐT..."
                searchFields={['label', 'code', 'phone']}
              />
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.25rem 0' }} />

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Giá Vốn</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.unitCost}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Sỉ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.wholesalePrice}
                onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Giá Lẻ</label>
              <input
                type="number"
                className="form-input mono"
                min="0"
                value={formData.retailPrice}
                onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
              />
            </div>
          </div>
        </form>
      </Modal>

      {/* Modal Điều Chỉnh Tồn Kho */}
      <Modal
        isOpen={isAdjustOpen}
        onClose={() => setIsAdjustOpen(false)}
        title={`Điều Chỉnh Tồn Kho: ${selectedProduct?.name || ''}`}
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
          <div className="form-group">
            <label className="form-label">Kho Điều Chỉnh</label>
            {!isOverview && currentWarehouseObj ? (
              <div
                style={{
                  padding: '0.65rem 0.85rem',
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--bg-tertiary)',
                  border: '1px solid var(--border-color)',
                  fontWeight: 700,
                  fontSize: '0.875rem',
                  color: 'var(--primary)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <span>{currentWarehouseObj.name}</span>
                <span className="mono" style={{ color: 'var(--text-secondary)' }}>
                  Tồn hiện tại: {formatNumber(getProductStockForWarehouse(selectedProduct, currentWarehouseObj.id))}
                </span>
              </div>
            ) : (
              <select
                className="form-select"
                value={adjustData.warehouse}
                onChange={(e) => {
                  const newWh = e.target.value;
                  const newWhStock = getProductStockForWarehouse(selectedProduct, newWh);
                  setAdjustData({
                    ...adjustData,
                    warehouse: newWh,
                    quantity: newWhStock,
                  });
                }}
              >
                {warehouses.map((wh) => (
                  <option key={wh.id} value={wh.id}>
                    {wh.name} - Tồn hiện tại: {formatNumber(getProductStockForWarehouse(selectedProduct, wh.id))}
                  </option>
                ))}
              </select>
            )}
            {!isOverview && currentWarehouseObj && (
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                * Đang ở chế độ xem kho riêng, chỉ được phép điều chỉnh tồn kho cho {currentWarehouseObj.name}.
              </div>
            )}
          </div>

          <div className="form-group">
            <label className="form-label">Cách Thức Điều Chỉnh</label>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="adjustMode"
                  value="delta"
                  checked={adjustData.mode === 'delta'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'delta' })}
                />
                <span>Tăng / Giảm độ lệch</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontSize: '0.875rem' }}>
                <input
                  type="radio"
                  name="adjustMode"
                  value="quantity"
                  checked={adjustData.mode === 'quantity'}
                  onChange={() => setAdjustData({ ...adjustData, mode: 'quantity' })}
                />
                <span>Nhập số lượng thực tế mới</span>
              </label>
            </div>
          </div>

          {adjustData.mode === 'delta' ? (
            <div className="form-group">
              <label className="form-label">
                Số Lượng Chênh Lệch
              </label>
              <input
                type="number"
                step="any"
                className="form-input mono"
                placeholder="VD: 5 hoặc -3"
                value={adjustData.delta}
                onChange={(e) => setAdjustData({ ...adjustData, delta: e.target.value })}
                required
              />
            </div>
          ) : (
            <div className="form-group">
              <label className="form-label">Số Lượng Tồn Thực Tế Mới Tại Kho</label>
              <input
                type="number"
                step="any"
                min="0"
                className="form-input mono"
                value={adjustData.quantity}
                onChange={(e) => setAdjustData({ ...adjustData, quantity: e.target.value })}
                required
              />
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Lý Do Điều Chỉnh</label>
            <select
              className="form-select"
              value={adjustData.reason}
              onChange={(e) => setAdjustData({ ...adjustData, reason: e.target.value })}
            >
              {STOCK_ADJUST_REASONS.map((r, i) => (
                <option key={i} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Ghi Chú Chi Tiết</label>
            <textarea
              className="form-textarea"
              rows={2}
              placeholder="VD: Kiểm kê kho cuối tháng 10..."
              value={adjustData.note}
              onChange={(e) => setAdjustData({ ...adjustData, note: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Modal Đổi Tên Kho */}
      <Modal
        isOpen={isRenameWarehouseOpen}
        onClose={() => setIsRenameWarehouseOpen(false)}
        title="Đổi Tên Kho Hàng"
        size="md"
        footer={
          <>
            <button className="btn btn-outline" onClick={() => setIsRenameWarehouseOpen(false)} disabled={submitting}>
              Hủy
            </button>
            <button className="btn btn-primary" onClick={handleRenameWarehouseSubmit} disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Lưu tên mới'}
            </button>
          </>
        }
      >
        <form onSubmit={handleRenameWarehouseSubmit}>
          <div className="form-group">
            <label className="form-label">Mã Kho (Định danh hệ thống)</label>
            <input
              type="text"
              className="form-input mono"
              value={renameWarehouseData.id}
              disabled
              style={{ background: 'var(--bg-tertiary)' }}
            />
          </div>

          <div className="form-group">
            <label className="form-label">
              Tên Kho Đầy Đủ <span className="req">*</span>
            </label>
            <input
              type="text"
              className="form-input"
              placeholder="VD: Kho Trung Tâm - KCN Vĩnh Lộc"
              value={renameWarehouseData.name}
              onChange={(e) => setRenameWarehouseData({ ...renameWarehouseData, name: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Tên Viết Tắt Hiển Thị Trên Bảng & Menu</label>
            <input
              type="text"
              className="form-input"
              placeholder="VD: Kho 1"
              value={renameWarehouseData.shortName}
              onChange={(e) => setRenameWarehouseData({ ...renameWarehouseData, shortName: e.target.value })}
            />
          </div>
        </form>
      </Modal>

      {/* Drawer Xem Lịch Sử Sổ Kho */}
      <Drawer
        isOpen={isHistoryOpen}
        onClose={() => setIsHistoryOpen(false)}
        title={`Sổ Kho: ${selectedProduct?.name || ''}`}
        subtitle={`Mã SKU: ${selectedProduct?.sku || ''} | Tổng tồn: ${formatNumber(selectedProduct?.totalStock || 0)}`}
        width="680px"
      >
        <div style={{ marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
          <TimeFilter
            mode={historyTimeMode}
            onModeChange={(newMode) => {
              setHistoryTimeMode(newMode);
              if (selectedProduct) {
                const p = newMode === 'day' ? historyDate : historyMonth;
                loadStockHistory(selectedProduct.id, p);
              }
            }}
            month={historyMonth}
            onMonthChange={(m) => {
              setHistoryMonth(m);
              if (selectedProduct) loadStockHistory(selectedProduct.id, m);
            }}
            date={historyDate}
            onDateChange={(d) => {
              setHistoryDate(d);
              if (selectedProduct) loadStockHistory(selectedProduct.id, d);
            }}
            showAll={false}
            showRange={false}
          />
        </div>

        {historyLoading ? (
          <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
            Đang tải dữ liệu sổ kho...
          </p>
        ) : historyRecords.length === 0 ? (
          <EmptyState
            icon={History}
            title="Chưa có biến động kho"
            description={
              historyTimeMode === 'day'
                ? `Không có bản ghi xuất/nhập/điều chỉnh kho nào trong ngày ${historyDate}.`
                : `Không có bản ghi xuất/nhập/điều chỉnh kho nào trong tháng ${historyMonth}.`
            }
          />
        ) : (
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Thời Gian</th>
                  <th>Kho</th>
                  <th>Nguồn</th>
                  <th style={{ textAlign: 'right' }}>Trước</th>
                  <th style={{ textAlign: 'right' }}>Biến Động</th>
                  <th style={{ textAlign: 'right' }}>Sau</th>
                  <th>Lý Do</th>
                </tr>
              </thead>
              <tbody>
                {historyRecords
                  .filter((r) => isOverview || r.warehouse === selectedWarehouse || !r.warehouse)
                  .map((r) => {
                    const isPositive = Number(r.delta || 0) > 0;
                    const whObj = warehouses.find((w) => w.id === r.warehouse);
                    return (
                      <tr key={r.id}>
                        <td style={{ fontSize: '0.8125rem' }}>{formatDate(r.createdAt || r.changeDate, true)}</td>
                        <td>
                          <span className="badge badge-neutral">{whObj?.shortName || whObj?.name || r.warehouse}</span>
                        </td>
                        <td>
                          <span className="badge badge-primary">{r.sourceType}</span>
                        </td>
                        <td style={{ textAlign: 'right' }} className="mono">
                          {formatNumber(r.beforeWarehouseStock)}
                        </td>
                        <td
                          style={{
                            textAlign: 'right',
                            fontWeight: 700,
                            color: isPositive ? 'var(--success)' : 'var(--danger)',
                          }}
                          className="mono"
                        >
                          {isPositive ? `+${formatNumber(r.delta)}` : formatNumber(r.delta)}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 600 }} className="mono">
                          {formatNumber(r.afterWarehouseStock)}
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
    </div>
  );
}

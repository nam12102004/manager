import React, { useState, useEffect, useMemo } from 'react';
import {
  FileSpreadsheet,
  Calendar,
  Layers,
  Building,
  User,
  Package,
  CheckSquare,
  Square,
  Play,
  X,
  Database,
  Info,
  Bookmark,
  BookmarkPlus,
  Save,
  Trash2,
  Check,
  Sparkles,
} from 'lucide-react';
import Modal from './Modal';
import SearchableSelect from './SearchableSelect';
import { useExport } from '../../context/ExportContext';
import { useNotification } from '../../context/NotificationContext';
import { exportService, warehouseService } from '../../services';
import { getCurrentMonthStr, getCurrentDateStr } from '../../utils/formatters';

const BUILT_IN_PRESETS = [
  {
    id: 'preset-standard',
    name: '📊 Doanh số & Số lượng',
    isBuiltIn: true,
    tab: 'matrix',
    timeScope: 'month',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: false,
    separateSheets: false,
  },
  {
    id: 'preset-inventory',
    name: '📦 Thủ kho',
    isBuiltIn: true,
    tab: 'matrix',
    timeScope: 'month',
    includeQuantity: true,
    includeRevenue: false,
    includePrice: false,
    separateSheets: false,
  },
  {
    id: 'preset-sales-price',
    name: '💰 Doanh số & Đơn giá',
    isBuiltIn: true,
    tab: 'matrix',
    timeScope: 'month',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: true,
    separateSheets: false,
  },
  {
    id: 'preset-all-time-sheets',
    name: '🗂️ Toàn bộ lịch sử',
    isBuiltIn: true,
    tab: 'matrix',
    timeScope: 'all',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: false,
    separateSheets: true,
  },
  {
    id: 'preset-backup-all',
    name: '💾 Sao lưu CSDL',
    isBuiltIn: true,
    tab: 'full_db',
    dbTimeScope: 'all',
    selectedTables: {
      products: true,
      customers: true,
      suppliers: true,
      exports: true,
      imports: true,
      receipts: true,
      payments: true,
    },
  },
];

export default function ExportMatrixModal() {
  const {
    isModalOpen,
    closeExportModal,
    modalConfig,
    startDailyMatrixExport,
    startFullDbExport,
  } = useExport();

  const notify = useNotification();
  const [activeTab, setActiveTab] = useState('matrix'); // 'matrix' | 'full_db'

  // Dependencies
  const [customers, setCustomers] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [products, setProducts] = useState([]);
  const [warehouses, setWarehouses] = useState([]);
  const [loadingDeps, setLoadingDeps] = useState(false);

  // Form State: Matrix
  const [partnerType, setPartnerType] = useState('customer'); // 'customer' | 'supplier'
  const [selectedCustomerId, setSelectedCustomerId] = useState('');
  const [selectedSupplierId, setSelectedSupplierId] = useState('');
  const [selectedWarehouse, setSelectedWarehouse] = useState('');
  const [selectedProductId, setSelectedProductId] = useState('');
  const [timeScope, setTimeScope] = useState('month'); // 'month' | 'all' | 'custom'
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonthStr());
  const [fromDate, setFromDate] = useState(getCurrentDateStr());
  const [toDate, setToDate] = useState(getCurrentDateStr());
  const [includeQuantity, setIncludeQuantity] = useState(true);
  const [includeRevenue, setIncludeRevenue] = useState(true);
  const [includePrice, setIncludePrice] = useState(false);
  const [separateSheets, setSeparateSheets] = useState(true);

  // Form State: Full DB Backup
  const [selectedTables, setSelectedTables] = useState({
    products: true,
    customers: true,
    suppliers: true,
    exports: true,
    imports: true,
    receipts: true,
    payments: true,
  });
  const [dbTimeScope, setDbTimeScope] = useState('all'); // 'all' | 'month' | 'custom'
  const [dbMonth, setDbMonth] = useState(getCurrentMonthStr());
  const [dbFromDate, setDbFromDate] = useState(getCurrentDateStr());
  const [dbToDate, setDbToDate] = useState(getCurrentDateStr());

  // Presets State
  const [customPresets, setCustomPresets] = useState(() => {
    try {
      const saved = localStorage.getItem('debtmanager_export_presets');
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });
  const [activePresetId, setActivePresetId] = useState(null);
  const [isSavingPreset, setIsSavingPreset] = useState(false);
  const [newPresetName, setNewPresetName] = useState('');

  const allPresets = [...BUILT_IN_PRESETS, ...customPresets];

  const handleApplyPreset = (preset) => {
    setActivePresetId(preset.id);
    if (preset.tab) setActiveTab(preset.tab);

    if (preset.tab === 'matrix' || (!preset.tab && preset.timeScope)) {
      if (preset.selectedCustomerId !== undefined) setSelectedCustomerId(preset.selectedCustomerId);
      if (preset.selectedWarehouse !== undefined) setSelectedWarehouse(preset.selectedWarehouse);
      if (preset.selectedProductId !== undefined) setSelectedProductId(preset.selectedProductId);
      if (preset.timeScope !== undefined) setTimeScope(preset.timeScope);
      if (preset.selectedMonth !== undefined) setSelectedMonth(preset.selectedMonth);
      if (preset.fromDate !== undefined) setFromDate(preset.fromDate);
      if (preset.toDate !== undefined) setToDate(preset.toDate);
      if (preset.includeQuantity !== undefined) setIncludeQuantity(preset.includeQuantity);
      if (preset.includeRevenue !== undefined) setIncludeRevenue(preset.includeRevenue);
      if (preset.includePrice !== undefined) setIncludePrice(preset.includePrice);
      if (preset.separateSheets !== undefined) setSeparateSheets(preset.separateSheets);
    } else if (preset.tab === 'full_db') {
      if (preset.selectedTables) setSelectedTables({ ...preset.selectedTables });
      if (preset.dbTimeScope) setDbTimeScope(preset.dbTimeScope);
      if (preset.dbMonth) setDbMonth(preset.dbMonth);
      if (preset.dbFromDate) setDbFromDate(preset.dbFromDate);
      if (preset.dbToDate) setDbToDate(preset.dbToDate);
    }

    notify.info(`Đã áp dụng mẫu: ${preset.name}`);
  };

  const handleSaveCustomPreset = () => {
    if (!newPresetName.trim()) {
      notify.warning('Vui lòng nhập tên cho mẫu xuất!');
      return;
    }

    const newPreset = {
      id: 'custom-' + Date.now(),
      name: '⭐ ' + newPresetName.trim(),
      isBuiltIn: false,
      tab: activeTab,
      selectedCustomerId,
      selectedWarehouse,
      selectedProductId,
      timeScope,
      selectedMonth,
      fromDate,
      toDate,
      includeQuantity,
      includeRevenue,
      includePrice,
      separateSheets,
      selectedTables,
      dbTimeScope,
      dbMonth,
      dbFromDate,
      dbToDate,
      createdAt: new Date().toISOString(),
    };

    const updated = [...customPresets, newPreset];
    setCustomPresets(updated);
    try {
      localStorage.setItem('debtmanager_export_presets', JSON.stringify(updated));
    } catch (e) {
      console.error(e);
    }

    setActivePresetId(newPreset.id);
    setNewPresetName('');
    setIsSavingPreset(false);
    notify.success(`Đã lưu mẫu xuất "${newPreset.name}" thành công!`);
  };

  const handleDeleteCustomPreset = (presetId, e) => {
    e.stopPropagation();
    const updated = customPresets.filter((p) => p.id !== presetId);
    setCustomPresets(updated);
    try {
      localStorage.setItem('debtmanager_export_presets', JSON.stringify(updated));
    } catch (e) {
      console.error(e);
    }
    if (activePresetId === presetId) {
      setActivePresetId(null);
    }
    notify.info('Đã xóa mẫu xuất tùy chỉnh');
  };

  // Load dependencies when modal opens
  useEffect(() => {
    if (!isModalOpen) return;

    let isMounted = true;
    setLoadingDeps(true);

    Promise.all([
      exportService.getDependencies(),
      warehouseService.getWarehouses(),
    ])
      .then(([{ customers: custs, products: prods, suppliers: supps }, whList]) => {
        if (!isMounted) return;
        setCustomers(custs || []);
        setSuppliers(supps || []);
        setProducts(prods || []);
        setWarehouses(whList || []);

        // Apply preset config if provided
        if (modalConfig) {
          if (modalConfig.tab) setActiveTab(modalConfig.tab);
          if (modalConfig.partnerType) setPartnerType(modalConfig.partnerType);
          if (modalConfig.customerId) setSelectedCustomerId(String(modalConfig.customerId));
          if (modalConfig.supplierId) {
            setSelectedSupplierId(String(modalConfig.supplierId));
            setPartnerType('supplier');
          }
          if (modalConfig.warehouse) setSelectedWarehouse(String(modalConfig.warehouse));
          if (modalConfig.productId) setSelectedProductId(String(modalConfig.productId));
          if (modalConfig.month) {
            setSelectedMonth(modalConfig.month);
            setTimeScope('month');
          }
        }
      })
      .catch((err) => {
        console.error('Failed to load export dependencies', err);
      })
      .finally(() => {
        if (isMounted) setLoadingDeps(false);
      });

    return () => {
      isMounted = false;
    };
  }, [isModalOpen, modalConfig]);

  if (!isModalOpen) return null;

  const handleStartMatrixExport = async (e) => {
    e.preventDefault();

    const isSupplier = partnerType === 'supplier';
    // Prepare title
    let titleParts = [isSupplier ? 'Ma trận nhập hàng' : 'Ma trận xuất hàng'];
    if (timeScope === 'month') {
      titleParts.push(`tháng ${selectedMonth}`);
    } else if (timeScope === 'all') {
      titleParts.push('từ trước tới nay');
    } else {
      titleParts.push(`${fromDate} đến ${toDate}`);
    }

    if (isSupplier) {
      if (selectedSupplierId) {
        const supp = suppliers.find((s) => String(s.id) === String(selectedSupplierId));
        if (supp) titleParts.push(`- NCC: ${supp.name}`);
      }
    } else {
      if (selectedCustomerId) {
        const cust = customers.find((c) => String(c.id) === String(selectedCustomerId));
        if (cust) titleParts.push(`- KH: ${cust.name}`);
      }
    }

    if (selectedWarehouse) {
      const wh = warehouses.find((w) => w.id === selectedWarehouse);
      if (wh) titleParts.push(`- Kho: ${wh.name || wh.id}`);
    }
    if (selectedProductId) {
      const prod = products.find((p) => String(p.id) === String(selectedProductId));
      if (prod) titleParts.push(`- SP: ${prod.sku || prod.name}`);
    }

    const payload = {
      partnerType,
      customerId: !isSupplier && selectedCustomerId ? Number(selectedCustomerId) : null,
      supplierId: isSupplier && selectedSupplierId ? Number(selectedSupplierId) : null,
      warehouse: selectedWarehouse || null,
      productId: selectedProductId ? Number(selectedProductId) : null,
      timeScope,
      month: timeScope === 'month' ? selectedMonth : null,
      fromDate: timeScope === 'custom' && fromDate ? fromDate : null,
      toDate: timeScope === 'custom' && toDate ? toDate : null,
      includeQuantity,
      includeRevenue,
      includePrice,
      separateSheets,
    };

    closeExportModal();
    await startDailyMatrixExport(payload, titleParts.join(' '));
  };

  const handleStartFullDbExport = async (e) => {
    e.preventDefault();

    const activeTableKeys = Object.keys(selectedTables).filter(
      (k) => selectedTables[k]
    );

    if (activeTableKeys.length === 0) {
      alert('Vui lòng chọn ít nhất 1 bảng dữ liệu để sao lưu!');
      return;
    }

    const payload = {
      tables: activeTableKeys,
      timeScope: dbTimeScope,
      month: dbTimeScope === 'month' ? dbMonth : null,
      fromDate: dbTimeScope === 'custom' && dbFromDate ? dbFromDate : null,
      toDate: dbTimeScope === 'custom' && dbToDate ? dbToDate : null,
    };

    const title = `Sao lưu CSDL (${activeTableKeys.length} bảng) - ${
      dbTimeScope === 'all'
        ? 'Toàn bộ lịch sử'
        : dbTimeScope === 'month'
        ? `Tháng ${dbMonth}`
        : `${dbFromDate} đến ${dbToDate}`
    }`;

    closeExportModal();
    await startFullDbExport(payload, title);
  };

  const toggleTable = (tableKey) => {
    setSelectedTables((prev) => ({
      ...prev,
      [tableKey]: !prev[tableKey],
    }));
  };

  const selectAllTables = (selectAll) => {
    setSelectedTables({
      products: selectAll,
      customers: selectAll,
      suppliers: selectAll,
      exports: selectAll,
      imports: selectAll,
      receipts: selectAll,
      payments: selectAll,
    });
  };

  return (
    <Modal
      isOpen={isModalOpen}
      onClose={closeExportModal}
      title="Kết Xuất Dữ Liệu Excel"
      size="lg"
    >
      <div>
        {/* Tab switch */}
        <div style={{ display: 'flex', gap: '8px', marginBottom: '16px', borderBottom: '1px solid var(--border-color, #e2e8f0)', paddingBottom: '8px' }}>
          <button
            type="button"
            className={`btn ${activeTab === 'matrix' ? 'btn-primary' : 'btn-outline'}`}
            onClick={() => setActiveTab('matrix')}
            style={{ fontSize: '0.875rem', gap: '6px' }}
          >
            <Calendar size={16} />
            <span>Ma Trận Theo Ngày</span>
          </button>
          <button
            type="button"
            className={`btn ${activeTab === 'full_db' ? 'btn-primary' : 'btn-outline'}`}
            onClick={() => setActiveTab('full_db')}
            style={{ fontSize: '0.875rem', gap: '6px' }}
          >
            <Database size={16} />
            <span>Sao Lưu Cơ Sở Dữ Liệu</span>
          </button>
        </div>

        {/* Presets Toolbar */}
        <div
          style={{
            background: 'var(--bg-secondary, #f8fafc)',
            border: '1px solid var(--border-color, #e2e8f0)',
            borderRadius: '8px',
            padding: '10px 14px',
            marginBottom: '16px',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: '8px',
              marginBottom: '8px',
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                fontSize: '0.8125rem',
                fontWeight: 700,
                color: 'var(--text-primary)',
              }}
            >
              <Bookmark size={15} color="var(--primary)" />
              <span>Mẫu xuất đã lưu:</span>
            </div>

            {!isSavingPreset ? (
              <button
                type="button"
                className="btn btn-outline"
                onClick={() => setIsSavingPreset(true)}
                style={{ fontSize: '0.75rem', padding: '3px 8px', height: 'auto', gap: '4px' }}
                title="Lưu cấu hình hiện tại thành một mẫu xuất"
              >
                <BookmarkPlus size={13} />
                <span>Lưu thành mẫu mới</span>
              </button>
            ) : (
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Tên mẫu xuất..."
                  value={newPresetName}
                  onChange={(e) => setNewPresetName(e.target.value)}
                  style={{ fontSize: '0.75rem', padding: '3px 8px', height: '28px', width: '220px' }}
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleSaveCustomPreset();
                    } else if (e.key === 'Escape') {
                      setIsSavingPreset(false);
                    }
                  }}
                />
                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={handleSaveCustomPreset}
                  style={{ fontSize: '0.75rem', padding: '3px 8px', height: '28px' }}
                >
                  Lưu
                </button>
                <button
                  type="button"
                  className="btn btn-ghost"
                  onClick={() => setIsSavingPreset(false)}
                  style={{ fontSize: '0.75rem', padding: '3px 6px', height: '28px' }}
                >
                  Hủy
                </button>
              </div>
            )}
          </div>

          {/* Preset Pills */}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
            {allPresets.map((preset) => {
              const isSelected = activePresetId === preset.id;
              return (
                <div
                  key={preset.id}
                  onClick={() => handleApplyPreset(preset)}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '4px 10px',
                    borderRadius: '16px',
                    fontSize: '0.75rem',
                    fontWeight: isSelected ? 700 : 500,
                    cursor: 'pointer',
                    background: isSelected ? 'var(--primary)' : 'var(--bg-card, #ffffff)',
                    color: isSelected ? '#ffffff' : 'var(--text-primary)',
                    border: isSelected ? '1px solid var(--primary)' : '1px solid var(--border-color)',
                    boxShadow: isSelected ? '0 1px 3px rgba(0,0,0,0.12)' : 'none',
                    transition: 'all 0.15s ease',
                    userSelect: 'none',
                  }}
                >
                  {isSelected && <Check size={12} />}
                  <span>{preset.name}</span>
                  {!preset.isBuiltIn && (
                    <button
                      type="button"
                      onClick={(e) => handleDeleteCustomPreset(preset.id, e)}
                      style={{
                        background: 'transparent',
                        border: 'none',
                        color: isSelected ? 'rgba(255,255,255,0.85)' : 'var(--text-muted)',
                        cursor: 'pointer',
                        padding: '0 2px',
                        display: 'flex',
                        alignItems: 'center',
                        marginLeft: '2px',
                      }}
                      title="Xóa mẫu xuất tùy chỉnh này"
                    >
                      <X size={12} />
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* TAB 1: DAILY MATRIX EXPORT */}
        {activeTab === 'matrix' && (
          <form onSubmit={handleStartMatrixExport}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {/* Partner Type Selector: Khách Hàng vs Nhà Cung Cấp */}
              <div style={{ background: 'var(--bg-secondary, #f8fafc)', border: '1px solid var(--border-color, #e2e8f0)', borderRadius: '8px', padding: '10px 12px' }}>
                <div style={{ fontSize: '0.8rem', fontWeight: 700, marginBottom: '6px', color: 'var(--text-primary)' }}>
                  Đối tượng kết xuất:
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                  <button
                    type="button"
                    onClick={() => setPartnerType('customer')}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                      padding: '8px 12px',
                      borderRadius: '6px',
                      border: partnerType === 'customer' ? '1.5px solid var(--primary)' : '1px solid var(--border-color)',
                      background: partnerType === 'customer' ? 'var(--primary-light, #eff6ff)' : 'var(--bg-card, #ffffff)',
                      color: partnerType === 'customer' ? 'var(--primary)' : 'var(--text-secondary)',
                      fontWeight: partnerType === 'customer' ? 700 : 500,
                      cursor: 'pointer',
                      fontSize: '0.85rem',
                      fontFamily: 'inherit',
                      transition: 'all 0.15s ease',
                    }}
                  >
                    <User size={16} />
                    <span>Khách Hàng</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPartnerType('supplier')}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                      padding: '8px 12px',
                      borderRadius: '6px',
                      border: partnerType === 'supplier' ? '1.5px solid var(--primary)' : '1px solid var(--border-color)',
                      background: partnerType === 'supplier' ? 'var(--primary-light, #eff6ff)' : 'var(--bg-card, #ffffff)',
                      color: partnerType === 'supplier' ? 'var(--primary)' : 'var(--text-secondary)',
                      fontWeight: partnerType === 'supplier' ? 700 : 500,
                      cursor: 'pointer',
                      fontSize: '0.85rem',
                      fontFamily: 'inherit',
                      transition: 'all 0.15s ease',
                    }}
                  >
                    <Building size={16} />
                    <span>Nhà Cung Cấp</span>
                  </button>
                </div>
              </div>

              {/* Row 1: Khách hàng / NCC & Kho & Sản phẩm */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '12px' }}>
                <div>
                  <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    {partnerType === 'supplier' ? <Building size={14} color="var(--primary)" /> : <User size={14} color="var(--primary)" />}
                    <span>{partnerType === 'supplier' ? 'Chọn Nhà Cung Cấp' : 'Chọn Khách Hàng'}</span>
                  </label>

                  {partnerType === 'supplier' ? (
                    <SearchableSelect
                      options={suppliers.map((s) => ({
                        id: s.id,
                        value: s.id,
                        label: s.name,
                        code: s.code,
                        phone: s.phone || '',
                      }))}
                      value={selectedSupplierId}
                      onChange={(val) => setSelectedSupplierId(val ?? '')}
                      placeholder="Tất cả nhà cung cấp"
                      searchPlaceholder="Tìm tên, mã, SĐT..."
                      disabled={loadingDeps}
                    />
                  ) : (
                    <SearchableSelect
                      options={customers.map((c) => ({
                        id: c.id,
                        value: c.id,
                        label: c.name,
                        code: c.code,
                        phone: c.phone || '',
                      }))}
                      value={selectedCustomerId}
                      onChange={(val) => setSelectedCustomerId(val ?? '')}
                      placeholder="Tất cả khách hàng"
                      searchPlaceholder="Tìm tên, mã, SĐT..."
                      disabled={loadingDeps}
                    />
                  )}
                </div>

                <div>
                  <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Building size={14} />
                    <span>Kho Hàng</span>
                  </label>
                  <SearchableSelect
                    options={warehouses.map((w) => ({
                      id: w.id,
                      value: w.id,
                      label: w.shortName || w.name,
                      code: w.id,
                    }))}
                    value={selectedWarehouse}
                    onChange={(val) => setSelectedWarehouse(val ?? '')}
                    placeholder="Tất cả kho"
                    searchPlaceholder="Tìm tên kho..."
                    disabled={loadingDeps}
                  />
                </div>

                <div>
                  <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Package size={14} />
                    <span>Sản Phẩm</span>
                  </label>
                  <SearchableSelect
                    options={products.map((p) => ({
                      id: p.id,
                      value: p.id,
                      label: p.name,
                      code: p.sku,
                      subLabel: p.uom || '',
                    }))}
                    value={selectedProductId}
                    onChange={(val) => setSelectedProductId(val ?? '')}
                    placeholder="Tất cả sản phẩm"
                    searchPlaceholder="Tìm tên SP, mã SKU..."
                    disabled={loadingDeps}
                  />
                </div>
              </div>

              {/* Row 2: Thời gian */}
              <div
                style={{
                  background: 'var(--bg-secondary, #f8fafc)',
                  border: '1px solid var(--border-color, #e2e8f0)',
                  borderRadius: '8px',
                  padding: '12px',
                }}
              >
                <div style={{ fontWeight: 600, fontSize: '0.875rem', marginBottom: '8px' }}>
                  Khoảng Thời Gian Xuất
                </div>
                <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', marginBottom: '10px' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="radio"
                      name="timeScope"
                      value="month"
                      checked={timeScope === 'month'}
                      onChange={() => setTimeScope('month')}
                    />
                    <span>Theo tháng cụ thể</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="radio"
                      name="timeScope"
                      value="all"
                      checked={timeScope === 'all'}
                      onChange={() => setTimeScope('all')}
                    />
                    <span>Toàn bộ từ trước tới nay</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="radio"
                      name="timeScope"
                      value="custom"
                      checked={timeScope === 'custom'}
                      onChange={() => setTimeScope('custom')}
                    />
                    <span>Tùy chọn khoảng ngày</span>
                  </label>
                </div>

                {timeScope === 'month' && (
                  <div style={{ maxWidth: '240px' }}>
                    <input
                      type="month"
                      className="form-input"
                      value={selectedMonth}
                      onChange={(e) => setSelectedMonth(e.target.value)}
                      required
                    />
                  </div>
                )}

                {timeScope === 'custom' && (
                  <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '0.8125rem' }}>Từ ngày:</span>
                      <input
                        type="date"
                        className="form-input"
                        value={fromDate}
                        onChange={(e) => setFromDate(e.target.value)}
                        required
                      />
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '0.8125rem' }}>Đến ngày:</span>
                      <input
                        type="date"
                        className="form-input"
                        value={toDate}
                        onChange={(e) => setToDate(e.target.value)}
                        required
                      />
                    </div>
                  </div>
                )}

                {timeScope === 'all' && (
                  <div style={{ marginTop: '8px' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.8125rem' }}>
                      <input
                        type="checkbox"
                        checked={separateSheets}
                        onChange={(e) => setSeparateSheets(e.target.checked)}
                      />
                      <span>Tự động chia mỗi tháng thành một Sheet riêng biệt trong cùng 1 file Excel</span>
                    </label>
                  </div>
                )}
              </div>

              {/* Row 3: Cột hiển thị */}
              <div
                style={{
                  background: 'var(--bg-secondary, #f8fafc)',
                  border: '1px solid var(--border-color, #e2e8f0)',
                  borderRadius: '8px',
                  padding: '12px',
                }}
              >
                <div style={{ fontWeight: 600, fontSize: '0.875rem', marginBottom: '8px' }}>
                  Lựa Chọn Cột Hiển Thị Ma Trận
                </div>
                <div style={{ display: 'flex', gap: '18px', flexWrap: 'wrap' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="checkbox"
                      checked={includeQuantity}
                      onChange={(e) => setIncludeQuantity(e.target.checked)}
                    />
                    <span>Số lượng theo ngày</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="checkbox"
                      checked={includeRevenue}
                      onChange={(e) => setIncludeRevenue(e.target.checked)}
                    />
                    <span>{partnerType === 'supplier' ? 'Tiền nhập theo ngày' : 'Doanh số theo ngày'}</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="checkbox"
                      checked={includePrice}
                      onChange={(e) => setIncludePrice(e.target.checked)}
                    />
                    <span>Đơn giá trung bình</span>
                  </label>
                </div>
              </div>

              {/* Submit Buttons */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '12px' }}>
                <button type="button" className="btn btn-outline" onClick={closeExportModal}>
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={!includeQuantity && !includeRevenue}
                  style={{ gap: '6px' }}
                >
                  <Play size={16} />
                  <span>Xuất File Excel</span>
                </button>
              </div>
            </div>
          </form>
        )}

        {/* TAB 2: FULL DB BACKUP EXPORT */}
        {activeTab === 'full_db' && (
          <form onSubmit={handleStartFullDbExport}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <span style={{ fontWeight: 600, fontSize: '0.875rem' }}>Các Bảng Dữ Liệu Cần Xuất:</span>
                  <div style={{ display: 'flex', gap: '8px', fontSize: '0.75rem' }}>
                    <button
                      type="button"
                      className="btn btn-ghost"
                      onClick={() => selectAllTables(true)}
                      style={{ padding: '2px 6px', height: 'auto', fontSize: '0.75rem' }}
                    >
                      Chọn tất cả
                    </button>
                    <button
                      type="button"
                      className="btn btn-ghost"
                      onClick={() => selectAllTables(false)}
                      style={{ padding: '2px 6px', height: 'auto', fontSize: '0.75rem' }}
                    >
                      Bỏ chọn hết
                    </button>
                  </div>
                </div>

                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                    gap: '10px',
                    padding: '12px',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color, #e2e8f0)',
                    background: 'var(--bg-secondary, #f8fafc)',
                  }}
                >
                  {[
                    { key: 'products', label: '1. Danh mục Sản phẩm & Tồn kho' },
                    { key: 'customers', label: '2. Khách hàng & Sổ nợ' },
                    { key: 'suppliers', label: '3. Nhà cung cấp & Sổ nợ' },
                    { key: 'exports', label: '4. Phiếu xuất kho & Bán hàng' },
                    { key: 'imports', label: '5. Phiếu nhập kho & Mua hàng' },
                    { key: 'receipts', label: '6. Phiếu thu tiền mặt' },
                    { key: 'payments', label: '7. Phiếu chi tiền mặt' },
                  ].map((tbl) => (
                    <label
                      key={tbl.key}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        cursor: 'pointer',
                        fontSize: '0.8125rem',
                        userSelect: 'none',
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={!!selectedTables[tbl.key]}
                        onChange={() => toggleTable(tbl.key)}
                      />
                      <span>{tbl.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Time scope for DB */}
              <div
                style={{
                  background: 'var(--bg-secondary, #f8fafc)',
                  border: '1px solid var(--border-color, #e2e8f0)',
                  borderRadius: '8px',
                  padding: '12px',
                }}
              >
                <div style={{ fontWeight: 600, fontSize: '0.875rem', marginBottom: '8px' }}>
                  Giới Hạn Thời Gian Chứng Từ
                </div>
                <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', marginBottom: '10px' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="radio"
                      name="dbTimeScope"
                      value="all"
                      checked={dbTimeScope === 'all'}
                      onChange={() => setDbTimeScope('all')}
                    />
                    <span>Toàn bộ từ trước tới nay</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="radio"
                      name="dbTimeScope"
                      value="month"
                      checked={dbTimeScope === 'month'}
                      onChange={() => setDbTimeScope('month')}
                    />
                    <span>Theo tháng</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.875rem' }}>
                    <input
                      type="radio"
                      name="dbTimeScope"
                      value="custom"
                      checked={dbTimeScope === 'custom'}
                      onChange={() => setDbTimeScope('custom')}
                    />
                    <span>Khoảng ngày tùy chọn</span>
                  </label>
                </div>

                {dbTimeScope === 'month' && (
                  <div style={{ maxWidth: '240px' }}>
                    <input
                      type="month"
                      className="form-input"
                      value={dbMonth}
                      onChange={(e) => setDbMonth(e.target.value)}
                      required
                    />
                  </div>
                )}

                {dbTimeScope === 'custom' && (
                  <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '0.8125rem' }}>Từ ngày:</span>
                      <input
                        type="date"
                        className="form-input"
                        value={dbFromDate}
                        onChange={(e) => setDbFromDate(e.target.value)}
                        required
                      />
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '0.8125rem' }}>Đến ngày:</span>
                      <input
                        type="date"
                        className="form-input"
                        value={dbToDate}
                        onChange={(e) => setDbToDate(e.target.value)}
                        required
                      />
                    </div>
                  </div>
                )}
              </div>

              {/* Submit Buttons */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '12px' }}>
                <button type="button" className="btn btn-outline" onClick={closeExportModal}>
                  Hủy Bỏ
                </button>
                <button type="submit" className="btn btn-primary" style={{ gap: '6px' }}>
                  <Play size={16} />
                  <span>Sao Lưu Dữ Liệu</span>
                </button>
              </div>
            </div>
          </form>
        )}
      </div>
    </Modal>
  );
}

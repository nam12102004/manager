import React, { useState, useEffect, useMemo } from 'react';
import {
  FileSpreadsheet,
  CalendarDays,
  Building,
  User,
  Package,
  Play,
  X,
  Database,
  Bookmark,
  BookmarkPlus,
  Check,
  Download,
  Clock,
  CheckCircle2,
  AlertCircle,
  AlertTriangle,
  RefreshCw,
  Hash,
  Banknote,
  Tag,
  Layers,
  Loader2,
  Inbox,
  Boxes,
  TrendingUp,
  ShoppingBag,
  ArrowLeftRight,
  Wallet,
  FileText,
  ChevronLeft,
  ChevronRight,
  ChevronRight as ArrowStep,
} from 'lucide-react';
import { useExport } from '../context/ExportContext';
import { useNotification } from '../context/NotificationContext';
import MultiSearchableSelect from '../components/common/MultiSearchableSelect';
import ExcelPreview from '../components/common/ExcelPreview';
import { exportService, warehouseService } from '../services';
import { getCurrentMonthStr, getCurrentDateStr } from '../utils/formatters';
import {
  PERIOD_MODES,
  GRANULARITIES,
  REPORT_TYPES,
  GROUP_BY_OPTIONS,
  getAllowedGranularities,
  estimateBucketCount,
  formatPeriodDescription,
} from '../utils/exportPeriod';

const PRESET_STORAGE_KEY = 'debtmanager_export_presets_v2';

const ALL_TABLES_ON = {
  products: true,
  customers: true,
  suppliers: true,
  exports: true,
  imports: true,
  receipts: true,
  payments: true,
};

const TABLE_OPTIONS = [
  { key: 'products', label: 'Sản phẩm & Tồn kho' },
  { key: 'customers', label: 'Khách hàng & Công nợ' },
  { key: 'suppliers', label: 'Nhà cung cấp & Công nợ' },
  { key: 'exports', label: 'Phiếu xuất kho' },
  { key: 'imports', label: 'Phiếu nhập kho' },
  { key: 'receipts', label: 'Phiếu thu' },
  { key: 'payments', label: 'Phiếu chi' },
];

const BUILT_IN_PRESETS = [
  {
    id: 'preset-sales-product-day',
    name: '📊 Doanh số sản phẩm theo ngày',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'sales',
    periodMode: 'month',
    granularity: 'day',
    groupBy: 'product',
    partnerType: 'customer',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: false,
    includeDetailSheet: true,
  },
  {
    id: 'preset-price-analysis',
    name: '💲 Bảng đơn giá xuất bán theo kỳ',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'sales',
    periodMode: 'month',
    granularity: 'week',
    groupBy: 'product',
    partnerType: 'customer',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: true,
    includeDetailSheet: true,
  },
  {
    id: 'preset-sales-customer-week',
    name: '📈 Xuất bán khách hàng theo tuần',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'sales',
    periodMode: 'monthRange',
    granularity: 'week',
    groupBy: 'partner_product',
    partnerType: 'customer',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: false,
    includeDetailSheet: true,
  },
  {
    id: 'preset-purchases-supplier',
    name: '📥 Nhập hàng nhà cung cấp',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'purchases',
    periodMode: 'month',
    granularity: 'day',
    groupBy: 'product',
    partnerType: 'supplier',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: false,
    includeDetailSheet: true,
  },
  {
    id: 'preset-purchase-price-analysis',
    name: '🏷️ Đơn giá nhập hàng theo sản phẩm',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'purchases',
    periodMode: 'month',
    granularity: 'week',
    groupBy: 'product',
    partnerType: 'supplier',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: true,
    includeDetailSheet: true,
  },
  {
    id: 'preset-inventory-current',
    name: '📊 Tồn kho hiện tại',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'inventory',
    periodMode: 'month',
    granularity: 'day',
    groupBy: 'product',
    partnerType: 'customer',
    includeQuantity: true,
    includeRevenue: true,
    includePrice: true,
    includeDetailSheet: true,
  },
  {
    id: 'preset-inout-product',
    name: '📦 Nhập - Xuất sản phẩm',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'inout',
    periodMode: 'month',
    granularity: 'week',
    groupBy: 'product',
    partnerType: 'customer',
    includeQuantity: true,
    includeRevenue: false,
    includePrice: false,
    includeDetailSheet: true,
  },
  {
    id: 'preset-cashflow-partner',
    name: '💳 Thu - Chi đối tác',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'cashflow',
    periodMode: 'month',
    granularity: 'month',
    groupBy: 'partner',
    partnerType: 'customer',
    includeQuantity: false,
    includeRevenue: true,
    includePrice: false,
    includeDetailSheet: true,
  },
  {
    id: 'preset-debt-period',
    name: '📑 Công nợ theo kỳ',
    isBuiltIn: true,
    tab: 'report',
    reportType: 'debt',
    periodMode: 'month',
    granularity: 'month',
    groupBy: 'partner',
    partnerType: 'customer',
    includeQuantity: false,
    includeRevenue: true,
    includePrice: false,
    includeDetailSheet: true,
  },
  {
    id: 'preset-backup-all',
    name: '💾 Sao lưu CSDL',
    isBuiltIn: true,
    tab: 'full_db',
    dbTimeScope: 'all',
    selectedTables: ALL_TABLES_ON,
  },
];

const REPORT_ACCENTS = {
  sales: { color: 'var(--primary)', bg: 'var(--primary-light)', glow: 'var(--primary-glow)' },
  purchases: { color: 'var(--warning)', bg: 'var(--warning-light)', glow: 'rgba(245, 158, 11, 0.2)' },
  inventory: { color: '#0d9488', bg: 'rgba(13, 148, 136, 0.12)', glow: 'rgba(13, 148, 136, 0.25)' },
  inout: { color: 'var(--purple)', bg: 'var(--purple-light)', glow: 'rgba(139, 92, 246, 0.2)' },
  cashflow: { color: 'var(--success)', bg: 'var(--success-light)', glow: 'rgba(16, 185, 129, 0.2)' },
  debt: { color: 'var(--info)', bg: 'var(--info-light)', glow: 'rgba(6, 182, 212, 0.2)' },
};

const STYLES = `
.xe-mode-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; margin-bottom: 16px; }
.xe-mode-card { display: flex; align-items: center; gap: 12px; padding: 12px 18px; border-radius: var(--radius-lg); border: 1.5px solid var(--border-color); background: var(--bg-card); cursor: pointer; text-align: left; transition: all var(--transition-fast); color: var(--text-primary); font-family: inherit; }
.xe-mode-card:hover { border-color: var(--primary); box-shadow: var(--shadow-sm); }
.xe-mode-card.active { border-color: var(--primary); background: var(--primary-light); box-shadow: 0 0 0 3px var(--primary-glow); }
.xe-mode-icon { width: 36px; height: 36px; border-radius: var(--radius-md); display: flex; align-items: center; justify-content: center; flex-shrink: 0; background: var(--bg-tertiary); color: var(--text-muted); }
.xe-mode-card.active .xe-mode-icon { background: var(--primary); color: #fff; }
.xe-mode-title { font-weight: 700; font-size: 0.9375rem; }

/* Step 1: Report Cards */
.xe-report-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; }
.xe-report-card { position: relative; display: flex; flex-direction: column; gap: 10px; padding: 12px 14px; border-radius: var(--radius-md); border: 1.5px solid var(--border-color); background: var(--bg-secondary); cursor: pointer; transition: all var(--transition-fast); text-align: left; color: var(--text-primary); font-family: inherit; }
.xe-report-card:hover { border-color: var(--text-muted); transform: translateY(-1px); box-shadow: var(--shadow-xs); }
.xe-report-card-top { display: flex; align-items: center; justify-content: space-between; }
.xe-report-card-icon { width: 32px; height: 32px; border-radius: var(--radius-sm); display: flex; align-items: center; justify-content: center; background: var(--bg-tertiary); color: var(--text-muted); transition: all var(--transition-fast); }
.xe-report-card-title { font-size: 0.875rem; font-weight: 700; }

/* Presets Bar */
.xe-presets { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; padding: 10px 14px; border-radius: var(--radius-lg); background: var(--bg-card); border: 1px solid var(--border-color); margin-bottom: 16px; }
.xe-presets-label { display: flex; align-items: center; gap: 6px; font-size: 0.76rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.04em; margin-right: 4px; }
.xe-chip { display: inline-flex; align-items: center; gap: 6px; padding: 5px 12px; border-radius: var(--radius-full); font-size: 0.8rem; font-weight: 600; border: 1px solid var(--border-color); background: var(--bg-tertiary); color: var(--text-secondary); cursor: pointer; transition: all var(--transition-fast); user-select: none; }
.xe-chip:hover { border-color: var(--primary); color: var(--primary); }
.xe-chip.active { background: var(--primary); border-color: var(--primary); color: #fff; }
.xe-chip.custom { border-style: dashed; }
.xe-chip-x { display: flex; background: transparent; border: none; color: inherit; opacity: 0.65; cursor: pointer; padding: 0; }
.xe-chip-x:hover { opacity: 1; }

/* Main 2-column layout */
.xe-layout { display: grid; grid-template-columns: minmax(0, 1fr) 350px; gap: 16px; align-items: start; }
@media (max-width: 1100px) { .xe-layout { grid-template-columns: 1fr; } }

.xe-card { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: var(--radius-lg); box-shadow: var(--shadow-xs); }
.xe-section { padding: 18px 20px; border-bottom: 1px solid var(--border-light); }
.xe-section:last-child { border-bottom: none; }
.xe-section-head { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
.xe-step { width: 24px; height: 24px; border-radius: 50%; background: var(--primary-light); color: var(--primary); font-size: 0.75rem; font-weight: 800; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.xe-section-title { font-weight: 700; font-size: 0.9375rem; color: var(--text-primary); }
.xe-section-hint { font-size: 0.76rem; color: var(--text-muted); margin-left: auto; }

.xe-field-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 14px; }
.xe-label { display: flex; align-items: center; gap: 6px; font-size: 0.8rem; font-weight: 600; color: var(--text-secondary); margin-bottom: 7px; }

/* Step 2: Time & Granularity Grid */
.xe-time-grid { display: grid; grid-template-columns: 1.35fr 1fr; gap: 18px; align-items: start; }
@media (max-width: 820px) { .xe-time-grid { grid-template-columns: 1fr; } }

.xe-period-pills { display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px; background: var(--bg-tertiary); padding: 5px; border-radius: var(--radius-md); border: 1px solid var(--border-color); }
@media (max-width: 560px) { .xe-period-pills { grid-template-columns: repeat(2, 1fr); } }
.xe-period-pill { border: none; background: transparent; padding: 7px 10px; border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; color: var(--text-secondary); cursor: pointer; font-family: inherit; transition: all var(--transition-fast); text-align: center; white-space: nowrap; }
.xe-period-pill:hover { color: var(--text-primary); background: rgba(255,255,255,0.4); }
.xe-period-pill.active { background: var(--bg-secondary); color: var(--primary); box-shadow: var(--shadow-xs); font-weight: 700; }

.xe-time-picker-box { margin-top: 10px; padding: 11px 13px; border-radius: var(--radius-md); background: var(--bg-primary); border: 1px solid var(--border-color); display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.xe-nav-btn { width: 34px; height: 34px; border-radius: var(--radius-sm); border: 1px solid var(--border-color); background: var(--bg-secondary); color: var(--text-secondary); display: inline-flex; align-items: center; justify-content: center; cursor: pointer; transition: all var(--transition-fast); flex-shrink: 0; }
.xe-nav-btn:hover { border-color: var(--primary); color: var(--primary); }
.xe-quick-btn { padding: 5px 10px; height: 34px; border-radius: var(--radius-sm); border: 1px solid var(--border-color); background: var(--bg-secondary); color: var(--text-secondary); font-size: 0.76rem; font-weight: 600; cursor: pointer; font-family: inherit; transition: all var(--transition-fast); }
.xe-quick-btn:hover { border-color: var(--primary); color: var(--primary); background: var(--primary-light); }

/* Granularity Cards */
.xe-gran-list { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.xe-gran-card { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; padding: 11px 8px; border-radius: var(--radius-md); border: 1.5px solid var(--border-color); background: var(--bg-secondary); cursor: pointer; font-family: inherit; transition: all var(--transition-fast); text-align: center; }
.xe-gran-card:hover:not(:disabled) { border-color: var(--primary); }
.xe-gran-card.active { border-color: var(--primary); background: var(--primary-light); color: var(--primary); box-shadow: 0 0 0 2px var(--primary-glow); }
.xe-gran-card:disabled { opacity: 0.4; cursor: not-allowed; background: var(--bg-tertiary); }
.xe-gran-title { font-size: 0.83rem; font-weight: 700; color: var(--text-primary); }
.xe-gran-card.active .xe-gran-title { color: var(--primary); }
.xe-gran-badge { font-size: 0.7rem; font-weight: 600; padding: 1px 7px; border-radius: var(--radius-full); background: var(--bg-tertiary); color: var(--text-muted); }
.xe-gran-card.active .xe-gran-badge { background: var(--primary); color: #ffffff; }

/* Partner Switcher Pills */
.xe-partner-tabs { display: inline-flex; gap: 6px; padding: 4px; background: var(--bg-tertiary); border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 12px; }
.xe-partner-tab { display: inline-flex; align-items: center; gap: 7px; padding: 7px 16px; border-radius: var(--radius-sm); border: none; background: transparent; color: var(--text-secondary); font-size: 0.82rem; font-weight: 600; cursor: pointer; font-family: inherit; transition: all var(--transition-fast); }
.xe-partner-tab:hover { color: var(--text-primary); }
.xe-partner-tab.active { background: var(--bg-secondary); color: var(--primary); box-shadow: var(--shadow-xs); font-weight: 700; }

/* Warehouse Quick Chips */
.xe-wh-chips { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.xe-wh-chip { display: inline-flex; align-items: center; gap: 6px; padding: 6px 13px; border-radius: var(--radius-md); border: 1.5px solid var(--border-color); background: var(--bg-secondary); color: var(--text-secondary); font-size: 0.81rem; font-weight: 600; cursor: pointer; font-family: inherit; transition: all var(--transition-fast); user-select: none; }
.xe-wh-chip:hover { border-color: var(--primary); color: var(--text-primary); }
.xe-wh-chip.active { border-color: var(--primary); background: var(--primary-light); color: var(--primary); }

/* Step 4: Group By Cards */
.xe-group-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 8px; }
.xe-group-card { position: relative; display: flex; align-items: center; gap: 10px; padding: 10px 13px; border-radius: var(--radius-md); border: 1.5px solid var(--border-color); background: var(--bg-secondary); cursor: pointer; font-family: inherit; transition: all var(--transition-fast); text-align: left; color: var(--text-secondary); }
.xe-group-card:hover { border-color: var(--primary); color: var(--text-primary); }
.xe-group-card.active { border-color: var(--primary); background: var(--primary-light); color: var(--primary); font-weight: 700; }
.xe-group-radio { width: 16px; height: 16px; border-radius: 50%; border: 1.5px solid var(--border-color); display: flex; align-items: center; justify-content: center; flex-shrink: 0; background: var(--bg-secondary); }
.xe-group-card.active .xe-group-radio { border-color: var(--primary); background: var(--primary); color: #ffffff; }
.xe-group-text { font-size: 0.82rem; font-weight: 600; line-height: 1.3; }

/* Metric Toggles */
.xe-toggle-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(165px, 1fr)); gap: 10px; }
.xe-toggle { position: relative; display: flex; align-items: center; gap: 10px; padding: 11px 14px; border-radius: var(--radius-md); border: 1.5px solid var(--border-color); background: var(--bg-secondary); cursor: pointer; transition: all var(--transition-fast); text-align: left; font-family: inherit; color: var(--text-primary); }
.xe-toggle:hover { border-color: var(--primary); }
.xe-toggle.on { border-color: var(--primary); background: var(--primary-light); }
.xe-toggle-icon { width: 32px; height: 32px; border-radius: var(--radius-sm); display: flex; align-items: center; justify-content: center; background: var(--bg-tertiary); color: var(--text-muted); flex-shrink: 0; }
.xe-toggle.on .xe-toggle-icon { background: var(--primary); color: #fff; }
.xe-toggle-title { font-size: 0.84rem; font-weight: 700; }
.xe-check { position: absolute; top: 8px; right: 8px; width: 18px; height: 18px; border-radius: 50%; border: 1.5px solid var(--border-color); display: flex; align-items: center; justify-content: center; background: var(--bg-secondary); }
.xe-toggle.on .xe-check { background: var(--primary); border-color: var(--primary); color: #fff; }

.xe-switch-row { display: inline-flex; align-items: center; gap: 10px; margin-top: 14px; font-size: 0.83rem; font-weight: 600; color: var(--text-secondary); cursor: pointer; user-select: none; }
.xe-switch { width: 36px; height: 20px; border-radius: 999px; background: var(--border-color); position: relative; transition: background var(--transition-fast); flex-shrink: 0; }
.xe-switch::after { content: ''; position: absolute; top: 2px; left: 2px; width: 16px; height: 16px; border-radius: 50%; background: #fff; box-shadow: var(--shadow-xs); transition: left var(--transition-fast); }
.xe-switch.on { background: var(--primary); }
.xe-switch.on::after { left: 18px; }

.xe-warning-box { display: flex; align-items: center; gap: 8px; padding: 10px 14px; border-radius: var(--radius-md); background: var(--warning-light); color: var(--warning-text); font-size: 0.8rem; font-weight: 600; margin-top: 12px; border: 1px solid rgba(245, 158, 11, 0.35); }

/* Right Summary & Queue */
.xe-side { position: sticky; top: 16px; display: flex; flex-direction: column; gap: 16px; }
.xe-summary-head { padding: 15px 18px; border-bottom: 1px solid var(--border-light); display: flex; align-items: center; gap: 8px; font-weight: 700; font-size: 0.9375rem; }
.xe-summary-list { padding: 8px 18px; }
.xe-summary-row { display: flex; justify-content: space-between; gap: 12px; padding: 8px 0; font-size: 0.82rem; border-bottom: 1px dashed var(--border-light); }
.xe-summary-row:last-child { border-bottom: none; }
.xe-summary-row span:first-child { color: var(--text-muted); }
.xe-summary-row span:last-child { font-weight: 600; color: var(--text-primary); text-align: right; }
.xe-summary-foot { padding: 14px 18px 18px; display: flex; flex-direction: column; gap: 10px; }
.xe-export-btn { width: 100%; justify-content: center; padding: 12px 16px; font-size: 0.9375rem; font-weight: 700; gap: 8px; }
.xe-save-row { display: flex; gap: 6px; }
.xe-save-row .form-input { flex: 1; font-size: 0.8rem; padding: 6px 10px; }

.xe-jobs-head { padding: 14px 18px; border-bottom: 1px solid var(--border-light); display: flex; align-items: center; gap: 8px; font-weight: 700; font-size: 0.9rem; }
.xe-jobs-count { margin-left: auto; font-size: 0.72rem; font-weight: 700; padding: 2px 8px; border-radius: 999px; background: var(--bg-tertiary); color: var(--text-muted); }
.xe-jobs-list { max-height: 380px; overflow-y: auto; }
.xe-job { padding: 12px 18px; border-bottom: 1px solid var(--border-light); display: flex; flex-direction: column; gap: 8px; }
.xe-job:last-child { border-bottom: none; }
.xe-job-top { display: flex; gap: 10px; align-items: flex-start; }
.xe-job-icon { width: 30px; height: 30px; border-radius: var(--radius-sm); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.xe-job-title { font-size: 0.8rem; font-weight: 600; color: var(--text-primary); line-height: 1.35; flex: 1; word-break: break-word; }
.xe-job-meta { font-size: 0.72rem; color: var(--text-muted); margin-top: 2px; }
.xe-progress { height: 5px; border-radius: 999px; background: var(--bg-tertiary); overflow: hidden; }
.xe-progress > div { height: 100%; border-radius: 999px; transition: width 0.4s ease; }
.xe-empty { padding: 28px 18px; text-align: center; color: var(--text-muted); font-size: 0.82rem; }
.xe-empty svg { margin: 0 auto 8px; opacity: 0.5; display: block; }

.xe-group-card.disabled, .xe-group-card:disabled { opacity: 0.45; cursor: not-allowed; border-color: var(--border-color) !important; background: var(--bg-tertiary) !important; }
.xe-group-card.disabled:hover { border-color: var(--border-color) !important; color: var(--text-secondary) !important; }
.xe-toggle.disabled, .xe-toggle:disabled { opacity: 0.45; cursor: not-allowed; border-color: var(--border-color) !important; background: var(--bg-tertiary) !important; }
.xe-toggle.disabled:hover { border-color: var(--border-color) !important; }
.xe-table-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 8px; }
.xe-table-item { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-radius: var(--radius-md); border: 1.5px solid var(--border-color); cursor: pointer; font-size: 0.82rem; font-weight: 600; color: var(--text-secondary); background: var(--bg-secondary); transition: all var(--transition-fast); user-select: none; }
.xe-table-item:hover { border-color: var(--primary); }
.xe-table-item.on { border-color: var(--primary); background: var(--primary-light); color: var(--text-primary); }
.xe-box { width: 18px; height: 18px; border-radius: 5px; border: 1.5px solid var(--border-color); display: flex; align-items: center; justify-content: center; flex-shrink: 0; background: var(--bg-secondary); }
.xe-table-item.on .xe-box { background: var(--primary); border-color: var(--primary); color: #fff; }
`;

const formatBytes = (bytes) => {
  if (!bytes) return '';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
};

function ToggleCard({ on, onClick, icon: Icon, title, disabled = false, disabledTooltip = '' }) {
  return (
    <button
      type="button"
      className={`xe-toggle ${on && !disabled ? 'on' : ''} ${disabled ? 'disabled' : ''}`}
      onClick={disabled ? undefined : onClick}
      aria-pressed={on && !disabled}
      disabled={disabled}
      title={disabled ? disabledTooltip : undefined}
    >
      <div className="xe-toggle-icon"><Icon size={16} /></div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 2, flex: 1, minWidth: 0, textAlign: 'left' }}>
        <div className="xe-toggle-title">{title}</div>
        {disabled && disabledTooltip && (
          <span style={{ fontSize: '0.68rem', color: 'var(--text-muted)', fontWeight: 500, lineHeight: 1.2 }}>
            {disabledTooltip}
          </span>
        )}
      </div>
      <span className="xe-check">{on && !disabled && <Check size={11} strokeWidth={3} />}</span>
    </button>
  );
}

function Switch({ on, onChange, label }) {
  return (
    <label className="xe-switch-row" onClick={(e) => { e.preventDefault(); onChange(!on); }}>
      <span className={`xe-switch ${on ? 'on' : ''}`} />
      <span>{label}</span>
    </label>
  );
}

const REPORT_ICONS = {
  sales: TrendingUp,
  purchases: ShoppingBag,
  inventory: Boxes,
  inout: ArrowLeftRight,
  cashflow: Wallet,
  debt: FileText,
};

export default function ExcelExport() {
  const notify = useNotification();
  const { jobs, startReportExport, startFullDbExport, downloadJob, dismissJob } = useExport();

  const [activeTab, setActiveTab] = useState('report'); // 'report' | 'full_db'
  const [submitting, setSubmitting] = useState(false);

  // Dependencies
  const [customers, setCustomers] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [products, setProducts] = useState([]);
  const [warehouses, setWarehouses] = useState([]);
  const [loadingDeps, setLoadingDeps] = useState(false);

  // Report configuration state
  const [reportType, setReportType] = useState('sales');
  const [periodMode, setPeriodMode] = useState('month');
  const [granularity, setGranularity] = useState('day');
  const [groupBy, setGroupBy] = useState('product');
  const [partnerType, setPartnerType] = useState('customer');

  // Dynamic period values
  const [day, setDay] = useState(getCurrentDateStr());
  const [fromDate, setFromDate] = useState(() => {
    const d = new Date();
    d.setDate(1);
    return getCurrentDateStr(d);
  });
  const [toDate, setToDate] = useState(getCurrentDateStr());
  const [month, setMonth] = useState(getCurrentMonthStr());
  const [fromMonth, setFromMonth] = useState(`${new Date().getFullYear()}-01`);
  const [toMonth, setToMonth] = useState(getCurrentMonthStr());
  const [year, setYear] = useState(new Date().getFullYear());

  // Filter targets (multi-select arrays)
  const [selectedProductIds, setSelectedProductIds] = useState([]);
  const [selectedCustomerIds, setSelectedCustomerIds] = useState([]);
  const [selectedSupplierIds, setSelectedSupplierIds] = useState([]);
  const [selectedWarehouses, setSelectedWarehouses] = useState([]);
  const [enableWarehouseBreakdown, setEnableWarehouseBreakdown] = useState(false);

  // Metrics and output options
  const [includeQuantity, setIncludeQuantity] = useState(true);
  const [includeRevenue, setIncludeRevenue] = useState(true);
  const [includePrice, setIncludePrice] = useState(false);
  const [includeDetailSheet, setIncludeDetailSheet] = useState(true);

  // Full DB state
  const [selectedTables, setSelectedTables] = useState(ALL_TABLES_ON);
  const [dbTimeScope, setDbTimeScope] = useState('all');
  const [dbMonth, setDbMonth] = useState(getCurrentMonthStr());
  const [dbFromDate, setDbFromDate] = useState(getCurrentDateStr());
  const [dbToDate, setDbToDate] = useState(getCurrentDateStr());

  // Presets state
  const [customPresets, setCustomPresets] = useState(() => {
    try {
      const saved = localStorage.getItem(PRESET_STORAGE_KEY);
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });
  const [activePresetId, setActivePresetId] = useState('preset-sales-product-day');
  const [isSavingPreset, setIsSavingPreset] = useState(false);
  const [newPresetName, setNewPresetName] = useState('');

  const allPresets = [...BUILT_IN_PRESETS, ...customPresets];

  const loadDependencies = () => {
    setLoadingDeps(true);
    Promise.all([exportService.getDependencies(), warehouseService.getWarehouses()])
      .then(([{ customers: custs, products: prods, suppliers: supps }, whList]) => {
        setCustomers(custs || []);
        setSuppliers(supps || []);
        setProducts(prods || []);
        setWarehouses(whList || []);
      })
      .catch((err) => console.error('Failed to load export dependencies', err))
      .finally(() => setLoadingDeps(false));
  };

  useEffect(() => {
    loadDependencies();
  }, []);

  const persistPresets = (list) => {
    setCustomPresets(list);
    try {
      localStorage.setItem(PRESET_STORAGE_KEY, JSON.stringify(list));
    } catch (e) {
      console.error(e);
    }
  };

  // Auto-sync partnerType when switching to sales or purchases
  const handleSelectReportType = (nextType) => {
    setReportType(nextType);
    setActivePresetId(null);
    if (nextType === 'sales') setPartnerType('customer');
    else if (nextType === 'purchases') setPartnerType('supplier');
  };

  // Adjust granularities when periodMode changes
  const allowedGranularities = useMemo(() => {
    return getAllowedGranularities(periodMode, { fromDate, toDate, fromMonth, toMonth });
  }, [periodMode, fromDate, toDate, fromMonth, toMonth]);

  useEffect(() => {
    const isCurrentAllowed = allowedGranularities.some((g) => g.value === granularity);
    if (!isCurrentAllowed && allowedGranularities.length > 0) {
      setGranularity(allowedGranularities[0].value);
    }
  }, [allowedGranularities, granularity]);

  // Adjust GroupBy when reportType changes
  const allowedGroupBys = useMemo(() => {
    const def = REPORT_TYPES.find((r) => r.value === reportType);
    return def ? def.allowedGroupBys : ['product'];
  }, [reportType]);

  useEffect(() => {
    if (!allowedGroupBys.includes(groupBy)) {
      const def = REPORT_TYPES.find((r) => r.value === reportType);
      setGroupBy(def?.defaultGroupBy || allowedGroupBys[0] || 'product');
    }
  }, [allowedGroupBys, groupBy, reportType]);

  const periodParams = useMemo(
    () => ({ day, fromDate, toDate, month, fromMonth, toMonth, year }),
    [day, fromDate, toDate, month, fromMonth, toMonth, year]
  );

  // Estimated bucket count check
  const estimatedBuckets = useMemo(
    () => Math.round(estimateBucketCount(periodMode, granularity, periodParams)),
    [periodMode, granularity, periodParams]
  );

  // Date navigation helpers
  const shiftDay = (delta) => {
    const d = new Date(day || getCurrentDateStr());
    d.setDate(d.getDate() + delta);
    setDay(getCurrentDateStr(d));
    setActivePresetId(null);
  };

  const shiftMonth = (delta) => {
    const [y, m] = (month || getCurrentMonthStr()).split('-').map(Number);
    const d = new Date(y, m - 1 + delta, 1);
    setMonth(getCurrentMonthStr(d));
    setActivePresetId(null);
  };

  const applyQuickDayRange = (daysBack) => {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - daysBack + 1);
    setFromDate(getCurrentDateStr(start));
    setToDate(getCurrentDateStr(end));
    setActivePresetId(null);
  };

  const applyQuickMonthRange = (monthsBack) => {
    const end = new Date();
    const start = new Date(end.getFullYear(), end.getMonth() - monthsBack + 1, 1);
    setFromMonth(getCurrentMonthStr(start));
    setToMonth(getCurrentMonthStr(end));
    setActivePresetId(null);
  };

  const toggleWarehouseChip = (whId) => {
    setActivePresetId(null);
    if (!enableWarehouseBreakdown) {
      setSelectedWarehouses((prev) => (prev.length === 1 && prev[0] === whId ? [] : [whId]));
    } else {
      setSelectedWarehouses((prev) =>
        prev.includes(whId) ? prev.filter((id) => id !== whId) : [...prev, whId]
      );
    }
  };

  const handleApplyPreset = (preset) => {
    setActivePresetId(preset.id);
    if (preset.tab) setActiveTab(preset.tab === 'matrix' ? 'report' : preset.tab);

    if (preset.tab !== 'full_db') {
      if (preset.reportType) setReportType(preset.reportType);
      if (preset.periodMode) setPeriodMode(preset.periodMode);
      else if (preset.timeScope) {
        setPeriodMode(preset.timeScope === 'custom' ? 'dayRange' : preset.timeScope);
      }
      if (preset.granularity) setGranularity(preset.granularity);
      if (preset.groupBy) setGroupBy(preset.groupBy);
      if (preset.partnerType) setPartnerType(preset.partnerType);

      if (preset.includeQuantity !== undefined) setIncludeQuantity(preset.includeQuantity);
      if (preset.includeRevenue !== undefined) setIncludeRevenue(preset.includeRevenue);
      if (preset.includePrice !== undefined) setIncludePrice(preset.includePrice);
      if (preset.includeDetailSheet !== undefined) setIncludeDetailSheet(preset.includeDetailSheet);

      if (preset.selectedProductIds) setSelectedProductIds(preset.selectedProductIds);
      if (preset.selectedCustomerIds) setSelectedCustomerIds(preset.selectedCustomerIds);
      if (preset.selectedSupplierIds) setSelectedSupplierIds(preset.selectedSupplierIds);
      if (preset.selectedWarehouses) setSelectedWarehouses(preset.selectedWarehouses);
      if (preset.enableWarehouseBreakdown !== undefined) {
        setEnableWarehouseBreakdown(preset.enableWarehouseBreakdown);
      } else {
        setEnableWarehouseBreakdown(false);
      }
    } else {
      if (preset.selectedTables) setSelectedTables({ ...preset.selectedTables });
      if (preset.dbTimeScope) setDbTimeScope(preset.dbTimeScope);
      if (preset.dbMonth) setDbMonth(preset.dbMonth);
      if (preset.dbFromDate) setDbFromDate(preset.dbFromDate);
      if (preset.dbToDate) setDbToDate(preset.dbToDate);
    }
  };

  const handleSaveCustomPreset = () => {
    if (!newPresetName.trim()) {
      notify.warning('Vui lòng nhập tên cho mẫu xuất!');
      return;
    }
    const newPreset = {
      id: 'custom-' + Date.now(),
      name: newPresetName.trim(),
      isBuiltIn: false,
      tab: activeTab,
      reportType,
      periodMode,
      granularity,
      groupBy,
      partnerType,
      day,
      fromDate,
      toDate,
      month,
      fromMonth,
      toMonth,
      year,
      selectedProductIds,
      selectedCustomerIds,
      selectedSupplierIds,
      selectedWarehouses,
      enableWarehouseBreakdown,
      includeQuantity,
      includeRevenue,
      includePrice,
      includeDetailSheet,
      selectedTables,
      dbTimeScope,
      dbMonth,
      dbFromDate,
      dbToDate,
      createdAt: new Date().toISOString(),
    };
    persistPresets([...customPresets, newPreset]);
    setActivePresetId(newPreset.id);
    setNewPresetName('');
    setIsSavingPreset(false);
    notify.success(`Đã lưu mẫu "${newPreset.name}"`);
  };

  const handleDeleteCustomPreset = (presetId, e) => {
    e.stopPropagation();
    persistPresets(customPresets.filter((p) => p.id !== presetId));
    if (activePresetId === presetId) setActivePresetId(null);
  };

  const touch = (setter) => (v) => {
    setter(v);
    setActivePresetId(null);
  };

  // Convert options for MultiSearchableSelect
  const customerOptions = useMemo(
    () =>
      customers.map((c) => ({
        id: c.id,
        value: c.id,
        label: c.name,
        code: c.code,
        phone: c.phone || '',
      })),
    [customers]
  );

  const supplierOptions = useMemo(
    () =>
      suppliers.map((s) => ({
        id: s.id,
        value: s.id,
        label: s.name,
        code: s.code,
        phone: s.phone || '',
      })),
    [suppliers]
  );

  const productOptions = useMemo(
    () =>
      products.map((p) => ({
        id: p.id,
        value: p.id,
        label: p.name,
        code: p.sku,
        subLabel: p.uom || '',
      })),
    [products]
  );

  const warehouseOptions = useMemo(
    () =>
      warehouses.map((w) => ({
        id: w.id,
        value: w.id,
        label: w.name,
        code: w.shortName || w.id,
      })),
    [warehouses]
  );

  const isSupplier = partnerType === 'supplier';
  const showPartnerFilter =
    reportType !== 'inventory' &&
    (reportType === 'cashflow' ||
      reportType === 'debt' ||
      ((reportType === 'sales' || reportType === 'purchases') &&
        groupBy !== 'product' &&
        groupBy !== 'warehouse_product') ||
      (reportType === 'inout' && groupBy === 'product_partner'));

  const showPartnerTypeSwitcher =
    reportType === 'cashflow' ||
    reportType === 'debt' ||
    (reportType === 'inout' && groupBy === 'product_partner');

  const showProductAndWarehouseFilter =
    reportType === 'sales' ||
    reportType === 'purchases' ||
    reportType === 'inventory' ||
    reportType === 'inout';

  // Format summary labels
  const reportTypeMeta = REPORT_TYPES.find((r) => r.value === reportType);
  const periodText = formatPeriodDescription(periodMode, periodParams);
  const granularityLabel = GRANULARITIES.find((g) => g.value === granularity)?.label || 'Theo ngày';

  const getGroupByDisplayLabel = (val) => {
    const partnerWord = isSupplier ? 'Nhà cung cấp' : 'Khách hàng';
    switch (val) {
      case 'product':
        return '📦 Theo sản phẩm';
      case 'product_partner':
        return `📦 Sản phẩm ▸ ${partnerWord}`;
      case 'partner':
        return `👤 Theo ${partnerWord.toLowerCase()}`;
      case 'partner_product':
        return `👤 ${partnerWord} ▸ Sản phẩm`;
      case 'warehouse_product':
        return '🏠 Kho hàng ▸ Sản phẩm';
      default:
        return val;
    }
  };

  const partnerCountText =
    partnerType === 'customer'
      ? selectedCustomerIds.length === 0
        ? 'Tất cả khách hàng'
        : `${selectedCustomerIds.length} khách hàng`
      : selectedSupplierIds.length === 0
      ? 'Tất cả nhà cung cấp'
      : `${selectedSupplierIds.length} nhà cung cấp`;

  const productCountText =
    selectedProductIds.length === 0
      ? 'Tất cả sản phẩm'
      : `${selectedProductIds.length} sản phẩm`;

  const isWhBreakdownActive = useMemo(() => {
    return (
      enableWarehouseBreakdown &&
      (selectedWarehouses.length > 1 || (selectedWarehouses.length === 0 && warehouses.length > 1))
    );
  }, [enableWarehouseBreakdown, selectedWarehouses, warehouses]);

  const warehouseCountText = useMemo(() => {
    if (selectedWarehouses.length === 0) {
      return isWhBreakdownActive ? 'Tất cả kho (tách cột)' : 'Tất cả kho';
    }
    return isWhBreakdownActive
      ? `${selectedWarehouses.length} kho (tách cột)`
      : `${selectedWarehouses.length} kho`;
  }, [selectedWarehouses, isWhBreakdownActive]);

  const metricsSummary = useMemo(() => {
    if (reportType === 'inventory') {
      const list = [];
      if (includeQuantity) list.push('Số lượng tồn');
      if (includeRevenue) list.push('Giá trị tồn');
      if (includePrice) list.push('Đơn giá vốn');
      return list.join(', ') || 'Chưa chọn';
    }
    if (reportType === 'inout') return 'Nhập, Xuất, Chênh lệch';
    if (reportType === 'cashflow') return 'Tổng thu, Tổng chi, Chênh lệch';
    if (reportType === 'debt') return 'Đầu kỳ, Tăng, Giảm, Cuối kỳ';
    const list = [];
    if (includeQuantity) list.push('Số lượng');
    if (includeRevenue) list.push(reportType === 'purchases' ? 'Tiền nhập' : 'Doanh số');
    if (includePrice) list.push('Đơn giá');
    return list.join(', ') || 'Chưa chọn';
  }, [reportType, includeQuantity, includeRevenue, includePrice]);

  const activeTableCount = Object.values(selectedTables).filter(Boolean).length;
  const canSubmit =
    activeTab === 'report'
      ? (reportType === 'inout' ||
          reportType === 'cashflow' ||
          reportType === 'debt' ||
          reportType === 'inventory' ||
          includeQuantity ||
          includeRevenue ||
          includePrice) &&
        estimatedBuckets <= 370
      : activeTableCount > 0;

  // Mutual constraint: groupBy === 'partner' vs includePrice
  const isPartnerOnlyGroup = groupBy === 'partner';
  const isPriceAllowed =
    reportType === 'inventory' ||
    (reportType !== 'sales' && reportType !== 'purchases') ||
    !isPartnerOnlyGroup;

  // Mutual filter: If currently in partner-only group, includePrice cannot be active
  useEffect(() => {
    if ((reportType === 'sales' || reportType === 'purchases') && isPartnerOnlyGroup && includePrice) {
      setIncludePrice(false);
    }
  }, [reportType, isPartnerOnlyGroup, includePrice]);

  const handleSelectGroupBy = (val) => {
    touch(setGroupBy)(val);
    if (val === 'partner' && includePrice) {
      setIncludePrice(false);
    }
  };

  const handleTogglePrice = () => {
    const nextVal = !includePrice;
    touch(setIncludePrice)(nextVal);
    // If turning on price while partner is selected, auto switch to product
    if (nextVal && groupBy === 'partner' && (reportType === 'sales' || reportType === 'purchases')) {
      setGroupBy('product');
    }
  };

  const previewRequestDto = useMemo(() => {
    return {
      reportType,
      period: {
        mode: periodMode,
        date: periodMode === 'day' ? day : null,
        day: periodMode === 'day' ? day : null,
        fromDate: periodMode === 'dayRange' ? fromDate : null,
        toDate: periodMode === 'dayRange' ? toDate : null,
        month: periodMode === 'month' ? month : null,
        fromMonth: periodMode === 'monthRange' ? fromMonth : null,
        toMonth: periodMode === 'monthRange' ? toMonth : null,
        year: periodMode === 'year' ? Number(year) : null,
      },
      granularity,
      groupBy,
      partnerScope: partnerType,
      partnerType,
      productIds: selectedProductIds.length > 0 ? selectedProductIds.map(Number) : [],
      customerIds:
        partnerType === 'customer' && selectedCustomerIds.length > 0
          ? selectedCustomerIds.map(Number)
          : [],
      supplierIds:
        partnerType === 'supplier' && selectedSupplierIds.length > 0
          ? selectedSupplierIds.map(Number)
          : [],
      warehouses: selectedWarehouses.length > 0 ? selectedWarehouses : [],
      breakdownByWarehouse: isWhBreakdownActive,
      includeQuantity,
      includeAmount: includeRevenue,
      includeRevenue,
      includeAvgPrice: includePrice,
      includePrice,
      includeDetailSheet,
    };
  }, [
    reportType,
    periodMode,
    day,
    fromDate,
    toDate,
    month,
    fromMonth,
    toMonth,
    year,
    granularity,
    groupBy,
    partnerType,
    selectedProductIds,
    selectedCustomerIds,
    selectedSupplierIds,
    selectedWarehouses,
    isWhBreakdownActive,
    includeQuantity,
    includeRevenue,
    includePrice,
    includeDetailSheet,
  ]);

  const handleStartExport = async () => {
    if (!canSubmit || submitting) return;
    setSubmitting(true);
    try {
      if (activeTab === 'report') {
        const titleParts = [
          reportTypeMeta?.label || 'Báo cáo',
          periodText,
          granularityLabel,
        ];
        if (selectedProductIds.length > 0) titleParts.push(`${selectedProductIds.length} SP`);

        await startReportExport(previewRequestDto, titleParts.join(' · '));
      } else {
        const tables = Object.keys(selectedTables).filter((k) => selectedTables[k]);
        await startFullDbExport(
          {
            tables,
            timeScope: dbTimeScope,
            month: dbTimeScope === 'month' ? dbMonth : null,
            fromDate: dbTimeScope === 'custom' ? dbFromDate : null,
            toDate: dbTimeScope === 'custom' ? dbToDate : null,
          },
          `Sao lưu ${tables.length} bảng · ${formatPeriodDescription(
            dbTimeScope === 'custom' ? 'dayRange' : dbTimeScope,
            { month: dbMonth, fromDate: dbFromDate, toDate: dbToDate }
          )}`
        );
      }
    } catch {
      // Errors handled via notification in ExportContext
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <style>{STYLES}</style>

      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <FileSpreadsheet size={28} color="var(--success)" />
            <span>Xuất Excel</span>
          </h1>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadDependencies} disabled={loadingDeps}>
            <RefreshCw size={16} className={loadingDeps ? 'animate-spin' : ''} />
            <span>Làm mới danh mục</span>
          </button>
        </div>
      </div>

      {/* Main Mode switcher */}
      <div className="xe-mode-grid">
        <button
          type="button"
          className={`xe-mode-card ${activeTab === 'report' ? 'active' : ''}`}
          onClick={() => setActiveTab('report')}
        >
          <div className="xe-mode-icon"><CalendarDays size={20} /></div>
          <div className="xe-mode-title">Báo cáo đa chiều</div>
        </button>
        <button
          type="button"
          className={`xe-mode-card ${activeTab === 'full_db' ? 'active' : ''}`}
          onClick={() => setActiveTab('full_db')}
        >
          <div className="xe-mode-icon"><Database size={20} /></div>
          <div className="xe-mode-title">Sao lưu CSDL</div>
        </button>
      </div>

      {/* Quick Presets */}
      <div className="xe-presets">
        <span className="xe-presets-label">
          <Bookmark size={13} />
          Mẫu nhanh
        </span>
        {allPresets.map((preset) => (
          <span
            key={preset.id}
            className={`xe-chip ${activePresetId === preset.id ? 'active' : ''} ${
              preset.isBuiltIn ? '' : 'custom'
            }`}
            onClick={() => handleApplyPreset(preset)}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => e.key === 'Enter' && handleApplyPreset(preset)}
          >
            {activePresetId === preset.id && <Check size={12} strokeWidth={3} />}
            {preset.name}
            {!preset.isBuiltIn && (
              <button
                type="button"
                className="xe-chip-x"
                onClick={(e) => handleDeleteCustomPreset(preset.id, e)}
                title="Xóa mẫu"
                aria-label="Xóa mẫu"
              >
                <X size={12} />
              </button>
            )}
          </span>
        ))}
      </div>

      <div className="xe-layout">
        {/* LEFT: Configuration panel */}
        <div className="xe-card">
          {activeTab === 'report' ? (
            <>
              {/* Step 1: Report Type */}
              <div className="xe-section">
                <div className="xe-section-head">
                  <span className="xe-step">1</span>
                  <span className="xe-section-title">Loại báo cáo</span>
                </div>
                <div className="xe-report-grid">
                  {REPORT_TYPES.map((rt) => {
                    const IconComponent = REPORT_ICONS[rt.value] || TrendingUp;
                    const isActive = reportType === rt.value;
                    const accent = REPORT_ACCENTS[rt.value] || REPORT_ACCENTS.sales;
                    return (
                      <button
                        key={rt.value}
                        type="button"
                        className={`xe-report-card ${isActive ? 'active' : ''}`}
                        onClick={() => handleSelectReportType(rt.value)}
                        style={
                          isActive
                            ? {
                                borderColor: accent.color,
                                background: accent.bg,
                                boxShadow: `0 0 0 2px ${accent.glow}`,
                              }
                            : undefined
                        }
                      >
                        <div className="xe-report-card-top">
                          <div
                            className="xe-report-card-icon"
                            style={
                              isActive
                                ? { background: accent.color, color: '#ffffff' }
                                : { color: accent.color }
                            }
                          >
                            <IconComponent size={18} />
                          </div>
                          <span
                            className="xe-check"
                            style={
                              isActive
                                ? { background: accent.color, borderColor: accent.color, color: '#fff' }
                                : undefined
                            }
                          >
                            {isActive && <Check size={11} strokeWidth={3} />}
                          </span>
                        </div>
                        <div className="xe-report-card-title">{rt.label}</div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Step 2: Time Scope & Granularity (Hidden for Point-in-time Inventory) */}
              {reportType !== 'inventory' && (
              <div className="xe-section">
                <div className="xe-section-head">
                  <span className="xe-step">2</span>
                  <span className="xe-section-title">Thời gian & Mốc thống kê</span>
                </div>

                <div className="xe-time-grid">
                  {/* Left: Period Mode + Picker */}
                  <div>
                    <div className="xe-label">Khoảng thời gian</div>
                    <div className="xe-period-pills" role="tablist">
                      {PERIOD_MODES.map((pm) => (
                        <button
                          key={pm.value}
                          type="button"
                          role="tab"
                          aria-selected={periodMode === pm.value}
                          className={`xe-period-pill ${periodMode === pm.value ? 'active' : ''}`}
                          onClick={() => touch(setPeriodMode)(pm.value)}
                        >
                          {pm.label}
                        </button>
                      ))}
                    </div>

                    {/* Dynamic Time Picker Box */}
                    <div className="xe-time-picker-box">
                      {periodMode === 'day' && (
                        <>
                          <button
                            type="button"
                            className="xe-nav-btn"
                            onClick={() => shiftDay(-1)}
                            title="Ngày trước"
                          >
                            <ChevronLeft size={16} />
                          </button>
                          <input
                            type="date"
                            className="form-input mono"
                            style={{ width: 155, height: 34, padding: '4px 10px' }}
                            value={day}
                            onChange={(e) => touch(setDay)(e.target.value)}
                          />
                          <button
                            type="button"
                            className="xe-nav-btn"
                            onClick={() => shiftDay(1)}
                            title="Ngày sau"
                          >
                            <ChevronRight size={16} />
                          </button>
                          <button
                            type="button"
                            className="xe-quick-btn"
                            onClick={() => touch(setDay)(getCurrentDateStr())}
                          >
                            Hôm nay
                          </button>
                        </>
                      )}

                      {periodMode === 'dayRange' && (
                        <>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                            <input
                              type="date"
                              className="form-input mono"
                              style={{ width: 145, height: 34, padding: '4px 8px' }}
                              value={fromDate}
                              onChange={(e) => touch(setFromDate)(e.target.value)}
                            />
                            <ArrowStep size={14} color="var(--text-muted)" />
                            <input
                              type="date"
                              className="form-input mono"
                              style={{ width: 145, height: 34, padding: '4px 8px' }}
                              value={toDate}
                              onChange={(e) => touch(setToDate)(e.target.value)}
                            />
                          </div>
                          <div style={{ display: 'flex', gap: 5 }}>
                            <button type="button" className="xe-quick-btn" onClick={() => applyQuickDayRange(7)}>
                              7 ngày
                            </button>
                            <button type="button" className="xe-quick-btn" onClick={() => applyQuickDayRange(30)}>
                              30 ngày
                            </button>
                          </div>
                        </>
                      )}

                      {periodMode === 'month' && (
                        <>
                          <button
                            type="button"
                            className="xe-nav-btn"
                            onClick={() => shiftMonth(-1)}
                            title="Tháng trước"
                          >
                            <ChevronLeft size={16} />
                          </button>
                          <input
                            type="month"
                            className="form-input mono"
                            style={{ width: 155, height: 34, padding: '4px 10px' }}
                            value={month}
                            onChange={(e) => touch(setMonth)(e.target.value)}
                          />
                          <button
                            type="button"
                            className="xe-nav-btn"
                            onClick={() => shiftMonth(1)}
                            title="Tháng sau"
                          >
                            <ChevronRight size={16} />
                          </button>
                          <button
                            type="button"
                            className="xe-quick-btn"
                            onClick={() => touch(setMonth)(getCurrentMonthStr())}
                          >
                            Tháng này
                          </button>
                        </>
                      )}

                      {periodMode === 'monthRange' && (
                        <>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                            <input
                              type="month"
                              className="form-input mono"
                              style={{ width: 140, height: 34, padding: '4px 8px' }}
                              value={fromMonth}
                              onChange={(e) => touch(setFromMonth)(e.target.value)}
                            />
                            <ArrowStep size={14} color="var(--text-muted)" />
                            <input
                              type="month"
                              className="form-input mono"
                              style={{ width: 140, height: 34, padding: '4px 8px' }}
                              value={toMonth}
                              onChange={(e) => touch(setToMonth)(e.target.value)}
                            />
                          </div>
                          <div style={{ display: 'flex', gap: 5 }}>
                            <button type="button" className="xe-quick-btn" onClick={() => applyQuickMonthRange(3)}>
                              3 tháng
                            </button>
                            <button type="button" className="xe-quick-btn" onClick={() => applyQuickMonthRange(6)}>
                              6 tháng
                            </button>
                          </div>
                        </>
                      )}

                      {periodMode === 'year' && (
                        <>
                          <button
                            type="button"
                            className="xe-nav-btn"
                            onClick={() => touch(setYear)(Number(year) - 1)}
                            title="Năm trước"
                          >
                            <ChevronLeft size={16} />
                          </button>
                          <input
                            type="number"
                            min="2000"
                            max="2100"
                            className="form-input mono"
                            style={{ width: 110, height: 34, padding: '4px 10px', textAlign: 'center', fontWeight: 700 }}
                            value={year}
                            onChange={(e) => touch(setYear)(e.target.value)}
                          />
                          <button
                            type="button"
                            className="xe-nav-btn"
                            onClick={() => touch(setYear)(Number(year) + 1)}
                            title="Năm sau"
                          >
                            <ChevronRight size={16} />
                          </button>
                          <button
                            type="button"
                            className="xe-quick-btn"
                            onClick={() => touch(setYear)(new Date().getFullYear())}
                          >
                            Năm nay
                          </button>
                        </>
                      )}

                      {periodMode === 'all' && (
                        <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', fontWeight: 500 }}>
                          Lấy toàn bộ dữ liệu lịch sử từ chứng từ đầu tiên đến hiện tại
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Right: Column Granularity */}
                  <div>
                    <div className="xe-label">Mốc thống kê từng cột</div>
                    <div className="xe-gran-list">
                      {GRANULARITIES.map((g) => {
                        const isAllowed = allowedGranularities.some((a) => a.value === g.value);
                        const isActive = granularity === g.value;
                        const estCols = Math.round(
                          estimateBucketCount(periodMode, g.value, periodParams)
                        );
                        return (
                          <button
                            key={g.value}
                            type="button"
                            disabled={!isAllowed}
                            className={`xe-gran-card ${isActive ? 'active' : ''}`}
                            onClick={() => touch(setGranularity)(g.value)}
                          >
                            <span className="xe-gran-title">{g.label}</span>
                            <span className="xe-gran-badge">
                              {isAllowed ? `~${estCols} cột` : 'Khóa'}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>

                {estimatedBuckets > 370 && (
                  <div className="xe-warning-box">
                    <AlertTriangle size={16} />
                    <span>
                      Khoảng thời gian này vượt quá 370 cột. Vui lòng chọn mốc Theo tuần hoặc Theo tháng.
                    </span>
                  </div>
                )}
              </div>
              )}

              {/* Step 3: Grouping & Metrics */}
              <div className="xe-section">
                <div className="xe-section-head">
                  <span className="xe-step">{reportType === 'inventory' ? 2 : 3}</span>
                  <span className="xe-section-title">Gom nhóm & Tùy chọn hiển thị</span>
                </div>

                {/* Group By Cards */}
                <div style={{ marginBottom: 16 }}>
                  <div className="xe-label">Cấu trúc gom nhóm dòng</div>
                  <div className="xe-group-grid">
                    {GROUP_BY_OPTIONS.filter((g) => allowedGroupBys.includes(g.value)).map((g) => {
                      const isActive = groupBy === g.value;
                      const isPartnerOnly = g.value === 'partner';
                      const isBlockedByPrice =
                        isPartnerOnly &&
                        includePrice &&
                        (reportType === 'sales' || reportType === 'purchases');

                      return (
                        <button
                          key={g.value}
                          type="button"
                          disabled={isBlockedByPrice}
                          className={`xe-group-card ${isActive ? 'active' : ''} ${
                            isBlockedByPrice ? 'disabled' : ''
                          }`}
                          onClick={() => {
                            if (isBlockedByPrice) return;
                            handleSelectGroupBy(g.value);
                          }}
                          title={
                            isBlockedByPrice
                              ? 'Không thể gom nhóm chỉ theo Đối tác khi đang chọn chỉ số Đơn giá (cần có Sản phẩm)'
                              : undefined
                          }
                        >
                          <span className="xe-group-radio">
                            {isActive && <Check size={10} strokeWidth={3} />}
                          </span>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <span className="xe-group-text">{getGroupByDisplayLabel(g.value)}</span>
                            {isBlockedByPrice && (
                              <span style={{ fontSize: '0.68rem', color: 'var(--danger)', fontWeight: 600 }}>
                                Khóa (đang chọn Đơn giá)
                              </span>
                            )}
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Metrics for Sales / Purchases / Inventory */}
                {(reportType === 'sales' || reportType === 'purchases' || reportType === 'inventory') && (
                  <div style={{ marginBottom: 14 }}>
                    <div className="xe-label">
                      <span>Chỉ số hiển thị</span>
                      {!includeQuantity && !includeRevenue && !includePrice && (
                        <span style={{ color: 'var(--danger)', marginLeft: 8, fontWeight: 500 }}>
                          Chọn ít nhất Số lượng, {reportType === 'inventory' ? 'Giá trị tồn' : (reportType === 'purchases' ? 'Tiền nhập' : 'Doanh số')} hoặc Đơn giá
                        </span>
                      )}
                    </div>
                    <div className="xe-toggle-grid">
                      <ToggleCard
                        on={includeQuantity}
                        onClick={() => touch(setIncludeQuantity)(!includeQuantity)}
                        icon={Hash}
                        title={reportType === 'inventory' ? 'Số lượng tồn' : 'Số lượng'}
                      />
                      <ToggleCard
                        on={includeRevenue}
                        onClick={() => touch(setIncludeRevenue)(!includeRevenue)}
                        icon={Banknote}
                        title={reportType === 'inventory' ? 'Giá trị tồn' : (reportType === 'purchases' ? 'Tiền nhập' : 'Doanh số')}
                      />
                      <ToggleCard
                        on={includePrice}
                        onClick={handleTogglePrice}
                        disabled={!isPriceAllowed}
                        disabledTooltip="Không hỗ trợ khi chỉ gom nhóm Đối tác (cần có Sản phẩm)"
                        icon={Tag}
                        title={reportType === 'inventory' ? 'Đơn giá vốn' : 'Đơn giá'}
                      />
                    </div>
                  </div>
                )}

                {/* Detail sheet toggle */}
                <Switch
                  on={includeDetailSheet}
                  onChange={touch(setIncludeDetailSheet)}
                  label={reportType === 'inventory' ? 'Kèm sheet phân bổ tồn kho chi tiết theo từng kho' : 'Kèm sheet dữ liệu chi tiết từng giao dịch'}
                />
              </div>

              {/* Step 4: Target Filters */}
              <div className="xe-section">
                <div className="xe-section-head">
                  <span className="xe-step">{reportType === 'inventory' ? 3 : 4}</span>
                  <span className="xe-section-title">Bộ lọc đối tượng</span>
                </div>

                {/* Partner Type Switcher when applicable (cashflow, debt, inout with partner) */}
                {showPartnerTypeSwitcher && showPartnerFilter && (
                  <div className="xe-partner-tabs" role="tablist">
                    <button
                      type="button"
                      className={`xe-partner-tab ${!isSupplier ? 'active' : ''}`}
                      onClick={() => touch(setPartnerType)('customer')}
                    >
                      <User size={15} />
                      <span>Khách hàng</span>
                    </button>
                    <button
                      type="button"
                      className={`xe-partner-tab ${isSupplier ? 'active' : ''}`}
                      onClick={() => touch(setPartnerType)('supplier')}
                    >
                      <Building size={15} />
                      <span>Nhà cung cấp</span>
                    </button>
                  </div>
                )}

                <div className="xe-field-grid">
                  {/* Partner MultiSelect */}
                  {showPartnerFilter && (
                    <div>
                      <div className="xe-label">
                        {isSupplier ? (
                          <Building size={14} color="var(--warning)" />
                        ) : (
                          <User size={14} color="var(--primary)" />
                        )}
                        <span>{isSupplier ? 'Nhà cung cấp' : 'Khách hàng'}</span>
                      </div>

                      {isSupplier ? (
                        <MultiSearchableSelect
                          options={supplierOptions}
                          value={selectedSupplierIds}
                          onChange={touch(setSelectedSupplierIds)}
                          placeholder="Tất cả nhà cung cấp"
                          searchPlaceholder="Tìm NCC theo tên, mã, SĐT..."
                          disabled={loadingDeps}
                        />
                      ) : (
                        <MultiSearchableSelect
                          options={customerOptions}
                          value={selectedCustomerIds}
                          onChange={touch(setSelectedCustomerIds)}
                          placeholder="Tất cả khách hàng"
                          searchPlaceholder="Tìm khách hàng theo tên, mã, SĐT..."
                          disabled={loadingDeps}
                        />
                      )}
                    </div>
                  )}

                  {/* Product MultiSelect */}
                  {showProductAndWarehouseFilter && (
                    <div>
                      <div className="xe-label">
                        <Package size={14} color="var(--primary)" />
                        <span>Sản phẩm</span>
                      </div>
                      <MultiSearchableSelect
                        options={productOptions}
                        value={selectedProductIds}
                        onChange={touch(setSelectedProductIds)}
                        placeholder="Tất cả sản phẩm"
                        searchPlaceholder="Tìm theo tên sản phẩm, mã SKU..."
                        disabled={loadingDeps}
                      />
                    </div>
                  )}
                </div>

                {/* Warehouses */}
                {showProductAndWarehouseFilter && warehouses.length > 0 && (
                  <div style={{ marginTop: 14 }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8, flexWrap: 'wrap', gap: 8 }}>
                      <div className="xe-label" style={{ margin: 0 }}>
                        <Building size={14} color="var(--text-secondary)" />
                        <span>Kho hàng</span>
                      </div>

                      <label
                        className="xe-wh-breakdown-toggle"
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 7,
                          fontSize: '0.8rem',
                          fontWeight: 600,
                          color: enableWarehouseBreakdown ? 'var(--primary)' : 'var(--text-secondary)',
                          cursor: 'pointer',
                          userSelect: 'none',
                        }}
                      >
                        <input
                          type="checkbox"
                          checked={enableWarehouseBreakdown}
                          onChange={(e) => {
                            const checked = e.target.checked;
                            setEnableWarehouseBreakdown(checked);
                            setActivePresetId(null);
                            if (!checked && selectedWarehouses.length > 1) {
                              setSelectedWarehouses(selectedWarehouses.slice(0, 1));
                            }
                          }}
                          style={{
                            width: 15,
                            height: 15,
                            accentColor: 'var(--primary)',
                            cursor: 'pointer',
                          }}
                        />
                        <span>
                          {reportType === 'inventory'
                            ? 'Tách cột tồn kho theo từng kho trên 1 sheet'
                            : 'Tách cột doanh số theo từng kho trên 1 sheet'}
                        </span>
                      </label>
                    </div>

                    {warehouses.length <= 6 ? (
                      <div className="xe-wh-chips">
                        <button
                          type="button"
                          className={`xe-wh-chip ${selectedWarehouses.length === 0 ? 'active' : ''}`}
                          onClick={() => {
                            setActivePresetId(null);
                            setSelectedWarehouses([]);
                          }}
                        >
                          {selectedWarehouses.length === 0 && <Check size={13} strokeWidth={3} />}
                          <span>Tất cả kho</span>
                        </button>
                        {warehouses.map((w) => {
                          const active = selectedWarehouses.includes(w.id);
                          return (
                            <button
                              key={w.id}
                              type="button"
                              className={`xe-wh-chip ${active ? 'active' : ''}`}
                              onClick={() => toggleWarehouseChip(w.id)}
                            >
                              {active && <Check size={13} strokeWidth={3} />}
                              <span>{w.shortName || w.name}</span>
                            </button>
                          );
                        })}
                      </div>
                    ) : (
                      <MultiSearchableSelect
                        options={warehouseOptions}
                        value={selectedWarehouses}
                        onChange={touch(setSelectedWarehouses)}
                        placeholder="Tất cả kho hàng"
                        searchPlaceholder="Tìm theo tên kho..."
                        disabled={loadingDeps}
                      />
                    )}
                  </div>
                )}
              </div>
            </>
          ) : (
            <>
              {/* Full DB tab */}
              <div className="xe-section">
                <div className="xe-section-head">
                  <span className="xe-step">1</span>
                  <span className="xe-section-title">Chọn bảng dữ liệu</span>
                  <span className="xe-section-hint">
                    <button
                      type="button"
                      className="btn btn-ghost btn-sm"
                      onClick={() => setSelectedTables(ALL_TABLES_ON)}
                    >
                      Chọn hết
                    </button>
                    <button
                      type="button"
                      className="btn btn-ghost btn-sm"
                      onClick={() =>
                        setSelectedTables(
                          Object.fromEntries(TABLE_OPTIONS.map((t) => [t.key, false]))
                        )
                      }
                    >
                      Bỏ chọn
                    </button>
                  </span>
                </div>
                <div className="xe-table-grid">
                  {TABLE_OPTIONS.map((t) => {
                    const on = !!selectedTables[t.key];
                    return (
                      <div
                        key={t.key}
                        className={`xe-table-item ${on ? 'on' : ''}`}
                        role="checkbox"
                        aria-checked={on}
                        tabIndex={0}
                        onClick={() => {
                          setSelectedTables((p) => ({ ...p, [t.key]: !p[t.key] }));
                          setActivePresetId(null);
                        }}
                        onKeyDown={(e) =>
                          e.key === ' ' && setSelectedTables((p) => ({ ...p, [t.key]: !p[t.key] }))
                        }
                      >
                        <span className="xe-box">{on && <Check size={12} strokeWidth={3} />}</span>
                        {t.label}
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="xe-section">
                <div className="xe-section-head">
                  <span className="xe-step">2</span>
                  <span className="xe-section-title">Thời gian chứng từ</span>
                </div>
                <div className="xe-partner-tabs">
                  {[
                    { value: 'month', label: 'Theo tháng' },
                    { value: 'custom', label: 'Khoảng ngày' },
                    { value: 'all', label: 'Toàn bộ' },
                  ].map((opt) => (
                    <button
                      key={opt.value}
                      type="button"
                      className={`xe-partner-tab ${dbTimeScope === opt.value ? 'active' : ''}`}
                      onClick={() => touch(setDbTimeScope)(opt.value)}
                    >
                      {opt.label}
                    </button>
                  ))}
                </div>
                {dbTimeScope === 'month' && (
                  <div className="xe-time-picker-box" style={{ maxWidth: 260 }}>
                    <input
                      type="month"
                      className="form-input mono"
                      value={dbMonth}
                      onChange={(e) => touch(setDbMonth)(e.target.value)}
                    />
                  </div>
                )}
                {dbTimeScope === 'custom' && (
                  <div className="xe-time-picker-box">
                    <input
                      type="date"
                      className="form-input mono"
                      style={{ width: 155 }}
                      value={dbFromDate}
                      onChange={(e) => touch(setDbFromDate)(e.target.value)}
                    />
                    <ArrowStep size={14} color="var(--text-muted)" />
                    <input
                      type="date"
                      className="form-input mono"
                      style={{ width: 155 }}
                      value={dbToDate}
                      onChange={(e) => touch(setDbToDate)(e.target.value)}
                    />
                  </div>
                )}
              </div>
            </>
          )}
        </div>

        {/* RIGHT: Summary & Running export queue */}
        <div className="xe-side">
          <div className="xe-card">
            <div className="xe-summary-head">
              <Layers size={17} color="var(--primary)" />
              Tóm tắt cấu hình
            </div>
            <div className="xe-summary-list">
              {activeTab === 'report' ? (
                <>
                  <div className="xe-summary-row">
                    <span>Loại báo cáo</span>
                    <span style={{ color: 'var(--primary)' }}>{reportTypeMeta?.label}</span>
                  </div>
                  {reportType === 'inventory' ? (
                    <div className="xe-summary-row">
                      <span>Thời điểm</span>
                      <span>Tức thời (Hiện tại)</span>
                    </div>
                  ) : (
                    <>
                      <div className="xe-summary-row">
                        <span>Kỳ thời gian</span>
                        <span>{periodText}</span>
                      </div>
                      <div className="xe-summary-row">
                        <span>Mốc thống kê</span>
                        <span>
                          {granularityLabel} · ~{estimatedBuckets} cột
                        </span>
                      </div>
                    </>
                  )}
                  <div className="xe-summary-row">
                    <span>Gom nhóm</span>
                    <span>{getGroupByDisplayLabel(groupBy)}</span>
                  </div>
                  {showPartnerFilter && (
                    <div className="xe-summary-row">
                      <span>Đối tác</span>
                      <span>{partnerCountText}</span>
                    </div>
                  )}
                  {showProductAndWarehouseFilter && (
                    <>
                      <div className="xe-summary-row">
                        <span>Sản phẩm</span>
                        <span>{productCountText}</span>
                      </div>
                      <div className="xe-summary-row">
                        <span>Kho hàng</span>
                        <span>{warehouseCountText}</span>
                      </div>
                      {isWhBreakdownActive && (
                        <div className="xe-summary-row">
                          <span>Phân tách kho</span>
                          <span style={{ color: 'var(--primary)' }}>Tách cột từng kho</span>
                        </div>
                      )}
                    </>
                  )}
                  <div className="xe-summary-row">
                    <span>Chỉ số</span>
                    <span>{metricsSummary}</span>
                  </div>
                  <div className="xe-summary-row">
                    <span>Sheet chi tiết</span>
                    <span>{includeDetailSheet ? 'Có' : 'Không'}</span>
                  </div>
                </>
              ) : (
                <>
                  <div className="xe-summary-row">
                    <span>Số bảng sao lưu</span>
                    <span>
                      {activeTableCount} / {TABLE_OPTIONS.length}
                    </span>
                  </div>
                  <div className="xe-summary-row">
                    <span>Thời gian chứng từ</span>
                    <span>
                      {formatPeriodDescription(
                        dbTimeScope === 'custom' ? 'dayRange' : dbTimeScope,
                        { month: dbMonth, fromDate: dbFromDate, toDate: dbToDate }
                      )}
                    </span>
                  </div>
                </>
              )}
            </div>

            <div className="xe-summary-foot">
              <button
                type="button"
                className="btn btn-primary xe-export-btn"
                onClick={handleStartExport}
                disabled={!canSubmit || submitting}
              >
                {submitting ? <Loader2 size={18} className="animate-spin" /> : <Play size={18} />}
                <span>
                  {activeTab === 'report'
                    ? `Xuất báo cáo ${reportTypeMeta?.label || ''}`
                    : 'Sao lưu dữ liệu'}
                </span>
              </button>

              {!isSavingPreset ? (
                <button
                  type="button"
                  className="btn btn-ghost btn-sm"
                  onClick={() => setIsSavingPreset(true)}
                  style={{ justifyContent: 'center' }}
                >
                  <BookmarkPlus size={14} />
                  <span>Lưu cấu hình thành mẫu</span>
                </button>
              ) : (
                <div className="xe-save-row">
                  <input
                    type="text"
                    className="form-input"
                    placeholder="Tên mẫu..."
                    value={newPresetName}
                    onChange={(e) => setNewPresetName(e.target.value)}
                    autoFocus
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') handleSaveCustomPreset();
                      else if (e.key === 'Escape') setIsSavingPreset(false);
                    }}
                  />
                  <button
                    type="button"
                    className="btn btn-primary btn-sm"
                    onClick={handleSaveCustomPreset}
                  >
                    Lưu
                  </button>
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    onClick={() => setIsSavingPreset(false)}
                    aria-label="Hủy"
                  >
                    <X size={14} />
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Running & recent export jobs */}
          <div className="xe-card">
            <div className="xe-jobs-head">
              <Clock size={16} color="var(--primary)" />
              File gần đây
              <span className="xe-jobs-count">{jobs.length}</span>
            </div>
            {jobs.length === 0 ? (
              <div className="xe-empty">
                <Inbox size={30} />
                Chưa có file nào trong phiên này
              </div>
            ) : (
              <div className="xe-jobs-list">
                {jobs.map((job) => {
                  const done = job.status === 'completed';
                  const failed = job.status === 'failed';
                  const pct = Math.min(100, Math.max(0, job.progressPercentage || 0));
                  const color = failed
                    ? 'var(--danger)'
                    : done
                    ? 'var(--success)'
                    : 'var(--primary)';
                  const bg = failed
                    ? 'var(--danger-light)'
                    : done
                    ? 'var(--success-light)'
                    : 'var(--primary-light)';
                  return (
                    <div key={job.jobId} className="xe-job">
                      <div className="xe-job-top">
                        <div className="xe-job-icon" style={{ background: bg, color }}>
                          {done ? (
                            <CheckCircle2 size={16} />
                          ) : failed ? (
                            <AlertCircle size={16} />
                          ) : (
                            <Loader2 size={16} className="animate-spin" />
                          )}
                        </div>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div className="xe-job-title">{job.title}</div>
                          <div className="xe-job-meta">
                            {done
                              ? [formatBytes(job.fileSize), 'Lưu trên máy chủ 2 giờ']
                                  .filter(Boolean)
                                  .join(' · ')
                              : failed
                              ? job.message || 'Xuất thất bại'
                              : `${job.message || 'Đang xử lý'} · ${pct}%`}
                          </div>
                        </div>
                        {done ? (
                          <button
                            type="button"
                            className="btn btn-outline btn-sm"
                            onClick={() => downloadJob(job.jobId, job.fileName)}
                            title="Tải file"
                            aria-label="Tải file"
                          >
                            <Download size={14} />
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="btn btn-ghost btn-sm"
                            onClick={() => dismissJob(job.jobId)}
                            title="Ẩn"
                            aria-label="Ẩn"
                          >
                            <X size={14} />
                          </button>
                        )}
                      </div>
                      {!done && !failed && (
                        <div className="xe-progress">
                          <div style={{ width: `${pct}%`, background: color }} />
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Live Excel Template Preview */}
      {activeTab === 'report' && (
        <ExcelPreview
          requestPayload={previewRequestDto}
          includeDetailSheet={includeDetailSheet}
        />
      )}
    </div>
  );
}

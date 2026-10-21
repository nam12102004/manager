import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  X,
  RefreshCw,
  Building,
  Calendar,
  Layers,
  ArrowDownLeft,
  ArrowUpRight,
  Wallet,
  ReceiptText,
  Filter,
  Maximize2,
  Minimize2,
  Package,
  User,
  Clock,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr, getCurrentDateStr } from '../../utils/formatters';
import { customerService, supplierService, productService, warehouseService } from '../../services';
import StatCard from './StatCard';
import EmptyState from './EmptyState';

export default function EntityTransactionLedger({
  entityType = 'customer', // 'customer' | 'supplier' | 'product'
  entityId,
  entityName,
  entityCode,
  onClose,
  asModal = true,
}) {
  const [isModal, setIsModal] = useState(asModal);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const containerRef = useRef(null);

  const [loading, setLoading] = useState(false);
  const [ledgerData, setLedgerData] = useState(null);
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());
  const [selectedWarehouse, setSelectedWarehouse] = useState('all');
  const [timeMode, setTimeMode] = useState('all'); // 'all' | 'month' | 'day'
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonthStr());
  const [selectedDate, setSelectedDate] = useState(getCurrentDateStr());

  // Keep isModal in sync with asModal if prop changes
  useEffect(() => {
    setIsModal(asModal);
  }, [asModal]);

  // Load warehouses
  useEffect(() => {
    warehouseService.getWarehouses().then((res) => {
      if (Array.isArray(res) && res.length > 0) setWarehouses(res);
    });
  }, []);

  // Smooth scroll into view when rendered inline
  useEffect(() => {
    if (!isModal && containerRef.current) {
      const timer = setTimeout(() => {
        containerRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }, 80);
      return () => clearTimeout(timer);
    }
  }, [entityId, isModal]);

  // Escape key handler for modal mode
  useEffect(() => {
    if (!isModal) return;
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && onClose) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isModal, onClose]);

  const fetchLedger = useCallback(async () => {
    if (!entityId) return;
    setLoading(true);
    try {
      const monthParam =
        timeMode === 'all'
          ? undefined
          : timeMode === 'day'
          ? selectedDate
          : selectedMonth;

      const params = {
        warehouse: selectedWarehouse !== 'all' ? selectedWarehouse : undefined,
        month: monthParam,
      };

      let res = null;
      if (entityType === 'customer') {
        res = await customerService.getLedger(entityId, params);
      } else if (entityType === 'supplier') {
        res = await supplierService.getLedger(entityId, params);
      } else if (entityType === 'product') {
        res = await productService.getLedger(entityId, params);
      }

      setLedgerData(res);
    } catch (err) {
      console.error('Lỗi tải sổ chi tiết giao dịch:', err);
    } finally {
      setLoading(false);
    }
  }, [entityId, entityType, selectedWarehouse, timeMode, selectedMonth, selectedDate]);

  useEffect(() => {
    fetchLedger();
  }, [fetchLedger]);

  const items = ledgerData?.items || [];

  const getWarehouseName = (whId) => {
    if (!whId) return '—';
    const found = warehouses.find((w) => w.id.toLowerCase() === whId.toLowerCase());
    return found?.shortName || found?.name || whId;
  };

  const entityTitle =
    entityType === 'customer'
      ? 'Khách Hàng'
      : entityType === 'supplier'
      ? 'Nhà Cung Cấp'
      : 'Sản Phẩm';

  const EntityIcon =
    entityType === 'customer'
      ? User
      : entityType === 'supplier'
      ? Building
      : Package;

  // Inner Ledger Content
  const ledgerContent = (
    <div
      ref={containerRef}
      style={{
        display: 'flex',
        flexDirection: 'column',
        borderRadius: isFullscreen ? '0' : '12px',
        backgroundColor: 'var(--bg-card, #ffffff)',
        overflow: 'hidden',
        width: '100%',
        height: '100%',
        maxHeight: isFullscreen ? '100vh' : '92vh',
      }}
      onClick={(e) => e.stopPropagation()}
    >
      {/* Header bar */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '12px 20px',
          backgroundColor: 'var(--bg-secondary, #f8fafc)',
          borderBottom: '1px solid var(--border-color, #e2e8f0)',
          flexWrap: 'wrap',
          gap: '12px',
          flexShrink: 0,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div
            style={{
              padding: '8px 10px',
              borderRadius: '8px',
              backgroundColor: 'var(--primary, #2563eb)',
              color: '#ffffff',
              display: 'flex',
              alignItems: 'center',
              boxShadow: '0 2px 6px rgba(37, 99, 235, 0.3)',
            }}
          >
            <EntityIcon size={20} />
          </div>
          <div>
            <div style={{ fontWeight: 800, fontSize: '1.1rem', color: 'var(--text-primary)' }}>
              Sổ Chi Tiết Nhập / Xuất / Thu / Chi: {entityName || `[${entityCode}]`}
            </div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '8px', marginTop: '2px' }}>
              <span
                style={{
                  background: 'var(--primary-light, #eff6ff)',
                  color: 'var(--primary, #2563eb)',
                  padding: '1px 8px',
                  borderRadius: '4px',
                  border: '1px solid rgba(37, 99, 235, 0.2)',
                }}
              >
                {entityTitle}
              </span>
              <span>
                Mã định danh: <strong className="mono" style={{ color: 'var(--text-primary)' }}>{entityCode}</strong>
              </span>
            </div>
          </div>
        </div>

        {/* Filter Controls & Action Buttons */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
          {/* Warehouse Dropdown */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Building size={14} color="var(--primary, #2563eb)" />
            <select
              className="form-control"
              style={{
                fontSize: '0.8125rem',
                padding: '6px 10px',
                height: 'auto',
                backgroundColor: 'var(--bg-card, #ffffff)',
                borderColor: 'var(--border-color, #cbd5e1)',
                fontWeight: 600,
                color: 'var(--text-primary)',
              }}
              value={selectedWarehouse}
              onChange={(e) => setSelectedWarehouse(e.target.value)}
            >
              <option value="all">Tất cả các kho</option>
              {warehouses.map((wh) => (
                <option key={wh.id} value={wh.id}>
                  {wh.name || wh.shortName}
                </option>
              ))}
            </select>
          </div>

          {/* Time mode selector */}
          <select
            className="form-control"
            style={{
              fontSize: '0.8125rem',
              padding: '6px 10px',
              height: 'auto',
              backgroundColor: 'var(--bg-card, #ffffff)',
              borderColor: 'var(--border-color, #cbd5e1)',
              fontWeight: 600,
              color: 'var(--text-primary)',
            }}
            value={timeMode}
            onChange={(e) => setTimeMode(e.target.value)}
          >
            <option value="all">Toàn bộ thời gian</option>
            <option value="month">Theo tháng</option>
            <option value="day">Theo ngày</option>
          </select>

          {timeMode === 'month' && (
            <input
              type="month"
              className="form-control"
              style={{ fontSize: '0.8125rem', padding: '5px 8px', height: 'auto', width: '135px' }}
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
            />
          )}

          {timeMode === 'day' && (
            <input
              type="date"
              className="form-control"
              style={{ fontSize: '0.8125rem', padding: '5px 8px', height: 'auto', width: '140px' }}
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
            />
          )}

          <button
            type="button"
            className="btn btn-outline btn-sm"
            onClick={fetchLedger}
            disabled={loading}
            title="Tải lại sổ chi tiết"
            style={{ padding: '6px 10px', height: 'auto' }}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          </button>

          {/* Toggle Fullscreen in Modal */}
          {isModal && (
            <button
              type="button"
              className="btn btn-outline btn-sm"
              onClick={() => setIsFullscreen(!isFullscreen)}
              title={isFullscreen ? 'Thu về kích thước lớn tiêu chuẩn' : 'Phóng to toàn màn hình'}
              style={{
                padding: '6px 10px',
                height: 'auto',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '5px',
              }}
            >
              {isFullscreen ? <Minimize2 size={14} /> : <Maximize2 size={14} />}
              <span style={{ fontSize: '0.78rem', fontWeight: 600 }}>{isFullscreen ? 'Thu nhỏ' : 'Toàn màn hình'}</span>
            </button>
          )}

          {onClose && (
            <button
              type="button"
              className="btn btn-danger btn-sm"
              onClick={onClose}
              title="Đóng cửa sổ chi tiết (Esc)"
              style={{
                padding: '6px 14px',
                height: 'auto',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                fontWeight: 700,
              }}
            >
              <X size={15} />
              <span>Đóng</span>
            </button>
          )}
        </div>
      </div>

      {/* Summary Stat Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: '10px',
          padding: '12px 20px',
          backgroundColor: 'var(--bg-secondary, #fafafa)',
          borderBottom: '1px solid var(--border-color, #e2e8f0)',
          flexShrink: 0,
        }}
      >
        {/* Card 1: NHẬP */}
        <div
          style={{
            padding: '10px 14px',
            borderRadius: '8px',
            backgroundColor: '#eff6ff',
            border: '1px solid #bfdbfe',
          }}
        >
          <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#1e40af', textTransform: 'uppercase' }}>
            Tổng Nhập
          </div>
          <div className="mono" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#1d4ed8', marginTop: '2px' }}>
            {entityType === 'product'
              ? `${formatNumber(ledgerData?.totalImportQty || 0)}`
              : formatVND(ledgerData?.totalImport || 0)}
          </div>
          {entityType === 'product' && (
            <div style={{ fontSize: '0.72rem', color: '#2563eb' }}>
              Trị giá: {formatVND(ledgerData?.totalImport || 0)}
            </div>
          )}
        </div>

        {/* Card 2: XUẤT */}
        <div
          style={{
            padding: '10px 14px',
            borderRadius: '8px',
            backgroundColor: '#fff7ed',
            border: '1px solid #fed7aa',
          }}
        >
          <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#c2410c', textTransform: 'uppercase' }}>
            Tổng Xuất
          </div>
          <div className="mono" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#ea580c', marginTop: '2px' }}>
            {entityType === 'product'
              ? `${formatNumber(ledgerData?.totalExportQty || 0)}`
              : formatVND(ledgerData?.totalExport || 0)}
          </div>
          {entityType === 'product' && (
            <div style={{ fontSize: '0.72rem', color: '#c2410c' }}>
              Trị giá: {formatVND(ledgerData?.totalExport || 0)}
            </div>
          )}
        </div>

        {/* Card 3: THU */}
        <div
          style={{
            padding: '10px 14px',
            borderRadius: '8px',
            backgroundColor: '#f0fdf4',
            border: '1px solid #bbf7d0',
          }}
        >
          <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#15803d', textTransform: 'uppercase' }}>
            Tổng Thu
          </div>
          <div className="mono" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#16a34a', marginTop: '2px' }}>
            {formatVND(ledgerData?.totalReceipt || 0)}
          </div>
          <div style={{ fontSize: '0.72rem', color: '#15803d' }}>
            {entityType === 'customer'
              ? 'Tiền khách trả nợ'
              : entityType === 'product'
              ? 'Doanh thu bán'
              : 'NCC hoàn lại'}
          </div>
        </div>

        {/* Card 4: CHI */}
        <div
          style={{
            padding: '10px 14px',
            borderRadius: '8px',
            backgroundColor: '#fef2f2',
            border: '1px solid #fecaca',
          }}
        >
          <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#b91c1c', textTransform: 'uppercase' }}>
            Tổng Chi
          </div>
          <div className="mono" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#dc2626', marginTop: '2px' }}>
            {formatVND(ledgerData?.totalPayment || 0)}
          </div>
          <div style={{ fontSize: '0.72rem', color: '#b91c1c' }}>
            {entityType === 'supplier'
              ? 'Tiền trả nợ NCC'
              : entityType === 'product'
              ? 'Tiền vốn nhập hàng'
              : 'Hoàn trả khách'}
          </div>
        </div>

        {/* Card 5: Dư nợ / Tồn kho */}
        <div
          style={{
            padding: '10px 14px',
            borderRadius: '8px',
            backgroundColor: '#faf5ff',
            border: '1px solid #e9d5ff',
          }}
        >
          <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#7e22ce', textTransform: 'uppercase' }}>
            {entityType === 'product' ? 'Tồn Hiện Tại' : 'Công Nợ Hiện Tại'}
          </div>
          <div className="mono" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#9333ea', marginTop: '2px' }}>
            {entityType === 'product'
              ? `${formatNumber(ledgerData?.currentBalance || 0)}`
              : formatVND(ledgerData?.currentBalance || 0)}
          </div>
          <div style={{ fontSize: '0.72rem', color: '#7e22ce' }}>
            {entityType === 'product'
              ? `Tồn ${selectedWarehouse === 'all' ? 'tất cả kho' : getWarehouseName(selectedWarehouse)}`
              : ledgerData?.currentBalance > 0
              ? entityType === 'customer'
                ? 'Khách nợ cửa hàng'
                : 'Cửa hàng nợ NCC'
              : 'Dư trước / cân bằng'}
          </div>
        </div>
      </div>

      {/* Main Ledger Table (Dedicated Columns: Nhập, Xuất, Thu, Chi) */}
      <div
        className="table-responsive"
        style={{
          flex: 1,
          overflowY: 'auto',
          minHeight: '260px',
          backgroundColor: 'var(--bg-card, #ffffff)',
        }}
      >
        <table className="data-table" style={{ fontSize: '0.84rem', width: '100%' }}>
          <thead style={{ position: 'sticky', top: 0, zIndex: 10, backgroundColor: 'var(--bg-secondary, #f8fafc)' }}>
            <tr>
              <th style={{ width: '135px' }}>Thời Gian</th>
              <th style={{ width: '130px' }}>Mã Phiếu</th>
              <th style={{ width: '120px' }}>Kho Hàng</th>
              <th>Diễn Giải / Nội Dung</th>
              <th style={{ textAlign: 'right', width: '125px', color: '#1d4ed8', backgroundColor: 'rgba(37, 99, 235, 0.05)' }}>
                NHẬP
              </th>
              <th style={{ textAlign: 'right', width: '125px', color: '#ea580c', backgroundColor: 'rgba(234, 88, 12, 0.05)' }}>
                XUẤT
              </th>
              <th style={{ textAlign: 'right', width: '125px', color: '#16a34a', backgroundColor: 'rgba(22, 163, 74, 0.05)' }}>
                THU
              </th>
              <th style={{ textAlign: 'right', width: '125px', color: '#dc2626', backgroundColor: 'rgba(220, 38, 38, 0.05)' }}>
                CHI
              </th>
              <th style={{ textAlign: 'right', width: '140px' }}>
                {entityType === 'product' ? 'TỒN LŨY KẾ' : 'DƯ NỢ LŨY KẾ'}
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: '3.5rem' }}>
                  <RefreshCw size={26} className="animate-spin" style={{ color: 'var(--primary, #2563eb)' }} />
                  <div style={{ marginTop: '0.65rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
                    Đang tải sổ chi tiết giao dịch thực tế...
                  </div>
                </td>
              </tr>
            ) : items.length === 0 ? (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: '3.5rem' }}>
                  <EmptyState
                    title="Chưa có phát sinh giao dịch nào"
                    description={`Chưa ghi nhận phiếu xuất, nhập, thu hoặc chi nào cho ${entityTitle.toLowerCase()} này trong kỳ đã chọn.`}
                  />
                </td>
              </tr>
            ) : (
              items.map((row, idx) => (
                <tr key={`${row.voucherNumber || row.id || idx}-${idx}`} style={{ borderBottom: '1px solid var(--border-color, #f1f5f9)' }}>
                  <td className="mono" style={{ fontSize: '0.8rem', whiteSpace: 'nowrap' }}>
                    {formatDate(row.date)}
                  </td>
                  <td>
                    <span
                      className="mono"
                      style={{
                        fontWeight: 700,
                        color: 'var(--primary, #2563eb)',
                        backgroundColor: 'var(--primary-light, #eff6ff)',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        border: '1px solid rgba(37, 99, 235, 0.2)',
                      }}
                    >
                      {row.voucherNumber || '—'}
                    </span>
                  </td>
                  <td>
                    <span
                      style={{
                        display: 'inline-block',
                        padding: '2px 8px',
                        borderRadius: '4px',
                        backgroundColor: 'var(--bg-tertiary, #f1f5f9)',
                        color: 'var(--text-secondary)',
                        fontSize: '0.78rem',
                        fontWeight: 600,
                      }}
                    >
                      {getWarehouseName(row.warehouse)}
                    </span>
                  </td>
                  <td style={{ fontSize: '0.84rem' }}>{row.description || '—'}</td>

                  {/* CỘT NHẬP */}
                  <td style={{ textAlign: 'right', backgroundColor: 'rgba(37, 99, 235, 0.02)' }} className="mono">
                    {entityType === 'product' ? (
                      row.importQty > 0 ? (
                        <span style={{ fontWeight: 700, color: '#1d4ed8' }}>
                          +{formatNumber(row.importQty)}
                        </span>
                      ) : (
                        <span style={{ color: '#cbd5e1' }}>—</span>
                      )
                    ) : row.importAmount > 0 ? (
                      <span style={{ fontWeight: 700, color: '#1d4ed8' }}>
                        {formatVND(row.importAmount)}
                      </span>
                    ) : (
                      <span style={{ color: '#cbd5e1' }}>—</span>
                    )}
                  </td>

                  {/* CỘT XUẤT */}
                  <td style={{ textAlign: 'right', backgroundColor: 'rgba(234, 88, 12, 0.02)' }} className="mono">
                    {entityType === 'product' ? (
                      row.exportQty > 0 ? (
                        <span style={{ fontWeight: 700, color: '#ea580c' }}>
                          -{formatNumber(row.exportQty)}
                        </span>
                      ) : (
                        <span style={{ color: '#cbd5e1' }}>—</span>
                      )
                    ) : row.exportAmount > 0 ? (
                      <span style={{ fontWeight: 700, color: '#ea580c' }}>
                        {formatVND(row.exportAmount)}
                      </span>
                    ) : (
                      <span style={{ color: '#cbd5e1' }}>—</span>
                    )}
                  </td>

                  {/* CỘT THU */}
                  <td style={{ textAlign: 'right', backgroundColor: 'rgba(22, 163, 74, 0.02)' }} className="mono">
                    {row.receiptAmount > 0 ? (
                      <span style={{ fontWeight: 700, color: '#16a34a' }}>
                        {formatVND(row.receiptAmount)}
                      </span>
                    ) : (
                      <span style={{ color: '#cbd5e1' }}>—</span>
                    )}
                  </td>

                  {/* CỘT CHI */}
                  <td style={{ textAlign: 'right', backgroundColor: 'rgba(220, 38, 38, 0.02)' }} className="mono">
                    {row.paymentAmount > 0 ? (
                      <span style={{ fontWeight: 700, color: '#dc2626' }}>
                        {formatVND(row.paymentAmount)}
                      </span>
                    ) : (
                      <span style={{ color: '#cbd5e1' }}>—</span>
                    )}
                  </td>

                  {/* CỘT DƯ NỢ / TỒN LŨY KẾ */}
                  <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                    {entityType === 'product'
                      ? formatNumber(row.balance)
                      : formatVND(row.balance)}
                  </td>
                </tr>
              ))
            )}
          </tbody>
          {items.length > 0 && (
            <tfoot
              style={{
                position: 'sticky',
                bottom: 0,
                zIndex: 10,
                backgroundColor: 'var(--bg-secondary, #f8fafc)',
                fontWeight: 800,
                borderTop: '2px solid var(--border-color, #cbd5e1)',
              }}
            >
              <tr>
                <td colSpan={4} style={{ textAlign: 'right', fontWeight: 800 }}>
                  TỔNG CỘNG PHÁT SINH:
                </td>
                <td style={{ textAlign: 'right', color: '#1d4ed8' }} className="mono">
                  {entityType === 'product'
                    ? formatNumber(ledgerData?.totalImportQty || 0)
                    : formatVND(ledgerData?.totalImport || 0)}
                </td>
                <td style={{ textAlign: 'right', color: '#ea580c' }} className="mono">
                  {entityType === 'product'
                    ? formatNumber(ledgerData?.totalExportQty || 0)
                    : formatVND(ledgerData?.totalExport || 0)}
                </td>
                <td style={{ textAlign: 'right', color: '#16a34a' }} className="mono">
                  {formatVND(ledgerData?.totalReceipt || 0)}
                </td>
                <td style={{ textAlign: 'right', color: '#dc2626' }} className="mono">
                  {formatVND(ledgerData?.totalPayment || 0)}
                </td>
                <td style={{ textAlign: 'right', color: 'var(--primary, #2563eb)' }} className="mono">
                  {entityType === 'product'
                    ? formatNumber(ledgerData?.currentBalance || 0)
                    : formatVND(ledgerData?.currentBalance || 0)}
                </td>
              </tr>
            </tfoot>
          )}
        </table>
      </div>
    </div>
  );

  if (isModal) {
    return (
      <div
        style={{
          position: 'fixed',
          inset: 0,
          zIndex: 9999,
          backgroundColor: 'rgba(15, 23, 42, 0.75)',
          backdropFilter: 'blur(5px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: isFullscreen ? '0' : '1.25rem',
          animation: 'fadeIn 0.15s ease-out',
        }}
        onClick={() => onClose && onClose()}
      >
        <div
          style={{
            width: isFullscreen ? '100vw' : '95vw',
            maxWidth: isFullscreen ? 'none' : '1560px',
            height: isFullscreen ? '100vh' : '92vh',
            maxHeight: isFullscreen ? '100vh' : '92vh',
            display: 'flex',
            flexDirection: 'column',
            backgroundColor: 'var(--bg-card, #ffffff)',
            borderRadius: isFullscreen ? '0' : '14px',
            border: isFullscreen ? 'none' : '1px solid var(--border-color, #cbd5e1)',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.45)',
            overflow: 'hidden',
          }}
          onClick={(e) => e.stopPropagation()}
        >
          {ledgerContent}
        </div>
      </div>
    );
  }

  return (
    <div style={{ marginTop: '1.5rem', marginBottom: '1.5rem' }}>
      {ledgerContent}
    </div>
  );
}

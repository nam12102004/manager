import React, { useState, useEffect } from 'react';
import {
  X,
  Printer,
  Calendar,
  Building,
  User,
  Package,
  ArrowDownLeft,
  ArrowUpRight,
  Wallet,
  CreditCard,
  CheckCircle,
  AlertCircle,
  FileText,
  Layers,
  RefreshCw,
  SlidersHorizontal,
  Clock,
  Phone,
  MapPin,
  Tag,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate } from '../../utils/formatters';
import { exportService, importService, cashBookService, warehouseService } from '../../services';
import { exportsApi, importsApi, ownersApi } from '../../api/endpoints';
import { printInNewTab, generateExportHtml, generateImportHtml, generateVoucherHtml } from '../../utils/printVoucher';

export default function VoucherDetailModal({
  isOpen,
  onClose,
  voucherInfo, // { record, sourceType, referenceType, referenceId, voucherNumber, id, customer, supplier }
  placement = 'left',
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [resolvedType, setResolvedType] = useState('unknown'); // 'export' | 'import' | 'receipt' | 'payment' | 'adjustment'
  const [voucherData, setVoucherData] = useState(null);
  const [ownerInfo, setOwnerInfo] = useState(null);
  const [warehouses, setWarehouses] = useState(() => warehouseService.getWarehousesSync());

  // Load warehouses & owner info once
  useEffect(() => {
    warehouseService.getWarehouses().then((res) => {
      if (Array.isArray(res) && res.length > 0) setWarehouses(res);
    });
    ownersApi.get().then((res) => setOwnerInfo(res)).catch(() => {});
  }, []);

  // Handle ESC key
  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        e.stopPropagation();
        onClose?.();
      }
    };
    window.addEventListener('keydown', handleKeyDown, true);
    return () => window.removeEventListener('keydown', handleKeyDown, true);
  }, [isOpen, onClose]);

  // Fetch full voucher data whenever voucherInfo changes
  useEffect(() => {
    if (!isOpen || !voucherInfo) {
      setVoucherData(null);
      setResolvedType('unknown');
      setLoading(false);
      setError(null);
      return;
    }

    let isMounted = true;

    async function loadVoucher() {
      setLoading(true);
      setError(null);

      const st = String(
        voucherInfo.sourceType ||
        voucherInfo.voucherType ||
        voucherInfo.referenceType ||
        voucherInfo.record?.sourceType ||
        ''
      ).toLowerCase();

      const rawRefId =
        voucherInfo.referenceId ||
        voucherInfo.voucherNumber ||
        voucherInfo.record?.referenceId ||
        voucherInfo.record?.voucherNumber;

      const rawId = voucherInfo.id || voucherInfo.record?.id;

      let type = 'unknown';
      if (st.includes('export') || (typeof rawRefId === 'string' && (rawRefId.startsWith('XK') || rawRefId.startsWith('PX')))) {
        type = 'export';
      } else if (st.includes('import') || (typeof rawRefId === 'string' && (rawRefId.startsWith('NK') || rawRefId.startsWith('PN')))) {
        type = 'import';
      } else if (st.includes('receipt') || st.includes('thu') || (typeof rawRefId === 'string' && rawRefId.startsWith('PT'))) {
        type = 'receipt';
      } else if (st.includes('payment') || st.includes('chi') || (typeof rawRefId === 'string' && rawRefId.startsWith('PC'))) {
        type = 'payment';
      } else if (st.includes('adjust') || st.includes('init')) {
        type = 'adjustment';
      }

      if (isMounted) setResolvedType(type);

      try {
        let loaded = null;

        if (type === 'export') {
          // Try loading by numeric id if it looks like an export id
          if (rawId && typeof rawId === 'number') {
            try {
              loaded = await exportService.getById(rawId);
            } catch (e) {
              // Ignore and fallback to search
            }
          }
          if (!loaded && rawRefId) {
            const res = await exportsApi.getAll({ q: String(rawRefId).trim() });
            const list = Array.isArray(res) ? res : (res?.items || []);
            const found = list.find((x) => x.voucherNumber?.toLowerCase() === String(rawRefId).trim().toLowerCase()) || list[0];
            if (found?.id) {
              loaded = await exportService.getById(found.id);
            } else if (found) {
              loaded = found;
            }
          }
        } else if (type === 'import') {
          if (rawId && typeof rawId === 'number') {
            try {
              loaded = await importService.getById(rawId);
            } catch (e) {
              // Ignore and fallback
            }
          }
          if (!loaded && rawRefId) {
            const res = await importsApi.getAll({ q: String(rawRefId).trim() });
            const list = Array.isArray(res) ? res : (res?.items || []);
            const found = list.find((x) => x.voucherNumber?.toLowerCase() === String(rawRefId).trim().toLowerCase()) || list[0];
            if (found?.id) {
              loaded = await importService.getById(found.id);
            } else if (found) {
              loaded = found;
            }
          }
        } else if (type === 'receipt') {
          if (rawId && typeof rawId === 'number') {
            try {
              loaded = await cashBookService.getReceiptById(rawId);
            } catch (e) {}
          }
          if (!loaded && rawRefId) {
            const res = await cashBookService.getReceipts({ q: String(rawRefId).trim() });
            const list = Array.isArray(res) ? res : (res?.items || []);
            const found = list.find((x) => x.receiptNumber?.toLowerCase() === String(rawRefId).trim().toLowerCase()) || list[0];
            if (found?.id) {
              loaded = await cashBookService.getReceiptById(found.id);
            } else if (found) {
              loaded = found;
            }
          }
        } else if (type === 'payment') {
          if (rawId && typeof rawId === 'number') {
            try {
              loaded = await cashBookService.getPaymentById(rawId);
            } catch (e) {}
          }
          if (!loaded && rawRefId) {
            const res = await cashBookService.getPayments({ q: String(rawRefId).trim() });
            const list = Array.isArray(res) ? res : (res?.items || []);
            const found = list.find((x) => x.paymentNumber?.toLowerCase() === String(rawRefId).trim().toLowerCase()) || list[0];
            if (found?.id) {
              loaded = await cashBookService.getPaymentById(found.id);
            } else if (found) {
              loaded = found;
            }
          }
        }

        if (isMounted) {
          setVoucherData(loaded);
        }
      } catch (err) {
        console.warn('Không tải được chi tiết chứng từ đầy đủ, sử dụng dữ liệu sổ nợ:', err);
        if (isMounted) {
          setError(err.message || 'Không thể tải chi tiết chứng từ');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }

    loadVoucher();

    return () => {
      isMounted = false;
    };
  }, [isOpen, voucherInfo]);

  if (!isOpen || !voucherInfo) return null;

  const record = voucherInfo.record || {};
  const currentCustomer = voucherInfo.customer || voucherData?.customer;
  const currentSupplier = voucherInfo.supplier || voucherData?.supplier;

  const getWarehouseName = (whId) => {
    if (!whId) return 'Kho mặc định';
    const found = warehouses.find((w) => w.id?.toLowerCase() === whId?.toLowerCase());
    return found?.shortName || found?.name || whId;
  };

  const handlePrint = () => {
    if (resolvedType === 'export') {
      const target = voucherData || {
        voucherNumber: voucherInfo.referenceId,
        date: record.createdAt,
        totalSale: Math.abs(record.delta || 0),
        items: [],
      };
      const html = generateExportHtml({ exportData: target, ownerInfo, customer: currentCustomer });
      printInNewTab(html);
    } else if (resolvedType === 'import') {
      const target = voucherData || {
        voucherNumber: voucherInfo.referenceId,
        date: record.createdAt,
        totalAmount: Math.abs(record.delta || 0),
        items: [],
      };
      const html = generateImportHtml({ importData: target, ownerInfo, supplier: currentSupplier });
      printInNewTab(html);
    } else if (resolvedType === 'receipt') {
      const target = voucherData || {
        receiptNumber: voucherInfo.referenceId,
        date: record.createdAt,
        amount: Math.abs(record.delta || 0),
        notes: record.reason || record.note,
        customerName: currentCustomer?.name,
      };
      const html = generateVoucherHtml({ voucher: target, type: 'receipt', ownerInfo });
      printInNewTab(html);
    } else if (resolvedType === 'payment') {
      const target = voucherData || {
        paymentNumber: voucherInfo.referenceId,
        date: record.createdAt,
        amount: Math.abs(record.delta || 0),
        notes: record.reason || record.note,
        supplierName: currentSupplier?.name,
      };
      const html = generateVoucherHtml({ voucher: target, type: 'payment', ownerInfo });
      printInNewTab(html);
    }
  };

  // Header icon and color
  const getTypeBadge = () => {
    switch (resolvedType) {
      case 'export':
        return {
          icon: Package,
          label: 'Phiếu Xuất Bán Hàng',
          color: '#ea580c',
          bg: '#fff7ed',
          border: '#fed7aa',
        };
      case 'import':
        return {
          icon: Layers,
          label: 'Phiếu Nhập Hàng',
          color: '#1d4ed8',
          bg: '#eff6ff',
          border: '#bfdbfe',
        };
      case 'receipt':
        return {
          icon: ArrowDownLeft,
          label: 'Phiếu Thu Tiền',
          color: '#16a34a',
          bg: '#f0fdf4',
          border: '#bbf7d0',
        };
      case 'payment':
        return {
          icon: ArrowUpRight,
          label: 'Phiếu Chi Tiền',
          color: '#dc2626',
          bg: '#fef2f2',
          border: '#fecaca',
        };
      case 'adjustment':
      default:
        return {
          icon: SlidersHorizontal,
          label: 'Điều Chỉnh Công Nợ',
          color: '#7e22ce',
          bg: '#faf5ff',
          border: '#e9d5ff',
        };
    }
  };

  const typeConfig = getTypeBadge();
  const TypeIcon = typeConfig.icon;
  const voucherCode = voucherInfo.referenceId || voucherData?.voucherNumber || voucherData?.receiptNumber || voucherData?.paymentNumber || (record.id ? `#${record.id}` : '—');

  // Backdrop positioning
  const isLeft = placement === 'left';

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 10050,
        backgroundColor: 'rgba(15, 23, 42, 0.45)',
        backdropFilter: 'blur(2px)',
        display: 'flex',
        justifyContent: isLeft ? 'flex-start' : 'flex-end',
        animation: 'fadeIn 0.2s ease',
      }}
      onClick={onClose}
    >
      <div
        style={{
          backgroundColor: 'var(--bg-secondary, #ffffff)',
          width: '100%',
          maxWidth: '650px',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          borderRight: isLeft ? '1px solid var(--border-color, #cbd5e1)' : 'none',
          borderLeft: !isLeft ? '1px solid var(--border-color, #cbd5e1)' : 'none',
          boxShadow: isLeft
            ? '12px 0 35px rgba(0, 0, 0, 0.28)'
            : '-12px 0 35px rgba(0, 0, 0, 0.28)',
          animation: isLeft
            ? 'slideRight 0.3s cubic-bezier(0.16, 1, 0.3, 1)'
            : 'slideLeft 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
          overflow: 'hidden',
        }}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
      >
        {/* Modal Header */}
        <div
          style={{
            padding: '1rem 1.25rem',
            borderBottom: '1px solid var(--border-color, #e2e8f0)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            backgroundColor: 'var(--bg-card, #ffffff)',
            flexShrink: 0,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '8px',
                backgroundColor: typeConfig.bg,
                border: `1px solid ${typeConfig.border}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: typeConfig.color,
                flexShrink: 0,
              }}
            >
              <TypeIcon size={20} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                <span
                  style={{
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    textTransform: 'uppercase',
                    color: typeConfig.color,
                    backgroundColor: typeConfig.bg,
                    padding: '2px 8px',
                    borderRadius: '4px',
                    border: `1px solid ${typeConfig.border}`,
                  }}
                >
                  {typeConfig.label}
                </span>
                <span className="mono" style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                  {voucherCode}
                </span>
              </div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', marginTop: '2px' }}>
                Chi tiết nghiệp vụ ảnh hưởng công nợ thực tế
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            {resolvedType !== 'adjustment' && (
              <button
                type="button"
                className="btn btn-outline btn-sm"
                onClick={handlePrint}
                title="In chứng từ này"
                style={{ display: 'inline-flex', alignItems: 'center', gap: '5px', padding: '0.35rem 0.65rem' }}
              >
                <Printer size={14} />
                <span style={{ fontSize: '0.8125rem' }}>In</span>
              </button>
            )}
            <button
              type="button"
              className="btn btn-ghost btn-sm"
              onClick={onClose}
              title="Đóng cửa sổ (ESC)"
              style={{ padding: '0.35rem 0.65rem' }}
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Modal Body */}
        <div
          style={{
            flex: 1,
            overflowY: 'auto',
            padding: '1.25rem',
            display: 'flex',
            flexDirection: 'column',
            gap: '1rem',
          }}
        >
          {loading ? (
            <div style={{ textAlign: 'center', padding: '3.5rem 1rem' }}>
              <RefreshCw size={28} className="animate-spin" style={{ color: 'var(--primary, #2563eb)' }} />
              <div style={{ marginTop: '0.75rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
                Đang tải chi tiết chứng từ...
              </div>
            </div>
          ) : (
            <>
              {/* Top Overview Grid */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
                  gap: '0.75rem',
                }}
              >
                {/* Box 1: Thông tin đối tác */}
                <div
                  style={{
                    padding: '0.85rem 1rem',
                    backgroundColor: 'var(--bg-card, #ffffff)',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color, #e2e8f0)',
                  }}
                >
                  <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                    {currentSupplier ? 'Nhà Cung Cấp' : 'Khách Hàng'}
                  </div>
                  <div style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--text-primary)', marginTop: '4px' }}>
                    {voucherData?.customerName || currentCustomer?.name || voucherData?.supplierName || currentSupplier?.name || '—'}
                  </div>
                  {(currentCustomer?.phone || currentSupplier?.phone || voucherData?.customerPhone || voucherData?.supplierPhone) && (
                    <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '3px' }}>
                      <Phone size={13} />
                      <span>{currentCustomer?.phone || currentSupplier?.phone || voucherData?.customerPhone || voucherData?.supplierPhone}</span>
                    </div>
                  )}
                  {(currentCustomer?.address || currentSupplier?.address || voucherData?.customerAddress || voucherData?.supplierAddress) && (
                    <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '3px' }}>
                      <MapPin size={13} />
                      <span>{currentCustomer?.address || currentSupplier?.address || voucherData?.customerAddress || voucherData?.supplierAddress}</span>
                    </div>
                  )}
                </div>

                {/* Box 2: Thời gian & Kho */}
                <div
                  style={{
                    padding: '0.85rem 1rem',
                    backgroundColor: 'var(--bg-card, #ffffff)',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color, #e2e8f0)',
                  }}
                >
                  <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                    Thời Gian & Địa Điểm
                  </div>
                  <div style={{ fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)', marginTop: '4px', display: 'flex', alignItems: 'center', gap: '5px' }}>
                    <Calendar size={14} color="var(--primary)" />
                    <span>{formatDate(voucherData?.date || record.createdAt, true)}</span>
                  </div>
                  <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '5px', marginTop: '4px' }}>
                    <Building size={14} />
                    <span>Kho hàng: <strong>{getWarehouseName(voucherData?.warehouse || record.warehouse)}</strong></span>
                  </div>
                  {(voucherData?.employeeName || voucherData?.employee?.name) && (
                    <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '5px', marginTop: '4px' }}>
                      <User size={14} />
                      <span>Nhân viên: <strong>{voucherData.employeeName || voucherData.employee?.name}</strong></span>
                    </div>
                  )}
                </div>
              </div>

              {/* Box 3: Biến động công nợ của phiếu này */}
              <div
                style={{
                  padding: '0.85rem 1rem',
                  backgroundColor: typeConfig.bg,
                  borderRadius: '8px',
                  border: `1px solid ${typeConfig.border}`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  flexWrap: 'wrap',
                  gap: '0.75rem',
                }}
              >
                <div>
                  <div style={{ fontSize: '0.75rem', fontWeight: 700, color: typeConfig.color, textTransform: 'uppercase' }}>
                    Tác Động Đến Sổ Nợ
                  </div>
                  <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', marginTop: '2px' }}>
                    {record.reason || record.note || (resolvedType === 'export' ? 'Ghi tăng nợ phải thu' : resolvedType === 'receipt' ? 'Giảm nợ do khách trả tiền' : resolvedType === 'import' ? 'Tăng nợ phải trả NCC' : resolvedType === 'payment' ? 'Giảm nợ do thanh toán NCC' : 'Điều chỉnh số dư')}
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Biến động nợ:</div>
                  <div className="mono" style={{ fontSize: '1.2rem', fontWeight: 800, color: typeConfig.color }}>
                    {record.delta != null ? (record.delta > 0 ? `+${formatVND(record.delta)}` : formatVND(record.delta)) : formatVND(voucherData?.totalSale || voucherData?.totalAmount || voucherData?.amount || 0)}
                  </div>
                  {record.afterDebt != null && (
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                      Dư nợ sau giao dịch: <strong className="mono">{formatVND(record.afterDebt)}</strong>
                    </div>
                  )}
                </div>
              </div>

              {/* SECTION: BẢNG SẢN PHẨM NẾU LÀ PHIẾU XUẤT / PHIẾU NHẬP */}
              {(resolvedType === 'export' || resolvedType === 'import') && (
                <div
                  style={{
                    backgroundColor: 'var(--bg-card, #ffffff)',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color, #e2e8f0)',
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      padding: '0.65rem 1rem',
                      backgroundColor: 'var(--bg-secondary, #f8fafc)',
                      borderBottom: '1px solid var(--border-color, #e2e8f0)',
                      fontWeight: 700,
                      fontSize: '0.85rem',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                    }}
                  >
                    <span>Danh Sách Sản Phẩm ({(voucherData?.items || []).length} mục)</span>
                    <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', fontWeight: 500 }}>
                      Đơn giá & Thành tiền
                    </span>
                  </div>

                  <div className="table-responsive" style={{ maxHeight: '280px', overflowY: 'auto' }}>
                    <table className="data-table" style={{ fontSize: '0.8125rem', width: '100%' }}>
                      <thead>
                        <tr>
                          <th style={{ width: '40px', textAlign: 'center' }}>#</th>
                          <th>Tên Hàng / Sản Phẩm</th>
                          <th style={{ width: '60px', textAlign: 'center' }}>ĐVT</th>
                          <th style={{ width: '70px', textAlign: 'right' }}>SL</th>
                          <th style={{ width: '105px', textAlign: 'right' }}>Đơn Giá</th>
                          <th style={{ width: '110px', textAlign: 'right' }}>Thành Tiền</th>
                        </tr>
                      </thead>
                      <tbody>
                        {(voucherData?.items || []).length === 0 ? (
                          <tr>
                            <td colSpan={6} style={{ textAlign: 'center', padding: '1.5rem', color: 'var(--text-muted)' }}>
                              Không có dữ liệu dòng sản phẩm chi tiết
                            </td>
                          </tr>
                        ) : (
                          voucherData.items.map((it, idx) => (
                            <tr key={it.id || idx}>
                              <td style={{ textAlign: 'center', color: 'var(--text-muted)' }}>{idx + 1}</td>
                              <td>
                                <strong style={{ color: 'var(--text-primary)' }}>{it.productName || it.sku}</strong>
                                {it.sku && (
                                  <div className="mono" style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                                    {it.sku}
                                  </div>
                                )}
                              </td>
                              <td style={{ textAlign: 'center' }}>
                                <span className="badge badge-neutral">{it.uom || '—'}</span>
                              </td>
                              <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                                {formatNumber(it.quantity)}
                              </td>
                              <td style={{ textAlign: 'right' }} className="mono">
                                {formatVND(it.salePrice || it.unitPrice || it.unitCost || 0)}
                              </td>
                              <td style={{ textAlign: 'right', fontWeight: 700, color: typeConfig.color }} className="mono">
                                {formatVND(it.lineTotal || (it.quantity * (it.salePrice || it.unitPrice || 0)))}
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>

                  {/* Financial Breakdown for Export / Import */}
                  <div
                    style={{
                      padding: '0.85rem 1.25rem',
                      borderTop: '1px solid var(--border-color, #e2e8f0)',
                      backgroundColor: 'var(--bg-secondary, #fafafa)',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.35rem',
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem' }}>
                      <span style={{ color: 'var(--text-secondary)' }}>Tiền hàng:</span>
                      <span className="mono" style={{ fontWeight: 600 }}>
                        {formatVND(voucherData?.subtotalSale || voucherData?.subtotalAmount || voucherData?.totalSale || voucherData?.totalAmount || Math.abs(record.delta || 0))}
                      </span>
                    </div>

                    {(voucherData?.discountAmount > 0 || voucherData?.discountPercent > 0) && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', color: '#dc2626' }}>
                        <span>Chiết khấu:</span>
                        <span className="mono">-{formatVND(voucherData.discountAmount || 0)}</span>
                      </div>
                    )}

                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.95rem', fontWeight: 800, borderTop: '1px dashed var(--border-color, #cbd5e1)', paddingTop: '0.35rem' }}>
                      <span>Tổng tiền thanh toán:</span>
                      <span className="mono" style={{ color: typeConfig.color }}>
                        {formatVND(voucherData?.totalSale || voucherData?.totalAmount || Math.abs(record.delta || 0))}
                      </span>
                    </div>

                    {voucherData?.paidAmount != null && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', color: '#16a34a' }}>
                        <span>{resolvedType === 'export' ? 'Khách đã trả:' : 'Đã thanh toán NCC:'}</span>
                        <span className="mono" style={{ fontWeight: 600 }}>{formatVND(voucherData.paidAmount)}</span>
                      </div>
                    )}

                    {voucherData?.unpaidAmount != null && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', fontWeight: 700, color: voucherData.unpaidAmount > 0 ? '#ea580c' : 'var(--text-muted)' }}>
                        <span>{resolvedType === 'export' ? 'Còn nợ lại đơn này:' : 'Còn nợ lại NCC đơn này:'}</span>
                        <span className="mono">{formatVND(voucherData.unpaidAmount)}</span>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* SECTION: THU TIỀN / CHI TIỀN / ĐIỀU CHỈNH */}
              {(resolvedType === 'receipt' || resolvedType === 'payment' || resolvedType === 'adjustment') && (
                <div
                  style={{
                    padding: '1.25rem',
                    backgroundColor: 'var(--bg-card, #ffffff)',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color, #e2e8f0)',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '0.75rem',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                      Số Tiền Giao Dịch
                    </span>
                    <span
                      style={{
                        fontSize: '0.78rem',
                        fontWeight: 600,
                        padding: '2px 8px',
                        borderRadius: '4px',
                        backgroundColor: 'var(--bg-tertiary, #f1f5f9)',
                        color: 'var(--text-secondary)',
                      }}
                    >
                      {voucherData?.method === 'bank' || voucherData?.method === 'transfer' ? 'Chuyển khoản' : 'Tiền mặt'}
                    </span>
                  </div>

                  <div className="mono" style={{ fontSize: '1.75rem', fontWeight: 800, color: typeConfig.color }}>
                    {formatVND(voucherData?.amount || Math.abs(record.delta || 0))}
                  </div>

                  {voucherData?.relatedVoucherId && (
                    <div style={{ fontSize: '0.84rem', color: 'var(--text-secondary)', borderTop: '1px solid var(--border-color, #f1f5f9)', paddingTop: '0.5rem' }}>
                      Mã phiếu liên quan:{' '}
                      <strong className="mono" style={{ color: 'var(--primary)' }}>
                        {voucherData.relatedVoucherId}
                      </strong>
                    </div>
                  )}

                  {(voucherData?.notes || record.reason || record.note) && (
                    <div style={{ fontSize: '0.84rem', color: 'var(--text-secondary)', borderTop: '1px solid var(--border-color, #f1f5f9)', paddingTop: '0.5rem' }}>
                      Nội dung / Ghi chú:{' '}
                      <span style={{ color: 'var(--text-primary)', fontWeight: 500 }}>
                        {voucherData?.notes || record.reason || record.note}
                      </span>
                    </div>
                  )}
                </div>
              )}

              {/* Status and Notes Banner */}
              {voucherData?.notes && resolvedType !== 'receipt' && resolvedType !== 'payment' && (
                <div
                  style={{
                    padding: '0.75rem 1rem',
                    backgroundColor: 'var(--bg-tertiary, #f8fafc)',
                    borderRadius: '6px',
                    border: '1px solid var(--border-color, #e2e8f0)',
                    fontSize: '0.8125rem',
                    color: 'var(--text-secondary)',
                  }}
                >
                  <strong>Ghi chú:</strong> {voucherData.notes}
                </div>
              )}
            </>
          )}
        </div>

        {/* Modal Footer */}
        <div
          style={{
            padding: '0.85rem 1.25rem',
            borderTop: '1px solid var(--border-color, #e2e8f0)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            backgroundColor: 'var(--bg-card, #ffffff)',
            flexShrink: 0,
          }}
        >
          <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
            Nhấn <kbd style={{ padding: '2px 5px', borderRadius: '3px', background: 'var(--bg-tertiary, #e2e8f0)', border: '1px solid var(--border-color)' }}>ESC</kbd> để đóng
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            {resolvedType !== 'adjustment' && (
              <button
                type="button"
                className="btn btn-outline btn-sm"
                onClick={handlePrint}
                style={{ display: 'inline-flex', alignItems: 'center', gap: '5px' }}
              >
                <Printer size={15} />
                <span>In Phiếu</span>
              </button>
            )}
            <button
              type="button"
              className="btn btn-primary btn-sm"
              onClick={onClose}
              style={{ minWidth: '80px' }}
            >
              Đóng
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

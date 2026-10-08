import React, { useState, useEffect } from 'react';
import {
  BarChart3,
  Boxes,
  TrendingUp,
  Calendar,
  Printer,
  Download,
  RefreshCw,
  Layers,
  ArrowUpRight,
  ArrowDownLeft,
  Building,
  Users,
} from 'lucide-react';
import { formatVND, formatNumber, formatDate, getCurrentMonthStr } from '../utils/formatters';
import { useNotification } from '../context/NotificationContext';
import StatCard from '../components/common/StatCard';
import EmptyState from '../components/common/EmptyState';
import { reportService } from '../services';

export default function Reports() {
  const notify = useNotification();

  const [activeReportTab, setActiveReportTab] = useState('stock'); // 'stock' | 'debts'
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonthStr());
  const [loading, setLoading] = useState(false);

  const [stockReport, setStockReport] = useState(null);
  const [debtReport, setDebtReport] = useState(null);

  const loadReport = async () => {
    setLoading(true);
    try {
      if (activeReportTab === 'stock') {
        const data = await reportService.getStockReport(selectedMonth);
        setStockReport(data || null);
      } else {
        const data = await reportService.getDebtReport(selectedMonth);
        setDebtReport(data || null);
      }
    } catch (err) {
      notify.error(err.message || 'Lỗi khi tải báo cáo');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReport();
  }, [activeReportTab, selectedMonth]);

  const handlePrint = () => {
    window.print();
  };

  // Export CSV via reportService
  const handleExportCSV = () => {
    try {
      if (activeReportTab === 'stock') {
        reportService.exportStockReportCSV(stockReport, selectedMonth);
        notify.success('Xuất file báo cáo tồn kho thành công!');
      } else {
        reportService.exportDebtReportCSV(debtReport, selectedMonth);
        notify.success('Xuất file báo cáo công nợ thành công!');
      }
    } catch (err) {
      notify.error(err.message || 'Không thể xuất file CSV');
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <BarChart3 size={28} color="var(--primary)" />
            <span>Báo Cáo Hoạt Động Định Kỳ</span>
          </h1>
          <p className="page-subtitle">
            Báo cáo biến động Xuất - Nhập - Tồn kho và Sổ tổng hợp công nợ hai chiều theo kỳ
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={handleExportCSV}>
            <Download size={16} />
            <span>Xuất file Excel/CSV</span>
          </button>
          <button className="btn btn-outline" onClick={handlePrint}>
            <Printer size={16} />
            <span>In Báo Cáo</span>
          </button>
          <button className="btn btn-primary" onClick={loadReport} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải dữ liệu</span>
          </button>
        </div>
      </div>

      {/* Filter and Tab controls */}
      <div className="filter-bar">
        {/* Month Selector */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Calendar size={18} color="var(--primary)" />
          <span style={{ fontSize: '0.875rem', fontWeight: 600 }}>Kỳ Báo Cáo:</span>
          <input
            type="month"
            className="form-input mono"
            style={{ width: '170px' }}
            value={selectedMonth}
            onChange={(e) => setSelectedMonth(e.target.value)}
          />
        </div>

        {/* Tab Toggle Buttons */}
        <div style={{ display: 'flex', gap: '0.5rem', marginLeft: 'auto' }}>
          <button
            className={`btn ${activeReportTab === 'stock' ? 'btn-primary' : 'btn-outline'}`}
            onClick={() => setActiveReportTab('stock')}
          >
            <Boxes size={16} />
            <span>Báo Cáo Tồn Kho Đa Điểm</span>
          </button>
          <button
            className={`btn ${activeReportTab === 'debts' ? 'btn-primary' : 'btn-outline'}`}
            onClick={() => setActiveReportTab('debts')}
          >
            <TrendingUp size={16} />
            <span>Báo Cáo Tổng Hợp Công Nợ</span>
          </button>
        </div>
      </div>

      {/* Stock Report Content */}
      {activeReportTab === 'stock' && (
        <div>
          {/* Summary Stat Cards */}
          <div className="stats-grid">
            <StatCard
              title="GIÁ TRỊ TỒN KHO THEO GIÁ VỐN"
              value={formatVND(stockReport?.totalCostValue || 0)}
              subtitle="Cơ sở tính toán tài sản lưu động"
              icon={Layers}
              color="primary"
            />
            <StatCard
              title="GIÁ TRỊ TỒN KHO THEO GIÁ SỈ"
              value={formatVND(stockReport?.totalWholesaleValue || 0)}
              subtitle="Doanh thu dự kiến bán buôn"
              icon={Building}
              color="info"
            />
            <StatCard
              title="GIÁ TRỊ TỒN KHO THEO GIÁ LẺ"
              value={formatVND(stockReport?.totalRetailValue || 0)}
              subtitle="Doanh thu dự kiến bán lẻ"
              icon={Boxes}
              color="purple"
            />
          </div>

          {!stockReport || stockReport.items.length === 0 ? (
            <EmptyState
              icon={Boxes}
              title="Chưa có dữ liệu tồn kho"
              description={`Chưa có số liệu tổng hợp kho cho tháng ${selectedMonth}.`}
            />
          ) : (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Mã SKU</th>
                    <th>Tên Hàng Hóa</th>
                    <th>ĐVT</th>
                    <th style={{ textAlign: 'right' }}>Tồn Đầu</th>
                    <th style={{ textAlign: 'right' }}>Nhập Kỳ</th>
                    <th style={{ textAlign: 'right' }}>Xuất Kỳ</th>
                    <th style={{ textAlign: 'right' }}>Tồn Cuối</th>
                    <th style={{ textAlign: 'right' }}>Kho 1</th>
                    <th style={{ textAlign: 'right' }}>Kho 2</th>
                    <th style={{ textAlign: 'right' }}>Kho 3</th>
                    <th style={{ textAlign: 'right' }}>Giá Vốn</th>
                    <th style={{ textAlign: 'right' }}>Thành Tiền (Vốn)</th>
                  </tr>
                </thead>
                <tbody>
                  {stockReport.items.map((it) => (
                    <tr key={it.productId}>
                      <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                        {it.sku}
                      </td>
                      <td style={{ fontWeight: 600 }}>{it.name}</td>
                      <td>{it.uom || 'Cái'}</td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatNumber(it.openingStock)}</td>
                      <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                        +{formatNumber(it.importStock)}
                      </td>
                      <td style={{ textAlign: 'right', color: 'var(--danger)' }} className="mono">
                        -{formatNumber(it.exportStock)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 800 }} className="mono">
                        {formatNumber(it.closingStock)}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatNumber(it.warehouse1?.closingStock ?? 0)}</td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatNumber(it.warehouse2?.closingStock ?? 0)}</td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatNumber(it.warehouse3?.closingStock ?? 0)}</td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatVND(it.unitCost)}</td>
                      <td style={{ textAlign: 'right', fontWeight: 700 }} className="mono">
                        {formatVND(it.totalCostValue)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Debt Report Content */}
      {activeReportTab === 'debts' && (
        <div>
          {/* Debt Summary Cards */}
          <div className="stats-grid">
            <StatCard
              title="PHẢI THU ĐẦU KỲ"
              value={formatVND(debtReport?.totalOpeningReceivable || 0)}
              subtitle="Khách nợ & Đã nộp trước NCC"
              icon={ArrowUpRight}
              color="danger"
            />
            <StatCard
              title="PHẢI TRẢ ĐẦU KỲ"
              value={formatVND(debtReport?.totalOpeningPayable || 0)}
              subtitle="Nợ NCC & KH gửi tiền trước"
              icon={ArrowDownLeft}
              color="warning"
            />
            <StatCard
              title="PHẢI THU CUỐI KỲ"
              value={formatVND(debtReport?.totalClosingReceivable || 0)}
              subtitle="Khách nợ & Đã nộp trước NCC"
              icon={ArrowUpRight}
              color="danger"
            />
            <StatCard
              title="PHẢI TRẢ CUỐI KỲ"
              value={formatVND(debtReport?.totalClosingPayable || 0)}
              subtitle="Nợ NCC & KH gửi tiền trước"
              icon={ArrowDownLeft}
              color="warning"
            />
          </div>

          {!debtReport || debtReport.items.length === 0 ? (
            <EmptyState
              icon={TrendingUp}
              title="Chưa có dữ liệu công nợ"
              description={`Chưa có số liệu tổng hợp công nợ cho tháng ${selectedMonth}.`}
            />
          ) : (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Mã</th>
                    <th>Đối Tác</th>
                    <th>Phân Loại</th>
                    <th style={{ textAlign: 'right' }}>Nợ Đầu Kỳ</th>
                    <th style={{ textAlign: 'right' }}>Phát Sinh Tăng</th>
                    <th style={{ textAlign: 'right' }}>Phát Sinh Giảm</th>
                    <th style={{ textAlign: 'right' }}>Dư Nợ Cuối Kỳ</th>
                    <th style={{ textAlign: 'right' }}>Phải Thu (Khách nợ / Nộp trước NCC)</th>
                    <th style={{ textAlign: 'right' }}>Phải Trả (Nợ NCC / KH gửi trước)</th>
                  </tr>
                </thead>
                <tbody>
                  {debtReport.items.map((it) => (
                    <tr key={`${it.partnerType}-${it.partnerId}`}>
                      <td className="mono" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                        {it.code}
                      </td>
                      <td style={{ fontWeight: 600 }}>{it.name}</td>
                      <td>
                        <span className={`badge badge-${it.partnerType === 'customer' ? 'primary' : 'neutral'}`}>
                          {it.partnerType === 'customer' ? 'Khách hàng' : 'Nhà cung cấp'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">{formatVND(it.openingDebt)}</td>
                      <td style={{ textAlign: 'right', color: 'var(--danger)' }} className="mono">
                        +{formatVND(it.increaseDebt)}
                      </td>
                      <td style={{ textAlign: 'right', color: 'var(--success)' }} className="mono">
                        -{formatVND(it.decreaseDebt)}
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 800 }} className="mono">
                        {formatVND(it.closingDebt)}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: it.receivable > 0 ? 700 : 400, color: it.receivable > 0 ? (it.partnerType === 'customer' ? 'var(--danger)' : 'var(--info-text)') : 'var(--text-muted)' }}>
                          {it.receivable > 0 ? `+${formatVND(it.receivable)}` : '0 ₫'}
                        </div>
                        {it.receivable > 0 && (
                          <div style={{ fontSize: '0.72rem', color: it.partnerType === 'customer' ? 'var(--danger)' : 'var(--info-text)', fontWeight: 600, marginTop: '2px' }}>
                            {it.partnerType === 'customer' ? 'Khách nợ' : 'Nộp trước lấy hàng'}
                          </div>
                        )}
                      </td>
                      <td style={{ textAlign: 'right' }} className="mono">
                        <div style={{ fontWeight: it.payable > 0 ? 700 : 400, color: it.payable > 0 ? (it.partnerType === 'supplier' ? 'var(--warning-text)' : 'var(--success)') : 'var(--text-muted)' }}>
                          {it.payable > 0 ? formatVND(it.payable) : '0 ₫'}
                        </div>
                        {it.payable > 0 && (
                          <div style={{ fontSize: '0.72rem', color: it.partnerType === 'supplier' ? 'var(--warning-text)' : 'var(--success)', fontWeight: 600, marginTop: '2px' }}>
                            {it.partnerType === 'supplier' ? 'Nợ NCC' : 'KH gửi trước'}
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

import { reportsApi } from '../api/endpoints';

/**
 * Frontend Business Logic & Service for Reports & Analytics
 */
export const reportService = {
  /**
   * Process and analyze debt report items
   */
  processDebtReport(reportData) {
    if (!reportData || !reportData.items) {
      return {
        customerItems: [],
        supplierItems: [],
        totals: {
          openingReceivable: 0,
          closingReceivable: 0,
          openingPayable: 0,
          closingPayable: 0,
        },
      };
    }

    const customerItems = reportData.items.filter((it) => it.partnerType === 'customer');
    const supplierItems = reportData.items.filter((it) => it.partnerType === 'supplier');

    return {
      customerItems,
      supplierItems,
      totals: {
        openingReceivable: reportData.totalOpeningReceivable || 0,
        closingReceivable: reportData.totalClosingReceivable || 0,
        openingPayable: reportData.totalOpeningPayable || 0,
        closingPayable: reportData.totalClosingPayable || 0,
      },
    };
  },

  /**
   * Helper to download CSV string as a file
   */
  downloadCSV(filename, csvContent) {
    const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  },

  /**
   * Export stock report to CSV file
   */
  exportStockReportCSV(stockReport, month) {
    if (!stockReport || !Array.isArray(stockReport.items) || stockReport.items.length === 0) {
      throw new Error('Không có dữ liệu tồn kho để xuất');
    }

    const headers = [
      'Mã SKU',
      'Tên sản phẩm',
      'ĐVT',
      'Tồn đầu kỳ',
      'Nhập trong kỳ',
      'Xuất trong kỳ',
      'Tồn cuối kỳ',
      'Kho 1',
      'Kho 2',
      'Kho 3',
      'Giá vốn',
      'Thành tiền tồn kho',
    ];

    const rows = stockReport.items.map((it) => [
      `"${it.sku || ''}"`,
      `"${it.name || ''}"`,
      `"${it.uom || ''}"`,
      Number(it.openingStock || 0),
      Number(it.importStock || 0),
      Number(it.exportStock || 0),
      Number(it.closingStock || 0),
      Number(it.warehouse1?.closingStock ?? 0),
      Number(it.warehouse2?.closingStock ?? 0),
      Number(it.warehouse3?.closingStock ?? 0),
      Number(it.unitCost || 0),
      Number(it.closingStock || 0) * Number(it.unitCost || 0),
    ]);

    const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    this.downloadCSV(`Bao_Cao_Ton_Kho_${month}.csv`, csvContent);
  },

  /**
   * Export debt report to CSV file
   */
  exportDebtReportCSV(debtReport, month) {
    if (!debtReport || !Array.isArray(debtReport.items) || debtReport.items.length === 0) {
      throw new Error('Không có dữ liệu công nợ để xuất');
    }

    const headers = [
      'Mã',
      'Tên đối tác',
      'Phân loại',
      'Nợ đầu kỳ',
      'Phát sinh tăng',
      'Phát sinh giảm',
      'Dư nợ cuối kỳ',
      'Phải thu (Khách nợ / Nộp trước NCC)',
      'Phải trả (Nợ NCC / KH gửi trước)',
    ];

    const rows = debtReport.items.map((it) => [
      `"${it.code || ''}"`,
      `"${it.name || ''}"`,
      `"${it.partnerType === 'customer' ? 'Khách hàng' : 'Nhà cung cấp'}"`,
      Number(it.openingDebt || 0),
      Number(it.increaseDebt || 0),
      Number(it.decreaseDebt || 0),
      Number(it.closingDebt || 0),
      Number(it.receivable || 0),
      Number(it.payable || 0),
    ]);

    const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    this.downloadCSV(`Bao_Cao_Cong_No_${month}.csv`, csvContent);
  },

  // ================= API Wrappers =================
  async getStockReport(month) {
    return await reportsApi.getStockReport(month);
  },

  async getDebtReport(month) {
    return await reportsApi.getDebtReport(month);
  },

  async getDashboardSummary() {
    return await reportsApi.getDashboardSummary();
  },

  async getSalesProfit(month) {
    return await reportsApi.getSalesProfit(month);
  },

  async getInventoryValuation() {
    return await reportsApi.getInventoryValuation();
  },

  async getCashFlow(month) {
    return await reportsApi.getCashFlow(month);
  },
};

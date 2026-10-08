import {
  productsApi,
  customersApi,
  suppliersApi,
  exportsApi,
  importsApi,
  receiptsApi,
  paymentsApi,
  reportsApi,
} from '../api/endpoints';
import { WAREHOUSES } from '../utils/constants';

/**
 * Frontend Business Logic & Service for Dashboard
 */
export const dashboardService = {
  /**
   * Fetch and calculate all summary data, metrics, warehouse stats, and recent activities
   * @param {string} month YYYY-MM
   */
  async getDashboardData(month) {
    const [
      prodsRes,
      custsRes,
      suppsRes,
      exportsRes,
      importsRes,
      receiptsRes,
      paymentsRes,
    ] = await Promise.allSettled([
      productsApi.getAll(),
      customersApi.getAll(),
      suppliersApi.getAll(),
      exportsApi.getAll({ month }),
      importsApi.getAll({ month }),
      receiptsApi.getAll(),
      paymentsApi.getAll(),
    ]);

    const products = prodsRes.status === 'fulfilled' && Array.isArray(prodsRes.value) ? prodsRes.value : [];
    const customers = custsRes.status === 'fulfilled' && Array.isArray(custsRes.value) ? custsRes.value : [];
    const suppliers = suppsRes.status === 'fulfilled' && Array.isArray(suppsRes.value) ? suppsRes.value : [];
    const recentExports = exportsRes.status === 'fulfilled' && Array.isArray(exportsRes.value) ? exportsRes.value : [];
    const recentImports = importsRes.status === 'fulfilled' && Array.isArray(importsRes.value) ? importsRes.value : [];
    const receipts = receiptsRes.status === 'fulfilled' && Array.isArray(receiptsRes.value) ? receiptsRes.value : [];
    const payments = paymentsRes.status === 'fulfilled' && Array.isArray(paymentsRes.value) ? paymentsRes.value : [];

    let stockReport = null;
    try {
      stockReport = await reportsApi.getStockReport(month);
    } catch (err) {
      console.warn('Stock report load error in dashboardService:', err);
    }

    // 1. Stock Computations
    const totalStockWarehouse1 = products.reduce((acc, p) => acc + Number(p.stockWarehouse1 || 0), 0);
    const totalStockWarehouse2 = products.reduce((acc, p) => acc + Number(p.stockWarehouse2 || 0), 0);
    const totalStockWarehouse3 = products.reduce((acc, p) => acc + Number(p.stockWarehouse3 || 0), 0);
    const totalAllStock = totalStockWarehouse1 + totalStockWarehouse2 + totalStockWarehouse3;

    // Valuation
    const totalStockValue = stockReport?.totalCostValue ?? products.reduce((acc, p) => {
      const stock = Number(p.totalStock || (Number(p.stockWarehouse1 || 0) + Number(p.stockWarehouse2 || 0) + Number(p.stockWarehouse3 || 0)));
      return acc + (stock * Number(p.unitCost || 0));
    }, 0);

    // 2. Debts (2-way logic)
    // Receivables: Khách nợ (> 0) + Mình nộp trước NCC (> 0)
    const customerDebt = customers.reduce((acc, c) => {
      const d = Number(c.debt || 0);
      return d > 0 ? acc + d : acc;
    }, 0);

    // Payables: Nợ NCC (< 0) + Khách gửi trước (< 0)
    const supplierDebt = suppliers.reduce((acc, s) => {
      const d = Number(s.debt || 0);
      return d < 0 ? acc + Math.abs(d) : acc;
    }, 0);

    // 3. Cashflow
    const totalReceivedMonth = receipts.reduce((acc, r) => acc + Number(r.amount || 0), 0);
    const totalPaidMonth = payments
      .filter((p) => p.status !== 'cancelled')
      .reduce((acc, p) => acc + Number(p.amount || 0), 0);
    const netCashflow = totalReceivedMonth - totalPaidMonth;

    // 4. Low Stock Alerts
    const lowStockProducts = products.filter(
      (p) => Number(p.totalStock || 0) <= Number(p.reorderPoint || 0) && Number(p.reorderPoint || 0) > 0
    );

    // 5. Warehouse breakdown
    const warehouseStats = WAREHOUSES.map((wh) => {
      let stock = 0;
      let count = 0;

      products.forEach((p) => {
        let whStock = 0;
        if (wh.id === 'warehouse1') whStock = Number(p.stockWarehouse1 || 0);
        else if (wh.id === 'warehouse2') whStock = Number(p.stockWarehouse2 || 0);
        else if (wh.id === 'warehouse3') whStock = Number(p.stockWarehouse3 || 0);

        if (whStock > 0) {
          stock += whStock;
          count += 1;
        }
      });

      const percent = totalAllStock > 0 ? Math.round((stock / totalAllStock) * 100) : 0;
      return {
        ...wh,
        stock,
        productCount: count,
        percent,
      };
    });

    // 6. Recent activities (combined exports and imports, sorted by date desc)
    const combinedActivities = [
      ...recentExports.map((e) => ({
        id: `exp-${e.id}`,
        type: 'export',
        title: `Xuất bán #${e.voucherNumber}`,
        subtitle: `${e.customerName || 'Khách hàng'} • Kho ${e.warehouse}`,
        amount: Number(e.totalSale || 0),
        date: e.date,
        status: e.status,
      })),
      ...recentImports.map((i) => ({
        id: `imp-${i.id}`,
        type: 'import',
        title: `Nhập kho #${i.voucherNumber}`,
        subtitle: `${i.supplierName || 'Nhà cung cấp'} • Kho ${i.warehouse}`,
        amount: Number(i.totalCost || 0),
        date: i.date,
        status: i.status,
      })),
    ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 6);

    return {
      metrics: {
        totalAllStock,
        totalStockValue,
        totalReceivables: customerDebt,
        totalPayables: supplierDebt,
        totalReceivedMonth,
        totalPaidMonth,
        netCashflow,
        productCount: products.length,
        customerCount: customers.length,
        supplierCount: suppliers.length,
      },
      warehouseStats,
      lowStockProducts,
      recentActivities: combinedActivities,
      recentExports: recentExports.slice(0, 5),
      recentImports: recentImports.slice(0, 5),
      products,
      customers,
      suppliers,
      stockReport,
    };
  },
};

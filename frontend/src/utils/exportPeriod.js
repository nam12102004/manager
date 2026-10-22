import { getCurrentMonthStr, getCurrentDateStr } from './formatters';

export const PERIOD_MODES = [
  { value: 'day', label: 'Trong 1 ngày' },
  { value: 'dayRange', label: 'Từ ngày đến ngày' },
  { value: 'month', label: 'Theo tháng' },
  { value: 'monthRange', label: 'Từ tháng đến tháng' },
  { value: 'year', label: 'Theo năm' },
  { value: 'all', label: 'Toàn bộ thời gian' },
];

export const GRANULARITIES = [
  { value: 'day', label: 'Theo ngày' },
  { value: 'week', label: 'Theo tuần' },
  { value: 'month', label: 'Theo tháng' },
];

export const REPORT_TYPES = [
  {
    value: 'sales',
    label: 'Xuất bán',
    desc: 'Doanh số và số lượng hàng xuất',
    defaultGroupBy: 'product',
    allowedGroupBys: ['product', 'product_partner', 'partner', 'partner_product', 'warehouse_product', 'employee', 'employee_product', 'employee_partner'],
  },
  {
    value: 'employee_sales',
    label: 'Doanh số nhân viên',
    desc: 'Doanh số, số lượng và chi tiết mặt hàng theo nhân viên',
    defaultGroupBy: 'employee',
    allowedGroupBys: ['employee', 'employee_product', 'employee_partner', 'product'],
  },
  {
    value: 'purchases',
    label: 'Nhập hàng',
    desc: 'Tiền nhập và số lượng hàng nhập',
    defaultGroupBy: 'product',
    allowedGroupBys: ['product', 'product_partner', 'partner', 'partner_product', 'warehouse_product'],
  },
  {
    value: 'inventory',
    label: 'Tồn kho hiện tại',
    desc: 'Số lượng và giá trị hàng tồn kho thực tế',
    defaultGroupBy: 'product',
    allowedGroupBys: ['product', 'warehouse_product'],
  },
  {
    value: 'inout',
    label: 'Nhập xuất sản phẩm',
    desc: 'Số lượng nhập, xuất và chênh lệch',
    defaultGroupBy: 'product',
    allowedGroupBys: ['product', 'warehouse_product', 'product_partner'],
  },
  {
    value: 'cashflow',
    label: 'Thu chi',
    desc: 'Tổng thu, tổng chi và chênh lệch',
    defaultGroupBy: 'partner',
    allowedGroupBys: ['partner'],
  },
  {
    value: 'debt',
    label: 'Công nợ theo kỳ',
    desc: 'Nợ đầu kỳ (ĐK) và nợ cuối kỳ (CK)',
    defaultGroupBy: 'partner',
    allowedGroupBys: ['partner'],
  },
];

export const GROUP_BY_OPTIONS = [
  { value: 'product', label: 'Theo sản phẩm' },
  { value: 'product_partner', label: 'Theo sản phẩm và đối tác' },
  { value: 'partner', label: 'Theo đối tác' },
  { value: 'partner_product', label: 'Theo đối tác và sản phẩm' },
  { value: 'warehouse_product', label: 'Theo kho và sản phẩm' },
  { value: 'employee', label: 'Theo nhân viên phụ trách' },
  { value: 'employee_product', label: 'Theo nhân viên và sản phẩm' },
  { value: 'employee_partner', label: 'Theo nhân viên và khách hàng' },
];

/**
 * Returns allowed granularities for a given period mode and parameters
 */
export function getAllowedGranularities(periodMode, params = {}) {
  switch (periodMode) {
    case 'day':
      return [{ value: 'day', label: 'Theo ngày' }];
    case 'year':
    case 'all':
      return [
        { value: 'week', label: 'Theo tuần' },
        { value: 'month', label: 'Theo tháng' },
      ];
    case 'monthRange': {
      const { fromMonth, toMonth } = params;
      if (fromMonth && toMonth) {
        const [y1, m1] = fromMonth.split('-').map(Number);
        const [y2, m2] = toMonth.split('-').map(Number);
        const diffMonths = (y2 - y1) * 12 + (m2 - m1) + 1;
        if (diffMonths > 12) {
          return [
            { value: 'week', label: 'Theo tuần' },
            { value: 'month', label: 'Theo tháng' },
          ];
        }
      }
      return GRANULARITIES;
    }
    case 'dayRange': {
      const { fromDate, toDate } = params;
      if (fromDate && toDate) {
        const d1 = new Date(fromDate);
        const d2 = new Date(toDate);
        const diffDays = Math.ceil((d2 - d1) / (1000 * 60 * 60 * 24)) + 1;
        if (diffDays > 365) {
          return [
            { value: 'week', label: 'Theo tuần' },
            { value: 'month', label: 'Theo tháng' },
          ];
        }
      }
      return GRANULARITIES;
    }
    case 'month':
    default:
      return GRANULARITIES;
  }
}

/**
 * Estimate column bucket count
 */
export function estimateBucketCount(periodMode, granularity, params = {}) {
  if (periodMode === 'day') return 1;

  if (periodMode === 'month') {
    if (granularity === 'day') return 31;
    if (granularity === 'week') return 5;
    return 1;
  }

  if (periodMode === 'year') {
    if (granularity === 'week') return 53;
    if (granularity === 'month') return 12;
    return 365;
  }

  if (periodMode === 'all') {
    if (granularity === 'month') return 36;
    if (granularity === 'week') return 150;
    return 1000;
  }

  if (periodMode === 'dayRange') {
    const { fromDate, toDate } = params;
    if (!fromDate || !toDate) return 30;
    const d1 = new Date(fromDate);
    const d2 = new Date(toDate);
    const diffDays = Math.max(1, Math.ceil((d2 - d1) / (1000 * 60 * 60 * 24)) + 1);
    if (granularity === 'day') return diffDays;
    if (granularity === 'week') return Math.ceil(diffDays / 7);
    return Math.max(1, Math.ceil(diffDays / 30));
  }

  if (periodMode === 'monthRange') {
    const { fromMonth, toMonth } = params;
    if (!fromMonth || !toMonth) return 12;
    const [y1, m1] = fromMonth.split('-').map(Number);
    const [y2, m2] = toMonth.split('-').map(Number);
    const diffMonths = Math.max(1, (y2 - y1) * 12 + (m2 - m1) + 1);
    if (granularity === 'month') return diffMonths;
    if (granularity === 'week') return diffMonths * 4.3;
    return diffMonths * 30.5;
  }

  return 31;
}

/**
 * Format Period description in Vietnamese
 */
export function formatPeriodDescription(periodMode, params = {}) {
  switch (periodMode) {
    case 'day':
      return params.day || getCurrentDateStr();
    case 'dayRange':
      return `${params.fromDate || ''} đến ${params.toDate || ''}`;
    case 'month':
      return `Tháng ${params.month || getCurrentMonthStr()}`;
    case 'monthRange':
      return `Tháng ${params.fromMonth || ''} đến ${params.toMonth || ''}`;
    case 'year':
      return `Năm ${params.year || new Date().getFullYear()}`;
    case 'all':
      return 'Toàn bộ lịch sử';
    default:
      return 'Không xác định';
  }
}

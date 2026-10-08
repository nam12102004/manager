export const WAREHOUSES = [
  { id: 'warehouse1', name: 'Kho 1 (Mặc định)', shortName: 'Kho 1', color: 'primary' },
  { id: 'warehouse2', name: 'Kho 2', shortName: 'Kho 2', color: 'info' },
  { id: 'warehouse3', name: 'Kho 3', shortName: 'Kho 3', color: 'purple' },
];

export const WAREHOUSE_MAP = {
  warehouse1: 'Kho 1',
  warehouse2: 'Kho 2',
  warehouse3: 'Kho 3',
};

export const PAYMENT_METHODS = [
  { id: 'cash', label: 'Tiền mặt' },
  { id: 'bank_transfer', label: 'Chuyển khoản ngân hàng' },
  { id: 'card', label: 'Thẻ tín dụng / POS' },
  { id: 'other', label: 'Khác' },
];

export const VOUCHER_STATUSES = {
  active: { label: 'Đang hoạt động', color: 'success' },
  confirmed: { label: 'Đã xác nhận', color: 'info' },
  cancelled: { label: 'Đã hủy', color: 'danger' },
};

export const STOCK_ADJUST_REASONS = [
  'Kiểm kê định kỳ phát hiện thừa/thiếu',
  'Hàng hóa bị hư hỏng, hết hạn',
  'Điều chuyển nội bộ',
  'Hàng mẫu / Khuyến mãi',
  'Lỗi nhập liệu trước đó',
  'Khác',
];

export const DEBT_ADJUST_REASONS = [
  'Đối soát định kỳ chênh lệch',
  'Chiết khấu bổ sung cuối kỳ',
  'Khấu trừ hư hỏng / hoàn trả',
  'Bù trừ công nợ đối ứng',
  'Xóa nợ khó đòi',
  'Lỗi nhập liệu trước đó',
  'Khác',
];

import api from './client';

// ==========================================
// 1. Auth API
// ==========================================
export const authApi = {
  login: async (credentials) => {
    const res = await api.post('/auth/login', credentials);
    return res.data; // LoginResponseDto: { token, username, role }
  },
};

// ==========================================
// 2. Customers API
// ==========================================
export const customersApi = {
  getAll: async (q = '') => {
    const res = await api.get('/customers', { params: { q: q || undefined } });
    return res.data; // List<CustomerDto>
  },
  getById: async (id) => {
    const res = await api.get(`/customers/${id}`);
    return res.data; // CustomerDto
  },
  create: async (data) => {
    const res = await api.post('/customers', data);
    return res.data; // CustomerDto
  },
  update: async (id, data) => {
    const res = await api.put(`/customers/${id}`, data);
    return res.data; // CustomerDto
  },
  getDebtHistory: async (id) => {
    const res = await api.get(`/customers/${id}/debt-history`);
    return res.data; // List<CustomerDebtHistoryDto>
  },
  adjustDebt: async (id, data) => {
    const res = await api.post(`/customers/${id}/debt-adjust`, data);
    return res.data; // boolean
  },
};

// ==========================================
// 3. Suppliers API
// ==========================================
export const suppliersApi = {
  getAll: async (q = '') => {
    const res = await api.get('/suppliers', { params: { q: q || undefined } });
    return res.data; // List<SupplierDto>
  },
  getById: async (id) => {
    const res = await api.get(`/suppliers/${id}`);
    return res.data; // SupplierDto
  },
  create: async (data) => {
    const res = await api.post('/suppliers', data);
    return res.data; // SupplierDto
  },
  update: async (id, data) => {
    const res = await api.put(`/suppliers/${id}`, data);
    return res.data; // SupplierDto
  },
  getDebtHistory: async (id) => {
    const res = await api.get(`/suppliers/${id}/debt-history`);
    return res.data; // List<SupplierDebtHistoryDto>
  },
  adjustDebt: async (id, data) => {
    const res = await api.post(`/suppliers/${id}/debt-adjust`, data);
    return res.data; // boolean
  },
};

// ==========================================
// 4. Products API
// ==========================================
export const productsApi = {
  getAll: async ({ q = '', supplierId = null } = {}) => {
    const params = {};
    if (q) params.q = q;
    if (supplierId) params.supplierId = supplierId;
    const res = await api.get('/products', { params });
    return res.data; // List<ProductDto>
  },
  getById: async (id) => {
    const res = await api.get(`/products/${id}`);
    return res.data; // ProductDto
  },
  create: async (data) => {
    const res = await api.post('/products', data);
    return res.data; // ProductDto
  },
  update: async (id, data) => {
    const res = await api.put(`/products/${id}`, data);
    return res.data; // ProductDto
  },
  adjustStock: async (id, data) => {
    const res = await api.post(`/products/${id}/stock-adjust`, data);
    return res.data; // boolean
  },
  getStockHistory: async (id, month = '') => {
    const params = {};
    if (month) params.month = month;
    const res = await api.get(`/products/${id}/stock-history`, { params });
    return res.data; // List<StockHistoryDto>
  },
};

// ==========================================
// 5. Exports API (Bán hàng / Xuất kho)
// ==========================================
export const exportsApi = {
  getAll: async ({ customerId = null, month = '' } = {}) => {
    const params = {};
    if (customerId) params.customerId = customerId;
    if (month) params.month = month;
    const res = await api.get('/exports', { params });
    return res.data; // List<ExportVoucherDto>
  },
  getById: async (id) => {
    const res = await api.get(`/exports/${id}`);
    return res.data; // ExportVoucherDto
  },
  create: async (data) => {
    const res = await api.post('/exports', data);
    return res.data; // ExportVoucherDto
  },
  updateStatus: async (id, action = 'cancel') => {
    const res = await api.patch(`/exports/${id}/status`, { action });
    return res.data; // boolean
  },
  delete: async (id) => {
    const res = await api.delete(`/exports/${id}`);
    return res.data; // boolean
  },
};

// ==========================================
// 6. Imports API (Mua hàng / Nhập kho)
// ==========================================
export const importsApi = {
  getAll: async ({ supplierId = null, month = '' } = {}) => {
    const params = {};
    if (supplierId) params.supplierId = supplierId;
    if (month) params.month = month;
    const res = await api.get('/imports', { params });
    return res.data; // List<ImportVoucherDto>
  },
  getById: async (id) => {
    const res = await api.get(`/imports/${id}`);
    return res.data; // ImportVoucherDto
  },
  create: async (data) => {
    const res = await api.post('/imports', data);
    return res.data; // ImportVoucherDto
  },
  updateStatus: async (id, action = 'cancel') => {
    const res = await api.patch(`/imports/${id}/status`, { action });
    return res.data; // boolean
  },
  delete: async (id) => {
    const res = await api.delete(`/imports/${id}`);
    return res.data; // boolean
  },
};

// ==========================================
// 7. Receipts API (Phiếu Thu)
// ==========================================
export const receiptsApi = {
  getAll: async ({ customerId = null, supplierId = null, q = '' } = {}) => {
    const params = {};
    if (customerId) params.customerId = customerId;
    if (supplierId) params.supplierId = supplierId;
    if (q) params.q = q;
    const res = await api.get('/receipts', { params });
    return res.data; // List<ReceiptDto>
  },
  getById: async (id) => {
    const res = await api.get(`/receipts/${id}`);
    return res.data; // ReceiptDto
  },
  create: async (data) => {
    const res = await api.post('/receipts', data);
    return res.data; // ReceiptDto
  },
  delete: async (id) => {
    const res = await api.delete(`/receipts/${id}`);
    return res.data; // boolean
  },
};

// ==========================================
// 8. Payments API (Phiếu Chi)
// ==========================================
export const paymentsApi = {
  getAll: async ({ supplierId = null, customerId = null, q = '' } = {}) => {
    const params = {};
    if (supplierId) params.supplierId = supplierId;
    if (customerId) params.customerId = customerId;
    if (q) params.q = q;
    const res = await api.get('/payments', { params });
    return res.data; // List<PaymentDto>
  },
  getById: async (id) => {
    const res = await api.get(`/payments/${id}`);
    return res.data; // PaymentDto
  },
  create: async (data) => {
    const res = await api.post('/payments', data);
    return res.data; // PaymentDto
  },
  updateStatus: async (id, action = 'cancel') => {
    const res = await api.patch(`/payments/${id}/status`, { action });
    return res.data; // boolean
  },
  delete: async (id) => {
    const res = await api.delete(`/payments/${id}`);
    return res.data; // boolean
  },
};

// ==========================================
// 9. Reports API (Báo cáo động)
// ==========================================
export const reportsApi = {
  getStockReport: async (month = '') => {
    const params = {};
    if (month) params.month = month;
    const res = await api.get('/reports/stock', { params });
    return res.data; // StockReportResponseDto
  },
  getDebtReport: async (month = '') => {
    const params = {};
    if (month) params.month = month;
    const res = await api.get('/reports/debts', { params });
    return res.data; // DebtReportResponseDto
  },
};

// ==========================================
// 10. Owners API (Cấu hình Chủ tài khoản & Cửa hàng)
// ==========================================
export const ownersApi = {
  get: async () => {
    const res = await api.get('/owners');
    return res.data; // OwnerDto
  },
  update: async (data) => {
    const res = await api.put('/owners', data);
    return res.data; // OwnerDto
  },
};

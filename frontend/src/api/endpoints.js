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
  getAll: async (params = {}) => {
    let queryParams = {};
    if (typeof params === 'string') {
      if (params) queryParams.q = params;
    } else if (params && typeof params === 'object') {
      queryParams = { ...params };
    }
    const res = await api.get('/customers', { params: queryParams });
    return res.data; // List<CustomerDto> or CustomerPagedResult
  },
  getRegions: async () => {
    const res = await api.get('/customers/regions');
    return res.data; // List<string>
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
  getDebtHistory: async (id, month) => {
    const res = await api.get(`/customers/${id}/debt-history`, { params: { month: month || undefined } });
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
  getAll: async (params = {}) => {
    let queryParams = {};
    if (typeof params === 'string') {
      if (params) queryParams.q = params;
    } else if (params && typeof params === 'object') {
      queryParams = { ...params };
    }
    const res = await api.get('/suppliers', { params: queryParams });
    return res.data; // List<SupplierDto> or SupplierPagedResult
  },
  getRegions: async () => {
    const res = await api.get('/suppliers/regions');
    return res.data; // List<string>
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
  getDebtHistory: async (id, month) => {
    const res = await api.get(`/suppliers/${id}/debt-history`, { params: { month: month || undefined } });
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
  getAll: async (params = {}) => {
    let queryParams = {};
    if (typeof params === 'string') {
      if (params) queryParams.q = params;
    } else if (params && typeof params === 'object') {
      queryParams = { ...params };
    }
    const res = await api.get('/products', { params: queryParams });
    return res.data; // List<ProductDto> or ProductPagedResult
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
  getCategories: async () => {
    const res = await api.get('/products/categories');
    return res.data; // List<string>
  },
};

// ==========================================
// 5. Exports API (Bán hàng / Xuất kho)
// ==========================================
export const exportsApi = {
  getAll: async (params = {}) => {
    const res = await api.get('/exports', { params: params || {} });
    return res.data; // List<ExportVoucherDto> or ExportPagedResult
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
  getAll: async (params = {}) => {
    const res = await api.get('/imports', { params: params || {} });
    return res.data; // List<ImportVoucherDto> or ImportPagedResult
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
  getAll: async (params = {}) => {
    const res = await api.get('/receipts', { params: params || {} });
    return res.data; // List<ReceiptDto> or ReceiptPagedResult
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
  getAll: async (params = {}) => {
    const res = await api.get('/payments', { params: params || {} });
    return res.data; // List<PaymentDto> or PaymentPagedResult
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

// ==========================================
// 11. Audit & Login History API
// ==========================================
export const auditApi = {
  getLogs: async (params = {}) => {
    const res = await api.get('/audit-logs', { params });
    return res.data; // List<AuditLogDto>
  },
  createLog: async (data) => {
    const res = await api.post('/audit-logs', data);
    return res.data; // AuditLogDto
  },
  getLoginHistory: async (params = {}) => {
    const res = await api.get('/audit-logs/login-history', { params });
    return res.data; // List<LoginHistoryDto>
  },
  createLoginHistory: async (data) => {
    const res = await api.post('/audit-logs/login-history', data);
    return res.data; // LoginHistoryDto
  },
};

// ==========================================
// 12. Users API (Quản lý tài khoản & Phân quyền)
// ==========================================
export const usersApi = {
  getAll: async () => {
    const res = await api.get('/users');
    return res.data; // List<UserDto>
  },
  getById: async (id) => {
    const res = await api.get(`/users/${id}`);
    return res.data; // UserDto
  },
  create: async (data) => {
    const res = await api.post('/users', data);
    return res.data; // UserDto
  },
  changePassword: async (id, newPassword) => {
    const res = await api.put(`/users/${id}/password`, { newPassword });
    return res.data; // boolean
  },
  updateRole: async (id, role) => {
    const res = await api.put(`/users/${id}/role`, { role });
    return res.data; // boolean
  },
  delete: async (id) => {
    const res = await api.delete(`/users/${id}`);
    return res.data; // boolean
  },
};


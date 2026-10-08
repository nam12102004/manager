import { receiptsApi, paymentsApi, customersApi, suppliersApi, ownersApi } from '../api/endpoints';

/**
 * Frontend Business Logic & Service for Cash Book (Thu - Chi & Sổ Quỹ)
 */
export const cashBookService = {
  /**
   * Validate receipt voucher form data
   */
  validateReceipt(formData) {
    const amount = Number(formData.amount || 0);
    if (!formData.partnerId && !formData.customerId && !formData.supplierId) {
      return { isValid: false, message: 'Vui lòng chọn đối tượng nộp tiền' };
    }
    if (isNaN(amount) || amount <= 0) {
      return { isValid: false, message: 'Số tiền thu phải lớn hơn 0' };
    }
    return { isValid: true };
  },

  /**
   * Validate payment voucher form data
   */
  validatePayment(formData) {
    const amount = Number(formData.amount || 0);
    if (!formData.partnerId && !formData.supplierId && !formData.customerId) {
      return { isValid: false, message: 'Vui lòng chọn đối tượng nhận tiền' };
    }
    if (isNaN(amount) || amount <= 0) {
      return { isValid: false, message: 'Số tiền chi phải lớn hơn 0' };
    }
    return { isValid: true };
  },

  /**
   * Compute cash flow statistics: Total Receipts, Total Payments, Net Fund, Breakdown by Method
   */
  calculateCashFlowStats(receipts = [], payments = []) {
    const validPayments = payments.filter((p) => p.status !== 'cancelled');

    const totalReceipts = receipts.reduce((acc, r) => acc + Number(r.amount || 0), 0);
    const totalPayments = validPayments.reduce((acc, p) => acc + Number(p.amount || 0), 0);
    const netFund = totalReceipts - totalPayments;

    // Breakdown by payment method
    const methodBreakdown = {
      cash: { receipts: 0, payments: 0, net: 0 },
      bank_transfer: { receipts: 0, payments: 0, net: 0 },
      card: { receipts: 0, payments: 0, net: 0 },
    };

    receipts.forEach((r) => {
      const m = r.method || 'cash';
      if (methodBreakdown[m]) {
        methodBreakdown[m].receipts += Number(r.amount || 0);
      }
    });

    validPayments.forEach((p) => {
      const m = p.method || 'cash';
      if (methodBreakdown[m]) {
        methodBreakdown[m].payments += Number(p.amount || 0);
      }
    });

    Object.keys(methodBreakdown).forEach((k) => {
      methodBreakdown[k].net = methodBreakdown[k].receipts - methodBreakdown[k].payments;
    });

    return {
      totalReceipts,
      totalPayments,
      netFund,
      receiptCount: receipts.length,
      paymentCount: validPayments.length,
      cancelledPaymentCount: payments.length - validPayments.length,
      methodBreakdown,
    };
  },

  // ================= Receipt API Wrappers =================
  async getReceipts(params) {
    return await receiptsApi.getAll(params);
  },

  async getReceiptById(id) {
    return await receiptsApi.getById(id);
  },

  async createReceipt(formData) {
    const validation = this.validateReceipt(formData);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }

    const payload = {
      customerId: formData.partnerType === 'customer' ? Number(formData.partnerId) : formData.customerId,
      supplierId: formData.partnerType === 'supplier' ? Number(formData.partnerId) : formData.supplierId,
      amount: Number(formData.amount),
      method: formData.method || 'cash',
      notes: formData.notes?.trim() || undefined,
      date: formData.date ? new Date(formData.date).toISOString() : new Date().toISOString(),
    };

    return await receiptsApi.create(payload);
  },

  async deleteReceipt(id) {
    return await receiptsApi.delete(id);
  },

  // ================= Payment API Wrappers =================
  async getPayments(params) {
    return await paymentsApi.getAll(params);
  },

  async getPaymentById(id) {
    return await paymentsApi.getById(id);
  },

  async createPayment(formData) {
    const validation = this.validatePayment(formData);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }

    const payload = {
      supplierId: formData.partnerType === 'supplier' ? Number(formData.partnerId) : formData.supplierId,
      customerId: formData.partnerType === 'customer' ? Number(formData.partnerId) : formData.customerId,
      amount: Number(formData.amount),
      method: formData.method || 'bank_transfer',
      notes: formData.notes?.trim() || undefined,
      date: formData.date ? new Date(formData.date).toISOString() : new Date().toISOString(),
    };

    return await paymentsApi.create(payload);
  },

  async updatePaymentStatus(id, action) {
    return await paymentsApi.updateStatus(id, action);
  },

  async deletePayment(id) {
    return await paymentsApi.delete(id);
  },

  async getDependencies() {
    const [cRes, sRes, oRes] = await Promise.allSettled([
      customersApi.getAll(),
      suppliersApi.getAll(),
      ownersApi.get(),
    ]);

    return {
      customers: cRes.status === 'fulfilled' && Array.isArray(cRes.value) ? cRes.value : [],
      suppliers: sRes.status === 'fulfilled' && Array.isArray(sRes.value) ? sRes.value : [],
      ownerInfo: oRes.status === 'fulfilled' ? oRes.value : null,
    };
  },
};

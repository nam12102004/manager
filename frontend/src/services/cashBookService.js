import { receiptsApi, paymentsApi, customersApi, suppliersApi, ownersApi } from '../api/endpoints';
import { auditService } from './auditService';

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

    const result = await receiptsApi.create(payload);
    auditService.logAction({
      action: 'CREATE',
      entityName: 'Receipt',
      entityId: result?.receiptNumber || result?.id || 'Mới',
      entityDisplayName: `Phiếu thu #${result?.receiptNumber || result?.id}`,
      details: `Lập phiếu thu tiền: ${Number(formData.amount).toLocaleString()}₫ (Hình thức: ${formData.method === 'bank_transfer' ? 'Chuyển khoản' : 'Tiền mặt'})`,
    });
    return result;
  },

  async deleteReceipt(id) {
    const result = await receiptsApi.delete(id);
    auditService.logAction({
      action: 'DELETE',
      entityName: 'Receipt',
      entityId: String(id),
      entityDisplayName: `Phiếu thu #${id}`,
      details: `Xóa phiếu thu tiền #${id}`,
    });
    return result;
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

    const result = await paymentsApi.create(payload);
    auditService.logAction({
      action: 'CREATE',
      entityName: 'Payment',
      entityId: result?.paymentNumber || result?.id || 'Mới',
      entityDisplayName: `Phiếu chi #${result?.paymentNumber || result?.id}`,
      details: `Lập phiếu chi tiền: ${Number(formData.amount).toLocaleString()}₫ (Hình thức: ${formData.method === 'bank_transfer' ? 'Chuyển khoản' : 'Tiền mặt'})`,
    });
    return result;
  },

  async updatePaymentStatus(id, action) {
    const result = await paymentsApi.updateStatus(id, action);
    auditService.logAction({
      action: action === 'cancel' ? 'CANCEL' : 'STATUS_CHANGE',
      entityName: 'Payment',
      entityId: String(id),
      entityDisplayName: `Phiếu chi #${id}`,
      details: `${action === 'cancel' ? 'Hủy' : 'Đổi trạng thái'} phiếu chi #${id}`,
    });
    return result;
  },

  async deletePayment(id) {
    const result = await paymentsApi.delete(id);
    auditService.logAction({
      action: 'DELETE',
      entityName: 'Payment',
      entityId: String(id),
      entityDisplayName: `Phiếu chi #${id}`,
      details: `Xóa vĩnh viễn phiếu chi #${id}`,
    });
    return result;
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

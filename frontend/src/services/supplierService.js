import { suppliersApi } from '../api/endpoints';

/**
 * Frontend Business Logic & Service for Suppliers & Payable Debt Management
 */
export const supplierService = {
  /**
   * Validate supplier creation/update form
   */
  validateSupplier(formData) {
    const errors = {};
    if (!formData.name || !formData.name.trim()) {
      errors.name = 'Tên nhà cung cấp không được để trống';
    }
    if (formData.email && formData.email.trim()) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(formData.email.trim())) {
        errors.email = 'Định dạng email không hợp lệ';
      }
    }
    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  },

  /**
   * Validate manual debt adjustment for supplier
   */
  validateDebtAdjustment({ delta, newDebt, reason }) {
    if (newDebt === undefined && (delta === undefined || Number(delta) === 0)) {
      return { isValid: false, message: 'Vui lòng nhập số nợ mới hoặc mức điều chỉnh nợ khác 0' };
    }
    if (!reason || !reason.trim()) {
      return { isValid: false, message: 'Vui lòng chọn hoặc nhập lý do điều chỉnh' };
    }
    return { isValid: true };
  },

  /**
   * Format supplier payload for API
   */
  formatSupplierPayload(formData) {
    let phonesJson = '';
    if (Array.isArray(formData.phones)) {
      phonesJson = JSON.stringify(formData.phones.filter(Boolean));
    } else if (typeof formData.phonesJson === 'string') {
      phonesJson = formData.phonesJson.trim();
    }

    let addressesJson = '';
    if (Array.isArray(formData.addresses)) {
      addressesJson = JSON.stringify(formData.addresses.filter(Boolean));
    } else if (typeof formData.addressesJson === 'string') {
      addressesJson = formData.addressesJson.trim();
    }

    return {
      name: formData.name.trim(),
      code: formData.code?.trim() || undefined,
      contactName: formData.contactName?.trim() || undefined,
      phonesJson: phonesJson || undefined,
      email: formData.email?.trim() || undefined,
      addressesJson: addressesJson || undefined,
      bankAccount: formData.bankAccount?.trim() || undefined,
      bankName: formData.bankName?.trim() || undefined,
      initialDebt: formData.initialDebt ? Number(formData.initialDebt) : 0,
      notes: formData.notes?.trim() || undefined,
    };
  },

  /**
   * Compute aggregated supplier statistics
   */
  calculateSupplierSummary(suppliers = []) {
    let totalPayables = 0;
    let totalReceivables = 0;
    let debtSupplierCount = 0;

    suppliers.forEach((s) => {
      const debt = Number(s.debt || 0);
      if (debt < 0) {
        totalPayables += Math.abs(debt);
        debtSupplierCount += 1;
      } else if (debt > 0) {
        totalReceivables += debt;
      }
    });

    return {
      totalSuppliers: suppliers.length,
      totalPayables,
      totalReceivables,
      debtSupplierCount,
    };
  },

  // ================= API Wrappers =================
  async getAll(params) {
    return await suppliersApi.getAll(params);
  },

  async getById(id) {
    return await suppliersApi.getById(id);
  },

  async create(data) {
    const validation = this.validateSupplier(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatSupplierPayload(data);
    return await suppliersApi.create(payload);
  },

  async update(id, data) {
    const validation = this.validateSupplier(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatSupplierPayload(data);
    return await suppliersApi.update(id, payload);
  },

  async adjustDebt(id, adjustData) {
    const validation = this.validateDebtAdjustment(adjustData);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }
    return await suppliersApi.adjustDebt(id, adjustData);
  },

  async getDebtHistory(id) {
    return await suppliersApi.getDebtHistory(id);
  },
};

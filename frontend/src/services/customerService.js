import { customersApi } from '../api/endpoints';
import { parseJsonList } from '../utils/formatters';
import { auditService } from './auditService';

/**
 * Frontend Business Logic & Service for Customer & Debt Management
 */
export const customerService = {
  /**
   * Validate customer creation/update form
   */
  validateCustomer(formData) {
    const errors = {};
    if (!formData.name || !formData.name.trim()) {
      errors.name = 'Tên khách hàng không được để trống';
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
   * Validate manual debt adjustment
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
   * Format customer payload for API submission
   */
  formatCustomerPayload(formData) {
    let phonesJson = '';
    if (Array.isArray(formData.phones)) {
      const flat = formData.phones
        .flatMap((p) => (typeof p === 'string' ? p.split(/[,;/\n]+/) : p))
        .map((p) => (typeof p === 'string' ? p.trim() : p))
        .filter(Boolean);
      phonesJson = JSON.stringify(flat);
    } else if (typeof formData.phone === 'string' && formData.phone.trim()) {
      const list = formData.phone.split(/[,;/\n]+/).map((p) => p.trim()).filter(Boolean);
      phonesJson = JSON.stringify(list);
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
      region: formData.region?.trim() || undefined,
      creditLimit: 0,
      initialDebt: formData.initialDebt ? Number(formData.initialDebt) : 0,
      notes: formData.notes?.trim() || undefined,
    };
  },

  /**
   * Compute aggregated customer statistics
   */
  calculateCustomerSummary(customers = []) {
    let totalReceivables = 0;
    let totalPayables = 0;
    let debtCustomerCount = 0;

    customers.forEach((c) => {
      const debt = Number(c.debt || 0);

      if (debt > 0) {
        totalReceivables += debt;
        debtCustomerCount += 1;
      } else if (debt < 0) {
        totalPayables += Math.abs(debt);
      }
    });

    return {
      totalCustomers: customers.length,
      totalReceivables,
      totalPayables,
      debtCustomerCount,
    };
  },

  // ================= API Wrappers =================
  async getAll(params) {
    return await customersApi.getAll(params);
  },

  async getById(id) {
    return await customersApi.getById(id);
  },

  async create(data) {
    const validation = this.validateCustomer(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatCustomerPayload(data);
    const result = await customersApi.create(payload);
    auditService.logAction({
      action: 'CREATE',
      entityName: 'Customer',
      entityId: result?.code || result?.id || 'Mới',
      entityDisplayName: result?.name || data.name,
      details: `Tạo mới khách hàng: ${result?.name || data.name}`,
    });
    return result;
  },

  async update(id, data) {
    const validation = this.validateCustomer(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatCustomerPayload(data);
    const result = await customersApi.update(id, payload);
    auditService.logAction({
      action: 'UPDATE',
      entityName: 'Customer',
      entityId: result?.code || String(id),
      entityDisplayName: result?.name || data.name,
      details: `Cập nhật thông tin khách hàng: ${result?.name || data.name}`,
    });
    return result;
  },

  async adjustDebt(id, adjustData) {
    const validation = this.validateDebtAdjustment(adjustData);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }
    const result = await customersApi.adjustDebt(id, adjustData);
    auditService.logAction({
      action: 'ADJUST_DEBT',
      entityName: 'Customer',
      entityId: String(id),
      entityDisplayName: `Khách hàng #${id}`,
      details: `Điều chỉnh công nợ: ${adjustData.delta > 0 ? '+' : ''}${adjustData.delta?.toLocaleString()}₫. Lý do: ${adjustData.reason}`,
    });
    return result;
  },

  async getDebtHistory(id, month) {
    return await customersApi.getDebtHistory(id, month);
  },
};

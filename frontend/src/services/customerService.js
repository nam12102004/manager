import { customersApi } from '../api/endpoints';
import { parseJsonList } from '../utils/formatters';

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
    if (formData.creditLimit !== undefined && formData.creditLimit !== '' && Number(formData.creditLimit) < 0) {
      errors.creditLimit = 'Hạn mức công nợ không được âm';
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
      creditLimit: formData.creditLimit ? Number(formData.creditLimit) : 0,
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
    let overLimitCount = 0;

    customers.forEach((c) => {
      const debt = Number(c.debt || 0);
      const limit = Number(c.creditLimit || 0);

      if (debt > 0) {
        totalReceivables += debt;
        debtCustomerCount += 1;
        if (limit > 0 && debt > limit) {
          overLimitCount += 1;
        }
      } else if (debt < 0) {
        totalPayables += Math.abs(debt);
      }
    });

    return {
      totalCustomers: customers.length,
      totalReceivables,
      totalPayables,
      debtCustomerCount,
      overLimitCount,
    };
  },

  /**
   * Check credit limit safety
   */
  checkCreditLimitRisk(currentDebt, additionalDebt, creditLimit) {
    const debt = Number(currentDebt || 0) + Number(additionalDebt || 0);
    const limit = Number(creditLimit || 0);

    if (limit <= 0) return { status: 'unlimited', message: 'Không giới hạn hạn mức' };
    if (debt > limit) {
      return {
        status: 'danger',
        message: `Vượt hạn mức nợ cho phép (${debt.toLocaleString()} / ${limit.toLocaleString()} ₫)`,
        percent: Math.round((debt / limit) * 100),
      };
    }
    if (debt >= limit * 0.8) {
      return {
        status: 'warning',
        message: `Cảnh báo: Đã đạt ${Math.round((debt / limit) * 100)}% hạn mức nợ`,
        percent: Math.round((debt / limit) * 100),
      };
    }
    return {
      status: 'safe',
      message: 'Trong giới hạn an toàn',
      percent: Math.round((debt / limit) * 100),
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
    return await customersApi.create(payload);
  },

  async update(id, data) {
    const validation = this.validateCustomer(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatCustomerPayload(data);
    return await customersApi.update(id, payload);
  },

  async adjustDebt(id, adjustData) {
    const validation = this.validateDebtAdjustment(adjustData);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }
    return await customersApi.adjustDebt(id, adjustData);
  },

  async getDebtHistory(id) {
    return await customersApi.getDebtHistory(id);
  },
};

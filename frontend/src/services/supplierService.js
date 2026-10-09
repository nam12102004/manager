import { suppliersApi } from '../api/endpoints';
import { auditService } from './auditService';

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
    const result = await suppliersApi.create(payload);
    auditService.logAction({
      action: 'CREATE',
      entityName: 'Supplier',
      entityId: result?.code || result?.id || 'Mới',
      entityDisplayName: result?.name || data.name,
      details: `Thêm nhà cung cấp mới: ${result?.name || data.name} (Mã: ${result?.code || 'NCC'})`,
    });
    return result;
  },

  async update(id, data) {
    const validation = this.validateSupplier(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatSupplierPayload(data);
    const result = await suppliersApi.update(id, payload);
    auditService.logAction({
      action: 'UPDATE',
      entityName: 'Supplier',
      entityId: result?.code || String(id),
      entityDisplayName: result?.name || data.name,
      details: `Cập nhật thông tin nhà cung cấp: ${result?.name || data.name}`,
    });
    return result;
  },

  async adjustDebt(id, adjustData) {
    const validation = this.validateDebtAdjustment(adjustData);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }
    const result = await suppliersApi.adjustDebt(id, adjustData);
    auditService.logAction({
      action: 'ADJUST_DEBT',
      entityName: 'Supplier',
      entityId: String(id),
      entityDisplayName: `Nhà cung cấp #${id}`,
      details: `Điều chỉnh công nợ NCC: ${adjustData.delta > 0 ? '+' : ''}${adjustData.delta?.toLocaleString()}₫. Lý do: ${adjustData.reason}`,
    });
    return result;
  },

  async getDebtHistory(id, month) {
    return await suppliersApi.getDebtHistory(id, month);
  },
};

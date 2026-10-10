import { exportsApi, customersApi, productsApi, ownersApi } from '../api/endpoints';
import { auditService } from './auditService';

/**
 * Frontend Business Logic & Service for Export Vouchers (Bán hàng, Xuất kho & Ghi nợ)
 */
export const exportService = {
  /**
   * Calculate single line total
   */
  calculateLineTotal(quantity, salePrice) {
    const q = Number(quantity || 0);
    const p = Number(salePrice || 0);
    return Math.round(q * p);
  },

  /**
   * Calculate subtotal, discount, total sale, and unpaid amount (projected debt)
   */
  calculateExportTotals({ items = [], discountType = 'amount', discountValue = 0, paidAmount = 0 }) {
    const subtotal = items.reduce((acc, it) => {
      const line = this.calculateLineTotal(it.quantity, it.salePrice);
      return acc + line;
    }, 0);

    let discountAmount = 0;
    const discVal = Number(discountValue || 0);
    if (discountType === 'percent') {
      discountAmount = Math.round((subtotal * Math.max(0, Math.min(100, discVal))) / 100);
    } else {
      discountAmount = Math.max(0, Math.min(discVal, subtotal));
    }

    const totalSale = Math.max(0, subtotal - discountAmount);
    const paid = Math.min(totalSale, Math.max(0, Number(paidAmount || 0)));
    const unpaidAmount = Math.max(0, totalSale - paid);

    return {
      subtotal,
      discountAmount,
      totalSale,
      paidAmount: paid,
      unpaidAmount, // Khoản khách hàng nợ thêm
    };
  },

  /**
   * Validate export voucher before submission
   */
  validateExport(formData, products = []) {
    const errors = {};

    if (!formData.customerId) {
      errors.customerId = 'Vui lòng chọn khách hàng';
    }
    if (!formData.warehouse) {
      errors.warehouse = 'Vui lòng chọn kho xuất hàng';
    }
    if (!formData.items || formData.items.length === 0) {
      errors.items = 'Phiếu xuất phải có ít nhất 1 sản phẩm';
    } else {
      const itemErrors = [];
      formData.items.forEach((it, idx) => {
        if (!it.productId) {
          itemErrors.push(`Dòng ${idx + 1}: Chưa chọn sản phẩm`);
        } else if (Number(it.quantity || 0) <= 0) {
          itemErrors.push(`Dòng ${idx + 1}: Số lượng xuất phải lớn hơn 0`);
        }
      });
      if (itemErrors.length > 0) {
        errors.items = itemErrors.join(', ');
      }
    }

    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  },

  /**
   * Format payload for API
   */
  formatExportPayload(formData) {
    const totals = this.calculateExportTotals({
      items: formData.items,
      discountType: formData.discountType,
      discountValue: formData.discountValue,
      paidAmount: formData.paidAmount,
    });

    return {
      customerId: Number(formData.customerId),
      warehouse: formData.warehouse || 'kho_1',
      date: formData.date ? new Date(formData.date).toISOString() : new Date().toISOString(),
      discountPercent: formData.discountType === 'percent' ? Number(formData.discountValue || 0) : undefined,
      discountValue: formData.discountType === 'amount' ? Number(formData.discountValue || 0) : undefined,
      paidAmount: totals.paidAmount,
      notes: formData.notes?.trim() || undefined,
      items: formData.items.map((it) => ({
        productId: Number(it.productId),
        quantity: Number(it.quantity),
        salePrice: Number(it.salePrice || 0),
      })),
    };
  },

  // ================= API Wrappers =================
  async getAll(params) {
    return await exportsApi.getAll(params);
  },

  async getById(id) {
    return await exportsApi.getById(id);
  },

  async create(formData, products = []) {
    const validation = this.validateExport(formData, products);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatExportPayload(formData);
    const result = await exportsApi.create(payload);
    auditService.logAction({
      action: 'CREATE',
      entityName: 'ExportVoucher',
      entityId: result?.voucherNumber || result?.id || 'Mới',
      entityDisplayName: `Phiếu xuất #${result?.voucherNumber || result?.id}`,
      details: `Lập phiếu bán hàng xuất kho, Tổng tiền: ${(result?.totalSale || formData.totalSale || 0).toLocaleString()}₫`,
    });
    return result;
  },

  async updateStatus(id, action) {
    const result = await exportsApi.updateStatus(id, action);
    auditService.logAction({
      action: action === 'cancel' ? 'CANCEL' : 'STATUS_CHANGE',
      entityName: 'ExportVoucher',
      entityId: String(id),
      entityDisplayName: `Phiếu xuất #${id}`,
      details: `${action === 'cancel' ? 'Hủy' : 'Đổi trạng thái'} phiếu xuất #${id}`,
    });
    return result;
  },

  async delete(id) {
    const result = await exportsApi.delete(id);
    auditService.logAction({
      action: 'DELETE',
      entityName: 'ExportVoucher',
      entityId: String(id),
      entityDisplayName: `Phiếu xuất #${id}`,
      details: `Xóa vĩnh viễn phiếu xuất #${id}`,
    });
    return result;
  },

  async getDependencies() {
    const [custs, prods, owner] = await Promise.allSettled([
      customersApi.getAll({ all: true }),
      productsApi.getAll({ all: true }),
      ownersApi.get(),
    ]);

    return {
      customers: custs.status === 'fulfilled' && Array.isArray(custs.value) ? custs.value : [],
      products: prods.status === 'fulfilled' && Array.isArray(prods.value) ? prods.value : [],
      ownerInfo: owner.status === 'fulfilled' ? owner.value : null,
    };
  },
};

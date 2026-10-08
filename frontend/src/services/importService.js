import { importsApi, suppliersApi, productsApi } from '../api/endpoints';

/**
 * Frontend Business Logic & Service for Import Vouchers (Mua hàng, Nhập kho & Nợ Nhà cung cấp)
 */
export const importService = {
  /**
   * Calculate single line total for purchase item
   */
  calculateLineTotal(quantity, unitCost) {
    const q = Number(quantity || 0);
    const c = Number(unitCost || 0);
    return Math.round(q * c);
  },

  /**
   * Calculate subtotal, discount, total purchase cost, paid amount, and unpaid amount (supplier debt)
   */
  calculateImportTotals({ items = [], discountType = 'amount', discountValue = 0, paidAmount = 0 }) {
    const subtotal = items.reduce((acc, it) => {
      const line = this.calculateLineTotal(it.quantity, it.unitCost);
      return acc + line;
    }, 0);

    let discountAmount = 0;
    const discVal = Number(discountValue || 0);
    if (discountType === 'percent') {
      discountAmount = Math.round((subtotal * Math.max(0, Math.min(100, discVal))) / 100);
    } else {
      discountAmount = Math.max(0, Math.min(discVal, subtotal));
    }

    const totalCost = Math.max(0, subtotal - discountAmount);
    const paid = Math.min(totalCost, Math.max(0, Number(paidAmount || 0)));
    const unpaidAmount = Math.max(0, totalCost - paid);

    return {
      subtotal,
      discountAmount,
      totalCost,
      paidAmount: paid,
      unpaidAmount, // Khoản nợ phát sinh với NCC
    };
  },

  /**
   * Validate import voucher before submission
   */
  validateImport(formData) {
    const errors = {};

    if (!formData.supplierId) {
      errors.supplierId = 'Vui lòng chọn nhà cung cấp';
    }
    if (!formData.warehouse) {
      errors.warehouse = 'Vui lòng chọn kho nhập hàng';
    }
    if (!formData.items || formData.items.length === 0) {
      errors.items = 'Phiếu nhập phải có ít nhất 1 sản phẩm';
    } else {
      const itemErrors = [];
      formData.items.forEach((it, idx) => {
        if (!it.productId) {
          itemErrors.push(`Dòng ${idx + 1}: Chưa chọn sản phẩm`);
        } else if (Number(it.quantity || 0) <= 0) {
          itemErrors.push(`Dòng ${idx + 1}: Số lượng nhập phải lớn hơn 0`);
        } else if (Number(it.unitCost || 0) < 0) {
          itemErrors.push(`Dòng ${idx + 1}: Giá vốn nhập không được âm`);
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
  formatImportPayload(formData) {
    const totals = this.calculateImportTotals({
      items: formData.items,
      discountType: formData.discountType,
      discountValue: formData.discountValue,
      paidAmount: formData.paidAmount,
    });

    return {
      supplierId: Number(formData.supplierId),
      warehouse: formData.warehouse || 'kho_1',
      date: formData.date ? new Date(formData.date).toISOString() : new Date().toISOString(),
      discountPercent: formData.discountType === 'percent' ? Number(formData.discountValue || 0) : undefined,
      discountValue: formData.discountType === 'amount' ? Number(formData.discountValue || 0) : undefined,
      paidAmount: totals.paidAmount,
      notes: formData.notes?.trim() || undefined,
      items: formData.items.map((it) => ({
        productId: Number(it.productId),
        quantity: Number(it.quantity),
        unitCost: Number(it.unitCost || 0),
      })),
    };
  },

  // ================= API Wrappers =================
  async getAll(params) {
    return await importsApi.getAll(params);
  },

  async getById(id) {
    return await importsApi.getById(id);
  },

  async create(formData) {
    const validation = this.validateImport(formData);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const payload = this.formatImportPayload(formData);
    return await importsApi.create(payload);
  },

  async updateStatus(id, action) {
    return await importsApi.updateStatus(id, action);
  },

  async delete(id) {
    return await importsApi.delete(id);
  },

  async getDependencies() {
    const [supps, prods] = await Promise.allSettled([
      suppliersApi.getAll(),
      productsApi.getAll(),
    ]);

    return {
      suppliers: supps.status === 'fulfilled' && Array.isArray(supps.value) ? supps.value : [],
      products: prods.status === 'fulfilled' && Array.isArray(prods.value) ? prods.value : [],
    };
  },
};

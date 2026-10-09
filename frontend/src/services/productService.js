import { productsApi, suppliersApi } from '../api/endpoints';
import { auditService } from './auditService';

/**
 * Frontend Business Logic & Service for Products & Inventory Management
 */
export const productService = {
  /**
   * Validate product creation/update form
   */
  validateProduct(formData) {
    const errors = {};
    if (!formData.name || !formData.name.trim()) {
      errors.name = 'Tên sản phẩm không được để trống';
    }
    if (formData.unitCost !== undefined && Number(formData.unitCost) < 0) {
      errors.unitCost = 'Giá vốn không được âm';
    }
    if (formData.salePrice !== undefined && Number(formData.salePrice) < 0) {
      errors.salePrice = 'Giá bán không được âm';
    }
    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  },

  /**
   * Validate stock adjustment
   */
  validateStockAdjustment({ warehouse, delta, newStock, reason }) {
    if (!warehouse) {
      return { isValid: false, message: 'Vui lòng chọn kho cần điều chỉnh' };
    }
    if (newStock === undefined && (delta === undefined || Number(delta) === 0)) {
      return { isValid: false, message: 'Vui lòng nhập tồn kho mới hoặc số lượng điều chỉnh khác 0' };
    }
    if (!reason || !reason.trim()) {
      return { isValid: false, message: 'Vui lòng chọn hoặc nhập lý do kiểm kê' };
    }
    return { isValid: true };
  },

  /**
   * Calculate profit margin & markup
   */
  calculateMargin(unitCost, salePrice) {
    const cost = Number(unitCost || 0);
    const price = Number(salePrice || 0);
    const profit = price - cost;
    const marginPercent = price > 0 ? Math.round((profit / price) * 100) : 0;
    const markupPercent = cost > 0 ? Math.round((profit / cost) * 100) : 0;

    return {
      profit,
      marginPercent,
      markupPercent,
      isLoss: profit < 0,
    };
  },

  /**
   * Compute aggregated product & inventory stats
   */
  calculateInventorySummary(products = []) {
    let totalStockAll = 0;
    let totalValuation = 0;
    let outOfStockCount = 0;
    let lowStockCount = 0;

    const warehouseTotals = {};

    products.forEach((p) => {
      const total = Number(p.totalStock ?? 0);
      const cost = Number(p.unitCost ?? 0);

      totalStockAll += total;
      totalValuation += total * cost;

      if (total <= 0) {
        outOfStockCount += 1;
      } else if (total < 10) {
        lowStockCount += 1;
      }
    });

    return {
      totalProducts: products.length,
      totalStockAll,
      totalValuation,
      outOfStockCount,
      lowStockCount,
      warehouseTotals,
    };
  },

  // ================= API Wrappers =================
  async getAll(params) {
    return await productsApi.getAll(params);
  },

  async getById(id) {
    return await productsApi.getById(id);
  },

  async create(data) {
    const validation = this.validateProduct(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const result = await productsApi.create(data);
    auditService.logAction({
      action: 'CREATE',
      entityName: 'Product',
      entityId: result?.sku || result?.id || 'Mới',
      entityDisplayName: result?.name || data.name,
      details: `Thêm sản phẩm mới: ${result?.name || data.name} (SKU: ${result?.sku || data.sku || 'Tự sinh'})`,
    });
    return result;
  },

  async update(id, data) {
    const validation = this.validateProduct(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }
    const result = await productsApi.update(id, data);
    auditService.logAction({
      action: 'UPDATE',
      entityName: 'Product',
      entityId: result?.sku || String(id),
      entityDisplayName: result?.name || data.name,
      details: `Cập nhật thông tin sản phẩm: ${result?.name || data.name}`,
    });
    return result;
  },

  async adjustStock(id, adjustData) {
    const validation = this.validateStockAdjustment(adjustData);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }
    const result = await productsApi.adjustStock(id, adjustData);
    auditService.logAction({
      action: 'ADJUST_STOCK',
      entityName: 'Product',
      entityId: String(id),
      entityDisplayName: `Sản phẩm #${id}`,
      details: `Điều chỉnh tồn kho (${adjustData.warehouse || 'Kho'}): Lượng đổi ${adjustData.delta > 0 ? '+' : ''}${adjustData.delta}. Lý do: ${adjustData.reason || 'Kiểm kê kho'}`,
    });
    return result;
  },

  async getStockHistory(id, month) {
    return await productsApi.getStockHistory(id, month);
  },

  async getDependencies() {
    const supps = await suppliersApi.getAll();
    return {
      suppliers: Array.isArray(supps) ? supps : [],
    };
  },

  filterProducts(products = [], { onlyLowStock = false }) {
    if (!onlyLowStock) return products;
    return products.filter(
      (p) => Number(p.totalStock || 0) <= Number(p.reorderPoint || 0) && Number(p.reorderPoint || 0) > 0
    );
  },
};

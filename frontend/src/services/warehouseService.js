import { settingService } from './settingService';
import { auditService } from './auditService';

export const DEFAULT_WAREHOUSES = [
  { id: 'warehouse1', name: 'Kho 1 (Mặc định)', shortName: 'Kho 1', color: 'primary' },
  { id: 'warehouse2', name: 'Kho 2', shortName: 'Kho 2', color: 'info' },
  { id: 'warehouse3', name: 'Kho 3', shortName: 'Kho 3', color: 'purple' },
];

const LOCAL_STORAGE_KEY = 'debtmanager_warehouses_cache';

/**
 * Universal helper to get stock quantity of a product in a given warehouse
 */
export const getProductStockForWarehouse = (product, whId) => {
  if (!product) return 0;
  if (product.warehouseStocks && product.warehouseStocks[whId] !== undefined) {
    return Number(product.warehouseStocks[whId] || 0);
  }
  if (whId === 'warehouse1') return Number(product.stockWarehouse1 || 0);
  if (whId === 'warehouse2') return Number(product.stockWarehouse2 || 0);
  if (whId === 'warehouse3') return Number(product.stockWarehouse3 || 0);
  return 0;
};

/**
 * Service for managing warehouses (listing, adding, updating, deleting, caching)
 */
export const warehouseService = {
  /**
   * Get all active warehouses dynamically from backend settings or local cache
   */
  async getWarehouses() {
    try {
      const settings = await settingService.getSettings();
      if (settings?.warehouses && Array.isArray(settings.warehouses) && settings.warehouses.length > 0) {
        const valid = settings.warehouses
          .filter((w) => w && w.id && w.name)
          .map((w) => ({
            id: String(w.id).trim(),
            name: String(w.name).trim(),
            shortName: String(w.shortName || w.name).trim(),
            color: w.color || 'primary',
            address: w.address ? String(w.address).trim() : '',
            note: w.note ? String(w.note).trim() : '',
          }));

        if (valid.length > 0) {
          localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(valid));
          return valid;
        }
      }
    } catch (err) {
      console.warn('Error loading warehouses from backend settings:', err);
    }

    // Fallback to localStorage cache
    try {
      const cached = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (cached) {
        const parsed = JSON.parse(cached);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed.map((w) => ({
            id: String(w.id).trim(),
            name: String(w.name).trim(),
            shortName: String(w.shortName || w.name).trim(),
            color: w.color || 'primary',
            address: w.address ? String(w.address).trim() : '',
            note: w.note ? String(w.note).trim() : '',
          }));
        }
      }
    } catch {
      // ignore
    }

    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(DEFAULT_WAREHOUSES));
    return DEFAULT_WAREHOUSES;
  },

  /**
   * Synchronous get from cache or default
   */
  getWarehousesSync() {
    try {
      const cached = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (cached) {
        const parsed = JSON.parse(cached);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed.map((w) => ({
            id: String(w.id).trim(),
            name: String(w.name).trim(),
            shortName: String(w.shortName || w.name).trim(),
            color: w.color || 'primary',
            address: w.address ? String(w.address).trim() : '',
            note: w.note ? String(w.note).trim() : '',
          }));
        }
      }
    } catch {
      // ignore
    }
    return DEFAULT_WAREHOUSES;
  },

  /**
   * Save warehouse list to backend and local storage
   */
  async saveWarehouses(warehouses) {
    if (!Array.isArray(warehouses) || warehouses.length === 0) {
      throw new Error('Danh sách kho không hợp lệ');
    }

    const sanitized = warehouses
      .filter((w) => w && w.id && w.name)
      .map((w) => ({
        id: String(w.id).trim(),
        name: String(w.name).trim(),
        shortName: String(w.shortName || w.name).trim(),
        color: w.color || 'primary',
        address: w.address ? String(w.address).trim() : '',
        note: w.note ? String(w.note).trim() : '',
      }));

    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(sanitized));

    try {
      const currentSettings = await settingService.getSettings();
      let rawInfoObj = {};
      if (currentSettings?.rawInfo) {
        try {
          rawInfoObj = JSON.parse(currentSettings.rawInfo);
        } catch {
          rawInfoObj = {};
        }
      }

      const updatedInfo = {
        ...rawInfoObj,
        storeName: currentSettings.storeName,
        storePhone: currentSettings.storePhone,
        storeAddress: currentSettings.storeAddress,
        bankName: currentSettings.bankName,
        bankAccount: currentSettings.bankAccount,
        accountHolder: currentSettings.accountHolder,
        warehouses: sanitized,
      };

      await settingService.saveSettings({
        ...currentSettings,
        rawInfo: JSON.stringify(updatedInfo),
        warehouses: sanitized,
      });
    } catch (err) {
      console.warn('Error syncing warehouses to backend settings:', err);
    }

    window.dispatchEvent(new CustomEvent('warehouses-updated', { detail: sanitized }));
    return sanitized;
  },

  /**
   * Add a new warehouse dynamically
   */
  async addWarehouse({ name, shortName, color, address, note }) {
    if (!name || !name.trim()) {
      throw new Error('Tên kho không được để trống');
    }

    const currentWarehouses = await this.getWarehouses();

    // Check duplicate name
    const trimmedName = name.trim();
    if (currentWarehouses.some((w) => w.name.toLowerCase() === trimmedName.toLowerCase())) {
      throw new Error(`Đã có kho mang tên "${trimmedName}" trong hệ thống`);
    }

    // Determine unique id
    const nums = currentWarehouses.map((w) => {
      const m = w.id.match(/^warehouse(\d+)$/);
      return m ? parseInt(m[1], 10) : 0;
    });
    const nextNum = Math.max(3, ...nums) + 1;
    let finalId = `warehouse${nextNum}`;
    let suffix = 1;
    while (currentWarehouses.some((w) => w.id === finalId)) {
      finalId = `warehouse${nextNum}_${suffix++}`;
    }

    const palette = ['primary', 'info', 'purple', 'warning', 'success', 'danger', 'teal'];
    const assignedColor = color || palette[(currentWarehouses.length) % palette.length];

    const newWarehouse = {
      id: finalId,
      name: trimmedName,
      shortName: (shortName || trimmedName).trim(),
      color: assignedColor,
      address: address ? address.trim() : '',
      note: note ? note.trim() : '',
    };

    const updated = [...currentWarehouses, newWarehouse];
    await this.saveWarehouses(updated);

    auditService.logAction({
      action: 'CREATE_WAREHOUSE',
      entityName: 'Warehouse',
      entityId: finalId,
      entityDisplayName: newWarehouse.name,
      details: `Thêm mới kho hàng: ${newWarehouse.name} (Mã: ${finalId})`,
    });

    return updated;
  },

  /**
   * Rename or update an existing warehouse
   */
  async renameWarehouse(warehouseId, newName, newShortName, color = null, address = null, note = null) {
    if (!newName || !newName.trim()) {
      throw new Error('Tên kho không được để trống');
    }

    const currentWarehouses = await this.getWarehouses();
    const target = currentWarehouses.find((w) => w.id === warehouseId);
    if (!target) {
      throw new Error(`Không tìm thấy kho với mã ${warehouseId}`);
    }

    const oldName = target.name;
    const trimmedName = newName.trim();

    // Check name duplicate with other warehouses
    if (
      currentWarehouses.some(
        (w) => w.id !== warehouseId && w.name.toLowerCase() === trimmedName.toLowerCase()
      )
    ) {
      throw new Error(`Tên kho "${trimmedName}" đã được sử dụng cho một kho khác`);
    }

    const updated = currentWarehouses.map((w) => {
      if (w.id === warehouseId) {
        return {
          ...w,
          name: trimmedName,
          shortName: (newShortName || trimmedName).trim(),
          ...(color ? { color } : {}),
          ...(address !== null && address !== undefined ? { address: address.trim() } : {}),
          ...(note !== null && note !== undefined ? { note: note.trim() } : {}),
        };
      }
      return w;
    });

    await this.saveWarehouses(updated);

    auditService.logAction({
      action: 'UPDATE_WAREHOUSE',
      entityName: 'Warehouse',
      entityId: warehouseId,
      entityDisplayName: trimmedName,
      details: `Cập nhật thông tin kho: Đổi tên từ "${oldName}" thành "${trimmedName}"`,
    });

    return updated;
  },

  /**
   * Delete a custom warehouse
   */
  async deleteWarehouse(warehouseId) {
    if (warehouseId === 'warehouse1') {
      throw new Error('Không thể xóa kho chính mặc định của hệ thống');
    }

    const currentWarehouses = await this.getWarehouses();
    const target = currentWarehouses.find((w) => w.id === warehouseId);
    if (!target) {
      throw new Error(`Không tìm thấy kho với mã ${warehouseId}`);
    }

    if (currentWarehouses.length <= 1) {
      throw new Error('Hệ thống phải có ít nhất một kho hoạt động');
    }

    const updated = currentWarehouses.filter((w) => w.id !== warehouseId);
    await this.saveWarehouses(updated);

    auditService.logAction({
      action: 'DELETE_WAREHOUSE',
      entityName: 'Warehouse',
      entityId: warehouseId,
      entityDisplayName: target.name,
      details: `Xóa kho hàng: ${target.name} (Mã: ${warehouseId})`,
    });

    return updated;
  },

  /**
   * Get warehouse mapping object: { [id]: name }
   */
  getWarehouseMap(warehouses = null) {
    const list = warehouses || this.getWarehousesSync();
    const map = {};
    list.forEach((w) => {
      map[w.id] = w.name;
    });
    return map;
  },

  /**
   * Get warehouse name by ID
   */
  getWarehouseName(whId, warehouses = null) {
    if (!whId) return 'Không xác định';
    const list = warehouses || this.getWarehousesSync();
    const found = list.find((w) => w.id === whId);
    return found ? found.name : whId;
  },
};

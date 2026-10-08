import { ownersApi } from '../api/endpoints';

const DEFAULT_SETTINGS = {
  storeName: 'KHO HÀNG & PHÂN PHỐI TỔNG HỢP',
  storePhone: '0988.123.456',
  storeAddress: '123 Đường Số 7, KCN Vĩnh Lộc, Bình Chánh, TP.HCM',
  bankName: 'MB',
  bankAccount: '0988123456',
  accountHolder: 'NGUYEN VAN ADMIN',
};

/**
 * Frontend Business Logic & Service for Store Settings & Owner Profile
 */
export const settingService = {
  /**
   * Load store settings and parse JSON
   */
  async getSettings() {
    try {
      const data = await ownersApi.get();
      if (!data || !data.info) {
        return { ...DEFAULT_SETTINGS, rawInfo: '' };
      }

      try {
        const parsed = JSON.parse(data.info);
        return {
          storeName: parsed.storeName || DEFAULT_SETTINGS.storeName,
          storePhone: parsed.storePhone || DEFAULT_SETTINGS.storePhone,
          storeAddress: parsed.storeAddress || DEFAULT_SETTINGS.storeAddress,
          bankName: parsed.bankName || DEFAULT_SETTINGS.bankName,
          bankAccount: parsed.bankAccount || DEFAULT_SETTINGS.bankAccount,
          accountHolder: parsed.accountHolder || DEFAULT_SETTINGS.accountHolder,
          rawInfo: data.info,
        };
      } catch {
        return {
          ...DEFAULT_SETTINGS,
          storeName: data.info,
          rawInfo: data.info,
        };
      }
    } catch (err) {
      console.warn('Error loading store settings:', err);
      return { ...DEFAULT_SETTINGS, rawInfo: '' };
    }
  },

  /**
   * Validate settings before saving
   */
  validateSettings(data) {
    if (!data.storeName || !data.storeName.trim()) {
      return { isValid: false, message: 'Tên cửa hàng không được để trống' };
    }
    return { isValid: true };
  },

  /**
   * Save store settings
   */
  async saveSettings(data) {
    const validation = this.validateSettings(data);
    if (!validation.isValid) {
      throw new Error(validation.message);
    }

    const payload = {
      storeName: data.storeName.trim(),
      storePhone: data.storePhone?.trim() || '',
      storeAddress: data.storeAddress?.trim() || '',
      bankName: data.bankName?.trim() || '',
      bankAccount: data.bankAccount?.trim() || '',
      accountHolder: data.accountHolder?.trim() || '',
    };

    return await ownersApi.update({
      info: JSON.stringify(payload),
    });
  },
};

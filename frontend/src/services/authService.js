import { authApi } from '../api/endpoints';
import { auditService } from './auditService';

const USER_STORAGE_KEY = 'debt_manager_user';
const LEGACY_TOKEN_KEY = 'debt_manager_token';

/**
 * Frontend Service for Simple/Normal User Authentication (No JWT)
 */
export const authService = {
  /**
   * Get current authenticated user session from local storage
   */
  getCurrentUser() {
    try {
      const saved = localStorage.getItem(USER_STORAGE_KEY);
      if (!saved) return null;
      return JSON.parse(saved);
    } catch {
      localStorage.removeItem(USER_STORAGE_KEY);
      return null;
    }
  },

  /**
   * Check if user is currently logged in
   */
  isAuthenticated() {
    return !!this.getCurrentUser();
  },

  /**
   * Standard login (username & password)
   */
  async login(username, password) {
    if (!username || !username.trim() || !password || !password.trim()) {
      throw new Error('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu');
    }

    try {
      const res = await authApi.login({
        username: username.trim(),
        password: password.trim(),
      });

      const user = {
        username: res.username || username.trim(),
        role: res.role || 'admin',
      };

      localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(user));
      // Clear legacy JWT token if present
      localStorage.removeItem(LEGACY_TOKEN_KEY);

      // Ghi nhận lịch sử đăng nhập thành công
      auditService.logLogin({
        username: user.username,
        isSuccess: true,
        note: 'Đăng nhập thành công vào hệ thống',
      });

      return user;
    } catch (err) {
      // Ghi nhận lịch sử đăng nhập thất bại
      auditService.logLogin({
        username: username.trim(),
        isSuccess: false,
        note: err.message || 'Sai thông tin đăng nhập',
      });
      throw err;
    }
  },

  /**
   * Logout user and clear local session
   */
  logout() {
    const user = this.getCurrentUser();
    if (user) {
      auditService.logAction({
        action: 'LOGOUT',
        entityName: 'User',
        entityId: user.username,
        entityDisplayName: `Tài khoản: ${user.username}`,
        details: 'Đăng xuất khỏi phiên làm việc',
        username: user.username,
      });
    }
    localStorage.removeItem(USER_STORAGE_KEY);
    localStorage.removeItem(LEGACY_TOKEN_KEY);
  },
};

import { authApi } from '../api/endpoints';

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

    return user;
  },

  /**
   * Logout user and clear local session
   */
  logout() {
    localStorage.removeItem(USER_STORAGE_KEY);
    localStorage.removeItem(LEGACY_TOKEN_KEY);
  },
};

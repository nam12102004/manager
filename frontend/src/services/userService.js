import { usersApi } from '../api/endpoints';
import { auditService } from './auditService';

/**
 * Frontend Business Logic & Service for User Account Management & Roles
 */
export const userService = {
  /**
   * Validate user creation form
   */
  validateUser(formData) {
    const errors = {};
    if (!formData.username || !formData.username.trim()) {
      errors.username = 'Tên đăng nhập không được để trống';
    } else if (formData.username.trim().length < 3) {
      errors.username = 'Tên đăng nhập phải có ít nhất 3 ký tự';
    }

    if (!formData.password || !formData.password.trim()) {
      errors.password = 'Mật khẩu không được để trống';
    } else if (formData.password.length < 6) {
      errors.password = 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  },

  /**
   * Get all users
   */
  async getAll() {
    return await usersApi.getAll();
  },

  /**
   * Create a new user (Staff or Admin)
   */
  async create(data) {
    const validation = this.validateUser(data);
    if (!validation.isValid) {
      const firstError = Object.values(validation.errors)[0];
      throw new Error(firstError);
    }

    const payload = {
      username: data.username.trim(),
      password: data.password.trim(),
      role: data.role || 'nv',
    };

    const result = await usersApi.create(payload);

    auditService.logAction({
      action: 'CREATE',
      entityName: 'User',
      entityId: result?.username || payload.username,
      entityDisplayName: `Tài khoản: ${payload.username} (${payload.role === 'admin' ? 'Quản trị viên' : 'Nhân viên'})`,
      details: `Tạo tài khoản ${payload.role === 'admin' ? 'Quản trị viên' : 'Nhân viên'} mới: ${payload.username}`,
    });

    return result;
  },

  /**
   * Change user password
   */
  async changePassword(id, username, newPassword) {
    if (!newPassword || newPassword.length < 6) {
      throw new Error('Mật khẩu mới phải có ít nhất 6 ký tự');
    }

    const result = await usersApi.changePassword(id, newPassword);

    auditService.logAction({
      action: 'UPDATE',
      entityName: 'User',
      entityId: username || String(id),
      entityDisplayName: `Tài khoản: ${username || id}`,
      details: `Đổi mật khẩu cho tài khoản: ${username || id}`,
    });

    return result;
  },

  /**
   * Update role
   */
  async updateRole(id, username, role) {
    const result = await usersApi.updateRole(id, role);

    auditService.logAction({
      action: 'UPDATE_ROLE',
      entityName: 'User',
      entityId: username || String(id),
      entityDisplayName: `Tài khoản: ${username || id}`,
      details: `Cập nhật quyền tài khoản ${username || id} thành: ${role === 'admin' ? 'Quản trị viên' : 'Nhân viên'}`,
    });

    return result;
  },

  /**
   * Delete user
   */
  async delete(id, username) {
    const result = await usersApi.delete(id);

    auditService.logAction({
      action: 'DELETE',
      entityName: 'User',
      entityId: username || String(id),
      entityDisplayName: `Tài khoản: ${username || id}`,
      details: `Xóa tài khoản người dùng: ${username || id}`,
    });

    return result;
  },
};

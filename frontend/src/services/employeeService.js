import { employeesApi } from '../api/endpoints';
import { auditService } from './auditService';

/**
 * Frontend Business Logic & Service for Employees (Nhân viên xuất hàng)
 */
export const employeeService = {
  async getAll(params = {}) {
    return await employeesApi.getAll(params);
  },

  async getById(id) {
    return await employeesApi.getById(id);
  },

  async create(formData) {
    if (!formData.name || !formData.name.trim()) {
      throw new Error('Vui lòng nhập tên nhân viên');
    }

    const payload = {
      name: formData.name.trim(),
      phone: formData.phone?.trim() || undefined,
      notes: formData.notes?.trim() || undefined,
    };

    const result = await employeesApi.create(payload);
    auditService.logAction({
      action: 'CREATE',
      entityName: 'Employee',
      entityId: String(result?.id || 'Mới'),
      entityDisplayName: `Nhân viên: ${result?.name || payload.name}`,
      details: `Thêm nhân viên mới: ${result?.name || payload.name}`,
    });
    return result;
  },

  async delete(id, name = '') {
    const result = await employeesApi.delete(id);
    auditService.logAction({
      action: 'DELETE',
      entityName: 'Employee',
      entityId: String(id),
      entityDisplayName: `Nhân viên: ${name || id}`,
      details: `Xóa nhân viên: ${name || id}`,
    });
    return result;
  },

  /**
   * Export sales & products report to Excel
   */
  async exportExcel(params = {}, defaultFileName = 'BaoCao_DoanhSo_NhanVien.xlsx') {
    const response = await employeesApi.exportExcel(params);
    let filename = defaultFileName;
    const disposition = response.headers?.['content-disposition'];
    if (disposition && disposition.includes('filename=')) {
      const match = disposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
      if (match && match[1]) {
        filename = decodeURIComponent(match[1].replace(/['"]/g, ''));
      }
    }

    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
    return filename;
  },
};

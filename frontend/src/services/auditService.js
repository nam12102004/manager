import { auditApi } from '../api/endpoints';

const AUDIT_STORAGE_KEY = 'debt_manager_audit_logs_v1';
const LOGIN_STORAGE_KEY = 'debt_manager_login_history_v1';

// Helper: Phân tích thiết bị & trình duyệt
export function getDeviceInfo() {
  if (typeof window === 'undefined' || !navigator) return 'Web Browser';
  const ua = navigator.userAgent || '';
  let browser = 'Trình duyệt';
  if (ua.includes('Edg/')) browser = 'Edge';
  else if (ua.includes('Chrome/')) browser = 'Chrome';
  else if (ua.includes('Firefox/')) browser = 'Firefox';
  else if (ua.includes('Safari/') && !ua.includes('Chrome/')) browser = 'Safari';

  let os = 'Thiết bị';
  if (ua.includes('Windows NT 10.0')) os = 'Windows 10/11';
  else if (ua.includes('Windows')) os = 'Windows';
  else if (ua.includes('Macintosh')) os = 'macOS';
  else if (ua.includes('Linux')) os = 'Linux';
  else if (ua.includes('iPhone') || ua.includes('iPad')) os = 'iOS';
  else if (ua.includes('Android')) os = 'Android';

  return `${browser} (${os})`;
}

// Dữ liệu mẫu ban đầu nếu bộ nhớ trống
function getInitialAuditLogs() {
  const now = new Date();
  return [
    {
      id: 'audit-001',
      action: 'UPDATE',
      entityName: 'Product',
      entityId: 'SP000001',
      entityDisplayName: 'Xi Măng Holcim Đa Dụng PCB40',
      details: 'Cập nhật giá bán lẻ từ 88,000₫ lên 92,000₫; Giá sỉ: 85,000₫',
      username: 'admin',
      ipAddress: '127.0.0.1',
      createdAt: new Date(now.getTime() - 25 * 60 * 1000).toISOString(),
    },
    {
      id: 'audit-002',
      action: 'CREATE',
      entityName: 'ExportVoucher',
      entityId: 'XK-202610-0012',
      entityDisplayName: 'Phiếu xuất bán hàng #XK-202610-0012',
      details: 'Lập phiếu bán hàng cho Công ty TNHH Xây Dựng Nam Thành, trị giá 18,500,000₫ (Trừ Kho 1)',
      username: 'admin',
      ipAddress: '127.0.0.1',
      createdAt: new Date(now.getTime() - 65 * 60 * 1000).toISOString(),
    },
    {
      id: 'audit-003',
      action: 'ADJUST_DEBT',
      entityName: 'Customer',
      entityId: 'KH000005',
      entityDisplayName: 'Khách hàng: Nhà thầu Trần Quốc Bảo',
      details: 'Điều chỉnh công nợ: Giảm nợ 5,000,000₫ do cấn trừ chiết khấu công trình',
      username: 'admin',
      ipAddress: '127.0.0.1',
      createdAt: new Date(now.getTime() - 140 * 60 * 1000).toISOString(),
    },
    {
      id: 'audit-004',
      action: 'CREATE',
      entityName: 'Receipt',
      entityId: 'PT-202610-0008',
      entityDisplayName: 'Phiếu thu tiền mặt #PT-202610-0008',
      details: 'Thu tiền khách hàng Công ty An Gia 12,000,000₫ (Chuyển khoản VietQR)',
      username: 'admin',
      ipAddress: '127.0.0.1',
      createdAt: new Date(now.getTime() - 210 * 60 * 1000).toISOString(),
    },
    {
      id: 'audit-005',
      action: 'UPDATE_SETTINGS',
      entityName: 'Owner',
      entityId: 'STORE-CONFIG',
      entityDisplayName: 'Cấu hình Cửa Hàng & VietQR',
      details: 'Cập nhật số tài khoản nhận tiền VietQR: 19036789999 (Techcombank)',
      username: 'admin',
      ipAddress: '127.0.0.1',
      createdAt: new Date(now.getTime() - 360 * 60 * 1000).toISOString(),
    },
  ];
}

function getInitialLoginHistory() {
  const now = new Date();
  const currentDevice = getDeviceInfo();
  return [
    {
      id: 'login-001',
      username: 'admin',
      isSuccess: true,
      ipAddress: '127.0.0.1 (Localhost)',
      device: currentDevice,
      note: 'Đăng nhập thành công',
      loginTime: new Date(now.getTime() - 10 * 60 * 1000).toISOString(),
    },
    {
      id: 'login-002',
      username: 'admin',
      isSuccess: true,
      ipAddress: '192.168.1.15',
      device: 'Chrome (Windows 10/11)',
      note: 'Đăng nhập phiên làm việc buổi sáng',
      loginTime: new Date(now.getTime() - 320 * 60 * 1000).toISOString(),
    },
    {
      id: 'login-003',
      username: 'guest',
      isSuccess: false,
      ipAddress: '192.168.1.44',
      device: 'Safari (macOS)',
      note: 'Sai mật khẩu hoặc tài khoản không tồn tại',
      loginTime: new Date(now.getTime() - 480 * 60 * 1000).toISOString(),
    },
    {
      id: 'login-004',
      username: 'admin',
      isSuccess: true,
      ipAddress: '192.168.1.15',
      device: 'Chrome (Windows 10/11)',
      note: 'Đăng nhập thành công',
      loginTime: new Date(now.getTime() - 24 * 3600 * 1000).toISOString(),
    },
  ];
}

export const auditService = {
  // ================= 1. AUDIT LOGS (LỊCH SỬ CHỈNH SỬA / THAO TÁC) =================
  /**
   * Ghi nhận một thao tác chỉnh sửa / thêm / xóa
   */
  async logAction({
    action,
    entityName,
    entityId,
    entityDisplayName,
    details,
    username = 'admin',
  }) {
    const newLog = {
      id: 'audit-' + Date.now(),
      action: action || 'UPDATE',
      entityName: entityName || 'System',
      entityId: String(entityId || ''),
      entityDisplayName: entityDisplayName || entityName || 'Hệ thống',
      details: details || '',
      username: username || 'admin',
      ipAddress: '127.0.0.1',
      createdAt: new Date().toISOString(),
    };

    // 1. Lưu cục bộ trước để luôn có dữ liệu tức thì
    try {
      const stored = this.getLocalAuditLogs();
      stored.unshift(newLog);
      localStorage.setItem(AUDIT_STORAGE_KEY, JSON.stringify(stored.slice(0, 500)));
    } catch (e) {
      console.warn('Cannot write local audit log:', e);
    }

    // 2. Đồng bộ lên Backend API
    try {
      await auditApi.createLog({
        action: newLog.action,
        entityName: newLog.entityName,
        entityId: newLog.entityId,
        entityDisplayName: newLog.entityDisplayName,
        details: newLog.details,
        username: newLog.username,
      });
    } catch {
      // Backend có thể đang offline, dữ liệu đã lưu an toàn trong local
    }

    return newLog;
  },

  /**
   * Lấy danh sách lịch sử thao tác từ localStorage
   */
  getLocalAuditLogs() {
    try {
      const data = localStorage.getItem(AUDIT_STORAGE_KEY);
      if (data) return JSON.parse(data);
      const initial = getInitialAuditLogs();
      localStorage.setItem(AUDIT_STORAGE_KEY, JSON.stringify(initial));
      return initial;
    } catch {
      return getInitialAuditLogs();
    }
  },

  /**
   * Lấy danh sách lịch sử thao tác kèm bộ lọc
   */
  async getAuditLogs(params = {}) {
    const { q, entityName, action, fromDate, toDate } = params;

    let logs = [];
    try {
      const apiLogs = await auditApi.getLogs(params);
      if (Array.isArray(apiLogs) && apiLogs.length > 0) {
        logs = apiLogs;
      } else {
        logs = this.getLocalAuditLogs();
      }
    } catch {
      logs = this.getLocalAuditLogs();
    }

    // Lọc dữ liệu client-side nếu cần
    let filtered = [...logs];
    if (entityName && entityName !== 'all') {
      filtered = filtered.filter(
        (l) => l.entityName?.toLowerCase() === entityName.toLowerCase()
      );
    }
    if (action && action !== 'all') {
      filtered = filtered.filter(
        (l) => l.action?.toLowerCase() === action.toLowerCase()
      );
    }
    if (fromDate) {
      const from = new Date(fromDate);
      filtered = filtered.filter((l) => new Date(l.createdAt) >= from);
    }
    if (toDate) {
      const to = new Date(toDate);
      to.setHours(23, 59, 59, 999);
      filtered = filtered.filter((l) => new Date(l.createdAt) <= to);
    }
    if (q && q.trim()) {
      const term = q.trim().toLowerCase();
      filtered = filtered.filter(
        (l) =>
          l.entityDisplayName?.toLowerCase().includes(term) ||
          l.entityId?.toLowerCase().includes(term) ||
          l.details?.toLowerCase().includes(term) ||
          l.username?.toLowerCase().includes(term)
      );
    }

    // Sắp xếp theo thời gian mới nhất lên đầu
    filtered.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return filtered;
  },

  // ================= 2. LOGIN HISTORY (LỊCH SỬ ĐĂNG NHẬP) =================
  /**
   * Ghi nhận một lần đăng nhập (thành công hoặc thất bại)
   */
  async logLogin({ username, isSuccess, note, device }) {
    const deviceInfo = device || getDeviceInfo();
    const newHistory = {
      id: 'login-' + Date.now(),
      username: username || 'unknown',
      isSuccess: Boolean(isSuccess),
      ipAddress: '127.0.0.1 (Localhost)',
      device: deviceInfo,
      note: note || (isSuccess ? 'Đăng nhập thành công' : 'Đăng nhập thất bại'),
      loginTime: new Date().toISOString(),
    };

    // 1. Lưu cục bộ
    try {
      const stored = this.getLocalLoginHistory();
      stored.unshift(newHistory);
      localStorage.setItem(LOGIN_STORAGE_KEY, JSON.stringify(stored.slice(0, 300)));
    } catch (e) {
      console.warn('Cannot write local login history:', e);
    }

    // 2. Đồng bộ lên Backend
    try {
      await auditApi.createLoginHistory({
        username: newHistory.username,
        isSuccess: newHistory.isSuccess,
        device: newHistory.device,
        note: newHistory.note,
      });
    } catch {
      // Backend có thể đang offline
    }

    return newHistory;
  },

  /**
   * Lấy lịch sử đăng nhập từ localStorage
   */
  getLocalLoginHistory() {
    try {
      const data = localStorage.getItem(LOGIN_STORAGE_KEY);
      if (data) return JSON.parse(data);
      const initial = getInitialLoginHistory();
      localStorage.setItem(LOGIN_STORAGE_KEY, JSON.stringify(initial));
      return initial;
    } catch {
      return getInitialLoginHistory();
    }
  },

  /**
   * Lấy lịch sử đăng nhập kèm bộ lọc
   */
  async getLoginHistory(params = {}) {
    const { q, username, isSuccess } = params;

    let histories = [];
    try {
      const apiHistories = await auditApi.getLoginHistory(params);
      if (Array.isArray(apiHistories) && apiHistories.length > 0) {
        histories = apiHistories;
      } else {
        histories = this.getLocalLoginHistory();
      }
    } catch {
      histories = this.getLocalLoginHistory();
    }

    let filtered = [...histories];
    if (username && username !== 'all') {
      filtered = filtered.filter(
        (h) => h.username?.toLowerCase() === username.toLowerCase()
      );
    }
    if (isSuccess !== undefined && isSuccess !== null && isSuccess !== 'all') {
      const boolVal = isSuccess === true || isSuccess === 'true';
      filtered = filtered.filter((h) => h.isSuccess === boolVal);
    }
    if (q && q.trim()) {
      const term = q.trim().toLowerCase();
      filtered = filtered.filter(
        (h) =>
          h.username?.toLowerCase().includes(term) ||
          h.device?.toLowerCase().includes(term) ||
          h.note?.toLowerCase().includes(term) ||
          h.ipAddress?.toLowerCase().includes(term)
      );
    }

    filtered.sort((a, b) => new Date(b.loginTime) - new Date(a.loginTime));
    return filtered;
  },

  // ================= 3. THỐNG KÊ TỔNG QUAN =================
  async getSummaryStats() {
    const [logs, logins] = await Promise.all([
      this.getAuditLogs(),
      this.getLoginHistory(),
    ]);

    const todayStr = new Date().toISOString().slice(0, 10);
    const todayLogs = logs.filter((l) => l.createdAt?.startsWith(todayStr));
    const successfulLogins = logins.filter((l) => l.isSuccess);
    const failedLogins = logins.filter((l) => !l.isSuccess);

    return {
      totalEdits: logs.length,
      editsToday: todayLogs.length,
      totalLogins: logins.length,
      successfulLogins: successfulLogins.length,
      failedLogins: failedLogins.length,
      lastActive: logs[0] ? logs[0].createdAt : null,
    };
  },

  /**
   * Xóa toàn bộ lịch sử
   */
  clearLogs(type = 'all') {
    if (type === 'all' || type === 'audit') {
      localStorage.removeItem(AUDIT_STORAGE_KEY);
    }
    if (type === 'all' || type === 'login') {
      localStorage.removeItem(LOGIN_STORAGE_KEY);
    }
  },
};

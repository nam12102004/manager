import React, { useState, useEffect, useMemo } from 'react';
import StatCard from '../components/common/StatCard';
import { auditService } from '../services/auditService';
import { formatDate } from '../utils/formatters';
import { useNotification } from '../context/NotificationContext';

export default function AuditHistory() {
  const notify = useNotification();
  const [activeSubTab, setActiveSubTab] = useState('edits'); // 'edits' | 'logins'
  const [loading, setLoading] = useState(false);

  // Data states
  const [auditLogs, setAuditLogs] = useState([]);
  const [loginHistory, setLoginHistory] = useState([]);
  const [stats, setStats] = useState({
    totalEdits: 0,
    editsToday: 0,
    totalLogins: 0,
    successfulLogins: 0,
    failedLogins: 0,
  });

  // Filters for Edits
  const [editSearch, setEditSearch] = useState('');
  const [selectedEntity, setSelectedEntity] = useState('all');
  const [selectedAction, setSelectedAction] = useState('all');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  // Filters for Logins
  const [loginSearch, setLoginSearch] = useState('');
  const [loginStatusFilter, setLoginStatusFilter] = useState('all');

  // Modal detail
  const [selectedLog, setSelectedLog] = useState(null);

  // Load Data
  const loadData = async () => {
    setLoading(true);
    try {
      const [logs, logins, summary] = await Promise.all([
        auditService.getAuditLogs({
          q: editSearch,
          entityName: selectedEntity,
          action: selectedAction,
          fromDate,
          toDate,
        }),
        auditService.getLoginHistory({
          q: loginSearch,
          isSuccess: loginStatusFilter,
        }),
        auditService.getSummaryStats(),
      ]);

      setAuditLogs(logs);
      setLoginHistory(logins);
      setStats(summary);
    } catch (err) {
      notify.error(err.message || 'Không thể tải lịch sử hệ thống');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [selectedEntity, selectedAction, fromDate, toDate, loginStatusFilter]);

  // Format datetime full
  const formatDateTime = (isoStr) => {
    if (!isoStr) return '—';
    const d = new Date(isoStr);
    if (isNaN(d.getTime())) return isoStr;
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    const seconds = String(d.getSeconds()).padStart(2, '0');
    return `${day}/${month}/${year} ${hours}:${minutes}:${seconds}`;
  };

  // Badge for Action Type
  const renderActionBadge = (action) => {
    switch (action?.toUpperCase()) {
      case 'CREATE':
        return <span className="badge badge-success">Thêm mới</span>;
      case 'UPDATE':
        return <span className="badge badge-primary">Chỉnh sửa</span>;
      case 'ADJUST':
      case 'ADJUST_STOCK':
      case 'ADJUST_DEBT':
        return <span className="badge badge-warning">Điều chỉnh</span>;
      case 'CANCEL':
      case 'CANCEL_VOUCHER':
        return <span className="badge badge-danger">Hủy phiếu</span>;
      case 'DELETE':
        return <span className="badge badge-danger">Đã xóa</span>;
      case 'UPDATE_SETTINGS':
        return <span className="badge badge-info">Cài đặt</span>;
      case 'LOGOUT':
        return <span className="badge badge-neutral">Đăng xuất</span>;
      default:
        return <span className="badge badge-neutral">{action}</span>;
    }
  };

  // Icon for Entity Type
  const renderEntityIcon = (entityName) => null;

  const getEntityLabel = (name) => {
    const map = {
      product: 'Sản phẩm',
      customer: 'Khách hàng',
      supplier: 'Nhà cung cấp',
      exportvoucher: 'Xuất hàng',
      importvoucher: 'Nhập hàng',
      receipt: 'Phiếu thu',
      payment: 'Phiếu chi',
      owner: 'Cài đặt cửa hàng',
      user: 'Tài khoản',
    };
    return map[name?.toLowerCase()] || name || 'Đối tượng';
  };

  // Export to CSV
  const handleExportCsv = () => {
    let csvContent = '\uFEFF'; // UTF-8 BOM
    if (activeSubTab === 'edits') {
      csvContent += 'Thời gian,Tài khoản,Hành động,Đối tượng,Mã đối tượng,Tên đối tượng,Chi tiết thay đổi\n';
      auditLogs.forEach((l) => {
        const time = formatDateTime(l.createdAt);
        const details = (l.details || '').replace(/"/g, '""');
        const name = (l.entityDisplayName || '').replace(/"/g, '""');
        csvContent += `"${time}","${l.username}","${l.action}","${getEntityLabel(l.entityName)}","${l.entityId}","${name}","${details}"\n`;
      });
    } else {
      csvContent += 'Thời gian,Tài khoản,Trạng thái,Thiết bị/Trình duyệt,Địa chỉ IP,Ghi chú\n';
      loginHistory.forEach((h) => {
        const time = formatDateTime(h.loginTime);
        const status = h.isSuccess ? 'Thành công' : 'Thất bại';
        const device = (h.device || '').replace(/"/g, '""');
        const note = (h.note || '').replace(/"/g, '""');
        csvContent += `"${time}","${h.username}","${status}","${device}","${h.ipAddress || ''}","${note}"\n`;
      });
    }

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Lich_su_${activeSubTab === 'edits' ? 'chinh_sua' : 'dang_nhap'}_${Date.now()}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    notify.success('Đã xuất file báo cáo lịch sử thành công!');
  };

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <span>Lịch Sử Chỉnh Sửa & Đăng Nhập</span>
          </h1>
          <p className="page-subtitle">
            Hệ thống nhật ký kiểm toán ghi nhận mọi thao tác sửa đổi dữ liệu và lịch sử truy cập tài khoản
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadData} disabled={loading}>
            <span>{loading ? 'Đang tải...' : 'Làm mới'}</span>
          </button>
          <button className="btn btn-primary" onClick={handleExportCsv}>
            <span>Xuất file Excel/CSV</span>
          </button>
        </div>
      </div>

      {/* Overview Stat Cards */}
      <div className="stats-grid">
        <StatCard
          title="TỔNG THAO TÁC GHI NHẬN"
          value={stats.totalEdits.toLocaleString()}
          subtitle="Các lượt tạo, sửa, xóa, đổi nợ/kho"
          color="primary"
          onClick={() => setActiveSubTab('edits')}
        />
        <StatCard
          title="THAO TÁC HÔM NAY"
          value={stats.editsToday.toLocaleString()}
          subtitle="Số lần chỉnh sửa trong ngày hiện tại"
          color="purple"
          onClick={() => setActiveSubTab('edits')}
        />
        <StatCard
          title="LƯỢT ĐĂNG NHẬP THÀNH CÔNG"
          value={stats.successfulLogins.toLocaleString()}
          subtitle="Phiên làm việc an toàn được xác thực"
          color="success"
          onClick={() => setActiveSubTab('logins')}
        />
        <StatCard
          title="ĐĂNG NHẬP THẤT BẠI / CẢNH BÁO"
          value={stats.failedLogins.toLocaleString()}
          subtitle="Số lần nhập sai mật khẩu tài khoản"
          color="danger"
          onClick={() => setActiveSubTab('logins')}
        />
      </div>

      {/* Tab Switcher */}
      <div
        style={{
          display: 'flex',
          gap: '0.75rem',
          borderBottom: '2px solid var(--border-color)',
          marginBottom: '1.5rem',
        }}
      >
        <button
          onClick={() => setActiveSubTab('edits')}
          style={{
            padding: '0.75rem 1.25rem',
            background: 'transparent',
            border: 'none',
            borderBottom: activeSubTab === 'edits' ? '3px solid var(--primary)' : '3px solid transparent',
            color: activeSubTab === 'edits' ? 'var(--primary)' : 'var(--text-secondary)',
            fontWeight: activeSubTab === 'edits' ? 700 : 500,
            fontSize: '0.9375rem',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            marginBottom: '-2px',
            transition: 'all var(--transition-fast)',
          }}
        >
          <span>Nhật Ký Chỉnh Sửa & Thao Tác</span>
          <span className="badge badge-primary">{auditLogs.length}</span>
        </button>

        <button
          onClick={() => setActiveSubTab('logins')}
          style={{
            padding: '0.75rem 1.25rem',
            background: 'transparent',
            border: 'none',
            borderBottom: activeSubTab === 'logins' ? '3px solid var(--primary)' : '3px solid transparent',
            color: activeSubTab === 'logins' ? 'var(--primary)' : 'var(--text-secondary)',
            fontWeight: activeSubTab === 'logins' ? 700 : 500,
            fontSize: '0.9375rem',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            marginBottom: '-2px',
            transition: 'all var(--transition-fast)',
          }}
        >
          <span>Lịch Sử Đăng Nhập & Truy Cập</span>
          <span className="badge badge-neutral">{loginHistory.length}</span>
        </button>
      </div>

      {/* ================= TAB 1: NHẬT KÝ CHỈNH SỬA & THAO TÁC ================= */}
      {activeSubTab === 'edits' && (
        <div>
          {/* Filter Bar */}
          <div className="filter-bar">
            {/* Search */}
            <div style={{ minWidth: '260px', flex: 1 }}>
              <input
                type="text"
                className="form-input"
                placeholder="Tìm kiếm theo mã, tên đối tượng, chi tiết thay đổi..."
                value={editSearch}
                onChange={(e) => setEditSearch(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && loadData()}
              />
            </div>

            {/* Entity Filter */}
            <select
              className="form-select"
              style={{ width: '170px' }}
              value={selectedEntity}
              onChange={(e) => setSelectedEntity(e.target.value)}
            >
              <option value="all">Tất cả đối tượng</option>
              <option value="Product">Sản phẩm & Kho</option>
              <option value="Customer">Khách hàng</option>
              <option value="Supplier">Nhà cung cấp</option>
              <option value="ExportVoucher">Phiếu bán hàng</option>
              <option value="ImportVoucher">Phiếu mua hàng</option>
              <option value="Receipt">Phiếu thu tiền</option>
              <option value="Payment">Phiếu chi tiền</option>
              <option value="Owner">Cài đặt hệ thống</option>
            </select>

            {/* Action Filter */}
            <select
              className="form-select"
              style={{ width: '150px' }}
              value={selectedAction}
              onChange={(e) => setSelectedAction(e.target.value)}
            >
              <option value="all">Mọi hành động</option>
              <option value="CREATE">Thêm mới</option>
              <option value="UPDATE">Chỉnh sửa</option>
              <option value="ADJUST_DEBT">Điều chỉnh nợ</option>
              <option value="ADJUST_STOCK">Điều chỉnh kho</option>
              <option value="CANCEL">Hủy phiếu</option>
              <option value="DELETE">Xóa</option>
            </select>

            {/* Date Range */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
              <input
                type="date"
                className="form-input"
                style={{ width: '140px' }}
                value={fromDate}
                onChange={(e) => setFromDate(e.target.value)}
                title="Từ ngày"
              />
              <span style={{ color: 'var(--text-muted)' }}>-</span>
              <input
                type="date"
                className="form-input"
                style={{ width: '140px' }}
                value={toDate}
                onChange={(e) => setToDate(e.target.value)}
                title="Đến ngày"
              />
            </div>

            {(editSearch || selectedEntity !== 'all' || selectedAction !== 'all' || fromDate || toDate) && (
              <button
                className="btn btn-ghost btn-sm"
                onClick={() => {
                  setEditSearch('');
                  setSelectedEntity('all');
                  setSelectedAction('all');
                  setFromDate('');
                  setToDate('');
                }}
              >
                Đặt lại
              </button>
            )}
          </div>

          {/* Table */}
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '175px' }}>Thời Gian</th>
                  <th style={{ width: '130px' }}>Người Thực Hiện</th>
                  <th style={{ width: '110px' }}>Hành Động</th>
                  <th style={{ width: '150px' }}>Phân Loại</th>
                  <th style={{ width: '220px' }}>Đối Tượng / Mã</th>
                  <th>Nội Dung Chi Tiết Thay Đổi</th>
                  <th style={{ width: '60px', textAlign: 'center' }}>Xem</th>
                </tr>
              </thead>
              <tbody>
                {auditLogs.length === 0 ? (
                  <tr>
                    <td colSpan={7} style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-muted)' }}>
                      Không có bản ghi lịch sử chỉnh sửa nào phù hợp với bộ lọc.
                    </td>
                  </tr>
                ) : (
                  auditLogs.map((log) => (
                    <tr key={log.id} style={{ cursor: 'pointer' }} onClick={() => setSelectedLog(log)}>
                      <td className="mono" style={{ fontSize: '0.8125rem', whiteSpace: 'nowrap' }}>
                        {formatDateTime(log.createdAt)}
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                          <div
                            style={{
                              width: '24px',
                              height: '24px',
                              borderRadius: 'var(--radius-full)',
                              background: 'var(--bg-tertiary)',
                              color: 'var(--primary)',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontWeight: 700,
                              fontSize: '0.6875rem',
                              textTransform: 'uppercase',
                            }}
                          >
                            {log.username?.charAt(0) || 'U'}
                          </div>
                          <span style={{ fontWeight: 600 }}>{log.username}</span>
                        </div>
                      </td>
                      <td>{renderActionBadge(log.action)}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.8125rem' }}>
                          <span style={{ fontWeight: 500 }}>{getEntityLabel(log.entityName)}</span>
                        </div>
                      </td>
                      <td>
                        <div>
                          <div style={{ fontWeight: 600, color: 'var(--text-primary)' }}>
                            {log.entityDisplayName || log.entityName}
                          </div>
                          {log.entityId && (
                            <span className="mono" style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                              #{log.entityId}
                            </span>
                          )}
                        </div>
                      </td>
                      <td>
                        <div
                          style={{
                            maxWidth: '480px',
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            fontSize: '0.875rem',
                            color: 'var(--text-secondary)',
                          }}
                          title={log.details}
                        >
                          {log.details || '—'}
                        </div>
                      </td>
                      <td style={{ textAlign: 'center' }}>
                        <button
                          className="btn btn-ghost btn-sm"
                          style={{ padding: '2px 6px', fontSize: '0.75rem' }}
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedLog(log);
                          }}
                          title="Xem chi tiết"
                        >
                          Xem
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ================= TAB 2: LỊCH SỬ ĐĂNG NHẬP ================= */}
      {activeSubTab === 'logins' && (
        <div>
          {/* Filter Bar */}
          <div className="filter-bar">
            {/* Search */}
            <div style={{ minWidth: '260px', flex: 1 }}>
              <input
                type="text"
                className="form-input"
                placeholder="Tìm kiếm tài khoản, thiết bị, IP, ghi chú..."
                value={loginSearch}
                onChange={(e) => setLoginSearch(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && loadData()}
              />
            </div>

            {/* Status Filter */}
            <select
              className="form-select"
              style={{ width: '180px' }}
              value={loginStatusFilter}
              onChange={(e) => setLoginStatusFilter(e.target.value)}
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="true">Đăng nhập thành công</option>
              <option value="false">Đăng nhập thất bại</option>
            </select>

            {(loginSearch || loginStatusFilter !== 'all') && (
              <button
                className="btn btn-ghost btn-sm"
                onClick={() => {
                  setLoginSearch('');
                  setLoginStatusFilter('all');
                }}
              >
                Đặt lại
              </button>
            )}
          </div>

          {/* Table */}
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '185px' }}>Thời Điểm Đăng Nhập</th>
                  <th style={{ width: '150px' }}>Tài Khoản</th>
                  <th style={{ width: '140px', textAlign: 'center' }}>Trạng Thái</th>
                  <th style={{ width: '220px' }}>Thiết Bị / Trình Duyệt</th>
                  <th style={{ width: '160px' }}>Địa Chỉ IP</th>
                  <th>Ghi Chú & Kết Quả Xác Thực</th>
                </tr>
              </thead>
              <tbody>
                {loginHistory.length === 0 ? (
                  <tr>
                    <td colSpan={6} style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-muted)' }}>
                      Không có bản ghi lịch sử đăng nhập nào phù hợp.
                    </td>
                  </tr>
                ) : (
                  loginHistory.map((item) => (
                    <tr key={item.id}>
                      <td className="mono" style={{ fontSize: '0.8125rem' }}>
                        {formatDateTime(item.loginTime)}
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <div
                            style={{
                              width: '28px',
                              height: '28px',
                              borderRadius: 'var(--radius-full)',
                              background: item.isSuccess ? 'var(--success-light)' : 'var(--danger-light)',
                              color: item.isSuccess ? 'var(--success)' : 'var(--danger)',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontWeight: 700,
                              fontSize: '0.75rem',
                              textTransform: 'uppercase',
                            }}
                          >
                            {item.username?.charAt(0) || 'U'}
                          </div>
                          <span style={{ fontWeight: 600 }}>{item.username}</span>
                        </div>
                      </td>
                      <td style={{ textAlign: 'center' }}>
                        {item.isSuccess ? (
                          <span className="badge badge-success">
                            <span>Thành công</span>
                          </span>
                        ) : (
                          <span className="badge badge-danger">
                            <span>Thất bại</span>
                          </span>
                        )}
                      </td>
                      <td>
                        <div style={{ fontSize: '0.875rem' }}>
                          <span>{item.device || 'Web Browser'}</span>
                        </div>
                      </td>
                      <td className="mono" style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                        {item.ipAddress || '127.0.0.1'}
                      </td>
                      <td>
                        <span
                          style={{
                            fontWeight: 500,
                            color: item.isSuccess ? 'var(--text-secondary)' : 'var(--danger)',
                          }}
                        >
                          {item.note || (item.isSuccess ? 'Đăng nhập thành công' : 'Đăng nhập thất bại')}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ================= MODAL XEM CHI TIẾT THAO TÁC ================= */}
      {selectedLog && (
        <div className="modal-backdrop" onClick={() => setSelectedLog(null)}>
          <div className="modal-dialog" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '600px' }}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
                <h3 className="modal-title">Chi Tiết Nhật Ký Chỉnh Sửa</h3>
              </div>
              <button className="btn btn-ghost btn-icon" onClick={() => setSelectedLog(null)}>
                ✕
              </button>
            </div>

            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div style={{ background: 'var(--bg-tertiary)', padding: '0.875rem', borderRadius: 'var(--radius-md)' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                    THỜI GIAN THỰC HIỆN
                  </div>
                  <div className="mono" style={{ fontWeight: 700, fontSize: '0.875rem' }}>
                    {formatDateTime(selectedLog.createdAt)}
                  </div>
                </div>

                <div style={{ background: 'var(--bg-tertiary)', padding: '0.875rem', borderRadius: 'var(--radius-md)' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                    NGƯỜI THỰC HIỆN
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '0.875rem' }}>
                    {selectedLog.username}
                  </div>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                    HÀNH ĐỘNG
                  </div>
                  <div>{renderActionBadge(selectedLog.action)}</div>
                </div>

                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                    ĐỐI TƯỢNG TÁC ĐỘNG
                  </div>
                  <div style={{ fontWeight: 600 }}>
                    {getEntityLabel(selectedLog.entityName)} ({selectedLog.entityId || 'N/A'})
                  </div>
                </div>
              </div>

              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                  TÊN ĐỐI TƯỢNG HIỂN THỊ
                </div>
                <div style={{ fontWeight: 700, fontSize: '0.9375rem', color: 'var(--text-primary)' }}>
                  {selectedLog.entityDisplayName || selectedLog.entityName}
                </div>
              </div>

              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.35rem' }}>
                  NỘI DUNG BIẾN ĐỘNG / CHI TIẾT CHỈNH SỬA
                </div>
                <div
                  style={{
                    background: 'var(--bg-tertiary)',
                    padding: '1rem',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--border-color)',
                    fontSize: '0.875rem',
                    lineHeight: '1.6',
                    color: 'var(--text-primary)',
                    whiteSpace: 'pre-wrap',
                    wordBreak: 'break-word',
                  }}
                >
                  {selectedLog.details || 'Không có mô tả chi tiết thêm.'}
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn btn-primary" onClick={() => setSelectedLog(null)}>
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

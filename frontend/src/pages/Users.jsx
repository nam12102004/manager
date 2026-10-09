import React, { useState, useEffect } from 'react';
import { formatDate } from '../utils/formatters';
import { useNotification } from '../context/NotificationContext';
import { useAuth } from '../context/AuthContext';
import { userService } from '../services';
import SearchBar from '../components/common/SearchBar';
import Modal from '../components/common/Modal';
import ConfirmModal from '../components/common/ConfirmModal';
import EmptyState from '../components/common/EmptyState';

export default function Users() {
  const notify = useNotification();
  const { user: currentUser } = useAuth();

  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isPasswordOpen, setIsPasswordOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);

  // Form states
  const [createForm, setCreateForm] = useState({
    username: '',
    password: '',
    role: 'nv',
  });

  const [newPassword, setNewPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Load Users
  const loadUsers = async () => {
    setLoading(true);
    try {
      const data = await userService.getAll();
      setUsers(data || []);
    } catch (err) {
      notify.error(err.message || 'Không thể tải danh sách tài khoản');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  // Filtered users
  const filteredUsers = users.filter((u) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase().trim();
    return u.username.toLowerCase().includes(q) || u.role.toLowerCase().includes(q);
  });

  // Open Create
  const handleOpenCreate = () => {
    setCreateForm({
      username: '',
      password: '',
      role: 'nv',
    });
    setIsCreateOpen(true);
  };

  // Submit Create
  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await userService.create(createForm);
      notify.success(`Tạo tài khoản ${createForm.role === 'admin' ? 'Quản trị viên' : 'Nhân viên'} thành công!`);
      setIsCreateOpen(false);
      loadUsers();
    } catch (err) {
      notify.error(err.message || 'Tạo tài khoản thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Password Modal
  const handleOpenPassword = (u) => {
    setSelectedUser(u);
    setNewPassword('');
    setIsPasswordOpen(true);
  };

  // Submit Password Change
  const handlePasswordSubmit = async (e) => {
    e.preventDefault();
    if (!newPassword || newPassword.length < 6) {
      notify.warning('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }

    setSubmitting(true);
    try {
      await userService.changePassword(selectedUser.id, selectedUser.username, newPassword);
      notify.success(`Đổi mật khẩu tài khoản ${selectedUser.username} thành công!`);
      setIsPasswordOpen(false);
    } catch (err) {
      notify.error(err.message || 'Đổi mật khẩu thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // Open Delete
  const handleOpenDelete = (u) => {
    if (u.username.toLowerCase() === 'admin') {
      notify.warning('Không thể xóa tài khoản Quản trị viên mặc định');
      return;
    }
    if (currentUser && u.username.toLowerCase() === currentUser.username.toLowerCase()) {
      notify.warning('Bạn không thể tự xóa tài khoản đang đăng nhập');
      return;
    }
    setSelectedUser(u);
    setIsDeleteOpen(true);
  };

  // Confirm Delete
  const handleConfirmDelete = async () => {
    setSubmitting(true);
    try {
      await userService.delete(selectedUser.id, selectedUser.username);
      notify.success(`Xóa tài khoản ${selectedUser.username} thành công!`);
      setIsDeleteOpen(false);
      loadUsers();
    } catch (err) {
      notify.error(err.message || 'Xóa tài khoản thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const adminCount = users.filter((u) => u.role?.toLowerCase() === 'admin').length;
  const staffCount = users.filter((u) => u.role?.toLowerCase() !== 'admin').length;

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <span>Quản Lý Tài Khoản & Phân Quyền</span>
          </h1>
          <p className="page-subtitle">
            Cấp quyền đăng nhập cho Nhân viên và Quản trị viên
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadUsers} disabled={loading}>
            <span>{loading ? 'Đang tải...' : 'Tải lại'}</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <span>Tạo tài khoản mới</span>
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="stats-grid" style={{ marginBottom: '1.25rem' }}>
        <div className="stat-card">
          <div className="stat-content">
            <div className="stat-label">Tổng tài khoản</div>
            <div className="stat-value">{users.length}</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <div className="stat-label">Quản trị viên</div>
            <div className="stat-value" style={{ color: '#d97706' }}>
              {adminCount}
            </div>
            <div className="stat-sub">Toàn quyền hệ thống & Lịch sử thao tác</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <div className="stat-label">Nhân viên</div>
            <div className="stat-value" style={{ color: '#0284c7' }}>
              {staffCount}
            </div>
            <div className="stat-sub">Không được xem Lịch sử thao tác & Quản lý TK</div>
          </div>
        </div>
      </div>

      {/* Policy Notice Box */}
      <div
        style={{
          background: 'var(--bg-card)',
          border: '1px solid var(--border-color)',
          borderLeft: '4px solid var(--primary)',
          borderRadius: 'var(--radius-md)',
          padding: '1rem 1.25rem',
          marginBottom: '1.25rem',
        }}
      >
        <div style={{ fontSize: '0.875rem', lineHeight: '1.5' }}>
          <strong>Phân quyền bảo mật:</strong> Tài khoản <strong>Nhân viên</strong> được thao tác bán hàng, nhập kho, quản lý sản phẩm, khách hàng, nhà cung cấp và thu chi nhưng <strong>bị khóa hoàn toàn</strong> tính năng <em>Lịch sử thao tác</em> và <em>Quản lý tài khoản</em>. Chỉ <strong>Quản trị viên</strong> mới có quyền xem nhật ký và tạo tài khoản.
        </div>
      </div>

      {/* Filter Bar */}
      <div className="filter-bar">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Tìm theo tên đăng nhập hoặc vai trò..."
          style={{ flex: 1, minWidth: '280px' }}
        />
      </div>

      {/* Users Table */}
      {filteredUsers.length === 0 && !loading ? (
        <EmptyState
          title="Không tìm thấy tài khoản"
          description="Chưa có tài khoản nào phù hợp với từ khóa tìm kiếm."
          action={
            <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
              <span>Tạo tài khoản nhân viên</span>
            </button>
          }
        />
      ) : (
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Tên Đăng Nhập</th>
                <th>Vai Trò & Quyền Hạn</th>
                <th>Quyền Xem Lịch Sử Thao Tác</th>
                <th>Ngày Tạo</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((u) => {
                const isAdmin = u.role?.toLowerCase() === 'admin';
                const isCurrent = currentUser && u.username.toLowerCase() === currentUser.username.toLowerCase();

                return (
                  <tr key={u.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
                        <div
                          style={{
                            width: '34px',
                            height: '34px',
                            borderRadius: '50%',
                            background: isAdmin ? 'linear-gradient(135deg, #7c3aed, #2563eb)' : 'var(--bg-tertiary)',
                            color: isAdmin ? '#ffffff' : 'var(--text-primary)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: 700,
                            fontSize: '0.875rem',
                          }}
                        >
                          {u.username.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight: 700, fontSize: '0.9375rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                            <span>{u.username}</span>
                            {isCurrent && (
                              <span
                                style={{
                                  fontSize: '0.6875rem',
                                  padding: '2px 6px',
                                  borderRadius: '4px',
                                  background: 'var(--primary-light)',
                                  color: 'var(--primary)',
                                  fontWeight: 600,
                                }}
                              >
                                Bạn
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      {isAdmin ? (
                        <span
                          className="badge"
                          style={{
                            background: '#fef3c7',
                            color: '#b45309',
                            border: '1px solid #fde68a',
                            fontWeight: 700,
                          }}
                        >
                          Quản trị viên
                        </span>
                      ) : (
                        <span
                          className="badge"
                          style={{
                            background: '#e0f2fe',
                            color: '#0369a1',
                            border: '1px solid #bae6fd',
                            fontWeight: 700,
                          }}
                        >
                          Nhân viên
                        </span>
                      )}
                    </td>
                    <td>
                      {isAdmin ? (
                        <span style={{ color: 'var(--success)', fontSize: '0.8125rem', fontWeight: 600 }}>
                          Có quyền truy cập
                        </span>
                      ) : (
                        <span style={{ color: 'var(--text-muted)', fontSize: '0.8125rem', fontWeight: 500 }}>
                          Bị khóa
                        </span>
                      )}
                    </td>
                    <td style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
                      {formatDate(u.createdAt, true)}
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                        <button
                          className="btn btn-outline btn-sm"
                          style={{ fontSize: '0.75rem', padding: '2px 6px' }}
                          title="Đổi mật khẩu"
                          onClick={() => handleOpenPassword(u)}
                        >
                          Đổi MK
                        </button>
                        {u.username.toLowerCase() !== 'admin' && !isCurrent && (
                          <button
                            className="btn btn-outline btn-sm"
                            style={{ fontSize: '0.75rem', padding: '2px 6px', color: 'var(--danger)' }}
                            title="Xóa tài khoản"
                            onClick={() => handleOpenDelete(u)}
                          >
                            Xóa
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal Tạo Tài Khoản Mới */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Tạo Tài Khoản Mới"
        maxWidth="480px"
      >
        <form onSubmit={handleCreateSubmit}>
          <div className="form-group" style={{ marginBottom: '1rem' }}>
            <label className="form-label" required>
              Tên đăng nhập
            </label>
            <input
              type="text"
              className="form-control"
              placeholder="VD: nhanvien1, ketoan..."
              value={createForm.username}
              onChange={(e) => setCreateForm({ ...createForm, username: e.target.value })}
              required
              autoFocus
            />
          </div>

          <div className="form-group" style={{ marginBottom: '1rem' }}>
            <label className="form-label" required>
              Mật khẩu ban đầu
            </label>
            <input
              type="password"
              className="form-control"
              placeholder="Tối thiểu 6 ký tự"
              value={createForm.password}
              onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
              required
              minLength={6}
            />
          </div>

          <div className="form-group" style={{ marginBottom: '1.25rem' }}>
            <label className="form-label" required>
              Phân quyền / Vai trò
            </label>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem' }}>
              <label
                style={{
                  flex: 1,
                  border: `2px solid ${createForm.role === 'nv' ? 'var(--primary)' : 'var(--border-color)'}`,
                  background: createForm.role === 'nv' ? 'var(--primary-light)' : 'var(--bg-card)',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.75rem',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '0.5rem',
                }}
              >
                <input
                  type="radio"
                  name="role"
                  value="nv"
                  checked={createForm.role === 'nv'}
                  onChange={() => setCreateForm({ ...createForm, role: 'nv' })}
                  style={{ marginTop: '3px' }}
                />
                <div>
                  <div style={{ fontWeight: 700, fontSize: '0.875rem' }}>Nhân viên</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                    Thao tác bán hàng, kho, công nợ. <strong>Không xem lịch sử & tài khoản</strong>.
                  </div>
                </div>
              </label>

              <label
                style={{
                  flex: 1,
                  border: `2px solid ${createForm.role === 'admin' ? 'var(--primary)' : 'var(--border-color)'}`,
                  background: createForm.role === 'admin' ? 'var(--primary-light)' : 'var(--bg-card)',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.75rem',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '0.5rem',
                }}
              >
                <input
                  type="radio"
                  name="role"
                  value="admin"
                  checked={createForm.role === 'admin'}
                  onChange={() => setCreateForm({ ...createForm, role: 'admin' })}
                  style={{ marginTop: '3px' }}
                />
                <div>
                  <div style={{ fontWeight: 700, fontSize: '0.875rem' }}>Quản trị viên</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                    Toàn quyền hệ thống, xem nhật ký kiểm toán và quản lý người dùng.
                  </div>
                </div>
              </label>
            </div>
          </div>

          <div className="modal-footer" style={{ marginTop: '1.5rem' }}>
            <button type="button" className="btn btn-outline" onClick={() => setIsCreateOpen(false)}>
              Hủy
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting}>
              {submitting ? 'Đang tạo...' : 'Tạo tài khoản'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal Đổi Mật Khẩu */}
      <Modal
        isOpen={isPasswordOpen}
        onClose={() => setIsPasswordOpen(false)}
        title={`Đổi Mật Khẩu: ${selectedUser?.username}`}
        maxWidth="400px"
      >
        <form onSubmit={handlePasswordSubmit}>
          <div className="form-group" style={{ marginBottom: '1.25rem' }}>
            <label className="form-label" required>
              Mật khẩu mới
            </label>
            <input
              type="password"
              className="form-control"
              placeholder="Nhập mật khẩu mới"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
              minLength={6}
              autoFocus
            />
          </div>

          <div className="modal-footer">
            <button type="button" className="btn btn-outline" onClick={() => setIsPasswordOpen(false)}>
              Hủy
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting}>
              {submitting ? 'Đang lưu...' : 'Lưu mật khẩu mới'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal Xác Nhận Xóa */}
      <ConfirmModal
        isOpen={isDeleteOpen}
        onClose={() => setIsDeleteOpen(false)}
        onConfirm={handleConfirmDelete}
        title="Xác nhận xóa tài khoản"
        message={`Bạn có chắc chắn muốn xóa tài khoản "${selectedUser?.username}"? Người dùng này sẽ không thể đăng nhập vào hệ thống nữa.`}
        confirmText="Xác nhận xóa"
        confirmType="danger"
        loading={submitting}
      />
    </div>
  );
}

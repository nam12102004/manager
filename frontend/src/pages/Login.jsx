import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNotification } from '../context/NotificationContext';

export default function Login() {
  const { login } = useAuth();
  const notify = useNotification();

  const [username, setUsername] = useState('admin');
  const [password, setPassword] = useState('admin123');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!username.trim() || !password.trim()) {
      setErrorMsg('Vui lòng nhập tên đăng nhập và mật khẩu.');
      return;
    }

    setIsLoading(true);
    setErrorMsg('');
    try {
      await login(username.trim(), password);
      notify.success(`Chào mừng ${username} trở lại hệ thống!`);
    } catch (err) {
      setErrorMsg(err.message || 'Đăng nhập không thành công. Vui lòng kiểm tra lại tài khoản.');
      notify.error(err.message || 'Đăng nhập thất bại');
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickDemo = (user, pass) => {
    setUsername(user);
    setPassword(pass);
    setErrorMsg('');
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'radial-gradient(ellipse at top, #1e293b, #0f172a, #020617)',
        padding: '1.5rem',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Decorative ambient background lights */}
      <div
        style={{
          position: 'absolute',
          top: '-15%',
          left: '20%',
          width: '500px',
          height: '500px',
          background: 'rgba(37, 99, 235, 0.15)',
          borderRadius: '50%',
          filter: 'blur(100px)',
          pointerEvents: 'none',
        }}
      />
      <div
        style={{
          position: 'absolute',
          bottom: '-15%',
          right: '20%',
          width: '500px',
          height: '500px',
          background: 'rgba(124, 58, 237, 0.15)',
          borderRadius: '50%',
          filter: 'blur(100px)',
          pointerEvents: 'none',
        }}
      />

      <div
        style={{
          width: '100%',
          maxWidth: '440px',
          background: 'rgba(15, 23, 42, 0.85)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          border: '1px solid rgba(255, 255, 255, 0.12)',
          borderRadius: 'var(--radius-xl)',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.05)',
          padding: '2.5rem 2.25rem',
          position: 'relative',
          zIndex: 1,
        }}
      >
        {/* Brand header */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <h1 style={{ fontSize: '1.625rem', fontWeight: 800, color: '#ffffff', letterSpacing: '-0.02em', marginBottom: '0.375rem' }}>
            DebtManager
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#94a3b8' }}>
            Hệ thống Quản lý Bán hàng, Kho & Công nợ
          </p>
        </div>

        {/* Error notification */}
        {errorMsg && (
          <div
            style={{
              background: 'rgba(239, 68, 68, 0.15)',
              border: '1px solid rgba(239, 68, 68, 0.3)',
              borderRadius: 'var(--radius-md)',
              padding: '0.75rem 1rem',
              color: '#fca5a5',
              fontSize: '0.8125rem',
              marginBottom: '1.5rem',
            }}
          >
            <span>{errorMsg}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          {/* Username */}
          <div className="form-group" style={{ marginBottom: '1.25rem' }}>
            <label className="form-label" style={{ color: '#cbd5e1' }}>
              Tên đăng nhập <span className="req">*</span>
            </label>
            <div>
              <input
                type="text"
                className="form-input"
                style={{
                  background: 'rgba(30, 41, 59, 0.8)',
                  borderColor: 'rgba(255, 255, 255, 0.1)',
                  color: '#ffffff',
                }}
                placeholder="Nhập tên đăng nhập"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                autoComplete="username"
                required
              />
            </div>
          </div>

          {/* Password */}
          <div className="form-group" style={{ marginBottom: '1.75rem' }}>
            <label className="form-label" style={{ color: '#cbd5e1' }}>
              Mật khẩu <span className="req">*</span>
            </label>
            <div>
              <input
                type="password"
                className="form-input"
                style={{
                  background: 'rgba(30, 41, 59, 0.8)',
                  borderColor: 'rgba(255, 255, 255, 0.1)',
                  color: '#ffffff',
                }}
                placeholder="Nhập mật khẩu"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                required
              />
            </div>
          </div>

          {/* Submit button */}
          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: '100%', padding: '0.8125rem', fontSize: '0.9375rem' }}
            disabled={isLoading}
          >
            {isLoading ? (
              <span>Đang kết nối...</span>
            ) : (
              <span>Đăng nhập hệ thống</span>
            )}
          </button>
        </form>

        {/* Demo Quick Fill Helper */}
        <div
          style={{
            marginTop: '1.75rem',
            paddingTop: '1.25rem',
            borderTop: '1px solid rgba(255, 255, 255, 0.08)',
            textAlign: 'center',
          }}
        >
          <div style={{ color: '#94a3b8', fontSize: '0.75rem', marginBottom: '0.625rem' }}>
            <span>Tài khoản quản trị mặc định:</span>
          </div>
          <button
            type="button"
            onClick={() => handleQuickDemo('admin', 'admin123')}
            style={{
              background: 'rgba(59, 130, 246, 0.12)',
              border: '1px solid rgba(59, 130, 246, 0.3)',
              borderRadius: 'var(--radius-md)',
              padding: '0.4rem 0.875rem',
              color: '#93c5fd',
              fontSize: '0.8125rem',
              cursor: 'pointer',
              fontWeight: 600,
            }}
          >
            <span>Điền mẫu: admin / admin123</span>
          </button>
        </div>
      </div>
    </div>
  );
}

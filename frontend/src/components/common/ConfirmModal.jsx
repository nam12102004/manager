import React from 'react';
import Modal from './Modal';
import { AlertCircle } from 'lucide-react';

export default function ConfirmModal({
  isOpen,
  onClose,
  onConfirm,
  title = 'Xác nhận hành động',
  message = 'Bạn có chắc chắn muốn thực hiện thao tác này?',
  confirmText = 'Xác nhận',
  cancelText = 'Hủy bỏ',
  isDanger = false,
  isLoading = false,
}) {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={title}
      size="sm"
      footer={
        <>
          <button className="btn btn-outline" onClick={onClose} disabled={isLoading}>
            {cancelText}
          </button>
          <button
            className={`btn ${isDanger ? 'btn-danger' : 'btn-primary'}`}
            onClick={onConfirm}
            disabled={isLoading}
          >
            {isLoading ? 'Đang xử lý...' : confirmText}
          </button>
        </>
      }
    >
      <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-start' }}>
        <div
          style={{
            background: isDanger ? 'var(--danger-light)' : 'var(--primary-light)',
            color: isDanger ? 'var(--danger)' : 'var(--primary)',
            padding: '0.625rem',
            borderRadius: 'var(--radius-md)',
            flexShrink: 0,
          }}
        >
          <AlertCircle size={24} />
        </div>
        <div>
          <p style={{ fontSize: '0.9375rem', color: 'var(--text-primary)', lineHeight: 1.5 }}>
            {message}
          </p>
        </div>
      </div>
    </Modal>
  );
}

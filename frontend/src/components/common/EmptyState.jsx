import React from 'react';
import { PackageOpen } from 'lucide-react';

export default function EmptyState({
  icon: Icon = PackageOpen,
  title = 'Không có dữ liệu',
  description = 'Chưa có bản ghi nào phù hợp với điều kiện tìm kiếm hoặc dữ liệu đang trống.',
  action = null,
}) {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '3.5rem 1.5rem',
        textAlign: 'center',
        background: 'var(--bg-secondary)',
        borderRadius: 'var(--radius-lg)',
        border: '1px dashed var(--border-color)',
        margin: '1rem 0',
      }}
    >
      <div
        style={{
          width: '56px',
          height: '56px',
          borderRadius: 'var(--radius-full)',
          background: 'var(--bg-tertiary)',
          color: 'var(--text-muted)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '1rem',
        }}
      >
        <Icon size={28} />
      </div>
      <h4 style={{ fontSize: '1.0625rem', fontWeight: 700, marginBottom: '0.375rem', color: 'var(--text-primary)' }}>
        {title}
      </h4>
      <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', maxWidth: '420px', marginBottom: action ? '1.25rem' : 0 }}>
        {description}
      </p>
      {action}
    </div>
  );
}

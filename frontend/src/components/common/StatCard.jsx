import React from 'react';

export default function StatCard({
  title,
  value,
  subtitle,
  icon: Icon,
  color = 'primary', // 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'purple'
  badge = null,
  onClick = null,
}) {
  const colorMap = {
    primary: { bg: 'var(--primary-light)', text: 'var(--primary)', border: 'rgba(59, 130, 246, 0.2)' },
    success: { bg: 'var(--success-light)', text: 'var(--success)', border: 'rgba(16, 185, 129, 0.2)' },
    warning: { bg: 'var(--warning-light)', text: 'var(--warning)', border: 'rgba(245, 158, 11, 0.2)' },
    danger: { bg: 'var(--danger-light)', text: 'var(--danger)', border: 'rgba(239, 68, 68, 0.2)' },
    info: { bg: 'var(--info-light)', text: 'var(--info)', border: 'rgba(6, 182, 212, 0.2)' },
    purple: { bg: 'var(--purple-light)', text: 'var(--purple)', border: 'rgba(139, 92, 246, 0.2)' },
  };

  const themeStyle = colorMap[color] || colorMap.primary;

  return (
    <div
      className="glass-card"
      style={{
        padding: '1.25rem 1.5rem',
        cursor: onClick ? 'pointer' : 'default',
        position: 'relative',
        overflow: 'hidden',
      }}
      onClick={onClick}
    >
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
        <span style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
          {title}
        </span>
        {Icon && (
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: 'var(--radius-md)',
              background: themeStyle.bg,
              color: themeStyle.text,
              border: `1px solid ${themeStyle.border}`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Icon size={20} />
          </div>
        )}
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', marginBottom: '0.35rem' }}>
        <div style={{ fontSize: '1.625rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
          {value}
        </div>
        {badge}
      </div>

      {subtitle && (
        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
          {subtitle}
        </div>
      )}
    </div>
  );
}

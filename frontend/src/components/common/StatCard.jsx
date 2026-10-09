import React from 'react';

export default function StatCard({
  title,
  value,
  subtitle,
  icon: Icon = null,
  color = 'primary', // 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'purple'
  badge = null,
  onClick = null,
}) {
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
              width: '34px',
              height: '34px',
              borderRadius: 'var(--radius-md)',
              background: `var(--${color}-light, var(--primary-light))`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: `var(--${color}, var(--primary))`,
            }}
          >
            <Icon size={18} />
          </div>
        )}
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', marginBottom: '0.35rem' }}>
        <div style={{ fontSize: '1.5rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
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

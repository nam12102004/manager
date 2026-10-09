import React from 'react';
import { ArrowUpDown } from 'lucide-react';

/**
 * Common Dropdown Component for Numeric Sorting
 */
export default function SortDropdown({ value, onChange, options = [], style = {} }) {
  const isCustomSorted = value && value !== 'default';

  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        position: 'relative',
        minWidth: '220px',
        ...style,
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: '0.75rem',
          display: 'flex',
          alignItems: 'center',
          pointerEvents: 'none',
          color: isCustomSorted ? 'var(--primary)' : 'var(--text-muted)',
          zIndex: 1,
        }}
      >
        <ArrowUpDown size={15} />
      </div>

      <select
        className="form-select"
        value={value || 'default'}
        onChange={(e) => onChange(e.target.value)}
        style={{
          paddingLeft: '2.25rem',
          paddingRight: '1.75rem',
          fontSize: '0.875rem',
          fontWeight: isCustomSorted ? 600 : 400,
          color: isCustomSorted ? 'var(--primary)' : 'var(--text-primary)',
          borderColor: isCustomSorted ? 'var(--primary)' : 'var(--border-color)',
          backgroundColor: isCustomSorted ? 'var(--primary-light)' : 'var(--bg-secondary)',
          cursor: 'pointer',
          height: '42px',
          borderRadius: 'var(--radius-md)',
          boxShadow: 'none',
        }}
      >
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
    </div>
  );
}

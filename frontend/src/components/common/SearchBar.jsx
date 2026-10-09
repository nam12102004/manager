import React, { useState, useEffect } from 'react';

export default function SearchBar({
  value = '',
  onChange,
  placeholder = 'Tìm kiếm...',
  debounceMs = 300,
  style = {},
}) {
  const [internalValue, setInternalValue] = useState(value);

  useEffect(() => {
    setInternalValue(value);
  }, [value]);

  useEffect(() => {
    const handler = setTimeout(() => {
      if (internalValue !== value) {
        onChange(internalValue);
      }
    }, debounceMs);

    return () => clearTimeout(handler);
  }, [internalValue, debounceMs, onChange, value]);

  const handleClear = () => {
    setInternalValue('');
    onChange('');
  };

  return (
    <div className="input-with-action" style={{ minWidth: '260px', position: 'relative', ...style }}>
      <input
        type="text"
        className="form-input"
        placeholder={placeholder}
        value={internalValue}
        onChange={(e) => setInternalValue(e.target.value)}
      />
      {internalValue && (
        <button 
          className="clear-btn" 
          onClick={handleClear} 
          type="button" 
          title="Xóa tìm kiếm"
          style={{ fontSize: '0.75rem', padding: '2px 6px', right: '8px' }}
        >
          Xóa
        </button>
      )}
    </div>
  );
}

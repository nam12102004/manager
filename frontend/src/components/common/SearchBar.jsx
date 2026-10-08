import React, { useState, useEffect } from 'react';
import { Search, X } from 'lucide-react';

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
    <div className="input-with-icon input-with-action" style={{ minWidth: '260px', ...style }}>
      <Search className="input-icon" size={18} />
      <input
        type="text"
        className="form-input"
        placeholder={placeholder}
        value={internalValue}
        onChange={(e) => setInternalValue(e.target.value)}
      />
      {internalValue && (
        <button className="clear-btn" onClick={handleClear} type="button" title="Xóa tìm kiếm">
          <X size={16} />
        </button>
      )}
    </div>
  );
}

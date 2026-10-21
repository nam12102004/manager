import React, { useState, useRef, useEffect, useMemo, useLayoutEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { Search, ChevronDown, X, Check } from 'lucide-react';

const STYLES = `
.mss-container { position: relative; width: 100%; font-family: inherit; }
.mss-trigger {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  min-height: 42px;
  padding: 5px 10px;
  background: var(--bg-secondary, #ffffff);
  border: 1px solid var(--border-color, #e2e8f0);
  border-radius: var(--radius-md, 10px);
  color: var(--text-primary, #0f172a);
  cursor: pointer;
  transition: border-color 0.15s ease, box-shadow 0.15s ease, background-color 0.15s ease;
  user-select: none;
}
.mss-trigger:hover:not(.disabled) {
  border-color: var(--text-muted, #64748b);
}
.mss-trigger.focused {
  border-color: var(--primary, #2563eb);
  box-shadow: 0 0 0 3px var(--primary-glow, rgba(37, 99, 235, 0.2));
}
.mss-trigger.disabled {
  background: var(--bg-tertiary, #f1f5f9);
  cursor: not-allowed;
  opacity: 0.65;
}
.mss-trigger-left {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
  flex: 1;
  min-width: 0;
}
.mss-all-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
  color: var(--text-secondary, #334155);
  font-weight: 500;
  padding: 2px 4px;
}
.mss-all-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--success, #10b981);
  flex-shrink: 0;
}
.mss-chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  max-width: 190px;
  padding: 3px 8px;
  border-radius: var(--radius-sm, 6px);
  background: var(--primary-light, #eff6ff);
  border: 1px solid rgba(37, 99, 235, 0.25);
  color: var(--primary, #2563eb);
  font-size: 0.78rem;
  font-weight: 600;
  line-height: 1.25;
}
.mss-chip-code {
  font-family: var(--font-mono, monospace);
  font-size: 0.72rem;
  opacity: 0.85;
}
.mss-chip-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.mss-chip-remove {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  padding: 1px;
  border-radius: 3px;
  opacity: 0.7;
  transition: opacity 0.12s ease, background-color 0.12s ease;
}
.mss-chip-remove:hover {
  opacity: 1;
  background: rgba(37, 99, 235, 0.15);
}
.mss-chip-more {
  display: inline-flex;
  align-items: center;
  padding: 3px 8px;
  border-radius: var(--radius-sm, 6px);
  background: var(--primary, #2563eb);
  color: #ffffff;
  font-size: 0.75rem;
  font-weight: 700;
}
.mss-trigger-right {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}
.mss-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border: none;
  background: transparent;
  color: var(--text-muted, #64748b);
  border-radius: var(--radius-xs, 4px);
  cursor: pointer;
  transition: color 0.15s ease, background-color 0.15s ease;
}
.mss-icon-btn:hover {
  color: var(--danger, #ef4444);
  background: var(--bg-tertiary, #f1f5f9);
}
.mss-chevron {
  color: var(--text-muted, #64748b);
  transition: transform 0.2s ease;
  display: flex;
  align-items: center;
}
.mss-chevron.open {
  transform: rotate(180deg);
  color: var(--primary, #2563eb);
}

/* Portal Popover */
.mss-popover {
  background: var(--bg-secondary, #ffffff);
  border: 1px solid var(--border-color, #e2e8f0);
  border-radius: var(--radius-md, 10px);
  box-shadow: var(--shadow-lg, 0 10px 25px -5px rgba(0, 0, 0, 0.15));
  display: flex;
  flex-direction: column;
  overflow: hidden;
  font-family: var(--font-sans, system-ui, sans-serif);
  animation: mssFadeIn 0.12s ease-out;
}
@keyframes mssFadeIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}
.mss-search-wrap {
  padding: 8px 10px;
  border-bottom: 1px solid var(--border-light, #f1f5f9);
  background: var(--bg-secondary, #ffffff);
}
.mss-search-box {
  position: relative;
  display: flex;
  align-items: center;
}
.mss-search-icon {
  position: absolute;
  left: 10px;
  color: var(--text-muted, #64748b);
  pointer-events: none;
}
.mss-search-input {
  width: 100%;
  padding: 7px 30px 7px 32px;
  font-size: 0.84rem;
  font-family: inherit;
  color: var(--text-primary, #0f172a);
  background: var(--bg-tertiary, #f1f5f9);
  border: 1px solid transparent;
  border-radius: var(--radius-sm, 6px);
  outline: none;
  transition: border-color 0.15s ease, background-color 0.15s ease;
}
.mss-search-input:focus {
  background: var(--bg-secondary, #ffffff);
  border-color: var(--primary, #2563eb);
}
.mss-search-clear {
  position: absolute;
  right: 6px;
  border: none;
  background: transparent;
  color: var(--text-muted, #64748b);
  cursor: pointer;
  padding: 3px;
  display: flex;
  align-items: center;
  border-radius: 4px;
}
.mss-search-clear:hover {
  color: var(--text-primary, #0f172a);
}

/* Quick Action Toolbar */
.mss-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 6px 12px;
  background: var(--bg-tertiary, #f1f5f9);
  border-bottom: 1px solid var(--border-color, #e2e8f0);
  font-size: 0.76rem;
}
.mss-count {
  font-weight: 700;
  color: var(--text-secondary, #334155);
}
.mss-count.active {
  color: var(--primary, #2563eb);
}
.mss-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}
.mss-action-btn {
  border: none;
  background: transparent;
  font-family: inherit;
  font-size: 0.76rem;
  font-weight: 600;
  color: var(--text-secondary, #334155);
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
  transition: all 0.12s ease;
}
.mss-action-btn:hover {
  background: var(--bg-hover, #e2e8f0);
  color: var(--primary, #2563eb);
}
.mss-action-btn.primary {
  color: var(--primary, #2563eb);
}
.mss-action-btn.active-filter {
  background: var(--primary, #2563eb);
  color: #ffffff;
}
.mss-divider {
  color: var(--border-color, #cbd5e1);
}

/* Options List */
.mss-list {
  overflow-y: auto;
  max-height: 260px;
  padding: 4px 0;
}
.mss-empty {
  padding: 20px 14px;
  text-align: center;
  font-size: 0.82rem;
  color: var(--text-muted, #64748b);
}
.mss-option {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  cursor: pointer;
  transition: background-color 0.1s ease;
  border-left: 3px solid transparent;
}
.mss-option:hover,
.mss-option.highlighted {
  background: var(--bg-tertiary, #f1f5f9);
}
.mss-option.checked {
  background: var(--primary-light, #eff6ff);
  border-left-color: var(--primary, #2563eb);
}
.mss-checkbox {
  width: 18px;
  height: 18px;
  border-radius: 5px;
  border: 1.5px solid var(--border-color, #cbd5e1);
  background: var(--bg-secondary, #ffffff);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.12s ease;
  color: #ffffff;
}
.mss-option.checked .mss-checkbox {
  background: var(--primary, #2563eb);
  border-color: var(--primary, #2563eb);
}
.mss-opt-body {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}
.mss-opt-main {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
}
.mss-opt-code {
  font-family: var(--font-mono, monospace);
  font-size: 0.73rem;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
  background: var(--bg-tertiary, #e2e8f0);
  color: var(--text-secondary, #475569);
  flex-shrink: 0;
}
.mss-option.checked .mss-opt-code {
  background: rgba(37, 99, 235, 0.14);
  color: var(--primary, #2563eb);
}
.mss-opt-label {
  font-size: 0.84rem;
  font-weight: 500;
  color: var(--text-primary, #0f172a);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.mss-option.checked .mss-opt-label {
  font-weight: 700;
  color: var(--primary, #2563eb);
}
.mss-opt-sub {
  font-size: 0.74rem;
  color: var(--text-muted, #64748b);
  flex-shrink: 0;
  white-space: nowrap;
}
`;

let stylesInjected = false;
function ensureStyles() {
  if (stylesInjected || typeof document === 'undefined') return;
  const styleEl = document.createElement('style');
  styleEl.setAttribute('data-component', 'multi-searchable-select');
  styleEl.textContent = STYLES;
  document.head.appendChild(styleEl);
  stylesInjected = true;
}

/**
 * MultiSearchableSelect
 * Portal-based multi-select dropdown using DebtManager CSS Variables.
 */
export default function MultiSearchableSelect({
  options = [],
  value = [],
  onChange,
  placeholder = 'Tất cả',
  searchPlaceholder = 'Gõ tên, mã hoặc SĐT để tìm...',
  searchFields = ['label', 'name', 'code', 'sku', 'phone', 'value'],
  allLabel,
  disabled = false,
  className = '',
  maxDisplayTags = 2,
}) {
  useEffect(() => {
    ensureStyles();
  }, []);

  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showOnlySelected, setShowOnlySelected] = useState(false);
  const [highlightedIndex, setHighlightedIndex] = useState(0);
  const [dropdownStyle, setDropdownStyle] = useState({});

  const containerRef = useRef(null);
  const dropdownRef = useRef(null);
  const inputRef = useRef(null);
  const listRef = useRef(null);

  const normalizeText = (str) => {
    if (!str) return '';
    return str
      .toString()
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();
  };

  const selectedValues = useMemo(
    () => (Array.isArray(value) ? value.map((v) => String(v)) : []),
    [value]
  );

  const selectedSet = useMemo(() => new Set(selectedValues), [selectedValues]);

  const optionMap = useMemo(() => {
    const map = new Map();
    options.forEach((opt) => {
      const key = String(opt.value ?? opt.id);
      map.set(key, opt);
    });
    return map;
  }, [options]);

  const filteredOptions = useMemo(() => {
    let list = options;
    if (showOnlySelected) {
      list = list.filter((opt) => selectedSet.has(String(opt.value ?? opt.id)));
    }
    if (!searchQuery.trim()) return list;
    const query = normalizeText(searchQuery);
    return list.filter((opt) =>
      searchFields.some((field) => {
        const val = opt[field] ?? opt.label ?? opt.name ?? opt.value;
        if (!val) return false;
        return normalizeText(val).includes(query);
      })
    );
  }, [options, searchQuery, searchFields, showOnlySelected, selectedSet]);

  useEffect(() => {
    setHighlightedIndex(0);
  }, [filteredOptions]);

  const updateDropdownPosition = useCallback(() => {
    if (isOpen && containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect();
      const windowHeight = window.innerHeight;
      const estimatedHeight = 350;

      let top = rect.bottom + 5;
      if (top + estimatedHeight > windowHeight && rect.top > estimatedHeight) {
        top = Math.max(8, rect.top - estimatedHeight - 5);
      }

      setDropdownStyle({
        position: 'fixed',
        top: `${top}px`,
        left: `${rect.left}px`,
        width: `${Math.max(rect.width, 280)}px`,
        zIndex: 999999,
      });
    }
  }, [isOpen]);

  useLayoutEffect(() => {
    updateDropdownPosition();
    if (isOpen) {
      window.addEventListener('scroll', updateDropdownPosition, true);
      window.addEventListener('resize', updateDropdownPosition);
    }
    return () => {
      window.removeEventListener('scroll', updateDropdownPosition, true);
      window.removeEventListener('resize', updateDropdownPosition);
    };
  }, [isOpen, updateDropdownPosition]);

  useEffect(() => {
    const handleClickOutside = (e) => {
      const outsideTrigger = containerRef.current && !containerRef.current.contains(e.target);
      const outsideDropdown = !dropdownRef.current || !dropdownRef.current.contains(e.target);
      if (outsideTrigger && outsideDropdown) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 30);
    } else {
      setSearchQuery('');
      setShowOnlySelected(false);
    }
  }, [isOpen]);

  const castValues = (strArr) =>
    strArr.map((v) => {
      const orig = optionMap.get(v);
      return orig && typeof orig.value === 'number' ? Number(v) : v;
    });

  const toggleOption = (optVal) => {
    const strVal = String(optVal);
    const next = selectedSet.has(strVal)
      ? selectedValues.filter((v) => v !== strVal)
      : [...selectedValues, strVal];
    onChange(castValues(next));
  };

  const selectAllFiltered = () => {
    const nextSet = new Set(selectedValues);
    filteredOptions.forEach((opt) => {
      nextSet.add(String(opt.value ?? opt.id));
    });
    onChange(castValues(Array.from(nextSet)));
  };

  const clearAll = () => {
    onChange([]);
    setShowOnlySelected(false);
  };

  const removeValue = (e, valToRemove) => {
    e.stopPropagation();
    const strVal = String(valToRemove);
    onChange(castValues(selectedValues.filter((v) => v !== strVal)));
  };

  const handleKeyDown = (e) => {
    if (!isOpen) {
      if (e.key === 'Enter' || e.key === 'ArrowDown' || e.key === ' ') {
        e.preventDefault();
        setIsOpen(true);
      }
      return;
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlightedIndex((prev) => (prev < filteredOptions.length - 1 ? prev + 1 : 0));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlightedIndex((prev) => (prev > 0 ? prev - 1 : Math.max(0, filteredOptions.length - 1)));
    } else if (e.key === 'Enter' && filteredOptions[highlightedIndex]) {
      e.preventDefault();
      const opt = filteredOptions[highlightedIndex];
      toggleOption(opt.value ?? opt.id);
    } else if (e.key === 'Escape') {
      e.preventDefault();
      setIsOpen(false);
    }
  };

  const selectedItems = useMemo(
    () => selectedValues.map((val) => optionMap.get(val)).filter(Boolean),
    [selectedValues, optionMap]
  );

  const displayPlaceholder = allLabel || placeholder;

  return (
    <div
      ref={containerRef}
      className={`mss-container ${className}`}
      onKeyDown={handleKeyDown}
    >
      {/* Trigger Box */}
      <div
        role="button"
        tabIndex={disabled ? -1 : 0}
        aria-expanded={isOpen}
        onClick={() => !disabled && setIsOpen((prev) => !prev)}
        className={`mss-trigger ${isOpen ? 'focused' : ''} ${disabled ? 'disabled' : ''}`}
      >
        <div className="mss-trigger-left">
          {selectedItems.length === 0 ? (
            <span className="mss-all-badge">
              <span className="mss-all-dot" />
              <span>{displayPlaceholder}</span>
            </span>
          ) : (
            <>
              {selectedItems.slice(0, maxDisplayTags).map((item) => {
                const key = String(item.value ?? item.id);
                return (
                  <span key={key} className="mss-chip">
                    {item.code && <span className="mss-chip-code">{item.code}</span>}
                    <span className="mss-chip-label">{item.label || item.name}</span>
                    <button
                      type="button"
                      className="mss-chip-remove"
                      onClick={(e) => removeValue(e, key)}
                      title="Bỏ mục này"
                    >
                      <X size={12} />
                    </button>
                  </span>
                );
              })}
              {selectedItems.length > maxDisplayTags && (
                <span className="mss-chip-more">
                  +{selectedItems.length - maxDisplayTags} đã chọn
                </span>
              )}
            </>
          )}
        </div>

        <div className="mss-trigger-right">
          {selectedItems.length > 0 && !disabled && (
            <button
              type="button"
              className="mss-icon-btn"
              onClick={(e) => {
                e.stopPropagation();
                clearAll();
              }}
              title="Bỏ chọn tất cả"
            >
              <X size={14} />
            </button>
          )}
          <span className={`mss-chevron ${isOpen ? 'open' : ''}`}>
            <ChevronDown size={16} />
          </span>
        </div>
      </div>

      {/* Floating Portal Dropdown */}
      {isOpen &&
        createPortal(
          <div
            ref={dropdownRef}
            className="mss-popover"
            style={dropdownStyle}
            onKeyDown={handleKeyDown}
          >
            {/* Search Input */}
            <div className="mss-search-wrap">
              <div className="mss-search-box">
                <Search size={15} className="mss-search-icon" />
                <input
                  ref={inputRef}
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder={searchPlaceholder}
                  className="mss-search-input"
                />
                {searchQuery && (
                  <button
                    type="button"
                    className="mss-search-clear"
                    onClick={() => setSearchQuery('')}
                  >
                    <X size={13} />
                  </button>
                )}
              </div>
            </div>

            {/* Quick Action Bar */}
            <div className="mss-toolbar">
              <span className={`mss-count ${selectedValues.length > 0 ? 'active' : ''}`}>
                {selectedValues.length === 0
                  ? `Đang lấy tất cả · ${options.length} mục`
                  : `Đã chọn ${selectedValues.length} / ${options.length}`}
              </span>
              <div className="mss-actions">
                <button
                  type="button"
                  className="mss-action-btn primary"
                  onClick={selectAllFiltered}
                >
                  Chọn hết
                </button>
                {selectedValues.length > 0 && (
                  <>
                    <span className="mss-divider">·</span>
                    <button
                      type="button"
                      className={`mss-action-btn ${showOnlySelected ? 'active-filter' : ''}`}
                      onClick={() => setShowOnlySelected((prev) => !prev)}
                    >
                      Đã chọn
                    </button>
                    <span className="mss-divider">·</span>
                    <button
                      type="button"
                      className="mss-action-btn"
                      onClick={clearAll}
                    >
                      Bỏ chọn
                    </button>
                  </>
                )}
              </div>
            </div>

            {/* Options List */}
            <div ref={listRef} className="mss-list">
              {filteredOptions.length === 0 ? (
                <div className="mss-empty">Không tìm thấy mục phù hợp</div>
              ) : (
                filteredOptions.map((opt, idx) => {
                  const optKey = String(opt.value ?? opt.id);
                  const isChecked = selectedSet.has(optKey);
                  const isHighlighted = idx === highlightedIndex;
                  return (
                    <div
                      key={optKey}
                      onClick={() => toggleOption(optKey)}
                      onMouseEnter={() => setHighlightedIndex(idx)}
                      className={`mss-option ${isChecked ? 'checked' : ''} ${
                        isHighlighted ? 'highlighted' : ''
                      }`}
                    >
                      <div className="mss-checkbox">
                        {isChecked && <Check size={12} strokeWidth={3} />}
                      </div>

                      <div className="mss-opt-body">
                        <div className="mss-opt-main">
                          {opt.code && <span className="mss-opt-code">{opt.code}</span>}
                          <span className="mss-opt-label">{opt.label || opt.name}</span>
                        </div>
                        {(opt.phone || opt.subLabel) && (
                          <span className="mss-opt-sub">
                            {opt.phone ? `📞 ${opt.phone}` : opt.subLabel}
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>,
          document.body
        )}
    </div>
  );
}

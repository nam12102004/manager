import React, { useState, useRef, useEffect, useMemo, useLayoutEffect } from 'react';
import { createPortal } from 'react-dom';
import { Search, ChevronDown, X, Check } from 'lucide-react';

/**
 * SearchableSelect Component
 * - Displays all options when input is empty.
 * - Filters options when user types (supports multiple search fields: name, code/sku, phone, etc.).
 * - Shows rich information for each option via custom label/subLabel or custom renderOption.
 * - Handles keyboard navigation (ArrowUp, ArrowDown, Enter, Escape).
 * - Click-outside to close.
 */
export default function SearchableSelect({
  options = [],
  value = '',
  onChange,
  placeholder = '-- Chọn hoặc gõ tìm kiếm --',
  searchPlaceholder = 'Gõ để tìm kiếm...',
  searchFields = ['label', 'code', 'phone'],
  renderOption,
  renderSelected,
  disabled = false,
  required = false,
  className = '',
  style = {},
  allowClear = true,
  allowCustom = false,
}) {
  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [highlightedIndex, setHighlightedIndex] = useState(0);

  const containerRef = useRef(null);
  const inputRef = useRef(null);
  const listRef = useRef(null);

  // Normalize search string helper (Vietnamese tone insensitive)
  const normalizeText = (str) => {
    if (!str) return '';
    return str
      .toString()
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();
  };

  // Find currently selected option
  const selectedOption = useMemo(() => {
    const found = options.find((opt) => String(opt.value ?? opt.id) === String(value));
    if (found) return found;
    if (allowCustom && value) {
      return { value: String(value), label: String(value) };
    }
    return null;
  }, [options, value, allowCustom]);

  // Filtered list based on search query
  const filteredOptions = useMemo(() => {
    let list = options;
    if (searchQuery.trim()) {
      const query = normalizeText(searchQuery);
      list = options.filter((opt) => {
        // Check across specified search fields
        return searchFields.some((field) => {
          const val = opt[field] ?? opt.label ?? opt.name ?? opt.value;
          if (!val) return false;
          return normalizeText(val).includes(query);
        });
      });
    }

    if (allowCustom && searchQuery.trim()) {
      const exactMatch = options.some(
        (opt) => normalizeText(opt.label || opt.name || opt.value) === normalizeText(searchQuery)
      );
      if (!exactMatch) {
        list = [
          { value: searchQuery.trim(), label: searchQuery.trim(), isCustom: true, subLabel: '✨ Dùng khu vực mới này' },
          ...list,
        ];
      }
    }

    return list;
  }, [options, searchQuery, searchFields, allowCustom]);

  // Reset highlight when filtered options change
  useEffect(() => {
    setHighlightedIndex(0);
  }, [filteredOptions]);

  // Focus search input when dropdown opens
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => {
        if (inputRef.current) {
          inputRef.current.focus();
        }
      }, 50);
    } else {
      setSearchQuery('');
    }
  }, [isOpen]);

  const [dropdownStyle, setDropdownStyle] = useState({});

  // Calculate position for portal
  const updateDropdownPosition = () => {
    if (isOpen && containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect();
      const windowHeight = window.innerHeight;
      const dropdownHeight = 320; // Max height
      
      let top = rect.bottom + 4;
      // If not enough space at bottom, pop up instead
      if (top + dropdownHeight > windowHeight && rect.top > dropdownHeight) {
        top = rect.top - dropdownHeight - 4;
      }
      
      setDropdownStyle({
        position: 'fixed',
        top: `${top}px`,
        left: `${rect.left}px`,
        width: `${rect.width}px`,
        zIndex: 999999,
      });
    }
  };

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
  }, [isOpen]);

  // Click outside listener
  useEffect(() => {
    const handleClickOutside = (event) => {
      // For portal, we need to check if the click is outside the trigger AND outside the portal dropdown
      const isOutsideContainer = containerRef.current && !containerRef.current.contains(event.target);
      const dropdownEl = document.getElementById('searchable-select-portal-dropdown');
      const isOutsideDropdown = dropdownEl && !dropdownEl.contains(event.target);

      if (isOutsideContainer && isOutsideDropdown) {
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

  // Handle select option
  const handleSelect = (option) => {
    const val = option ? (option.value ?? option.id) : '';
    onChange && onChange(val, option);
    setIsOpen(false);
    setSearchQuery('');
  };

  // Clear value
  const handleClear = (e) => {
    e.stopPropagation();
    onChange && onChange('', null);
  };

  // Keyboard navigation inside dropdown
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
      scrollHighlightedIntoView();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlightedIndex((prev) => (prev > 0 ? prev - 1 : filteredOptions.length - 1));
      scrollHighlightedIntoView();
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filteredOptions.length > 0 && highlightedIndex >= 0 && highlightedIndex < filteredOptions.length) {
        handleSelect(filteredOptions[highlightedIndex]);
      }
    } else if (e.key === 'Escape') {
      e.preventDefault();
      setIsOpen(false);
    }
  };

  const scrollHighlightedIntoView = () => {
    setTimeout(() => {
      if (listRef.current) {
        const item = listRef.current.querySelector(`[data-index="${highlightedIndex}"]`);
        if (item) {
          item.scrollIntoView({ block: 'nearest' });
        }
      }
    }, 0);
  };

  return (
    <div
      ref={containerRef}
      className={`searchable-select-container ${disabled ? 'disabled' : ''} ${className}`}
      style={{ position: 'relative', width: '100%', ...style }}
      onKeyDown={handleKeyDown}
    >
      {/* Hidden input for HTML form validation if required */}
      {required && (
        <input
          tabIndex={-1}
          autoComplete="off"
          style={{ opacity: 0, width: 0, height: 0, position: 'absolute', pointerEvents: 'none' }}
          value={value || ''}
          required={required}
          onChange={() => {}}
        />
      )}

      {/* Main Trigger Display as Direct Input */}
      <div
        className={`searchable-select-trigger ${isOpen ? 'focused' : ''}`}
        onClick={() => {
          if (!disabled) {
            setIsOpen(true);
            if (inputRef.current) inputRef.current.focus();
          }
        }}
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0.35rem 0.65rem',
          border: '1px solid var(--border-color, #cbd5e1)',
          borderRadius: 'var(--radius, 6px)',
          backgroundColor: disabled ? 'var(--bg-disabled, #f1f5f9)' : 'var(--bg-card, #ffffff)',
          cursor: disabled ? 'not-allowed' : 'text',
          minHeight: '38px',
          fontSize: '0.875rem',
          color: 'var(--text-primary, #1e293b)',
          transition: 'border-color 0.15s ease, box-shadow 0.15s ease',
          boxShadow: isOpen ? '0 0 0 3px rgba(37, 99, 235, 0.15)' : 'none',
          borderColor: isOpen ? 'var(--primary, #2563eb)' : 'var(--border-color, #cbd5e1)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', flex: 1, minWidth: 0, gap: '6px' }}>
          <Search size={15} style={{ color: 'var(--text-muted, #94a3b8)', flexShrink: 0 }} />
          <input
            ref={inputRef}
            type="text"
            disabled={disabled}
            placeholder={selectedOption ? (selectedOption.label || selectedOption.name) : placeholder}
            value={isOpen ? searchQuery : (selectedOption ? (selectedOption.code ? `[${selectedOption.code}] ${selectedOption.label || selectedOption.name}` : (selectedOption.label || selectedOption.name)) : '')}
            onChange={(e) => {
              const val = e.target.value;
              setSearchQuery(val);
              if (allowCustom) {
                onChange && onChange(val, null);
              }
              if (!isOpen) setIsOpen(true);
            }}
            onFocus={() => {
              setIsOpen(true);
              setSearchQuery(allowCustom && value ? String(value) : '');
            }}
            style={{
              width: '100%',
              border: 'none',
              outline: 'none',
              background: 'transparent',
              fontSize: '0.875rem',
              color: 'var(--text-primary, #1e293b)',
              padding: 0,
              cursor: disabled ? 'not-allowed' : 'text',
            }}
          />
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginLeft: '6px' }}>
          {allowClear && (selectedOption || searchQuery) && !disabled && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                setSearchQuery('');
                onChange && onChange('', null);
              }}
              style={{
                border: 'none',
                background: 'transparent',
                cursor: 'pointer',
                padding: '2px',
                color: 'var(--text-muted, #94a3b8)',
                display: 'flex',
                alignItems: 'center',
              }}
              title="Xóa lựa chọn"
            >
              <X size={14} />
            </button>
          )}
          <button
            type="button"
            tabIndex={-1}
            onClick={(e) => {
              e.stopPropagation();
              if (!disabled) {
                setIsOpen(!isOpen);
                if (!isOpen && inputRef.current) inputRef.current.focus();
              }
            }}
            style={{
              border: 'none',
              background: 'transparent',
              cursor: 'pointer',
              padding: '2px',
              color: 'var(--text-muted, #94a3b8)',
              display: 'flex',
              alignItems: 'center',
            }}
          >
            <ChevronDown
              size={16}
              style={{
                transition: 'transform 0.2s',
                transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
              }}
            />
          </button>
        </div>
      </div>

      {/* Dropdown Menu Popover via Portal */}
      {isOpen &&
        createPortal(
          <div
            id="searchable-select-portal-dropdown"
            className="searchable-select-dropdown"
            style={{
              ...dropdownStyle,
              backgroundColor: 'var(--bg-card, #ffffff)',
              border: '1px solid var(--border-color, #cbd5e1)',
              borderRadius: 'var(--radius, 6px)',
              boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)',
              overflow: 'hidden',
              maxHeight: '320px',
              display: 'flex',
              flexDirection: 'column',
            }}
            onKeyDown={handleKeyDown}
          >
            {/* Option Items List */}
            <div
              ref={listRef}
              style={{
                overflowY: 'auto',
                maxHeight: '320px',
                padding: '4px 0',
              }}
            >
              {filteredOptions.length === 0 ? (
                <div
                  style={{
                    padding: '0.75rem 1rem',
                    fontSize: '0.84rem',
                    color: 'var(--text-muted, #94a3b8)',
                    textAlign: 'center',
                  }}
                >
                  Không tìm thấy kết quả phù hợp
                </div>
              ) : (
                filteredOptions.map((opt, index) => {
                  const isSelected = String(opt.value ?? opt.id) === String(value);
                  const isHighlighted = index === highlightedIndex;

                  return (
                    <div
                      key={opt.value ?? opt.id ?? index}
                      data-index={index}
                      onClick={(e) => {
                        e.stopPropagation();
                        handleSelect(opt);
                      }}
                      onMouseEnter={() => setHighlightedIndex(index)}
                      style={{
                        padding: '0.55rem 0.75rem',
                        cursor: 'pointer',
                        fontSize: '0.84rem',
                        backgroundColor: isHighlighted
                          ? 'var(--bg-hover, #f1f5f9)'
                          : isSelected
                          ? 'rgba(37, 99, 235, 0.06)'
                          : 'transparent',
                        color: isSelected ? 'var(--primary, #2563eb)' : 'var(--text-primary, #1e293b)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        gap: '8px',
                        transition: 'background-color 0.1s ease',
                        borderLeft: isSelected ? '3px solid var(--primary, #2563eb)' : '3px solid transparent',
                      }}
                    >
                      <div style={{ flex: 1, minWidth: 0 }}>
                        {renderOption ? (
                          renderOption(opt)
                        ) : (
                          <div>
                            <div style={{ fontWeight: isSelected ? 600 : 500, display: 'flex', alignItems: 'center', gap: '6px' }}>
                              {opt.code && (
                                <span
                                  style={{
                                    fontSize: '0.75rem',
                                    padding: '1px 5px',
                                    borderRadius: '4px',
                                    backgroundColor: 'var(--bg-secondary, #e2e8f0)',
                                    color: 'var(--text-secondary, #475569)',
                                    fontFamily: 'monospace',
                                  }}
                                >
                                  {opt.code}
                                </span>
                              )}
                              <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                {opt.label || opt.name}
                              </span>
                            </div>
                            {(opt.phone || opt.subLabel || opt.debt != null) && (
                              <div
                                style={{
                                  fontSize: '0.75rem',
                                  color: 'var(--text-secondary, #64748b)',
                                  marginTop: '2px',
                                  display: 'flex',
                                  gap: '8px',
                                  flexWrap: 'wrap',
                                }}
                              >
                                {opt.phone && <span>📞 {opt.phone}</span>}
                                {opt.subLabel && <span>{opt.subLabel}</span>}
                              </div>
                            )}
                          </div>
                        )}
                      </div>

                      {isSelected && <Check size={15} style={{ color: 'var(--primary, #2563eb)', flexShrink: 0 }} />}
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

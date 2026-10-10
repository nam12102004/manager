import React from 'react';
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from 'lucide-react';

/**
 * Reusable Modern Pagination Component
 * Displays 15 items per page with smart page number windowing
 */
export default function Pagination({
  currentPage = 1,
  totalPages = 1,
  totalCount = 0,
  pageSize = 15,
  onPageChange,
  disabled = false,
  itemLabel = 'mục',
}) {
  if (totalCount === 0 && totalPages <= 1) {
    return null;
  }

  const startItem = totalCount > 0 ? (currentPage - 1) * pageSize + 1 : 0;
  const endItem = totalCount > 0 ? Math.min(currentPage * pageSize, totalCount) : 0;

  // Generate page numbers with ellipses
  const getPageNumbers = () => {
    const pages = [];
    const maxVisible = 5;

    if (totalPages <= maxVisible + 2) {
      for (let i = 1; i <= totalPages; i++) {
        pages.push(i);
      }
    } else {
      pages.push(1);
      const start = Math.max(2, currentPage - 1);
      const end = Math.min(totalPages - 1, currentPage + 1);

      if (start > 2) {
        pages.push('...');
      }

      for (let i = start; i <= end; i++) {
        pages.push(i);
      }

      if (end < totalPages - 1) {
        pages.push('...');
      }

      pages.push(totalPages);
    }
    return pages;
  };

  const pages = getPageNumbers();

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '0.75rem',
        padding: '0.875rem 1rem',
        marginTop: '0.75rem',
        backgroundColor: 'var(--bg-card, #ffffff)',
        border: '1px solid var(--border-color, #e2e8f0)',
        borderRadius: 'var(--radius-md, 8px)',
        fontSize: '0.875rem',
      }}
    >
      {/* Information text */}
      <div style={{ color: 'var(--text-secondary, #475569)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
        <span>Hiển thị</span>
        <strong style={{ color: 'var(--text-primary, #0f172a)' }}>
          {startItem} - {endItem}
        </strong>
        <span>trên tổng số</span>
        <strong style={{ color: 'var(--primary, #2563eb)' }}>{totalCount}</strong>
        <span>{itemLabel}</span>
        {totalPages > 1 && (
          <span style={{ color: 'var(--text-muted, #94a3b8)', marginLeft: '0.5rem' }}>
            (Trang {currentPage} / {totalPages})
          </span>
        )}
      </div>

      {/* Navigation controls */}
      {totalPages > 1 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
          {/* First Page button */}
          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            disabled={disabled || currentPage <= 1}
            onClick={() => onPageChange(1)}
            title="Trang đầu tiên"
          >
            <ChevronsLeft size={15} />
          </button>

          {/* Previous Page button */}
          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            disabled={disabled || currentPage <= 1}
            onClick={() => onPageChange(currentPage - 1)}
            title="Trang trước"
          >
            <ChevronLeft size={15} />
          </button>

          {/* Page numbers */}
          {pages.map((p, idx) => {
            if (p === '...') {
              return (
                <span
                  key={`ellipsis-${idx}`}
                  style={{
                    padding: '0 6px',
                    color: 'var(--text-muted, #94a3b8)',
                    userSelect: 'none',
                  }}
                >
                  ...
                </span>
              );
            }

            const isActive = p === currentPage;
            return (
              <button
                key={p}
                type="button"
                className={`btn ${isActive ? 'btn-primary' : 'btn-outline'}`}
                style={{
                  minWidth: '32px',
                  height: '32px',
                  padding: '0 8px',
                  fontSize: '0.8125rem',
                  fontWeight: isActive ? 700 : 500,
                  boxShadow: isActive ? '0 1px 3px rgba(37, 99, 235, 0.3)' : 'none',
                }}
                disabled={disabled}
                onClick={() => onPageChange(p)}
              >
                {p}
              </button>
            );
          })}

          {/* Next Page button */}
          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            disabled={disabled || currentPage >= totalPages}
            onClick={() => onPageChange(currentPage + 1)}
            title="Trang kế tiếp"
          >
            <ChevronRight size={15} />
          </button>

          {/* Last Page button */}
          <button
            type="button"
            className="btn btn-outline btn-icon"
            style={{ width: '32px', height: '32px', padding: 0 }}
            disabled={disabled || currentPage >= totalPages}
            onClick={() => onPageChange(totalPages)}
            title="Trang cuối cùng"
          >
            <ChevronsRight size={15} />
          </button>
        </div>
      )}
    </div>
  );
}

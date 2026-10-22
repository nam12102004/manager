import React, { useRef, useEffect, useState, useCallback } from 'react';

/**
 * Reusable wrapper that adds a synchronized top horizontal scrollbar above a data table.
 * Ideal for wide, long tables so users do not have to scroll down to the bottom just to pan horizontally.
 * The bottom scrollbar is preserved and stays 100% in sync with the top scrollbar.
 */
export default function TableScrollContainer({
  children,
  targetRef,
  className = '',
  style = {},
  sticky = true,
  stickyTop = 'var(--header-height, 68px)',
  alwaysShow = true,
}) {
  const wrapperRef = useRef(null);
  const topScrollRef = useRef(null);
  const [scrollWidth, setScrollWidth] = useState(0);
  const [canScroll, setCanScroll] = useState(false);

  // Helper to resolve the scrollable table element
  const getBottomEl = useCallback(() => {
    if (targetRef && targetRef.current) return targetRef.current;
    if (wrapperRef.current) {
      return wrapperRef.current.querySelector('.table-responsive');
    }
    return null;
  }, [targetRef]);

  // Synchronize scrollLeft positions between top and bottom containers
  useEffect(() => {
    const bottomEl = getBottomEl();
    const topEl = topScrollRef.current;
    if (!bottomEl || !topEl) return;

    let isSyncing = false;

    // Keep initial positions matched
    if (bottomEl.scrollLeft > 0) {
      topEl.scrollLeft = bottomEl.scrollLeft;
    } else if (topEl.scrollLeft > 0) {
      bottomEl.scrollLeft = topEl.scrollLeft;
    }

    const syncTopToBottom = () => {
      if (isSyncing) return;
      isSyncing = true;
      if (Math.abs(bottomEl.scrollLeft - topEl.scrollLeft) > 1) {
        bottomEl.scrollLeft = topEl.scrollLeft;
      }
      isSyncing = false;
    };

    const syncBottomToTop = () => {
      if (isSyncing) return;
      isSyncing = true;
      if (Math.abs(topEl.scrollLeft - bottomEl.scrollLeft) > 1) {
        topEl.scrollLeft = bottomEl.scrollLeft;
      }
      isSyncing = false;
    };

    topEl.addEventListener('scroll', syncTopToBottom, { passive: true });
    bottomEl.addEventListener('scroll', syncBottomToTop, { passive: true });

    return () => {
      topEl.removeEventListener('scroll', syncTopToBottom);
      bottomEl.removeEventListener('scroll', syncBottomToTop);
    };
  }, [getBottomEl, scrollWidth, canScroll]);

  // Measure scrollWidth and clientWidth to determine if horizontal scrolling is needed
  const updateMetrics = useCallback(() => {
    const bottomEl = getBottomEl();
    if (!bottomEl) return;

    const tableEl = bottomEl.querySelector('table');
    const sw = Math.max(
      bottomEl.scrollWidth || 0,
      tableEl ? tableEl.scrollWidth || 0 : 0,
      tableEl ? tableEl.offsetWidth || 0 : 0
    );
    const cw = bottomEl.clientWidth || 0;
    const overflowed = sw > cw + 1;

    setScrollWidth(sw);
    setCanScroll(overflowed);

    if (topScrollRef.current) {
      if (Math.abs(topScrollRef.current.scrollLeft - bottomEl.scrollLeft) > 1) {
        topScrollRef.current.scrollLeft = bottomEl.scrollLeft;
      }
    }
  }, [getBottomEl]);

  // Watch for layout changes, column toggles, or data changes
  useEffect(() => {
    const wrapper = wrapperRef.current;
    if (!wrapper) return;

    updateMetrics();

    // Staggered timers to ensure metric measurements after CSS/data render
    const t1 = setTimeout(updateMetrics, 50);
    const t2 = setTimeout(updateMetrics, 200);
    const t3 = setTimeout(updateMetrics, 600);

    let ro = null;
    if (typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(() => {
        updateMetrics();
      });
      ro.observe(wrapper);
      const bottomEl = getBottomEl();
      if (bottomEl) {
        ro.observe(bottomEl);
        const tableEl = bottomEl.querySelector('table');
        if (tableEl) ro.observe(tableEl);
      }
    }

    // Mutation observer for column / row DOM changes
    const mo = new MutationObserver(() => {
      updateMetrics();
    });
    mo.observe(wrapper, { childList: true, subtree: true });

    window.addEventListener('resize', updateMetrics);

    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
      clearTimeout(t3);
      if (ro) ro.disconnect();
      mo.disconnect();
      window.removeEventListener('resize', updateMetrics);
    };
  }, [getBottomEl, updateMetrics]);

  // Allow vertical mouse wheel on top scrollbar to scroll horizontally
  const handleTopWheel = (e) => {
    if (topScrollRef.current && e.deltaY !== 0 && e.deltaX === 0) {
      e.preventDefault();
      topScrollRef.current.scrollLeft += e.deltaY;
    }
  };

  return (
    <div
      ref={wrapperRef}
      className={`table-scroll-wrapper ${className}`}
      style={{
        position: 'relative',
        width: '100%',
        ...style,
      }}
    >
      {/* Top horizontal scrollbar bar: always rendered directly above the table list */}
      {(alwaysShow || canScroll) && (
        <div
          ref={topScrollRef}
          className="table-top-scrollbar"
          onWheel={handleTopWheel}
          style={{
            position: sticky ? 'sticky' : 'relative',
            top: sticky ? stickyTop : undefined,
            zIndex: 15,
            overflowX: 'auto',
            overflowY: 'hidden',
            width: '100%',
            height: '20px',
            boxSizing: 'border-box',
            backgroundColor: 'var(--bg-tertiary, #f1f5f9)',
            border: '1px solid var(--border-color, #e2e8f0)',
            borderRadius: 'var(--radius-sm, 6px)',
            marginBottom: '4px',
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05)',
          }}
          title="Thanh cuộn ngang danh sách (phía trên)"
        >
          {/* Dummy element that establishes the exact scrollWidth */}
          <div
            style={{
              width: `${scrollWidth ? `${scrollWidth}px` : '100%'}`,
              height: '2px',
              pointerEvents: 'none',
            }}
          />
        </div>
      )}

      {children}
    </div>
  );
}

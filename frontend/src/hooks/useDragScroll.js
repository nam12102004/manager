import { useRef, useEffect } from 'react';

/**
 * Custom hook to enable smooth mouse drag-to-scroll (grab & pan) on horizontally scrollable containers.
 * Prevents unintended row clicks when dragging.
 */
export function useDragScroll() {
  const containerRef = useRef(null);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    let isDown = false;
    let startX = 0;
    let scrollLeft = 0;
    let hasDragged = false;

    el.classList.add('drag-scroll-enabled');

    const handleMouseDown = (e) => {
      // Only respond to main left click
      if (e.button !== 0) return;

      // Ignore clicks on buttons, inputs, dropdowns, links, or marked elements
      if (e.target.closest('button, input, select, textarea, a, .btn, [data-no-drag]')) {
        return;
      }

      isDown = true;
      hasDragged = false;
      startX = e.pageX - el.offsetLeft;
      scrollLeft = el.scrollLeft;

      el.classList.add('is-dragging');
      document.body.style.cursor = 'grabbing';
      document.body.style.userSelect = 'none';
    };

    const handleMouseMove = (e) => {
      if (!isDown) return;
      e.preventDefault();

      const x = e.pageX - el.offsetLeft;
      const walk = (x - startX) * 1.25; // 1.25x speed multiplier for responsiveness

      if (Math.abs(walk) > 5) {
        hasDragged = true;
      }

      el.scrollLeft = scrollLeft - walk;
    };

    const handleMouseUp = () => {
      if (!isDown) return;
      isDown = false;

      el.classList.remove('is-dragging');
      document.body.style.cursor = '';
      document.body.style.removeProperty('user-select');

      // Clear dragged flag shortly after to ensure click capture works
      setTimeout(() => {
        hasDragged = false;
      }, 50);
    };

    const handleClickCapture = (e) => {
      // If user dragged, intercept the click so rows don't toggle open/closed
      if (hasDragged) {
        e.stopPropagation();
        e.preventDefault();
        hasDragged = false;
      }
    };

    el.addEventListener('mousedown', handleMouseDown);
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
    el.addEventListener('click', handleClickCapture, true);

    return () => {
      el.removeEventListener('mousedown', handleMouseDown);
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
      el.removeEventListener('click', handleClickCapture, true);
      el.classList.remove('drag-scroll-enabled', 'is-dragging');
      document.body.style.cursor = '';
      document.body.style.removeProperty('user-select');
    };
  }, []);

  return containerRef;
}

export default useDragScroll;

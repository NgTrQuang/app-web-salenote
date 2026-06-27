import { useCallback, useEffect, useRef, useState, type RefObject } from 'react';
import { DEFAULT_PAGE_SIZE } from './useClientPagination';

/** Tăng số dòng hiển thị khi cuộn gần cuối (load-more tự động). */
export function useInfiniteScroll<T>(
  items: T[],
  pageSize = DEFAULT_PAGE_SIZE,
  scrollRootRef?: RefObject<Element | null>,
) {
  const [visibleCount, setVisibleCount] = useState(pageSize);
  const observerRef = useRef<IntersectionObserver | null>(null);

  useEffect(() => {
    setVisibleCount(pageSize);
  }, [items, pageSize]);

  const slice = items.slice(0, visibleCount);
  const hasMore = visibleCount < items.length;

  const loadMore = useCallback(() => {
    setVisibleCount((n) => Math.min(n + pageSize, items.length));
  }, [items.length, pageSize]);

  // Callback ref: gắn observer khi sentinel mount (modal mở, tab hiện…)
  const sentinelRef = useCallback(
    (node: Element | null) => {
      observerRef.current?.disconnect();
      observerRef.current = null;
      if (!node || !hasMore) return;

      const observer = new IntersectionObserver(
        (entries) => {
          if (entries[0]?.isIntersecting) loadMore();
        },
        {
          root: scrollRootRef?.current ?? null,
          rootMargin: '120px',
          threshold: 0,
        },
      );
      observer.observe(node);
      observerRef.current = observer;
    },
    [hasMore, loadMore, scrollRootRef],
  );

  useEffect(() => () => observerRef.current?.disconnect(), []);

  return { slice, hasMore, loadMore, sentinelRef, total: items.length, visibleCount };
}

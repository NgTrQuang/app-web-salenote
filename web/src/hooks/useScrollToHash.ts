import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

/** Scroll to hash anchor after page content has loaded (SPA-friendly). */
export function useScrollToHash(ready: boolean) {
  const location = useLocation();

  useEffect(() => {
    if (!ready) return;
    const hash = location.hash.replace('#', '');
    if (!hash) return;
    const timer = window.setTimeout(() => {
      document.getElementById(hash)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 150);
    return () => window.clearTimeout(timer);
  }, [ready, location.hash]);
}

import { useEffect } from 'react';
import { fireDueRemindersNow } from '@/lib/notificationService';

const TICK_MS = 15_000;

/** Kiểm tra nhắc nhở mỗi 15s + khi tab được focus — bắt cả trường hợp lỡ đúng phút. */
export function useNotificationScheduler() {
  useEffect(() => {
    void fireDueRemindersNow();

    const interval = window.setInterval(() => {
      void fireDueRemindersNow();
    }, TICK_MS);

    const onVisible = () => {
      if (document.visibilityState === 'visible') {
        void fireDueRemindersNow();
      }
    };
    const onFocus = () => void fireDueRemindersNow();

    document.addEventListener('visibilitychange', onVisible);
    window.addEventListener('focus', onFocus);

    return () => {
      window.clearInterval(interval);
      document.removeEventListener('visibilitychange', onVisible);
      window.removeEventListener('focus', onFocus);
    };
  }, []);
}

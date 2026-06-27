import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Copy, X } from 'lucide-react';
import type { ProductSegment } from '@/lib/segmentService';
import { applyMessageTemplate, getMessageTemplate } from '@/lib/customerService';
import { useInfiniteScroll } from '@/hooks/useInfiniteScroll';
import { PrimaryButton, SecondaryButton, Toast } from './ui';

interface SegmentActionDialogProps {
  segment: ProductSegment | null;
  onClose: () => void;
}

export function SegmentActionDialog({ segment, onClose }: SegmentActionDialogProps) {
  const [template, setTemplate] = useState('');
  const [toast, setToast] = useState('');

  useEffect(() => {
    if (!segment) return;
    getMessageTemplate().then(setTemplate);
  }, [segment]);

  const scrollRef = useRef<HTMLDivElement>(null);
  const { slice, hasMore, sentinelRef, total } = useInfiniteScroll(
    segment?.customers ?? [],
    undefined,
    scrollRef,
  );

  if (!segment) return null;

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 2500);
  }

  async function copyMessage(name: string, product: string) {
    const text = applyMessageTemplate(template, name, product);
    await navigator.clipboard.writeText(text);
    showToast(`Đã copy tin cho ${name}`);
  }

  async function copyAll() {
    const lines = segment!.customers.map((c) =>
      applyMessageTemplate(template, c.name, c.product),
    );
    await navigator.clipboard.writeText(lines.join('\n\n'));
    showToast(`Đã copy ${lines.length} tin nhắn`);
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-900/50 p-4 sm:items-center">
      <div className="max-h-[85vh] w-full max-w-lg overflow-hidden rounded-xl bg-white shadow-xl dark:bg-slate-900">
        <div className="flex items-start justify-between border-b border-slate-200 px-5 py-4 dark:border-slate-800">
          <div>
            <h2 className="text-lg font-bold text-slate-900 dark:text-white">
              Nhắn {segment.customers.length} khách
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              Mua <strong>{segment.productName}</strong> cách đây 30+ ngày — copy tin dán Zalo
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
            aria-label="Đóng"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div ref={scrollRef} className="max-h-[50vh] overflow-y-auto px-5 py-3">
          <ul className="divide-y divide-slate-100 dark:divide-slate-800">
            {slice.map((c) => (
              <li key={c.customerId} className="flex items-center gap-3 py-3">
                <div className="min-w-0 flex-1">
                  <Link
                    to={`/customers/${c.customerId}`}
                    className="font-medium text-slate-900 hover:text-brand-600 dark:text-white dark:hover:text-brand-400"
                  >
                    {c.name}
                  </Link>
                  <p className="text-xs text-slate-500">Mua {c.daysSincePurchase} ngày trước</p>
                </div>
                <button
                  type="button"
                  onClick={() => void copyMessage(c.name, c.product)}
                  className="inline-flex shrink-0 items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                >
                  <Copy className="h-3.5 w-3.5" />
                  Copy
                </button>
              </li>
            ))}
          </ul>
          {hasMore && (
            <div ref={sentinelRef} className="py-3 text-center text-xs text-slate-400">
              Đang tải thêm… ({slice.length}/{total})
            </div>
          )}
        </div>

        <div className="flex flex-wrap gap-2 border-t border-slate-200 px-5 py-4 dark:border-slate-800">
          <PrimaryButton type="button" onClick={() => void copyAll()}>
            <Copy className="mr-2 h-4 w-4" />
            Copy tất cả ({segment.customers.length})
          </PrimaryButton>
          <SecondaryButton type="button" onClick={onClose}>
            Đóng
          </SecondaryButton>
        </div>
      </div>

      {toast && <Toast message={toast} />}
    </div>
  );
}

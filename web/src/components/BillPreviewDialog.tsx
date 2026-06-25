import { useEffect, useState } from 'react';
import { Download, Share2, X } from 'lucide-react';
import type { Customer, Order } from '@/types';
import { BillDocument } from './BillDocument';
import {
  billFilename,
  buildBillData,
  buildBillPdfBlob,
  downloadBillPdf,
  exportBillPdfFromData,
  shareBillPdfFile,
  type BillData,
} from '@/lib/billService';
import { PrimaryButton, SecondaryButton } from './ui';

interface BillPreviewDialogProps {
  customer: Customer;
  order: Order;
  onClose: () => void;
}

export function BillPreviewDialog({ customer, order, onClose }: BillPreviewDialogProps) {
  const [data, setData] = useState<BillData | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState('');

  useEffect(() => {
    let cancelled = false;
    buildBillData(customer, order)
      .then((d) => {
        if (!cancelled) {
          setData(d);
          setLoading(false);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setMsg('Không tải được dữ liệu bill');
          setLoading(false);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [customer, order]);

  async function handleDownload() {
    if (!data) return;
    setBusy(true);
    setMsg('');
    try {
      await exportBillPdfFromData(data, billFilename(order));
      setMsg('Đã tải PDF');
    } catch (e) {
      const detail = e instanceof Error ? e.message : '';
      setMsg(detail ? `Không thể tạo PDF: ${detail}` : 'Không thể tạo PDF — kiểm tra kết nối mạng lần đầu tải font');
    } finally {
      setBusy(false);
    }
  }

  async function handleShare() {
    if (!data) return;
    setBusy(true);
    setMsg('');
    try {
      const blob = await buildBillPdfBlob(data);
      const name = billFilename(order);
      const shared = await shareBillPdfFile(blob, name);
      if (!shared) {
        downloadBillPdf(blob, name);
        setMsg('Trình duyệt không hỗ trợ chia sẻ file — đã tải PDF');
      } else {
        setMsg('Đã mở chia sẻ');
      }
    } catch (e) {
      const detail = e instanceof Error ? e.message : '';
      setMsg(detail ? `Không thể chia sẻ PDF: ${detail}` : 'Không thể chia sẻ PDF');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 sm:items-center">
      <div className="flex max-h-[92vh] w-full max-w-lg flex-col rounded-xl bg-white shadow-xl dark:bg-slate-900">
        <div className="flex items-center justify-between border-b border-slate-200 px-4 py-3 dark:border-slate-800">
          <h3 className="font-bold">Xem trước bill</h3>
          <button type="button" onClick={onClose} className="rounded-lg p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto bg-slate-100 p-4 dark:bg-slate-950">
          {loading || !data ? (
            <p className="py-8 text-center text-sm text-slate-500">
              {loading ? 'Đang tải...' : 'Không có dữ liệu bill'}
            </p>
          ) : (
            <div className="rounded-lg shadow-md">
              <BillDocument data={data} />
            </div>
          )}
        </div>

        {msg && <p className="px-4 py-2 text-center text-sm text-brand-600">{msg}</p>}

        <div className="flex flex-wrap gap-2 border-t border-slate-200 p-4 dark:border-slate-800">
          <SecondaryButton type="button" className="flex-1" onClick={onClose}>
            Đóng
          </SecondaryButton>
          <SecondaryButton
            type="button"
            className="flex-1"
            disabled={busy || !data}
            onClick={() => void handleShare()}
          >
            <Share2 className="h-4 w-4" />
            Chia sẻ
          </SecondaryButton>
          <PrimaryButton
            type="button"
            className="flex-1"
            disabled={busy || !data}
            onClick={() => void handleDownload()}
          >
            <Download className="h-4 w-4" />
            Tải PDF
          </PrimaryButton>
        </div>
      </div>
    </div>
  );
}

import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Download, Upload, FileSpreadsheet, Moon, Sun, Monitor, BookOpen } from 'lucide-react';
import { Breadcrumbs } from '@/components/CustomerTable';
import {
  PageHeader,
  Panel,
  FieldLabel,
  TextArea,
  PrimaryButton,
  SecondaryButton,
  Toast,
} from '@/components/ui';
import { useTheme } from '@/contexts/ThemeContext';
import { downloadBackup, exportCsv, restoreFromFile } from '@/lib/backupService';
import { getMessageTemplate, saveMessageTemplate } from '@/lib/customerService';
import { getSetting } from '@/lib/db';
import { SETTING_KEYS, APP_NAME, APP_TAGLINE, DEFAULT_MESSAGE } from '@/lib/constants';

export function SettingsPage() {
  const { mode, setMode } = useTheme();
  const fileRef = useRef<HTMLInputElement>(null);
  const [template, setTemplate] = useState(DEFAULT_MESSAGE);
  const [lastBackup, setLastBackup] = useState<string | null>(null);
  const [toast, setToast] = useState('');
  const [restoring, setRestoring] = useState(false);

  useEffect(() => {
    getMessageTemplate().then(setTemplate);
    getSetting(SETTING_KEYS.lastBackupDate).then((v) => setLastBackup(v ?? null));
  }, []);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 2800);
  }

  async function handleSaveTemplate() {
    await saveMessageTemplate(template);
    showToast('Đã lưu mẫu tin nhắn');
  }

  async function handleBackup() {
    await downloadBackup();
    const stamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    setLastBackup(stamp);
    showToast('Đã tải file backup');
  }

  async function handleRestore(file: File) {
    if (!confirm('Khôi phục sẽ ghi đè toàn bộ dữ liệu hiện tại. Tiếp tục?')) return;
    setRestoring(true);
    try {
      await restoreFromFile(file);
      showToast('Khôi phục thành công');
      window.location.reload();
    } catch (e) {
      showToast(e instanceof Error ? e.message : 'Lỗi khôi phục');
    } finally {
      setRestoring(false);
    }
  }

  return (
    <div>
      <Breadcrumbs items={[{ label: 'Bảng điều khiển', to: '/' }, { label: 'Cài đặt' }]} />
      <PageHeader title="Cài đặt" subtitle="Tuỳ chỉnh ứng dụng và quản lý dữ liệu" />

      <div className="grid gap-6 lg:grid-cols-2">
        <Panel title={`Về ${APP_NAME}`}>
          <p className="text-sm text-slate-600 dark:text-slate-400">{APP_TAGLINE}</p>
          <p className="mt-3 text-sm text-slate-500">
            Dữ liệu lưu trên trình duyệt (IndexedDB). Không gửi lên server.
          </p>
          <p className="mt-2 text-xs text-brand-600">
            Phase 1 — chăm khách + ghi đơn + dashboard tiền. Phase 2: ảnh/HĐ, nguồn khách.
          </p>
          <Link
            to="/guide"
            className="mt-4 inline-flex items-center gap-2 text-sm font-semibold text-brand-600 hover:text-brand-700 dark:text-brand-400"
          >
            <BookOpen className="h-4 w-4" />
            Xem hướng dẫn sử dụng
          </Link>
        </Panel>

        <Panel title="Giao diện">
          <div className="flex gap-2">
            <ThemeBtn
              active={mode === 'light'}
              onClick={() => setMode('light')}
              icon={<Sun className="h-4 w-4" />}
              label="Sáng"
            />
            <ThemeBtn
              active={mode === 'dark'}
              onClick={() => setMode('dark')}
              icon={<Moon className="h-4 w-4" />}
              label="Tối"
            />
            <ThemeBtn
              active={mode === 'system'}
              onClick={() => setMode('system')}
              icon={<Monitor className="h-4 w-4" />}
              label="Hệ thống"
            />
          </div>
        </Panel>

        <Panel title="Mẫu tin nhắn mặc định" className="lg:col-span-2">
          <p className="mb-3 text-sm text-slate-500">
            Dùng {'{tên}'} và {'{sản_phẩm}'} để tự điền khi soạn tin
          </p>
          <TextArea value={template} onChange={(e) => setTemplate(e.target.value)} rows={4} />
          <PrimaryButton onClick={handleSaveTemplate} className="mt-4">
            Lưu mẫu
          </PrimaryButton>
        </Panel>

        <Panel title="Sao lưu & khôi phục" className="lg:col-span-2">
          <p className="mb-4 text-sm text-slate-500">
            File JSON tương thích với app mobile Sổ Khách
            {lastBackup && ` · Lần cuối: ${lastBackup}`}
          </p>
          <div className="flex flex-wrap gap-3">
            <PrimaryButton onClick={handleBackup}>
              <Download className="h-4 w-4" />
              Tải backup JSON
            </PrimaryButton>
            <SecondaryButton onClick={() => fileRef.current?.click()} disabled={restoring}>
              <Upload className="h-4 w-4" />
              {restoring ? 'Đang khôi phục...' : 'Khôi phục JSON'}
            </SecondaryButton>
            <SecondaryButton onClick={() => exportCsv()}>
              <FileSpreadsheet className="h-4 w-4" />
              Xuất CSV
            </SecondaryButton>
          </div>
          <input
            ref={fileRef}
            type="file"
            accept="application/json,.json"
            className="hidden"
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) void handleRestore(f);
              e.target.value = '';
            }}
          />
        </Panel>
      </div>

      {toast && <Toast message={toast} />}
    </div>
  );
}

function ThemeBtn({
  active,
  onClick,
  icon,
  label,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  label: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex flex-1 items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-medium transition ${
        active
          ? 'bg-brand-600 text-white shadow-sm'
          : 'border border-slate-200 bg-white text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300'
      }`}
    >
      {icon}
      {label}
    </button>
  );
}

import { useEffect, useRef, useState } from 'react';

import { Link } from 'react-router-dom';

import {

  Download,

  Upload,

  FileSpreadsheet,

  Moon,

  Sun,

  Monitor,

  BookOpen,

  Bell,

  Clock,

  CalendarRange,

  CalendarDays,

  Gift,

  Send,

} from 'lucide-react';

import { Breadcrumbs } from '@/components/CustomerTable';

import {

  PageHeader,

  Panel,

  TextArea,

  PrimaryButton,

  SecondaryButton,

  Toast,

} from '@/components/ui';

import { useTheme } from '@/contexts/ThemeContext';

import { downloadBackup, exportCsv, restoreFromFile } from '@/lib/backupService';

import { getMessageTemplate, saveMessageTemplate } from '@/lib/customerService';

import { getSetting } from '@/lib/db';

import { getShopSettings, saveShopSettings } from '@/lib/shopSettings';

import { APP_NAME, APP_TAGLINE, DEFAULT_MESSAGE, SETTING_KEYS } from '@/lib/constants';

import {

  formatNotifTime,

  fireDueRemindersNow,

  getNotificationPermission,

  getNotificationSettings,

  isPastScheduledTimeForSettings,

  parseTimeInput,

  requestNotificationPermission,

  saveNotificationTime,

  sendTestNotification,

  setDailyReminderEnabled,

  setLoyaltyReminderEnabled,

  setMonthlyDigestEnabled,

  setWeeklyDigestEnabled,

  type NotificationSettings,

} from '@/lib/notificationService';



export function SettingsPage() {

  const { mode, setMode } = useTheme();

  const fileRef = useRef<HTMLInputElement>(null);

  const [template, setTemplate] = useState(DEFAULT_MESSAGE);

  const [lastBackup, setLastBackup] = useState<string | null>(null);

  const [toast, setToast] = useState('');

  const [restoring, setRestoring] = useState(false);

  const [notif, setNotif] = useState<NotificationSettings | null>(null);
  const [shopName, setShopName] = useState(APP_NAME);
  const [shopPhone, setShopPhone] = useState('');
  const [perm, setPerm] = useState<NotificationPermission>('default');
  const notifLoadGen = useRef(0);



  useEffect(() => {

    getMessageTemplate().then(setTemplate);

    getSetting(SETTING_KEYS.lastBackupDate).then((v) => setLastBackup(v ?? null));

    getShopSettings().then((s) => {
      setShopName(s.shopName);
      setShopPhone(s.shopPhone);
    });

    void loadNotif();

    setPerm(getNotificationPermission());

  }, []);



  async function loadNotif() {
    const gen = ++notifLoadGen.current;
    const data = await getNotificationSettings();
    if (gen !== notifLoadGen.current) return;
    setNotif(data);
  }

  function invalidateNotifLoads() {
    notifLoadGen.current++;
  }



  function showToast(msg: string) {

    setToast(msg);

    setTimeout(() => setToast(''), 2800);

  }



  async function ensurePermission(): Promise<boolean> {

    const ok = await requestNotificationPermission();

    setPerm(getNotificationPermission());

    if (!ok) {

      showToast('Cần cấp quyền thông báo trình duyệt');

    }

    return ok;

  }



  async function handleSaveTemplate() {

    await saveMessageTemplate(template);

    showToast('Đã lưu mẫu tin nhắn');

  }

  async function handleSaveShop() {
    await saveShopSettings({ shopName, shopPhone });
    showToast('Đã lưu thông tin cửa hàng trên bill');
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



  function patchNotif(patch: Partial<NotificationSettings>) {
    setNotif((prev) => (prev ? { ...prev, ...patch } : prev));
  }

  async function toggleDaily(enabled: boolean) {
    if (!notif) return;
    invalidateNotifLoads();
    const previous = notif.dailyEnabled;
    patchNotif({ dailyEnabled: enabled });

    if (enabled && !(await ensurePermission())) {
      patchNotif({ dailyEnabled: previous });
      return;
    }

    await setDailyReminderEnabled(enabled);
    if (enabled) void fireDueRemindersNow();

    showToast(
      enabled
        ? `Đã bật nhắc nhở ${formatNotifTime(notif.hour, notif.minute)} ✓`
        : 'Đã tắt nhắc nhở hàng ngày',
    );
  }

  async function toggleWeekly(enabled: boolean) {
    if (!notif) return;
    invalidateNotifLoads();
    const previous = notif.weeklyEnabled;
    patchNotif({ weeklyEnabled: enabled });

    if (enabled && !(await ensurePermission())) {
      patchNotif({ weeklyEnabled: previous });
      return;
    }

    await setWeeklyDigestEnabled(enabled);
    if (enabled) void fireDueRemindersNow();
  }

  async function toggleMonthly(enabled: boolean) {
    if (!notif) return;
    invalidateNotifLoads();
    const previous = notif.monthlyEnabled;
    patchNotif({ monthlyEnabled: enabled });

    if (enabled && !(await ensurePermission())) {
      patchNotif({ monthlyEnabled: previous });
      return;
    }

    await setMonthlyDigestEnabled(enabled);
    if (enabled) void fireDueRemindersNow();
  }

  async function toggleLoyalty(enabled: boolean) {
    if (!notif) return;
    invalidateNotifLoads();
    const previous = notif.loyaltyEnabled;
    patchNotif({ loyaltyEnabled: enabled });

    if (enabled && !(await ensurePermission())) {
      patchNotif({ loyaltyEnabled: previous });
      return;
    }

    await setLoyaltyReminderEnabled(enabled);
    if (enabled) void fireDueRemindersNow();
  }



  async function handleTimeChange(value: string) {

    const parsed = parseTimeInput(value);

    if (!parsed || !notif) return;

    await saveNotificationTime(parsed.hour, parsed.minute);

    setNotif({ ...notif, hour: parsed.hour, minute: parsed.minute });

    const fired = await fireDueRemindersNow();

    showToast(

      fired > 0

        ? `Đã cập nhật giờ & gửi ${fired} nhắc nhở ✓`

        : 'Đã cập nhật giờ nhắc nhở ✓',

    );

  }



  async function handleFireNow() {

    if (!(await ensurePermission())) return;

    const fired = await fireDueRemindersNow();

    showToast(

      fired > 0

        ? `Đã gửi ${fired} thông báo nhắc nhở`

        : notif && isPastScheduledTimeForSettings(notif)

          ? 'Hôm nay đã gửi nhắc rồi'

          : 'Chưa đến giờ nhắc hoặc chưa bật loại nhắc nào',

    );

  }



  async function handleTestNotif() {

    if (!(await ensurePermission())) return;

    await sendTestNotification();

    showToast('Đã gửi thông báo thử — kiểm tra góc màn hình');

  }



  const notifSupported = typeof Notification !== 'undefined';

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

          <Link

            to="/guide"

            className="mt-4 inline-flex items-center gap-2 text-sm font-semibold text-brand-600 hover:text-brand-700 dark:text-brand-400"

          >

            <BookOpen className="h-4 w-4" />

            Xem hướng dẫn sử dụng

          </Link>

        </Panel>



        <Panel title="Thông tin trên bill" className="lg:col-span-2">

          <p className="mb-4 text-sm text-slate-500">

            Hiển thị trên phiếu bán hàng PDF — tên shop và SĐT liên hệ.

          </p>

          <div className="grid gap-4 sm:grid-cols-2">

            <div>

              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">

                Tên cửa hàng / shop

              </label>

              <input

                type="text"

                value={shopName}

                onChange={(e) => setShopName(e.target.value)}

                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900"

                placeholder="Salenote Shop"

              />

            </div>

            <div>

              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">

                SĐT shop

              </label>

              <input

                type="tel"

                value={shopPhone}

                onChange={(e) => setShopPhone(e.target.value)}

                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900"

                placeholder="0901234567"

              />

            </div>

          </div>

          <PrimaryButton type="button" className="mt-4" onClick={() => void handleSaveShop()}>

            Lưu thông tin bill

          </PrimaryButton>

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



        <Panel title="Thông báo nhắc nhở" className="lg:col-span-2">

          {!notifSupported ? (

            <p className="text-sm text-slate-500">

              Trình duyệt không hỗ trợ thông báo. Dùng app mobile Salenote để nhắc nền 24/7.

            </p>

          ) : notif ? (

            <div className="space-y-4">

              {perm === 'denied' && (

                <p className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800 dark:border-amber-900 dark:bg-amber-950/40 dark:text-amber-200">

                  Quyền thông báo bị chặn. Mở cài đặt trình duyệt → cho phép thông báo từ trang này.

                </p>

              )}



              <NotifToggle

                icon={<Bell className="h-5 w-5 text-amber-700 dark:text-amber-400" />}

                title="Nhắc nhở hàng ngày"

                subtitle="Thông báo vào giờ bạn chọn — khách cần liên hệ hoặc gợi ý xem doanh số"

                checked={notif.dailyEnabled}

                onChange={(v) => void toggleDaily(v)}

              />



              <div className="ml-0 space-y-3 rounded-xl border border-slate-200 bg-slate-50/80 p-4 dark:border-slate-700 dark:bg-slate-800/40 sm:ml-11">

                  <label className="flex flex-wrap items-center gap-3">

                    <span className="inline-flex items-center gap-2 text-sm font-semibold text-slate-700 dark:text-slate-200">

                      <Clock className="h-4 w-4 text-blue-600" />

                      Giờ nhắc

                    </span>

                    <input

                      type="time"

                      value={formatNotifTime(notif.hour, notif.minute)}

                      onChange={(e) => void handleTimeChange(e.target.value)}

                      className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-semibold tabular-nums dark:border-slate-600 dark:bg-slate-900"

                    />

                    <span className="text-xs text-slate-500">

                      Áp dụng cho tất cả loại nhắc bên dưới

                    </span>

                  </label>



                  <p className="text-xs leading-relaxed text-brand-700 dark:text-brand-400">

                    Web: giữ tab mở quanh giờ nhắc, hoặc mở lại tab sau giờ nhắc để nhận ngay. App mobile nhắc nền kể cả khi đóng app.

                  </p>



                  <div className="flex flex-wrap gap-2">

                    <SecondaryButton onClick={() => void handleTestNotif()}>

                      <Send className="h-4 w-4" />

                      Gửi thử

                    </SecondaryButton>

                    <SecondaryButton onClick={() => void handleFireNow()}>

                      <Bell className="h-4 w-4" />

                      Gửi nhắc hôm nay

                    </SecondaryButton>

                  </div>

                </div>



              <div className="border-t border-slate-200 pt-4 dark:border-slate-700">

                <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-500">

                  Nhắc nhở kinh doanh

                </p>

                <div className="space-y-3">

                  <NotifToggle

                    icon={<CalendarRange className="h-5 w-5 text-indigo-600" />}

                    title="Tổng kết tuần"

                    subtitle="Thứ Hai — doanh số 7 ngày & gợi ý kế hoạch tuần mới"

                    checked={notif.weeklyEnabled}

                    onChange={(v) => void toggleWeekly(v)}

                  />

                  <NotifToggle

                    icon={<CalendarDays className="h-5 w-5 text-teal-600" />}

                    title="Tổng kết tháng"

                    subtitle="Ngày 1 hàng tháng — liên hệ, chốt đơn tháng trước & mục tiêu mới"

                    checked={notif.monthlyEnabled}

                    onChange={(v) => void toggleMonthly(v)}

                  />

                  <NotifToggle

                    icon={<Gift className="h-5 w-5 text-pink-600" />}

                    title="Tri ân & ưu đãi khách"

                    subtitle="Thứ Sáu — khách tiềm năng lâu chưa chăm & khách cũ gửi quà tri ân"

                    checked={notif.loyaltyEnabled}

                    onChange={(v) => void toggleLoyalty(v)}

                  />

                </div>

              </div>

            </div>

          ) : (

            <p className="text-sm text-slate-500">Đang tải...</p>

          )}

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

            File JSON tương thích với app mobile Salenote

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



function NotifToggle({

  icon,

  title,

  subtitle,

  checked,

  onChange,

}: {

  icon: React.ReactNode;

  title: string;

  subtitle: string;

  checked: boolean;

  onChange: (v: boolean) => void;

}) {

  const [on, setOn] = useState(checked);

  useEffect(() => {
    setOn(checked);
  }, [checked]);

  return (

    <div className="flex items-start gap-3 rounded-lg p-1">

      <div className="mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-white shadow-sm dark:bg-slate-900">

        {icon}

      </div>

      <div className="min-w-0 flex-1 pt-0.5">

        <p className="text-sm font-semibold text-slate-900 dark:text-white">{title}</p>

        <p className="text-xs text-slate-500">{subtitle}</p>

      </div>

      <button

        type="button"

        role="switch"

        aria-checked={on}

        aria-label={`${title}: ${on ? 'Bật' : 'Tắt'}`}

        onClick={() => {
          const next = !on;
          setOn(next);
          onChange(next);
        }}

        className={`relative mt-1 inline-flex h-6 w-11 shrink-0 rounded-full border-2 border-transparent transition-colors focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900 ${

          on ? 'bg-brand-600' : 'bg-slate-300 dark:bg-slate-600'

        }`}

      >

        <span

          className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow transition ${

            on ? 'translate-x-5' : 'translate-x-0'

          }`}

        />

      </button>

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



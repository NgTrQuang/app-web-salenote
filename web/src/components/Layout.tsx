import { NavLink, Outlet, Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Package,
  Receipt,
  BarChart3,
  Settings,
  Plus,
  Menu,
  X,
  Database,
  BookOpen,
} from 'lucide-react';
import { APP_NAME, APP_TAGLINE } from '@/lib/constants';
import { useShell } from '@/contexts/ShellContext';
import { useNotificationScheduler } from '@/hooks/useNotificationScheduler';

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Bảng điều khiển', end: true },
  { to: '/customers', icon: Users, label: 'Khách hàng' },
  { to: '/products', icon: Package, label: 'Sản phẩm' },
  { to: '/orders', icon: Receipt, label: 'Đơn hàng' },
  { to: '/stats', icon: BarChart3, label: 'Thống kê' },
  { to: '/guide', icon: BookOpen, label: 'Hướng dẫn' },
  { to: '/settings', icon: Settings, label: 'Cài đặt' },
];

export function Layout() {
  const { mobileNavOpen, setMobileNavOpen } = useShell();
  const location = useLocation();
  useNotificationScheduler();
  const hideQuickAdd =
    location.pathname.includes('/new') ||
    location.pathname.includes('/edit') ||
    location.pathname.includes('/orders/new');

  return (
    <div className="flex min-h-screen bg-slate-100/80 dark:bg-slate-950">
      {/* Desktop sidebar */}
      <aside className="hidden w-64 shrink-0 flex-col border-r border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-900 lg:flex">
        <SidebarBrand />
        <nav className="flex-1 space-y-1 px-3 py-4">
          {navItems.map((item) => (
            <SidebarLink key={item.to} {...item} onNavigate={() => {}} />
          ))}
        </nav>
        <SidebarFooter />
      </aside>

      {/* Mobile drawer */}
      {mobileNavOpen && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <button
            type="button"
            className="absolute inset-0 bg-slate-900/50"
            aria-label="Đóng menu"
            onClick={() => setMobileNavOpen(false)}
          />
          <aside className="relative flex h-full w-72 max-w-[85vw] flex-col bg-white shadow-xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-slate-200 px-4 py-3 dark:border-slate-800">
              <SidebarBrand compact />
              <button
                type="button"
                onClick={() => setMobileNavOpen(false)}
                className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <nav className="flex-1 space-y-1 px-3 py-4">
              {navItems.map((item) => (
                <SidebarLink
                  key={item.to}
                  {...item}
                  onNavigate={() => setMobileNavOpen(false)}
                />
              ))}
            </nav>
            <SidebarFooter />
          </aside>
        </div>
      )}

      {/* Main column */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-14 items-center gap-4 border-b border-slate-200 bg-white/95 px-4 backdrop-blur dark:border-slate-800 dark:bg-slate-900/95 lg:px-8">
          <button
            type="button"
            onClick={() => setMobileNavOpen(true)}
            className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 lg:hidden dark:text-slate-300 dark:hover:bg-slate-800"
            aria-label="Mở menu"
          >
            <Menu className="h-5 w-5" />
          </button>

          <div className="hidden text-sm text-slate-500 lg:block dark:text-slate-400">
            Dữ liệu lưu trên trình duyệt · Không gửi lên server
          </div>

          <div className="ml-auto flex items-center gap-2">
            {!hideQuickAdd && (
              <>
                <Link
                  to="/orders/new"
                  className="hidden items-center gap-2 rounded-lg border border-brand-200 bg-brand-50 px-3 py-2 text-sm font-semibold text-brand-700 transition hover:bg-brand-100 sm:inline-flex dark:border-brand-900 dark:bg-brand-950/40 dark:text-brand-400"
                >
                  Ghi đơn
                </Link>
                <Link
                  to="/customers/new"
                  className="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-700"
                >
                  <Plus className="h-4 w-4" />
                  <span className="hidden sm:inline">Thêm khách</span>
                </Link>
              </>
            )}
          </div>
        </header>

        <main className="flex-1 px-4 py-6 lg:px-8 lg:py-8">
          <div className="mx-auto max-w-7xl">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}

function SidebarBrand({ compact }: { compact?: boolean }) {
  return (
    <div className={`border-b border-slate-200 dark:border-slate-800 ${compact ? '' : 'px-5 py-5'}`}>
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-lg">
          <img src="/icons/logo.png" alt="Salenote" className="h-10 w-10" />
        </div>
        <div>
          <p className="font-bold text-slate-900 dark:text-white">{APP_NAME}</p>
          {!compact && (
            <p className="text-xs text-slate-500 dark:text-slate-400">{APP_TAGLINE}</p>
          )}
        </div>
      </div>
    </div>
  );
}

function SidebarFooter() {
  return (
    <div className="border-t border-slate-200 px-4 py-4 dark:border-slate-800">
      <div className="flex items-center gap-2 rounded-lg bg-slate-50 px-3 py-2 text-xs text-slate-600 dark:bg-slate-800/50 dark:text-slate-400">
        <Database className="h-3.5 w-3.5 shrink-0" />
        <span>IndexedDB · Offline</span>
      </div>
    </div>
  );
}

function SidebarLink({
  to,
  icon: Icon,
  label,
  end,
  onNavigate,
}: {
  to: string;
  icon: typeof LayoutDashboard;
  label: string;
  end?: boolean;
  onNavigate: () => void;
}) {
  return (
    <NavLink
      to={to}
      end={end}
      onClick={onNavigate}
      className={({ isActive }) =>
        `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition ${
          isActive
            ? 'bg-brand-50 text-brand-700 dark:bg-brand-950/50 dark:text-brand-400'
            : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100'
        }`
      }
    >
      <Icon className="h-5 w-5 shrink-0" />
      {label}
    </NavLink>
  );
}

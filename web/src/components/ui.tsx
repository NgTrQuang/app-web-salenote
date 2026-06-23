import type { ReactNode } from 'react';

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  action?: ReactNode;
}

export function PageHeader({ title, subtitle, action }: PageHeaderProps) {
  return (
    <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          {title}
        </h1>
        {subtitle && (
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{subtitle}</p>
        )}
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </div>
  );
}

export function Panel({
  children,
  className = '',
  title,
  action,
  noPadding,
}: {
  children: ReactNode;
  className?: string;
  title?: string;
  action?: ReactNode;
  noPadding?: boolean;
}) {
  return (
    <section
      className={`rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900 ${className}`}
    >
      {(title || action) && (
        <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4 dark:border-slate-800">
          {title && (
            <h2 className="text-sm font-semibold text-slate-900 dark:text-white">{title}</h2>
          )}
          {action}
        </div>
      )}
      <div className={noPadding ? '' : 'p-5'}>{children}</div>
    </section>
  );
}

export function StatCard({
  label,
  value,
  hint,
  variant = 'default',
}: {
  label: string;
  value: string | number;
  hint?: string;
  variant?: 'default' | 'warning' | 'success' | 'brand';
}) {
  const styles = {
    default: 'border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-900',
    warning: 'border-red-200 bg-red-50 dark:border-red-900 dark:bg-red-950/30',
    success: 'border-emerald-200 bg-emerald-50 dark:border-emerald-900 dark:bg-emerald-950/30',
    brand: 'border-brand-200 bg-brand-50 dark:border-brand-900 dark:bg-brand-950/30',
  };
  const valueStyles = {
    default: 'text-slate-900 dark:text-white',
    warning: 'text-red-700 dark:text-red-400',
    success: 'text-emerald-700 dark:text-emerald-400',
    brand: 'text-brand-700 dark:text-brand-400',
  };

  return (
    <div className={`rounded-xl border p-5 shadow-sm ${styles[variant]}`}>
      <p className="text-sm font-medium text-slate-500 dark:text-slate-400">{label}</p>
      <p className={`mt-1 text-3xl font-bold tabular-nums ${valueStyles[variant]}`}>
        {value}
      </p>
      {hint && <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{hint}</p>}
    </div>
  );
}

export function EmptyState({
  icon,
  title,
  description,
  action,
}: {
  icon: ReactNode;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-300 bg-white px-8 py-16 text-center dark:border-slate-700 dark:bg-slate-900">
      <div className="mb-4 text-slate-400">{icon}</div>
      <p className="text-base font-semibold text-slate-700 dark:text-slate-300">{title}</p>
      <p className="mt-2 max-w-md text-sm text-slate-500">{description}</p>
      {action && <div className="mt-6">{action}</div>}
    </div>
  );
}

export function SectionTitle({ children }: { children: ReactNode }) {
  return (
    <h3 className="mb-3 text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
      {children}
    </h3>
  );
}

export function FieldLabel({ children }: { children: ReactNode }) {
  return (
    <label className="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300">
      {children}
    </label>
  );
}

export function TextInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      {...props}
      className={`w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none transition focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 dark:border-slate-600 dark:bg-slate-900 ${props.className ?? ''}`}
    />
  );
}

export function TextArea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      {...props}
      className={`w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none transition focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 dark:border-slate-600 dark:bg-slate-900 ${props.className ?? ''}`}
    />
  );
}

export function PrimaryButton({
  children,
  className = '',
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      type="button"
      {...props}
      className={`inline-flex items-center justify-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-700 disabled:opacity-50 ${className}`}
    >
      {children}
    </button>
  );
}

export function SecondaryButton({
  children,
  className = '',
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      type="button"
      {...props}
      className={`inline-flex items-center justify-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200 dark:hover:bg-slate-800 ${className}`}
    >
      {children}
    </button>
  );
}

export function LoadingSpinner() {
  return (
    <div className="flex justify-center py-24">
      <div className="h-9 w-9 animate-spin rounded-full border-2 border-brand-600 border-t-transparent" />
    </div>
  );
}

export function Toast({ message }: { message: string }) {
  return (
    <div className="fixed right-6 top-20 z-50 rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-800 shadow-lg dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100">
      {message}
    </div>
  );
}

export function SearchInput({
  value,
  onChange,
  placeholder,
  className = '',
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  className?: string;
}) {
  return (
    <input
      type="search"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      className={`w-full max-w-md rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none transition focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 dark:border-slate-600 dark:bg-slate-900 ${className}`}
    />
  );
}

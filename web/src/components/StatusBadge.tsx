import { STATUS_COLORS, STATUS_LABELS } from '@/lib/constants';

interface StatusBadgeProps {
  status: string;
  className?: string;
}

export function StatusBadge({ status, className = '' }: StatusBadgeProps) {
  const color = STATUS_COLORS[status] ?? '#64748b';
  const label = STATUS_LABELS[status] ?? status;

  return (
    <span
      className={`inline-flex items-center rounded-md px-2 py-0.5 text-xs font-semibold text-white ${className}`}
      style={{ backgroundColor: color }}
    >
      {label}
    </span>
  );
}

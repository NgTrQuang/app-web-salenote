import { Link } from 'react-router-dom';
import {
  Flame,
  Phone,
  Wallet,
  RotateCcw,
  ChevronRight,
  CheckCircle2,
  Package,
  AlertTriangle,
  Users,
} from 'lucide-react';
import type { DailyAction } from '@/lib/insightsService';
import { Panel } from './ui';

const iconByType: Record<DailyAction['type'], typeof Phone> = {
  contact_hot: Flame,
  contact: Phone,
  collect_debt: Wallet,
  re_engage: RotateCcw,
  re_engage_product: Users,
  restock: Package,
  restock_urgent: AlertTriangle,
};

const colorByType: Record<DailyAction['type'], string> = {
  contact_hot: 'text-red-600 bg-red-50 dark:bg-red-950/40 dark:text-red-400',
  contact: 'text-amber-600 bg-amber-50 dark:bg-amber-950/40 dark:text-amber-400',
  collect_debt: 'text-brand-700 bg-brand-50 dark:bg-brand-950/40 dark:text-brand-400',
  re_engage: 'text-violet-600 bg-violet-50 dark:bg-violet-950/40 dark:text-violet-400',
  re_engage_product: 'text-indigo-600 bg-indigo-50 dark:bg-indigo-950/40 dark:text-indigo-400',
  restock: 'text-orange-600 bg-orange-50 dark:bg-orange-950/40 dark:text-orange-400',
  restock_urgent: 'text-red-700 bg-red-50 dark:bg-red-950/40 dark:text-red-400',
};

function actionHref(action: DailyAction): string {
  if (action.href) return action.href;
  if (action.customerId != null) return `/customers/${action.customerId}`;
  return '/';
}

interface DailyActionCenterProps {
  actions: DailyAction[];
  onSegmentAction?: (productId: number) => void;
}

function ActionRow({
  action,
  index,
  onSegmentAction,
}: {
  action: DailyAction;
  index: number;
  onSegmentAction?: (productId: number) => void;
}) {
  const Icon = iconByType[action.type];
  const content = (
    <>
      <span
        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${colorByType[action.type]}`}
      >
        <Icon className="h-4 w-4" />
      </span>
      <div className="min-w-0 flex-1">
        <p className="truncate font-medium text-slate-900 dark:text-white">
          {index + 1}. {action.title}
        </p>
        <p className="truncate text-sm text-slate-500">{action.subtitle}</p>
      </div>
      <ChevronRight className="h-4 w-4 shrink-0 text-slate-400" />
    </>
  );

  if (action.type === 're_engage_product' && action.productId != null && onSegmentAction) {
    return (
      <button
        type="button"
        onClick={() => onSegmentAction(action.productId!)}
        className="flex w-full items-center gap-3 py-3 text-left transition hover:bg-slate-50 dark:hover:bg-slate-800/40"
      >
        {content}
      </button>
    );
  }

  return (
    <Link
      to={actionHref(action)}
      className="flex items-center gap-3 py-3 transition hover:bg-slate-50 dark:hover:bg-slate-800/40"
    >
      {content}
    </Link>
  );
}

export function DailyActionCenter({ actions, onSegmentAction }: DailyActionCenterProps) {
  const hasDebt = actions.some((a) => a.type === 'collect_debt');
  const title =
    actions.length > 0 ? `Việc hôm nay (${actions.length})` : 'Việc hôm nay';

  return (
    <Panel title={title} subtitle="Làm theo thứ tự ưu tiên — không bỏ sót khách và tiền">
      {actions.length === 0 ? (
        <div className="flex items-start gap-3 rounded-lg bg-emerald-50 p-4 dark:bg-emerald-950/30">
          <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-emerald-600" />
          <div>
            <p className="font-semibold text-emerald-800 dark:text-emerald-300">
              Không có việc gấp
            </p>
            <p className="mt-1 text-sm text-emerald-700/80 dark:text-emerald-400/80">
              Hôm nay bạn đã theo kịp. Xem gợi ý bên dưới hoặc mở Sổ khách.
            </p>
          </div>
        </div>
      ) : (
        <ul className="divide-y divide-slate-100 dark:divide-slate-800">
          {actions.map((action, i) => (
            <li key={action.id}>
              <ActionRow action={action} index={i} onSegmentAction={onSegmentAction} />
            </li>
          ))}
        </ul>
      )}

      {hasDebt && (
        <Link
          to="/debts"
          className="mt-3 inline-block text-sm font-medium text-brand-600 hover:underline dark:text-brand-400"
        >
          Xem tất cả ai nợ tôi →
        </Link>
      )}
    </Panel>
  );
}

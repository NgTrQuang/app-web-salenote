import { Link } from 'react-router-dom';
import type { GoalProgress } from '@/lib/goalService';
import { formatMoney } from '@/lib/money';
import { Panel } from './ui';

interface GoalProgressCardProps {
  progress: GoalProgress;
}

export function GoalProgressCard({ progress }: GoalProgressCardProps) {
  const { goal, current, remaining, percent, ordersNeeded } = progress;
  const achieved = remaining <= 0;

  return (
    <Panel
      title="Mục tiêu tháng này"
      subtitle={
        achieved
          ? 'Bạn đã đạt mục tiêu — có thể đặt mục tiêu mới trong Cài đặt'
          : 'Theo dõi tiến độ doanh thu cá nhân'
      }
    >
      <div className="space-y-3">
        <div className="flex items-end justify-between gap-4 text-sm">
          <div>
            <p className="text-2xl font-bold text-slate-900 dark:text-white">
              {formatMoney(current)}
            </p>
            <p className="text-slate-500">/ {formatMoney(goal)}</p>
          </div>
          <p className="text-right font-semibold text-brand-600 dark:text-brand-400">
            {achieved ? 'Đã đạt!' : `${percent}%`}
          </p>
        </div>

        <div className="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
          <div
            className={`h-full rounded-full transition-all ${
              achieved ? 'bg-emerald-500' : 'bg-brand-500'
            }`}
            style={{ width: `${percent}%` }}
          />
        </div>

        {!achieved && (
          <p className="text-sm text-slate-600 dark:text-slate-400">
            Còn <strong>{formatMoney(remaining)}</strong>
            {ordersNeeded != null && ordersNeeded > 0 && (
              <>
                {' '}
                — cần thêm khoảng <strong>{ordersNeeded}</strong> đơn
              </>
            )}
          </p>
        )}

        <Link
          to="/stats"
          className="inline-block text-sm font-medium text-brand-600 hover:underline dark:text-brand-400"
        >
          Xem tiền của tôi →
        </Link>
      </div>
    </Panel>
  );
}

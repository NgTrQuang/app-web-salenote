import { Link } from 'react-router-dom';
import { Lightbulb, ChevronRight } from 'lucide-react';
import type { RevenueInsight } from '@/lib/insightsService';
import { Panel } from './ui';

interface RevenueInsightCardProps {
  insights: RevenueInsight[];
}

export function RevenueInsightCard({ insights }: RevenueInsightCardProps) {
  if (insights.length === 0) return null;

  return (
    <Panel title="Gợi ý hôm nay" subtitle="Trợ lý gợi ý việc tiếp theo — không cần tự phân tích">
      <ul className="space-y-2">
        {insights.map((insight, i) => (
          <li
            key={i}
            className="rounded-lg bg-slate-50 px-3 py-2 text-sm dark:bg-slate-800/60"
          >
            <div className="flex items-start gap-2">
              <Lightbulb className="mt-0.5 h-4 w-4 shrink-0 text-amber-500" />
              <div className="min-w-0 flex-1">
                <span className="text-slate-700 dark:text-slate-300">{insight.text}</span>
                {insight.actionText && insight.actionHref && (
                  <Link
                    to={insight.actionHref}
                    className="mt-1 flex items-center gap-0.5 text-xs font-semibold text-brand-600 hover:underline dark:text-brand-400"
                  >
                    {insight.actionText}
                    <ChevronRight className="h-3 w-3" />
                  </Link>
                )}
              </div>
            </div>
          </li>
        ))}
      </ul>
    </Panel>
  );
}

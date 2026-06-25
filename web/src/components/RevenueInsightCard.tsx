import { Lightbulb } from 'lucide-react';
import type { RevenueInsight } from '@/lib/insightsService';
import { Panel } from './ui';

interface RevenueInsightCardProps {
  insights: RevenueInsight[];
}

export function RevenueInsightCard({ insights }: RevenueInsightCardProps) {
  if (insights.length === 0) return null;

  return (
    <Panel title="Insight doanh thu" subtitle="Kết luận từ dữ liệu tháng này — không cần tự phân tích">
      <ul className="space-y-2">
        {insights.map((insight, i) => (
          <li
            key={i}
            className="flex items-start gap-2 rounded-lg bg-slate-50 px-3 py-2 text-sm dark:bg-slate-800/60"
          >
            <Lightbulb className="mt-0.5 h-4 w-4 shrink-0 text-amber-500" />
            <span className="text-slate-700 dark:text-slate-300">{insight.text}</span>
          </li>
        ))}
      </ul>
    </Panel>
  );
}

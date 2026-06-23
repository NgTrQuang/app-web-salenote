import { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import { Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, Panel } from '@/components/ui';
import { GUIDE_SECTIONS } from '@/lib/guideContent';
import { APP_NAME, APP_TAGLINE } from '@/lib/constants';

export function GuidePage() {
  return (
    <div>
      <Breadcrumbs
        items={[{ label: 'Bảng điều khiển', to: '/' }, { label: 'Hướng dẫn sử dụng' }]}
      />

      <PageHeader
        title="Hướng dẫn sử dụng"
        subtitle="Cách dùng Salenote hiệu quả trên web"
      />

      <div className="mb-8 overflow-hidden rounded-xl bg-gradient-to-br from-brand-600 to-brand-700 p-6 text-white shadow-md lg:p-8">
        <div className="flex items-start gap-5">
          <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-white/20 text-2xl font-bold">
            <img src="/icons/logo.png" alt="Salenote" className="h-10 w-10" />
          </div>
          <div>
            <h2 className="text-xl font-bold">{APP_NAME}</h2>
            <p className="mt-1 text-sm text-brand-100">{APP_TAGLINE}</p>
            <p className="mt-3 max-w-2xl text-sm leading-relaxed text-white/90">
              Sổ sale cá nhân — chăm khách, ghi đơn có tiền, biết doanh thu theo sản phẩm và nguồn.
              Dữ liệu khách ↔ sản phẩm ↔ đơn hàng liên kết trên máy bạn.
            </p>
          </div>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {GUIDE_SECTIONS.map((section, index) => (
          <GuideAccordion key={section.title} section={section} defaultOpen={index === 0} />
        ))}
      </div>

      <Panel title="Mẹo nhanh" className="mt-8">
        <ul className="list-inside list-disc space-y-2 text-sm text-slate-600 dark:text-slate-400">
          <li>
            Tạo <strong>Sản phẩm</strong> trước, rồi thêm khách kèm <strong>nguồn</strong> và SP quan tâm từ danh mục.
          </li>
          <li>Sáng mỗi ngày mở <strong>Bảng điều khiển</strong> — xử lý khách cần liên hệ và xem doanh số hôm nay.</li>
          <li><strong>Ghi đơn</strong> thay vì chỉ đánh dấu chốt — dashboard và thống kê lấy số từ đơn thực.</li>
          <li>Xem <strong>Doanh thu theo nguồn</strong> trong Thống kê để biết kênh nào hiệu quả.</li>
          <li>Backup JSON mỗi tuần trong <strong>Cài đặt</strong>.</li>
        </ul>
      </Panel>
    </div>
  );
}

function GuideAccordion({
  section,
  defaultOpen = false,
}: {
  section: (typeof GUIDE_SECTIONS)[number];
  defaultOpen?: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);
  const Icon = section.icon;

  return (
    <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center gap-4 px-5 py-4 text-left transition hover:bg-slate-50 dark:hover:bg-slate-800/50"
        aria-expanded={open}
      >
        <div
          className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${section.iconBg}`}
        >
          <Icon className={`h-5 w-5 ${section.iconColor}`} />
        </div>
        <span className="flex-1 font-semibold text-slate-900 dark:text-white">
          {section.title}
        </span>
        <ChevronDown
          className={`h-5 w-5 shrink-0 text-slate-400 transition-transform ${open ? 'rotate-180' : ''}`}
        />
      </button>
      {open && (
        <div className="border-t border-slate-100 px-5 pb-5 pt-2 dark:border-slate-800">
          <GuideBody text={section.body} />
        </div>
      )}
    </div>
  );
}

/** Renders plain text with **bold** and newlines */
function GuideBody({ text }: { text: string }) {
  const paragraphs = text.split('\n\n');
  return (
    <div className="space-y-3 text-sm leading-relaxed text-slate-600 dark:text-slate-400">
      {paragraphs.map((para, i) => (
        <p key={i}>
          {para.split('\n').map((line, j) => (
            <span key={j}>
              {j > 0 && <br />}
              <InlineBold text={line} />
            </span>
          ))}
        </p>
      ))}
    </div>
  );
}

function InlineBold({ text }: { text: string }) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return (
    <>
      {parts.map((part, i) =>
        part.startsWith('**') && part.endsWith('**') ? (
          <strong key={i} className="font-semibold text-slate-800 dark:text-slate-200">
            {part.slice(2, -2)}
          </strong>
        ) : (
          <span key={i}>{part}</span>
        ),
      )}
    </>
  );
}

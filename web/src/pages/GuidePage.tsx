import { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import { Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, Panel } from '@/components/ui';
import { GUIDE_SECTIONS, GUIDE_VERSION } from '@/lib/guideContent';
import { APP_NAME, APP_TAGLINE } from '@/lib/constants';

export function GuidePage() {
  return (
    <div>
      <Breadcrumbs
        items={[{ label: 'Bảng điều khiển', to: '/' }, { label: 'Hướng dẫn sử dụng' }]}
      />

      <PageHeader
        title="Hướng dẫn sử dụng"
        subtitle={`Salenote v${GUIDE_VERSION} — web & app đồng bộ tính năng`}
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
              Sổ sale cá nhân v{GUIDE_VERSION} — chăm khách, ghi đơn có tiền, snapshot giao hàng, bill PDF,
              Trợ lý Sale gợi ý việc làm. Dữ liệu khách ↔ sản phẩm ↔ đơn hàng trên máy bạn.
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
            Tạo <strong>Sản phẩm</strong> trước, thêm khách kèm <strong>nguồn</strong> và <strong>địa chỉ mặc định</strong>.
          </li>
          <li>
            Mở <strong>Bảng điều khiển</strong> sáng — xem <strong>Trợ lý Sale</strong> (việc nên làm, cảnh báo) trước khi nhắn khách.
          </li>
          <li>
            <strong>Ghi đơn</strong> kèm giao hàng — địa chỉ snapshot trên đơn; dùng <strong>Copy ship</strong> / <strong>Bill PDF</strong> khi giao hàng.
          </li>
          <li>
            Cấu hình <strong>tên shop trên bill</strong> trong Cài đặt trước khi gửi PDF cho khách.
          </li>
          <li>
            Xem <strong>Doanh thu theo nguồn</strong> trong Thống kê; backup JSON mỗi tuần.
          </li>
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

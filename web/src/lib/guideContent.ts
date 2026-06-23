import type { LucideIcon } from 'lucide-react';
import {
  Package,
  UserPlus,
  Receipt,
  Link2,
  BarChart3,
  MessageSquare,
  CloudUpload,
} from 'lucide-react';

export interface GuideSection {
  icon: LucideIcon;
  iconColor: string;
  iconBg: string;
  title: string;
  body: string;
}

export const GUIDE_SECTIONS: GuideSection[] = [
  {
    icon: Package,
    iconColor: 'text-violet-700 dark:text-violet-400',
    iconBg: 'bg-violet-100 dark:bg-violet-950/50',
    title: '1. Danh mục sản phẩm',
    body: `Vào **Sản phẩm** trên sidebar trước khi ghi đơn.

Mỗi sản phẩm có: tên, **giá vốn**, **giá bán mặc định**, **hoa hồng mặc định**.

**Theo dõi tồn kho** (tuỳ chọn):
• **Bật** — hàng vật lý: nhập tồn hiện tại, ngưỡng cảnh báo sắp hết. Ghi đơn tự trừ kho; Bảng điều khiển báo hàng sắp hết / hết.
• **Tắt** — dịch vụ, đặt hộ, dropship… không cần quản số lượng.

Danh mục liên kết khách ↔ đơn ↔ tiền ↔ kho (nếu bật).`,
  },
  {
    icon: UserPlus,
    iconColor: 'text-blue-700 dark:text-blue-400',
    iconBg: 'bg-blue-100 dark:bg-blue-950/50',
    title: '2. Thêm khách & nguồn',
    body: `Nhấn **Thêm khách** hoặc vào **Khách hàng → Thêm khách**.

Điền:
• **Tên** (bắt buộc), SĐT, ghi chú
• **Nguồn khách** — Facebook, Zalo, TikTok, giới thiệu… để sau này xem doanh thu theo kênh
• **Sản phẩm quan tâm** — chọn từ danh mục (khuyến nghị) hoặc nhập tay
• **Trạng thái** — Mới / Tiềm năng / Nóng / Đã chốt (quyết định lịch nhắc chăm)

Ghi nguồn ngay khi thêm giúp thống kê chính xác, không cần nhớ lại sau.`,
  },
  {
    icon: Receipt,
    iconColor: 'text-emerald-700 dark:text-emerald-400',
    iconBg: 'bg-emerald-100 dark:bg-emerald-950/50',
    title: '3. Ghi đơn hàng (có số tiền)',
    body: `Từ **Chi tiết khách** bấm **Ghi đơn**, hoặc vào **Đơn hàng → Ghi đơn mới**.

Form tự điền SP và giá nếu khách đã liên kết danh mục. SP có theo dõi kho sẽ hiện tồn và cảnh báo nếu bán vượt số lượng.

Bạn nhập:
• Số lượng, giá bán, giá vốn, hoa hồng
• Trạng thái thanh toán: đã trả / cọc / nợ
• Tuỳ chọn đánh dấu khách **Đã chốt**

Mỗi đơn lưu liên kết **khách ↔ sản phẩm ↔ tiền**. Ghi đơn cũng cập nhật SP quan tâm của khách nếu chọn từ danh mục.`,
  },
  {
    icon: Link2,
    iconColor: 'text-orange-700 dark:text-orange-400',
    iconBg: 'bg-orange-100 dark:bg-orange-950/50',
    title: '4. Liên kết dữ liệu Salenote',
    body: `Salenote không chỉ là sổ chăm khách — mọi thứ nối với nhau:

**Khách** → có nguồn + SP quan tâm (\`product_id\`)
**Đơn hàng** → trỏ tới khách + SP, có doanh thu / lời / HH / công nợ
**Dashboard** → cộng từ đơn thực (hôm nay + tháng)
**Thống kê** → doanh thu theo SP và theo **nguồn khách**

Xoá khách sẽ xoá luôn đơn và lịch sử liên hệ của khách đó — cẩn thận trước khi xoá.`,
  },
  {
    icon: MessageSquare,
    iconColor: 'text-sky-700 dark:text-sky-400',
    iconBg: 'bg-sky-100 dark:bg-sky-950/50',
    title: '5. Chăm khách & nhắc lịch',
    body: `**Bảng điều khiển** hiển thị khách cần liên hệ ngay và sắp tới.

🔵 **Mới** — nhắc sau 1 ngày
🟠 **Tiềm năng** — nhắc sau 2 ngày
🔴 **Nóng** — nhắc mỗi ngày
🟢 **Đã chốt** — nhắc chăm lại sau 7 ngày

Bấm **Đã nhắn** để ghi nhận liên hệ (reset đồng hồ nhắc). Trong chi tiết khách: soạn tin mẫu, sao chép sang Zalo/Messenger. Mẫu tin tuỳ chỉnh tại **Cài đặt**.`,
  },
  {
    icon: BarChart3,
    iconColor: 'text-purple-700 dark:text-purple-400',
    iconBg: 'bg-purple-100 dark:bg-purple-950/50',
    title: '6. Dashboard & thống kê',
    body: `**Bảng điều khiển**: doanh thu, lợi nhuận, hoa hồng, số đơn, công nợ — hôm nay và tháng này. Kèm danh sách khách cần chăm.

**Thống kê** (theo tháng):
• Doanh số thực từ đơn hàng
• Lượt liên hệ, khách mới, streak 🔥
• Top SP bán chạy (theo doanh thu đơn)
• **Doanh thu theo nguồn khách** — biết kênh nào mang tiền

**Khách hàng**: lọc theo trạng thái và nguồn. **Chi tiết khách**: xem tất cả đơn + tổng doanh thu / lời / HH / nợ.`,
  },
  {
    icon: CloudUpload,
    iconColor: 'text-teal-700 dark:text-teal-400',
    iconBg: 'bg-teal-100 dark:bg-teal-950/50',
    title: '7. Sao lưu dữ liệu',
    body: `Dữ liệu lưu trên trình duyệt (IndexedDB), không gửi lên server.

Vào **Cài đặt → Sao lưu & khôi phục**:
• **Tải backup JSON** — gồm khách, liên hệ, sản phẩm, đơn hàng (version 2)
• **Khôi phục JSON** — khi đổi máy hoặc trình duyệt
• **Xuất CSV** — khách (kèm nguồn), liên hệ, đơn hàng

Nên backup ít nhất 1 lần/tuần.`,
  },
];

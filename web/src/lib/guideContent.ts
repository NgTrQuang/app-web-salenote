import type { LucideIcon } from 'lucide-react';
import {
  Package,
  UserPlus,
  Truck,
  Receipt,
  FileText,
  Sparkles,
  Link2,
  MessageSquare,
  BarChart3,
  CloudUpload,
  Bell,
} from 'lucide-react';

export const GUIDE_VERSION = '2.0';

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

Mỗi sản phẩm có: tên, **giá vốn**, **giá bán mặc định**, **hoa hồng mặc định**, ghi chú nội bộ (tuỳ chọn).

**Theo dõi tồn kho** (tuỳ chọn):
• **Bật** — hàng vật lý: nhập tồn, ngưỡng cảnh báo. Ghi đơn tự trừ kho; Bảng điều khiển báo sắp hết / hết.
• **Tắt** — dịch vụ, đặt hộ, dropship… không quản số lượng.

Danh mục liên kết khách ↔ đơn ↔ tiền ↔ kho (nếu bật).`,
  },
  {
    icon: UserPlus,
    iconColor: 'text-blue-700 dark:text-blue-400',
    iconBg: 'bg-blue-100 dark:bg-blue-950/50',
    title: '2. Khách hàng, địa chỉ & nguồn',
    body: `Nhấn **Thêm khách** hoặc **Khách hàng → Thêm khách**.

Điền:
• **Tên** (bắt buộc), SĐT, **địa chỉ giao hàng mặc định**, ghi chú
• **Nguồn khách** — Facebook, Zalo, TikTok, giới thiệu… (xem doanh thu theo kênh trong Thống kê)
• **Sản phẩm quan tâm** — chọn từ danh mục (khuyến nghị) hoặc nhập tay
• **Trạng thái** — Mới / Tiềm năng / Nóng / Đã chốt (quyết định lịch nhắc chăm)
• **Ngày hết bảo hành** (tuỳ chọn)

**Địa chỉ trên hồ sơ khách** là mặc định cho đơn mới — sửa hồ sơ **không** làm đổi địa chỉ trên đơn đã ghi (xem mục 3).`,
  },
  {
    icon: Truck,
    iconColor: 'text-cyan-700 dark:text-cyan-400',
    iconBg: 'bg-cyan-100 dark:bg-cyan-950/50',
    title: '3. Ghi đơn & giao hàng (snapshot)',
    body: `Từ **Chi tiết khách → Ghi đơn**, hoặc **Đơn hàng → Ghi đơn mới**.

Form ghi đơn có block **Thông tin giao hàng** — tự điền từ hồ sơ khách:
• **Người nhận**, **SĐT**, **Địa chỉ** — sửa được ngay lúc ghi đơn (giao hộ, địa chỉ tạm…)
• Khi lưu, Salenote **snapshot** 3 trường này vào đơn — cố định, không đổi khi bạn sửa hồ sơ khách sau này

Phần sản phẩm & tiền:
• Chọn SP từ danh mục (tự điền giá) hoặc nhập tay; cảnh báo nếu vượt tồn kho
• SL, giá bán / vốn / hoa hồng, thanh toán (đủ / cọc / nợ)
• Tuỳ chọn đánh dấu khách **Đã chốt** sau khi ghi đơn`,
  },
  {
    icon: FileText,
    iconColor: 'text-emerald-700 dark:text-emerald-400',
    iconBg: 'bg-emerald-100 dark:bg-emerald-950/50',
    title: '4. Bill, copy ship & cập nhật đơn',
    body: `Trong **Chi tiết khách** (từng dòng đơn) hoặc **Đơn hàng → mở đơn**:

• **Sao chép giao hàng** — copy block người nhận / SĐT / địa chỉ / SP / tiền dán sang shipper hoặc Zalo
• **Xem bill** — preview phiếu bán hàng → **Tải PDF** hoặc **Chia sẻ**
• Sửa **giao hàng trên đơn** (người nhận, SĐT, địa chỉ) — badge **Khác hồ sơ khách** nếu khác profile
• Cập nhật **thanh toán** (cọc / nợ) nếu đơn chưa thu đủ

**Cài đặt → Thông tin trên bill**: nhập tên shop & SĐT hiển thị trên PDF.

Danh sách **Đơn hàng** có phân trang; mỗi đơn hiển thị doanh thu và trạng thái thanh toán.`,
  },
  {
    icon: Sparkles,
    iconColor: 'text-fuchsia-700 dark:text-fuchsia-400',
    iconBg: 'bg-fuchsia-100 dark:bg-fuchsia-950/50',
    title: '5. Trợ lý Sale — Bảng điều khiển',
    body: `**Bảng điều khiển** (Trang chủ) không chỉ liệt kê khách — có **Trợ lý Sale** gợi ý việc làm hôm nay:

• **Việc nên làm hôm nay** — ưu tiên nhắn khách, thu nợ, gửi ưu đãi, chăm khách cũ…
• **Cảnh báo rủi ro** — khách nóng lâu chưa liên hệ, công nợ cao, bảo hành sắp hết
• **Gợi ý doanh thu** — so sánh tuần/tháng, top SP, kênh bán tốt
• **Thành tích** — streak liên hệ 🔥, mốc đơn / doanh thu

Bấm từng gợi ý để nhảy thẳng tới khách hoặc màn hình liên quan. **Chi tiết khách** còn có panel **Thông minh khách** (tổng đơn, doanh thu, gợi ý hành động).`,
  },
  {
    icon: Link2,
    iconColor: 'text-orange-700 dark:text-orange-400',
    iconBg: 'bg-orange-100 dark:bg-orange-950/50',
    title: '6. Liên kết dữ liệu Salenote',
    body: `Mọi thứ nối với nhau trên máy bạn:

**Khách** → nguồn + SP quan tâm + địa chỉ mặc định
**Đơn hàng** → khách + SP + snapshot giao hàng + doanh thu / lời / HH / công nợ
**Dashboard & Trợ lý Sale** → tính từ đơn và lịch sử liên hệ thực
**Thống kê** → doanh thu theo SP và **nguồn khách**

Xoá khách sẽ xoá luôn đơn và lịch sử liên hệ — cẩn thận trước khi xoá.`,
  },
  {
    icon: MessageSquare,
    iconColor: 'text-sky-700 dark:text-sky-400',
    iconBg: 'bg-sky-100 dark:bg-sky-950/50',
    title: '7. Chăm khách & nhắc lịch',
    body: `**Bảng điều khiển** hiển thị khách cần liên hệ ngay và sắp tới.

🔵 **Mới** — nhắc sau 1 ngày
🟠 **Tiềm năng** — nhắc sau 2 ngày
🔴 **Nóng** — nhắc mỗi ngày
🟢 **Đã chốt** — nhắc chăm lại sau 7 ngày

Bấm **Đã nhắn** để ghi nhận liên hệ (reset đồng hồ nhắc). Trong chi tiết khách: soạn tin mẫu, sao chép sang Zalo/Messenger, gọi 1 chạm (app). Mẫu tin tuỳ chỉnh tại **Cài đặt**.`,
  },
  {
    icon: BarChart3,
    iconColor: 'text-purple-700 dark:text-purple-400',
    iconBg: 'bg-purple-100 dark:bg-purple-950/50',
    title: '8. Thống kê',
    body: `**Thống kê** (theo tháng):
• Doanh số thực từ đơn hàng (doanh thu, lời, HH, công nợ)
• Lượt liên hệ, khách mới, streak 🔥
• Top SP bán chạy (theo doanh thu đơn)
• **Doanh thu theo nguồn khách** — biết kênh nào mang tiền

**Khách hàng**: lọc theo trạng thái và nguồn; tìm theo tên, SĐT, địa chỉ, SP.
**Chi tiết khách**: tất cả đơn + tổng doanh thu / lời / HH / nợ + thông minh khách.`,
  },
  {
    icon: CloudUpload,
    iconColor: 'text-teal-700 dark:text-teal-400',
    iconBg: 'bg-teal-100 dark:bg-teal-950/50',
    title: '9. Sao lưu dữ liệu',
    body: `Dữ liệu lưu trên máy bạn (IndexedDB web / SQLite app), không gửi lên server.

**Cài đặt → Sao lưu & khôi phục**:
• **Tải backup JSON** — khách, liên hệ, sản phẩm, đơn hàng (kèm snapshot giao hàng)
• **Khôi phục JSON** — file dùng chung giữa web và app mobile
• **Xuất CSV** — khách (kèm nguồn), liên hệ, đơn hàng

Nên backup ít nhất 1 lần/tuần.`,
  },
  {
    icon: Bell,
    iconColor: 'text-amber-700 dark:text-amber-400',
    iconBg: 'bg-amber-100 dark:bg-amber-950/50',
    title: '10. Thông báo nhắc nhở',
    body: `**Cài đặt → Thông báo nhắc nhở**:

• **Hàng ngày** — giờ tuỳ chọn: khách cần liên hệ (Mới/Tiềm năng/Nóng)
• **Tổng kết tuần** (Thứ Hai) — doanh số 7 ngày, số đơn
• **Tổng kết tháng** (ngày 1) — liên hệ & chốt đơn tháng trước
• **Tri ân & ưu đãi** (Thứ Sáu) — khách tiềm năng lâu chưa chăm, khách cũ nên gửi quà

**Web**: nhắc khi tab Salenote đang mở (hoặc PWA đã cài). **App mobile**: nhắc nền cả khi đóng app.`,
  },
];

import 'package:flutter/material.dart';

class GuideSectionData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const GuideSectionData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

/// Nội dung đồng bộ với web/src/lib/guideContent.ts (+ mục app mobile)
List<GuideSectionData> salenoteGuideSections({bool includeMobile = true}) {
  final sections = <GuideSectionData>[
    const GuideSectionData(
      icon: Icons.inventory_2_outlined,
      iconColor: Color(0xFF6D28D9),
      title: '1. Danh mục sản phẩm',
      body:
          'Vào Sản phẩm trước khi ghi đơn.\n\n'
          'Mỗi SP có: giá vốn, giá bán mặc định, hoa hồng mặc định.\n\n'
          'Theo dõi tồn kho (tuỳ chọn):\n'
          '• Bật — hàng vật lý: nhập tồn, cảnh báo sắp hết. Ghi đơn tự trừ kho.\n'
          '• Tắt — dịch vụ / đặt hộ / không quản kho.\n\n'
          'Danh mục liên kết khách ↔ đơn ↔ tiền ↔ kho.',
    ),
    const GuideSectionData(
      icon: Icons.person_add_outlined,
      iconColor: Color(0xFF1565C0),
      title: '2. Thêm khách & nguồn',
      body:
          'Thêm khách từ FAB hoặc Khách hàng.\n\n'
          'Điền: tên, SĐT, nguồn (Facebook, Zalo…), SP từ danh mục hoặc nhập tay, trạng thái, bảo hành.\n\n'
          'Ghi nguồn ngay khi thêm để xem doanh thu theo kênh trong Thống kê.',
    ),
    const GuideSectionData(
      icon: Icons.receipt_long_outlined,
      iconColor: Color(0xFF047857),
      title: '3. Ghi đơn hàng (có số tiền)',
      body:
          'Chi tiết khách → Ghi đơn, hoặc menu → Ghi đơn mới / Đơn hàng.\n\n'
          'Form tự điền SP và giá nếu khách liên kết danh mục. SP có kho sẽ cảnh báo khi bán vượt tồn.\n\n'
          'Nhập SL, giá bán/vốn/HH, thanh toán (đủ / cọc / nợ). Tuỳ chọn đánh dấu khách Đã chốt.',
    ),
    const GuideSectionData(
      icon: Icons.link_rounded,
      iconColor: Color(0xFFEA580C),
      title: '4. Liên kết dữ liệu Salenote',
      body:
          'Khách → nguồn + SP quan tâm\n'
          'Đơn hàng → khách + SP + doanh thu / lời / HH / công nợ\n'
          'Bảng điều khiển → cộng từ đơn thực\n'
          'Thống kê → doanh thu theo SP và nguồn khách\n\n'
          'Xoá khách sẽ xoá luôn đơn và lịch sử liên hệ.',
    ),
    const GuideSectionData(
      icon: Icons.chat_bubble_outline,
      iconColor: Color(0xFF0284C7),
      title: '5. Chăm khách & nhắc lịch',
      body:
          '🔵 Mới — nhắc sau 1 ngày\n'
          '🟠 Tiềm năng — 2 ngày\n'
          '🔴 Nóng — mỗi ngày\n'
          '🟢 Đã chốt — chăm lại sau 7 ngày\n\n'
          'Vuốt thẻ hoặc Chi tiết → Nhắn tin. Mẫu tin tuỳ chỉnh trong Cài đặt.',
    ),
    const GuideSectionData(
      icon: Icons.bar_chart_outlined,
      iconColor: Color(0xFF7C3AED),
      title: '6. Dashboard & thống kê',
      body:
          'Trang chủ: doanh số hôm nay/tháng, cảnh báo tồn kho, khách cần chăm.\n\n'
          'Thống kê: doanh số đơn thực, lượt liên hệ, top SP bán, doanh thu theo nguồn, streak.',
    ),
    const GuideSectionData(
      icon: Icons.cloud_upload_outlined,
      iconColor: Color(0xFF0D9488),
      title: '7. Sao lưu & đồng bộ web',
      body:
          'Cài đặt → Sao lưu JSON (Salenote v2: khách, liên hệ, SP, đơn).\n\n'
          'File JSON dùng chung với web Salenote — export app, import web và ngược lại.\n\n'
          'Nên backup mỗi tuần. Cài đặt app (PIN, thông báo) không nằm trong file JSON.',
    ),
  ];

  if (includeMobile) {
    sections.add(
      const GuideSectionData(
        icon: Icons.notifications_active_outlined,
        iconColor: Color(0xFFF57F17),
        title: '8. Riêng app mobile',
        body:
            'Cài đặt → Thông báo:\n'
            '• Hàng ngày — giờ tuỳ chọn, khách cần liên hệ\n'
            '• Tổng kết tuần (T2) — doanh số 7 ngày\n'
            '• Tổng kết tháng (ngày 1) — thống kê tháng trước\n'
            '• Tri ân & ưu đãi (T6) — khách tiềm năng & khách cũ\n\n'
            'Thêm: gọi điện 1 chạm, PIN khóa app, vuốt thẻ nhanh.\n\n'
            'Web có nhắc trình duyệt khi tab mở; app nhắc nền 24/7.',
      ),
    );
  }

  return sections;
}

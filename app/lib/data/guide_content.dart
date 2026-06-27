import 'package:flutter/material.dart';

/// Phiên bản hướng dẫn — đồng bộ web/src/lib/guideContent.ts
const String guideVersion = '2.3';

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

/// Nội dung đồng bộ với web/src/lib/guideContent.ts (+ mục riêng app mobile)
List<GuideSectionData> salenoteGuideSections({bool includeMobile = true}) {
  final sections = <GuideSectionData>[
    const GuideSectionData(
      icon: Icons.inventory_2_outlined,
      iconColor: Color(0xFF6D28D9),
      title: '1. Danh mục sản phẩm',
      body:
          'Vào Sản phẩm trước khi ghi đơn.\n\n'
          'Mỗi SP có: giá vốn, giá bán mặc định, hoa hồng mặc định, ghi chú nội bộ.\n\n'
          'Theo dõi tồn kho (tuỳ chọn):\n'
          '• Bật — hàng vật lý: nhập tồn, cảnh báo sắp hết. Ghi đơn tự trừ kho.\n'
          '• Tắt — dịch vụ / đặt hộ / không quản kho.\n\n'
          'Danh mục liên kết khách ↔ đơn ↔ tiền ↔ kho.',
    ),
    const GuideSectionData(
      icon: Icons.person_add_outlined,
      iconColor: Color(0xFF1565C0),
      title: '2. Khách hàng, địa chỉ & nguồn',
      body:
          'Thêm khách từ FAB hoặc menu Khách hàng.\n\n'
          'Điền: tên, SĐT, địa chỉ giao hàng mặc định, nguồn (Facebook, Zalo…), '
          'SP từ danh mục hoặc nhập tay, trạng thái, bảo hành.\n\n'
          'Địa chỉ trên hồ sơ khách là mặc định cho đơn mới — sửa hồ sơ không đổi địa chỉ trên đơn đã ghi.',
    ),
    const GuideSectionData(
      icon: Icons.local_shipping_outlined,
      iconColor: Color(0xFF0891B2),
      title: '3. Ghi đơn & giao hàng (snapshot)',
      body:
          'Chi tiết khách → Ghi đơn, hoặc menu → Ghi đơn / Đơn hàng.\n\n'
          'Block Thông tin giao hàng tự điền từ khách — có thể sửa người nhận, SĐT, địa chỉ trước khi lưu.\n\n'
          'Salenote snapshot 3 trường này vào đơn — cố định, không đổi khi sửa hồ sơ khách sau này.\n\n'
          'Nhập SL, giá bán/vốn/HH, thanh toán (đủ / cọc / nợ). Tuỳ chọn đánh dấu Đã chốt.',
    ),
    const GuideSectionData(
      icon: Icons.receipt_long_outlined,
      iconColor: Color(0xFF047857),
      title: '4. Bill, copy ship & cập nhật đơn',
      body:
          'Chi tiết khách hoặc Đơn hàng → mở đơn:\n\n'
          '• Copy ship — sao chép thông tin giao hàng\n'
          '• Xem bill — preview → Tải PDF / Chia sẻ\n'
          '• Sửa giao hàng trên đơn (badge Khác hồ sơ nếu khác profile)\n'
          '• Cập nhật thanh toán nếu chưa thu đủ\n\n'
          'Cài đặt → Thông tin trên bill: tên shop & SĐT trên PDF.\n\n'
          'Danh sách Đơn hàng hiển thị doanh thu và trạng thái thanh toán. '
          'Trên app: cuộn xuống cuối để tải thêm (xem mục 11).',
    ),
    const GuideSectionData(
      icon: Icons.auto_awesome_outlined,
      iconColor: Color(0xFFC026D3),
      title: '5. Trợ lý — Trang Hôm nay',
      body:
          'Trang chủ là trợ lý kinh doanh cá nhân:\n\n'
          '• Việc hôm nay — nhắn khách, thu nợ, mời mua lại, nhập hàng sắp hết…\n'
          '• Mục tiêu tháng — tiến độ doanh thu (đặt trong Cài đặt)\n'
          '• Gợi ý hôm nay — kết luận từ dữ liệu tháng\n'
          '• Ai nợ tôi — danh sách khách còn nợ\n\n'
          'Bấm từng việc để nhảy tới khách hoặc màn hình liên quan. '
          'Chi tiết khách có panel trí nhớ (tổng đơn, doanh thu, gợi ý).',
    ),
    const GuideSectionData(
      icon: Icons.link_rounded,
      iconColor: Color(0xFFEA580C),
      title: '6. Liên kết dữ liệu Salenote',
      body:
          'Khách → nguồn + SP quan tâm + địa chỉ mặc định\n'
          'Đơn hàng → khách + SP + snapshot giao hàng + doanh thu / lời / HH / công nợ\n'
          'Hôm nay & Trợ lý → tính từ đơn và lịch sử liên hệ thực\n'
          'Tiền của tôi → doanh thu theo SP và nguồn khách\n\n'
          'Xoá khách sẽ xoá luôn đơn và lịch sử liên hệ.',
    ),
    const GuideSectionData(
      icon: Icons.chat_bubble_outline,
      iconColor: Color(0xFF0284C7),
      title: '7. Chăm khách & nhắc lịch',
      body:
          'Hôm nay hiển thị khách cần liên hệ (mục Sổ khách hôm nay — mở rộng khi cần).\n\n'
          '🔵 Mới — nhắc sau 1 ngày\n'
          '🟠 Tiềm năng — 2 ngày\n'
          '🔴 Nóng — mỗi ngày\n'
          '🟢 Đã chốt — chăm lại sau 7 ngày\n\n'
          'Vuốt thẻ hoặc Chi tiết → Nhắn tin / Gọi. Mẫu tin tuỳ chỉnh trong Cài đặt.',
    ),
    const GuideSectionData(
      icon: Icons.bar_chart_outlined,
      iconColor: Color(0xFF7C3AED),
      title: '8. Thống kê',
      body:
          'Thống kê: doanh số đơn thực, lượt liên hệ, khách mới, top SP bán, '
          'doanh thu theo nguồn, streak.\n\n'
          'Sổ khách: lọc trạng thái, nguồn; tìm tên, SĐT, địa chỉ, SP. '
          'Danh sách dài: cuộn xuống cuối để tải thêm (mục 11).\n\n'
          'Chi tiết khách: tất cả đơn + tổng doanh thu / lời / HH / nợ.',
    ),
    const GuideSectionData(
      icon: Icons.cloud_upload_outlined,
      iconColor: Color(0xFF0D9488),
      title: '9. Sao lưu & đồng bộ web',
      body:
          'Cài đặt → Sao lưu JSON (khách, liên hệ, SP, đơn kèm snapshot giao hàng).\n\n'
          'File JSON dùng chung với web Salenote — export app, import web và ngược lại.\n\n'
          'Nên backup mỗi tuần. PIN và cài đặt thông báo không nằm trong JSON.',
    ),
    const GuideSectionData(
      icon: Icons.view_list_outlined,
      iconColor: Color(0xFF475569),
      title: '10. Danh sách dài (cuộn tải thêm)',
      body:
          'App không tải hết hàng nghìn dòng một lúc — hiển thị 20 mục đầu, '
          'rồi tải thêm khi bạn cuộn.\n\n'
          'Áp dụng: Sổ khách, Sản phẩm, Đơn hàng, Ai nợ tôi, sổ hôm nay trên Trang chủ, '
          'form chọn khách/SP.\n\n'
          'Cuộn xuống cuối danh sách để tự tải thêm. Cuối list có dòng '
          '«Cuộn để xem thêm (x/y)» hoặc «Đã hiển thị tất cả». '
          'Không cần bấm nút chuyển trang.\n\n'
          'Nếu danh sách ngắn hơn màn hình mà vẫn còn dữ liệu, app tự tải thêm — '
          'bạn luôn xem được toàn bộ sổ.\n\n'
          'Trên web: trang danh sách đầy đủ dùng nút Phân trang; popup chọn khách/SP cuộn tải thêm giống app.',
    ),
  ];

  if (includeMobile) {
    sections.add(
      const GuideSectionData(
        icon: Icons.notifications_active_outlined,
        iconColor: Color(0xFFF57F17),
        title: '11. Riêng app mobile',
        body:
            'Cài đặt → Thông báo:\n'
            '• Hàng ngày — giờ tuỳ chọn, khách cần liên hệ\n'
            '• Tổng kết tuần (T2) — doanh số 7 ngày\n'
            '• Tổng kết tháng (ngày 1) — thống kê tháng trước\n'
            '• Tri ân & ưu đãi (T6) — khách tiềm năng & khách cũ\n\n'
            'Thêm: gọi điện 1 chạm, PIN khóa app, vuốt thẻ nhanh, nhắc nền 24/7.\n'
            'Web nhắc khi tab mở; app nhắc cả khi đóng app.',
      ),
    );
  }

  return sections;
}

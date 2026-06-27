import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isVi => locale.languageCode == 'vi';

  // ── App ────────────────────────────────────────────────────
  String get appName => isVi ? 'Salenote' : 'Salenote';
  String get appNameFull =>
      isVi ? 'Sổ Sale Cá Nhân - Salenote' : 'Personal Sales Ledger - Salenote';
  String get appTagline => isVi
      ? 'Trợ lý kinh doanh cá nhân'
      : 'Personal business assistant';
  String get version => isVi ? 'Phiên bản' : 'Version';

  // ── Home ───────────────────────────────────────────────────
  String get needsAttention => isVi ? 'Cần liên hệ ngay' : 'Needs Attention';
  String get upcoming => isVi ? 'Sắp tới' : 'Upcoming';
  String get noCustomers => isVi ? 'Chưa có khách hàng' : 'No customers yet';
  String get noCustomersHint => isVi
      ? 'Thêm khách hàng đầu tiên để bắt đầu theo dõi và nhắc nhở liên hệ.'
      : 'Add your first customer to start tracking and scheduling follow-ups.';
  String get addCustomer => isVi ? 'Thêm khách' : 'Add customer';
  String get searchHint => isVi ? 'Tìm tên, SĐT, sản phẩm...' : 'Search name, phone, product...';
  String get noSearchResults => isVi ? 'Không tìm thấy khách nào' : 'No customers found';
  String get allCustomers => isVi ? 'Sổ khách' : 'Customers';
  String get stats => isVi ? 'Tiền của tôi' : 'My money';
  String get settings => isVi ? 'Cài đặt' : 'Settings';
  String get messageSentConfirm =>
      isVi ? 'Đã nhắn tin cho {name} ✓' : 'Messaged {name} ✓';
  String get undo => isVi ? 'Hoàn tác' : 'Undo';
  String get deleteCustomerTitle => isVi ? 'Xoá khách hàng?' : 'Delete customer?';
  String get deleteCustomerConfirm =>
      isVi ? 'Xoá "{name}" và toàn bộ lịch sử?' : 'Delete "{name}" and all history?';
  String get delete => isVi ? 'Xoá' : 'Delete';
  String get cancel => isVi ? 'Huỷ' : 'Cancel';
  String get streakDays => isVi ? '{n} ngày' : '{n} days';

  // ── Statuses ───────────────────────────────────────────────
  String get statusNew => isVi ? 'Mới' : 'New';
  String get statusWarm => isVi ? 'Tiềm năng' : 'Warm';
  String get statusHot => isVi ? 'Nóng' : 'Hot';
  String get statusClosed => isVi ? 'Đã chốt' : 'Closed';
  String statusLabel(String s) {
    switch (s) {
      case 'warm': return statusWarm;
      case 'hot': return statusHot;
      case 'closed': return statusClosed;
      default: return statusNew;
    }
  }

  // ── Add / Edit Customer ────────────────────────────────────
  String get addCustomerTitle => isVi ? 'Thêm khách hàng' : 'Add Customer';
  String get editCustomerTitle => isVi ? 'Chỉnh sửa' : 'Edit Customer';
  String get customerName => isVi ? 'Tên khách hàng *' : 'Customer name *';
  String get customerNameHint => isVi ? 'Nhập tên...' : 'Enter name...';
  String get customerNameRequired => isVi ? 'Nhập tên khách hàng' : 'Enter customer name';
  String get phone => isVi ? 'Số điện thoại' : 'Phone number';
  String get phoneHint => isVi ? '0901...' : '0901...';
  String get product => isVi ? 'Sản phẩm quan tâm' : 'Product of interest';
  String get productHint => isVi ? 'Áo, túi, mỹ phẩm...' : 'Shirt, bag, cosmetics...';
  String get note => isVi ? 'Ghi chú' : 'Note';
  String get noteHint => isVi ? 'Khách ở quận 1, thích màu xanh...' : 'Customer notes...';
  String get status => isVi ? 'Trạng thái' : 'Status';
  String get save => isVi ? 'Lưu' : 'Save';
  String get saving => isVi ? 'Đang lưu...' : 'Saving...';

  // ── Customer Detail ────────────────────────────────────────
  String get markMessaged => isVi ? 'Đã nhắn' : 'Mark Messaged';
  String get closeDeal => isVi ? 'Chốt đơn' : 'Close Deal';
  String get closeDealTitle => isVi ? 'Chốt đơn thành công?' : 'Close this deal?';
  String get closeDealContent => isVi
      ? 'Xác nhận đã chốt đơn với khách này.'
      : 'Confirm closing the deal with this customer.';
  String get confirm => isVi ? 'Xác nhận' : 'Confirm';
  String get history => isVi ? 'Lịch sử liên hệ' : 'Contact History';
  String get noHistory => isVi ? 'Chưa có lịch sử' : 'No history yet';
  String get sendMessage => isVi ? 'Nhắn tin' : 'Send Message';
  String get copyMessage => isVi ? 'Copy tin nhắn' : 'Copy Message';
  String get messageCopied => isVi ? 'Đã copy tin nhắn ✓' : 'Message copied ✓';
  String get messageSent => isVi ? 'Đã nhắn tin ✓' : 'Message sent ✓';
  String get nextContact => isVi ? 'Lịch liên hệ' : 'Next Contact';
  String get lastContact => isVi ? 'Liên hệ gần nhất' : 'Last Contact';
  String get changeStatus => isVi ? 'Đổi trạng thái' : 'Change Status';

  // ── Stats ──────────────────────────────────────────────────
  String get statsTitle => isVi ? 'Thống kê' : 'Statistics';
  String get contacts => isVi ? 'Lượt liên hệ' : 'Contacts';
  String get closedDeals => isVi ? 'Đơn chốt' : 'Closed Deals';
  String get newCustomers => isVi ? 'Khách mới' : 'New Customers';
  String get conversionRate => isVi ? 'Tỷ lệ chốt' : 'Conversion Rate';
  String get topProducts => isVi ? 'Sản phẩm phổ biến' : 'Top Products';
  String get noProductsYet => isVi ? 'Chưa có dữ liệu sản phẩm' : 'No product data yet';
  String get streak => isVi ? 'Chuỗi liên hệ' : 'Contact Streak';
  String get streakDaysLabel => isVi ? 'ngày liên tiếp' : 'consecutive days';
  String get streakMotivation => isVi
      ? 'Bạn đang làm rất tốt! Giữ vững phong độ nhé!'
      : 'Keep it up! You\'re doing great!';

  // ── Settings ───────────────────────────────────────────────
  String get settingsTitle => isVi ? 'Cài đặt' : 'Settings';
  String get backup => isVi ? 'Sao lưu dữ liệu' : 'Data Backup';
  String get exportBackup => isVi ? 'Xuất sao lưu' : 'Export Backup';
  String get exportBackupSub => isVi
      ? 'Lưu file JSON và chia sẻ qua ứng dụng khác'
      : 'Save JSON file and share via other apps';
  String get importBackup => isVi ? 'Khôi phục từ sao lưu' : 'Restore from Backup';
  String get importBackupSub => isVi
      ? 'Chọn file JSON để khôi phục toàn bộ dữ liệu'
      : 'Select JSON file to restore all data';
  String get restoreTitle => isVi ? 'Khôi phục dữ liệu?' : 'Restore data?';
  String get restoreContent => isVi
      ? 'Toàn bộ dữ liệu hiện tại sẽ bị xoá và thay thế. Hành động này không thể hoàn tác.'
      : 'All current data will be deleted and replaced. This cannot be undone.';
  String get restore => isVi ? 'Khôi phục' : 'Restore';
  String get exportSuccess => isVi ? 'Đã xuất file sao lưu ✓' : 'Backup exported ✓';
  String get importSuccess => isVi ? 'Khôi phục thành công ✓' : 'Restored successfully ✓';
  String get importCancelled => isVi ? 'Đã huỷ chọn file' : 'File selection cancelled';
  String get invalidFile => isVi ? 'File không hợp lệ' : 'Invalid file';
  String get notifications => isVi ? 'Thông báo' : 'Notifications';
  String get dailyReminder => isVi ? 'Nhắc nhở hàng ngày' : 'Daily Reminder';
  String get dailyReminderSub => isVi
      ? 'Thông báo vào giờ bạn chọn nếu có khách cần nhắn'
      : 'Notification at your chosen time when follow-ups are due';
  String notifEnabledAt(int hour, int minute) => isVi
      ? 'Đã bật nhắc nhở ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ✓'
      : 'Reminder enabled at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ✓';
  String get notifTimeSaved => isVi
      ? 'Đã cập nhật giờ nhắc nhở ✓'
      : 'Reminder time updated ✓';
  String get weeklyDigest => isVi ? 'Tổng kết tuần' : 'Weekly digest';
  String get weeklyDigestSub => isVi
      ? 'Thứ Hai — doanh số 7 ngày & gợi ý kế hoạch tuần mới'
      : 'Monday — last 7 days sales & weekly planning';
  String get monthlyDigest => isVi ? 'Tổng kết tháng' : 'Monthly digest';
  String get monthlyDigestSub => isVi
      ? 'Ngày 1 hàng tháng — liên hệ, chốt đơn tháng trước & mục tiêu mới'
      : '1st of month — last month stats & new goals';
  String get loyaltyReminder => isVi ? 'Tri ân & ưu đãi khách' : 'Loyalty & promos';
  String get loyaltyReminderSub => isVi
      ? 'Thứ Sáu — khách tiềm năng lâu chưa chăm & khách cũ gửi quà tri ân'
      : 'Friday — warm leads to nurture & past customers for thank-you offers';
  String get notifPermRequired =>
      isVi ? 'Cần cấp quyền thông báo trong Cài đặt điện thoại' : 'Notification permission required in phone Settings';
  String get notifEnabled => isVi ? 'Đã bật nhắc nhở ✓' : 'Daily reminder enabled ✓';
  String get notifDisabled => isVi ? 'Đã tắt thông báo nhắc nhở' : 'Reminder disabled';
  String get appearance => isVi ? 'Giao diện' : 'Appearance';
  String get themeSystem => isVi ? 'Theo hệ thống' : 'System';
  String get themeLight => isVi ? 'Sáng' : 'Light';
  String get themeDark => isVi ? 'Tối' : 'Dark';
  String get language => isVi ? 'Ngôn ngữ' : 'Language';
  String get langVi => isVi ? 'Tiếng Việt' : 'Vietnamese';
  String get langEn => isVi ? 'Tiếng Anh' : 'English';
  String get security => isVi ? 'Bảo mật' : 'Security';
  String get pinLock => isVi ? 'Khoá PIN' : 'PIN Lock';
  String get pinLockSub =>
      isVi ? 'Yêu cầu nhập mã 4 số khi mở app' : 'Require 4-digit PIN to open app';
  String get pinEnabled => isVi ? 'Đã bật khoá PIN ✓' : 'PIN lock enabled ✓';
  String get pinDisabled => isVi ? 'Đã tắt khoá PIN' : 'PIN lock disabled';
  String get changePin => isVi ? 'Đổi mã PIN' : 'Change PIN';
  String get changePinSuccess => isVi ? 'Đã đổi mã PIN ✓' : 'PIN changed ✓';
  String get messageTemplates => isVi ? 'Mẫu tin nhắn' : 'Message Templates';
  String get templateLibrary => isVi ? 'Thư viện mẫu tin' : 'Template Library';
  String get templateSelected => isVi ? 'Đã chọn mẫu tin ✓' : 'Template selected ✓';
  String get templateHint =>
      isVi ? 'Dùng {tên} và {sản_phẩm} để tự điền' : 'Use {name} and {product} as placeholders';
  String get templateLibraryHint =>
      isVi ? 'Chọn mẫu có sẵn hoặc tự soạn bên trên.' : 'Pick a preset or write your own above.';
  String get about => isVi ? 'Về ứng dụng' : 'About';
  String get guide => isVi ? 'Hướng dẫn sử dụng' : 'User Guide';

  // ── PIN Screen ─────────────────────────────────────────────
  String get pinUnlockTitle => isVi ? 'Nhập mã PIN' : 'Enter PIN';
  String get pinUnlockSub => isVi ? 'Nhập mã PIN để mở Salenote' : 'Enter PIN to open Salenote';
  String get pinSetupTitle => isVi ? 'Đặt mã PIN mới' : 'Set New PIN';
  String get pinSetupSub => isVi ? 'Chọn mã PIN 4 chữ số' : 'Choose a 4-digit PIN';
  String get pinConfirmTitle => isVi ? 'Nhập lại mã PIN' : 'Confirm PIN';
  String get pinConfirmSub => isVi ? 'Nhập lại PIN vừa chọn để xác nhận' : 'Re-enter PIN to confirm';
  String get pinChangeTitle => isVi ? 'Nhập PIN hiện tại' : 'Enter Current PIN';
  String get pinChangeSub => isVi ? 'Nhập mã PIN hiện tại của bạn' : 'Enter your current PIN';
  String get pinWrong => isVi ? 'Sai mã PIN, thử lại' : 'Wrong PIN, try again';
  String get pinMismatch => isVi ? 'PIN không khớp, thử lại' : 'PINs don\'t match, try again';

  // ── Notifications (smart) ─────────────────────────────────
  String get notifTitle => isVi ? 'Salenote' : 'Salenote';
  String notifBodyHot(int n) => isVi
      ? 'Có $n khách NÓNG đang chờ bạn liên hệ!'
      : '$n HOT customers are waiting for your follow-up!';
  String notifBodyMixed(int urgent, int total) => isVi
      ? 'Bạn có $urgent khách cần nhắn ngay, $total tổng cộng hôm nay'
      : 'You have $urgent urgent, $total total follow-ups today';
  String notifBodyGeneral(int n) => isVi
      ? 'Bạn có $n khách cần liên hệ hôm nay'
      : 'You have $n customers to follow up today';

  // ── Onboarding ─────────────────────────────────────────────
  String get onboardSkip => isVi ? 'Bỏ qua' : 'Skip';
  String get onboardNext => isVi ? 'Tiếp theo' : 'Next';
  String get onboardStart => isVi ? 'Bắt đầu ngay!' : 'Get Started!';
  String get onboard1Title => isVi ? 'Theo dõi mọi khách hàng' : 'Track Every Customer';
  String get onboard1Body => isVi
      ? 'Lưu tên, SĐT, sản phẩm và ghi chú cho từng khách. Không bao giờ quên khách nào nữa.'
      : 'Save name, phone, product and notes for each customer. Never forget anyone again.';
  String get onboard2Title => isVi ? 'Nhắc nhở thông minh' : 'Smart Reminders';
  String get onboard2Body => isVi
      ? 'App tự động tính ngày cần liên hệ lại theo trạng thái khách. Khách Nóng nhắc 1 ngày, khách Tiềm năng nhắc 2 ngày.'
      : 'App auto-schedules follow-up dates based on customer status. Hot leads: 1 day, Warm: 2 days.';
  String get onboard3Title => isVi ? 'Chốt đơn, xem kết quả' : 'Close Deals & See Results';
  String get onboard3Body => isVi
      ? 'Theo dõi tỷ lệ chốt, streak liên hệ hàng ngày và top sản phẩm. Biết mình đang làm tốt không.'
      : 'Track your conversion rate, daily contact streak and top products. See how well you\'re doing.';

  // ── Guide ──────────────────────────────────────────────────
  String get guideTitle => isVi ? 'Hướng dẫn sử dụng' : 'User Guide';
  String get guideIntro => isVi
      ? 'Salenote v2 — sổ sale cá nhân: chăm khách, ghi đơn có tiền, snapshot giao hàng, bill PDF, Trợ lý Sale. Dữ liệu trên máy bạn, backup JSON dùng chung web ↔ app.'
      : 'Salenote v2 — personal sales CRM: orders, shipping snapshots, PDF bills, Sales Assistant. Data stays on device; JSON backup syncs web ↔ app.';
  String get guide1Title => isVi ? 'Thêm khách hàng' : 'Add a Customer';
  String get guide1Body => isVi
      ? 'Nhấn nút "Thêm khách" ở góc dưới màn hình chính. Điền tên (bắt buộc), SĐT, sản phẩm và ghi chú tuỳ ý.\n\nQuan trọng: Chọn đúng trạng thái ngay khi thêm khách để app tính lịch nhắc chính xác. Mặc định là "Mới".'
      : 'Tap "Add customer" at the bottom of the home screen. Fill in name (required), phone, product and notes.\n\nImportant: Choose the correct status when adding a customer so the app schedules the right reminder. Default is "New".';
  String get guide2Title => isVi ? 'Nhắn tin & Cập nhật' : 'Message & Update';
  String get guide2Body => isVi
      ? 'Vuốt phải thẻ khách để đánh dấu "Đã nhắn". Vuốt trái để xoá. Nhấn vào thẻ để xem chi tiết và thay đổi trạng thái.'
      : 'Swipe right to mark as messaged. Swipe left to delete. Tap card for details and status changes.';
  String get guide3Title => isVi ? 'Trạng thái & Lịch nhắc' : 'Statuses & Reminder Schedule';
  String get guide3Body => isVi
      ? '🔵 Mới — Nhắc sau 1 ngày\nKhách vừa được thêm, chưa liên hệ lần nào. App sẽ nhắc bạn liên hệ lần đầu vào ngày hôm sau.\n\n🟠 Tiềm năng — Nhắc sau 2 ngày\nĐã liên hệ nhưng khách còn đang cân nhắc. App cho thêm 2 ngày trước khi nhắc theo dõi lại.\n\n🔴 Nóng — Nhắc sau 1 ngày\nKhách sắp chốt đơn, cần theo sát. App nhắc mỗi 1 ngày để bạn không bỏ lỡ cơ hội.\n\n🟢 Đã chốt — Nhắc sau 7 ngày\nĐã mua hàng. App sẽ nhắc bạn chăm sóc lại sau 7 ngày để tạo cơ hội mua hàng tiếp theo.\n\nSau mỗi lần "Đã nhắn", đồng hồ nhắc được reset theo đúng chu kỳ trên.'
      : '🔵 New — Remind in 1 day\nJust added, no contact yet. App reminds you to make first contact the next day.\n\n🟠 Warm — Remind in 2 days\nContacted but still considering. App gives 2 days before prompting a follow-up.\n\n🔴 Hot — Remind in 1 day\nAbout to close. App reminds every 1 day so you never miss the opportunity.\n\n🟢 Closed — Remind in 7 days\nPurchased. App reminds you to re-engage after 7 days for repeat business.\n\nAfter each "Messaged" action, the reminder clock resets per the cycle above.';
  String get guide4Title => isVi ? 'Thống kê & Streak' : 'Stats & Streak';
  String get guide4Body => isVi
      ? 'Nhấn biểu tượng 📊 để xem thống kê tháng. Streak 🔥 là số ngày liên tiếp bạn liên hệ ít nhất 1 khách — giữ streak càng lâu càng tốt!'
      : 'Tap 📊 to see monthly stats. Streak 🔥 is how many consecutive days you contacted at least 1 customer — keep it going!';
  String get guide5Title => isVi ? 'Sao lưu dữ liệu' : 'Backup Data';
  String get guide5Body => isVi
      ? 'Vào Cài đặt → Xuất sao lưu để tạo file JSON. Khi đổi điện thoại, dùng "Khôi phục" để nạp lại dữ liệu. App cũng tự sao lưu mỗi ngày.'
      : 'Go to Settings → Export Backup to create a JSON file. When changing phones, use "Restore" to reload data. App also auto-backs up daily.';
  String get guide6Title => isVi ? 'Hệ thống thông báo' : 'Notification System';
  String get guide6Body => isVi
      ? 'App gửi thông báo 1 lần mỗi ngày lúc 9:00 sáng nếu bạn có khách cần liên hệ.\n\nNội dung thông báo:\n• Có khách NÓNG → "Có X khách NÓNG đang chờ bạn liên hệ!"\n• Có nhiều loại trộn lẫn → "Bạn có X khách cần nhắn ngay, Y tổng cộng"\n• Khách thường → "Bạn có X khách cần liên hệ hôm nay"\n\nKhách "Đã chốt" KHÔNG xuất hiện trong thông báo dù đã quá hạn nhắc — chỉ các trạng thái Mới, Tiềm năng, Nóng mới được tính.\n\nĐể bật/tắt: Cài đặt → Thông báo → Nhắc nhở hàng ngày.\n\nLưu ý: Nếu không thấy thông báo, kiểm tra quyền thông báo trong Cài đặt điện thoại.'
      : 'App sends one notification per day at 9:00 AM if you have customers to follow up.\n\nNotification content:\n• Has HOT customers → "X HOT customers are waiting for your follow-up!"\n• Mixed types → "You have X urgent, Y total follow-ups today"\n• Regular → "You have X customers to follow up today"\n\nClosed customers do NOT appear in notifications even if overdue — only New, Warm, and Hot statuses count.\n\nTo enable/disable: Settings → Notifications → Daily Reminder.\n\nNote: If you don\'t see notifications, check notification permissions in phone Settings.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

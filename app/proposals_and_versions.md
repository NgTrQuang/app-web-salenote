# 🗺️ Sổ Khách — Đề Xuất Chỉnh Sửa & Kịch Bản Theo Phiên Bản

---

## 📌 Nguyên tắc phát triển

> **Mỗi version phải trả lời câu hỏi: "Tính năng này giúp người dùng hành động nhanh hơn không?"**
>
> Nếu không → Không thêm.

---

## ✅ Version 1.0.0 — MVP (Hiện tại)

**Trạng thái:** Hoàn thiện

### Tính năng

- [x] Thêm khách hàng (tên, sản phẩm, ghi chú)
- [x] Danh sách "Cần liên hệ ngay" và "Sắp tới"
- [x] Chi tiết khách hàng
- [x] Nhắn tin (mẫu tin nhắn + sao chép + xác nhận đã gửi)
- [x] Chốt đơn
- [x] Chỉnh sửa / Xoá khách
- [x] Lịch sử liên hệ
- [x] Sao lưu xuất/nhập JSON
- [x] Màu trạng thái (Mới/Tiềm năng/Nóng/Đã chốt)
- [x] Offline-first, không tài khoản

### Kịch bản người dùng v1.0

**Chị Mai — Chủ shop quần áo**
> Sáng 8h mở app, thấy 3 khách trong "Cần liên hệ ngay". Mở từng người, nhấn "Nhắn tin", copy tin nhắn dán vào Zalo. Nhấn "Đã nhắn". Khách tự động lui xuống "Sắp tới". Tổng thời gian: 3 phút.

**Anh Minh — Bán mỹ phẩm online**
> Cuối ngày thêm 2 khách mới hỏi sản phẩm. Điền tên + sản phẩm. Sáng hôm sau app tự nhắc liên hệ lại.

---

## ✅ Version 1.1.0 — Cải thiện UX

**Trạng thái:** Hoàn thiện
**Mục tiêu:** Giảm thêm thao tác, tăng tốc độ dùng hàng ngày

### Tính năng đã implement

| # | Tính năng | Lý do | Độ ưu tiên |
|---|---|---|---|
| 1 | **Swipe-to-action** | Vuốt phải = "Đã nhắn", vuốt trái = Xoá — giảm 2 tap | 🔴 Cao |
| 2 | **Tìm kiếm khách** | Search nhanh theo tên/SĐT/sản phẩm realtime | 🟠 Trung |
| 3 | **Nhắn tin tuỳ chỉnh** | Sửa mẫu tin trong cài đặt, hỗ trợ `{tên}` `{sản_phẩm}` | 🟠 Trung |
| 4 | **Màn hình "Tất cả khách"** | Filter 5 trạng thái + search + pull-to-refresh | 🟡 Thấp |

### Kịch bản v1.1

**Swipe gesture:**
> Chị Lan có 7 khách cần nhắn. Thay vì vào từng trang chi tiết, chị vuốt phải từng thẻ. Mỗi thao tác 1 giây. 7 khách = 7 giây.

**Mẫu tin tuỳ chỉnh:**
> Anh Hùng bán đồ gia dụng. Mẫu tin mặc định không phù hợp. Anh vào cài đặt, sửa thành: *"Anh/chị có quan tâm đến [sản phẩm] không? Shop đang có giá tốt ạ."*

---

## ✅ Version 1.2.0 — Thông báo & Nhắc nhở

**Trạng thái:** Hoàn thiện
**Mục tiêu:** Đảm bảo người dùng mở app mỗi ngày

### Tính năng đã implement

| # | Tính năng | Chi tiết | Độ ưu tiên |
|---|---|---|---|
| 1 | **Local notification** | 9:00 sáng hàng ngày — bật/tắt trong Cài đặt, xin quyền tự động | 🔴 Cao |
| 2 | **Auto backup hàng ngày** | Silent backup `so_khach_backup_YYYYMMDD.json` khi mở app | 🟠 Trung |

### Kịch bản v1.2

**Daily notification:**
> Anh Tuấn hay quên. 9 giờ sáng điện thoại rung: *"Bạn có 4 khách cần nhắn hôm nay"*. Anh vuốt thông báo, app mở thẳng vào danh sách.

**Auto backup:**
> Chị Hoa xài app 2 tuần không backup. Một hôm điện thoại hỏng. Từ v1.2, app tự backup hàng ngày vào folder Downloads — chị khôi phục dễ dàng.

---

## ✅ Version 2.0.0 — Insight & Báo cáo nhẹ

**Trạng thái:** Hoàn thiện
**Mục tiêu:** Cho chủ shop thấy hiệu quả công việc — không biến thành CRM

### Tính năng đã implement

| # | Tính năng | Chi tiết | Độ ưu tiên |
|---|---|---|---|
| 1 | **Thống kê tháng** | Lượt liên hệ / chốt đơn / khách mới — chọn tháng qua lại | 🔴 Cao |
| 2 | **Tỷ lệ chốt đơn** | Hiển thị % conversion với progress bar màu động | 🟠 Trung |
| 3 | **Streak hàng ngày** | Banner 🔥 trên màn hình thống kê + chip trên home | 🟠 Trung |
| 4 | **Top sản phẩm** | Top 5 sản phẩm được hỏi nhiều nhất với progress bar | � Trung |

### Kịch bản v2.0

**Thống kê tháng:**
> Cuối tháng 3, anh Minh xem: *"Tháng này liên hệ 47 khách, chốt 12 đơn."* Anh tăng effort vào khách Nóng.

**Streak:**
> Chị Mai thấy streak 14 ngày. Ngày 15 bận, nhưng streak thúc đẩy chị mở app nhắn nhanh 2 tin trước khi ngủ.

---

## ✅ Version 2.1.0 — UI/UX, Bảo mật & Thông báo nâng cao

**Trạng thái:** Hoàn thiện
**Mục tiêu:** Trải nghiệm mượt mà, bảo mật, thông báo thông minh, đa ngôn ngữ, onboarding

### Tính năng đã implement

| # | Tính năng | Chi tiết | Độ ưu tiên |
|---|---|---|---|
| 1 | **App logo + Splash screen** | Logo `assets/images/logo.png`, animation scale+fade, `BoxFit.contain` | 🔴 Cao |
| 2 | **App icon (Android)** | Adaptive icon, foreground PNG với padding 40%, ic_launcher đầy đủ mật độ | 🔴 Cao |
| 3 | **Đa ngôn ngữ (vi/en)** | `AppLocalizations` thủ công — Tiếng Việt mặc định, chuyển ngay không restart | 🔴 Cao |
| 4 | **Intro / Onboarding** | 3 slides animated, chỉ hiện lần đầu, lưu trạng thái DB | 🔴 Cao |
| 5 | **Hướng dẫn sử dụng** | `guide_screen.dart` — 5 mục collapsible trong Cài đặt | 🟠 Trung |
| 6 | **Thông báo thông minh** | Phân tích trạng thái khách (Nóng → Tiềm năng → Mới), bỏ qua khi foreground | 🔴 Cao |
| 7 | **Cài đặt thông báo** | Giờ/phút tuỳ chọn, âm thanh (Mặc định/Im lặng), rung toggle độc lập | 🔴 Cao |
| 8 | **Gửi thử thông báo** | Nút trong Cài đặt — gửi ngay với âm+rung hiện tại để kiểm tra | 🟠 Trung |
| 9 | **PIN lock** | 4 số SHA-256, bật (setup+confirm), tắt ngay (không verify), đổi mã | � Cao |
| 10 | **Dark mode** | Theo hệ thống / Sáng / Tối — lưu DB, áp dụng live | 🟠 Trung |
| 11 | **Mẫu tin tuỳ chỉnh** | Sửa mẫu + `{tên}` `{sản_phẩm}`, preview ngay | � Trung |
| 12 | **Fix PIN toggle UI** | `pop(true)` từ confirm về đúng settings qua double-pop, không race condition | � Cao |

### Kịch bản v2.1

**Smart notification:**
> 9 giờ sáng, anh Tuấn nhận: *"🔥 Có 2 khách NÓNG đang chờ bạn liên hệ!"* Không phải thông báo chung chung.

**PIN lock:**
> Chị Hoa muốn bảo mật app. Bật PIN → đặt 4 số → xác nhận. Hôm sau mở app phải nhập PIN. Muốn tắt: gạt switch là xong, không phải nhập lại mã.

**Gửi thử thông báo:**
> Anh Minh không chắc thông báo có hoạt động không. Nhấn "Gửi thử" — thông báo hiện lên ngay với đúng âm+rung đã chọn.

---

## 🔜 Version 2.2.0 — Đề xuất tiếp theo

**Trạng thái:** Đề xuất
**Mục tiêu:** Tăng giá trị thực tế hàng ngày, giảm ma sát thêm nữa

### Tính năng đề xuất

| # | Tính năng | Lý do | Độ ưu tiên |
|---|---|---|---|
| 1 | **Gọi điện 1 chạm** | Nhấn số điện thoại → gọi thẳng (hiện chỉ copy) — giảm 1 bước | 🔴 Cao |
| 2 | **Nhắc nhở tuỳ chỉnh theo khách** | Đặt lịch riêng cho 1 khách cụ thể ngoài lịch tự động | � Trung |
| 3 | **Tag / nhãn khách** | Gắn tag tự do (VD: "khách VIP", "hay hỏi giá") để lọc nhanh | 🟠 Trung |
| 4 | **Thêm khách từ danh bạ** | Chọn 1 contact từ điện thoại → tự điền tên + SĐT (không import toàn bộ) | 🟠 Trung |
| 5 | **Widget màn hình chính** | Android home screen widget hiện số khách cần nhắn hôm nay | 🟡 Thấp |
| 6 | **Backup lên Google Drive** | Tích hợp Drive API để backup/restore tự động trên cloud | 🟡 Thấp |
| 7 | **Lịch liên hệ tuỳ chỉnh** | Cho phép sửa số ngày nhắc lại theo từng trạng thái (mặc định: 1/2/1/7) | 🟡 Thấp |

### Kịch bản v2.2

**Gọi điện 1 chạm:**
> Chị Lan xem chi tiết khách. Thay vì copy SĐT rồi mở ứng dụng điện thoại, nhấn nút 📞 ngay trong app → gọi thẳng.

**Tag khách:**
> Anh Hùng gắn tag "hay chần chừ" cho 3 khách. Khi nhắn tin, anh nhớ ngay cần approach khác so với khách thường.

---

## 🚫 Tính năng ĐỀ XUẤT KHÔNG LÀM (Anti-Features)

Những tính năng dưới đây **có vẻ hữu ích nhưng thực tế sẽ làm hỏng sản phẩm**:

| Tính năng | Lý do từ chối |
|---|---|
| Cloud sync real-time | Tăng độ phức tạp, yêu cầu login, tốn tiền server |
| Gửi tin nhắn tự động | Khách thấy spam, vi phạm chính sách nền tảng |
| Phân tích AI / gợi ý | Quá phức tạp, không cần thiết ở scale nhỏ |
| Nhiều người dùng / phân quyền | Không phải use case của tool này |
| Lịch / Calendar sync | Làm phức tạp core flow không cần thiết |
| Giao diện kiểu CRM | Mâu thuẫn với triết lý "công cụ hành động hàng ngày" |

---

## 🐛 Bugs đã biết & cần theo dõi

| # | Mô tả | Mức độ | Trạng thái |
|---|---|---|---|
| 1 | Export backup trên iOS cần kiểm tra đường dẫn `getExternalStorageDirectory` | 🟠 Trung | Cần test |
| 2 | Android notification channel không thay đổi vibrate sau khi cài lần đầu (giải pháp: channel ID riêng theo combo sound×vibrate) | 🟠 Trung | Đã fix v2.1 |
| 3 | Không có xử lý lỗi khi JSON backup bị corrupt một phần | 🟡 Thấp | Backlog |
| 4 | `nextActionLabel` chưa xử lý edge case khi `nextActionAt = 0` | 🟡 Thấp | Backlog |
| 5 | PIN toggle không cập nhật UI ngay do race condition `_loadPinState()` | 🔴 Cao | Đã fix v2.1 |

---

## 📐 Đề xuất kỹ thuật

### Ngắn hạn

- **Unit test** cho `CustomerService` và `PinService` — đặc biệt logic `next_action_at` và hash PIN.
- **Integration test** luồng: Thêm khách → Nhắn tin → Xác nhận → Kiểm tra ngày được cập nhật.
- Tách `NotificationService._buildDetails` thành file riêng khi thêm nhiều loại thông báo hơn.

### Trung hạn

- Xem xét migrate sang **Drift** (type-safe SQLite) nếu schema phức tạp hơn.
- Thêm **Firebase Crashlytics** (optional, opt-in) để theo dõi crash ẩn danh.
- `BackupService` tách thành `ExportService` + `ImportService` khi bổ sung Drive backup.

---

## 🏁 Tiêu chí thành công theo version

| Version | KPI |
|---|---|
| v1.0 | Người dùng mở app > 3 lần/tuần |
| v1.1 | Thời gian xử lý 1 khách < 10 giây |
| v1.2 | Retention 30 ngày > 60% |
| v2.0 | Người dùng tự báo cáo: "app giúp tôi chốt thêm đơn" |
| v2.1 | Không có crash liên quan PIN/notification sau 1 tuần dùng thực tế |
| v2.2 | Thời gian từ "mở app" → "đã nhắn khách đầu tiên" < 5 giây |

---

*Cập nhật lần cuối: tháng 4/2026 — sau sprint v2.1 hoàn thiện.*

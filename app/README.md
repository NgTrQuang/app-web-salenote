# 📒 Sổ Khách — Customer Notebook

> **"Không bao giờ quên khách. Luôn biết cần nhắn ai tiếp theo."**

Sổ Khách là ứng dụng di động dành cho chủ shop / bán hàng nhỏ lẻ giúp **nhớ khách, biết khi nào cần liên hệ lại, và không bỏ lỡ đơn hàng**. Hoàn toàn offline, không cần tài khoản, không cần internet.

**Phiên bản hiện tại: 2.3.0** (Android targetSdk **36**, hỗ trợ **16 KB page size** — xem [`ANDROID_BUILD.md`](ANDROID_BUILD.md))

---

## 📱 Tính năng đầy đủ (v2.2.0)

### Quản lý khách hàng
| Tính năng | Mô tả |
|---|---|
| ➕ Thêm khách | Tên, SĐT, sản phẩm, ghi chú, ngày hết bảo hành |
| ✏️ Chỉnh sửa / Xoá | Cập nhật thông tin, trạng thái, bảo hành |
| 🔥 Cần liên hệ ngay | Khách đến hạn — ưu tiên hành động ngay |
| ⚡ Sắp tới | Khách chưa đến hạn, sắp xếp theo thời gian |
| 👆 Vuốt nhanh | Vuốt phải = Đã nhắn · Vuốt trái = Xoá |
| 🔍 Tìm kiếm | Realtime theo tên, SĐT, sản phẩm |
| 📋 Tất cả khách | Lọc theo 5 trạng thái |
| 📜 Lịch sử liên hệ | Timeline tương tác từng khách |
| 🛡️ Bảo hành | Badge "BH: X ngày" màu cam/đỏ khi sắp hết hạn |

### Gọi điện & Nhắn tin
| Tính năng | Mô tả |
|---|---|
| 📞 Gọi điện 1 chạm | Gọi trực tiếp từ thẻ khách, màn hình chi tiết, hoặc bottom sheet |
| 💬 Nhắn tin | Mẫu tự động điền tên + sản phẩm, sao chép 1 chạm |
| 🏷️ Gợi ý theo ngành | 5 chip nhanh: Quần áo, Mỹ phẩm, Đồ ăn, Bảo hành, Giao hàng |
| ✅ Chốt đơn | Đánh dấu đã mua, tự lên lịch chăm sóc sau 7 ngày |
| 📝 Mẫu tin tuỳ chỉnh | Sửa mẫu, hỗ trợ `{tên}` `{sản_phẩm}` |

### Insight & Nhắc nhở
| Tính năng | Mô tả |
|---|---|
| � Insight banner | Banner đỏ trên Home khi có khách quá hạn liên hệ |
| �🔔 Nhắc nhở hàng ngày | Thông báo lúc giờ tuỳ chọn nếu có khách cần liên hệ |
| 🧠 Nội dung thông minh | Phân tích trạng thái — ưu tiên Nóng trước |
| ⏭️ Bỏ qua khi đang mở | Không gửi nếu app đang ở foreground |
| 🔊 Âm thanh & Rung | Mặc định / Im lặng, toggle rung độc lập |
| 🧪 Gửi thử | Nút gửi thử thông báo ngay trong Cài đặt |

### Sao lưu & Xuất dữ liệu
| Tính năng | Mô tả |
|---|---|
| �️ Trạng thái sao lưu | Banner xanh "Đã an toàn / Lần cuối: dd/MM/yyyy" hoặc cam "Chưa sao lưu" |
| ☁️ Sao lưu ngay | 1 nút — tạo file JSON + cập nhật trạng thái ngay |
| 📊 Xuất CSV | `customers_YYYYMMDD.csv` + `interactions_YYYYMMDD.csv` — mở được bằng Excel |
| 📥 Khôi phục | Import file JSON, app tự reload |
| 💾 Auto backup | Tự sao lưu 1 lần/ngày khi mở app |

### Giao diện & Bảo mật
| Tính năng | Mô tả |
|---|---|
| � Gradient avatar | Avatar màu gradient theo tên cho mọi màn hình |
| �🌙 Dark mode | Theo hệ thống / Sáng / Tối |
| 🌐 Đa ngôn ngữ | Tiếng Việt / English |
| 🔐 PIN lock | Khoá app 4 số, SHA-256, bật/tắt/đổi |
| � Splash screen | Animated logo khi khởi động |
| 📖 Onboarding | 3 slides chỉ hiện lần đầu cài đặt |
| 📊 Thống kê | Liên hệ/chốt đơn theo tháng, tỷ lệ chuyển đổi, streak, top sản phẩm |
| ❓ Hướng dẫn | Màn hình Guide 5 mục collapsible trong Cài đặt |

---

## 🆕 Thay đổi theo phiên bản

### v2.2.0
- 🛡️ **Bảo hành**: thêm trường `warranty_end_date`, badge "BH: X ngày" trong thẻ khách
- 🚨 **Insight banner**: cảnh báo khách quá hạn trên màn hình chính
- ☁️ **Backup UX**: banner trạng thái, nút "Sao lưu ngay", hiển thị lần backup cuối
- 📊 **Xuất CSV**: 2 file `customers.csv` + `interactions.csv` mở được bằng Excel
- � **Gọi điện 1 chạm**: gọi trực tiếp từ thẻ khách và màn hình chi tiết
- 🏷️ **Template theo ngành**: 5 chip gợi ý nhanh khi soạn tin nhắn
- 🎨 **Gradient avatar**: avatar đẹp hơn, nhất quán toàn app

### v2.1.0
- Thêm trường số điện thoại, copy SĐT 1 chạm
- DB migration version 2

### v2.0.0
- Onboarding 3 slides
- Thống kê theo tháng, streak, top sản phẩm
- PIN lock SHA-256
- Dark mode + đa ngôn ngữ vi/en

### v1.0.0
- Ra mắt: quản lý khách, nhắn tin, thông báo, backup JSON

---

## �🚀 Hướng dẫn cài đặt (Dev)

### Yêu cầu môi trường

- Flutter SDK `>=3.19.0`
- Dart SDK `>=3.3.0`
- Android Studio / VS Code (với Flutter & Dart extension)
- Thiết bị Android (API 21+) hoặc Android Emulator

### Các bước cài đặt

```bash
# 1. Clone dự án
git clone <repository-url>
cd app_customer_notebook

# 2. Cài dependencies
flutter pub get

# 3. Chạy debug trên thiết bị kết nối
flutter run

# 4. Build APK release
flutter build apk --release
```

> **Windows:** Cần bật **Developer Mode** trước khi chạy (`Settings → Developer Mode → ON`).

File APK sau khi build:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📖 Hướng dẫn sử dụng chi tiết

### 1. Màn hình chính (Home)

Màn hình chính hiển thị tự động theo mức độ ưu tiên:

```
┌──────────────────────────────────────┐
│  📒 Sổ Khách    [🔥3]  [streak 5🔥] │
├──────────────────────────────────────┤
│  🔍 Tìm kiếm khách...                │
├──────────────────────────────────────┤
│  ⚠️  Có 2 khách quá hạn liên hệ!    │  ← Insight banner
│     Nhắn sớm để không mất đơn hàng  │
├──────────────────────────────────────┤
│  🔥 CẦN LIÊN HỆ NGAY (3)            │
│  ┌─────────────────────────────────┐ │
│  │  NTM   Nguyễn Thị Mai  [Nóng]  │ │
│  │        📞 0912 345 678          │ │
│  │        Áo khoác · Hôm nay       │ │
│  │        🛡️ BH: 5 ngày           │ │  ← Warranty badge
│  └─────────────────────────────────┘ │
│  ⚡ SẮP TỚI (5)                       │
│  ...                                 │
└──────────────────────────────────────┘
```

- **Banner đỏ** xuất hiện khi có khách quá hạn → nhấn để xem tất cả
- **Vuốt phải** thẻ khách = đánh dấu "Đã nhắn" ngay
- **Vuốt trái** thẻ khách = Xoá (có xác nhận)
- **Badge BH** màu cam (≤30 ngày) hoặc đỏ (≤7 ngày) khi bảo hành sắp hết

---

### 2. Thêm khách hàng

1. Nhấn nút **"Thêm khách"** (góc dưới phải, màn hình Home)
2. Điền thông tin:
   - **Tên khách** *(bắt buộc)*
   - **Số điện thoại** *(tuỳ chọn)*
   - **Sản phẩm quan tâm** *(tuỳ chọn)*
   - **Ghi chú** *(tuỳ chọn)*
   - **Ngày hết bảo hành** *(tuỳ chọn — nhấn để mở date picker)*
3. Chọn **trạng thái ban đầu**
4. Nhấn **"Thêm khách hàng"**

> Khách mới tự nhận trạng thái **Mới**, lên lịch liên hệ lại sau **1 ngày**.

---

### 3. Trạng thái khách hàng

| Màu | Trạng thái | Ý nghĩa | Lịch liên hệ lại |
|---|---|---|---|
| 🔵 | **Mới** | Hỏi lần đầu | 1 ngày |
| 🟠 | **Tiềm năng** | Quan tâm, chưa quyết | 2 ngày |
| 🔴 | **Nóng** | Gần chốt, theo sát | 1 ngày |
| 🟢 | **Đã chốt** | Đã mua — chăm sóc sau | 7 ngày |

---

### 4. Chi tiết khách hàng

Nhấn thẻ khách để xem đầy đủ:

- **Sao chép SĐT** → nhấn icon copy bên cạnh số điện thoại
- **Gọi điện** → nhấn nút 📞 xanh (yêu cầu quyền CALL_PHONE lần đầu)
- **Nhắn tin** → mở bottom sheet soạn tin
- **Chốt đơn** → chuyển trạng thái Đã chốt, ghi lịch sử
- **✏️ Chỉnh sửa** → cập nhật thông tin, trạng thái, bảo hành
- **🗑️ Xoá** → xoá khách (có xác nhận)

---

### 5. Gọi điện 1 chạm

Có 3 cách gọi điện cho khách (khi có số điện thoại):

1. **Từ thẻ khách** — nhấn chip SĐT trực tiếp trên danh sách
2. **Từ màn hình chi tiết** — nhấn nút 📞 trong ActionBar hoặc ProfileCard
3. **Từ bottom sheet nhắn tin** — nhấn nút gọi điện màu xanh

> Lần đầu gọi, app sẽ xin quyền `CALL_PHONE`. Nếu từ chối vĩnh viễn, vào **Cài đặt → Ứng dụng** để cấp lại.

---

### 6. Soạn tin nhắn & Gợi ý theo ngành

Nhấn **"Nhắn tin"** trên màn hình chi tiết để mở bottom sheet:

```
┌─────────────────────────────────────────┐
│  Liên hệ Nguyễn Thị Mai                 │
│  0912 345 678                            │
├─────────────────────────────────────────┤
│  [ 📞 0912 345 678 ]  ← Gọi trực tiếp  │
├─────────────────────────────────────────┤
│  Gợi ý nhanh:                           │
│  [👗 Quần áo] [💄 Mỹ phẩm] [🍜 Đồ ăn] │
│  [🔧 Bảo hành] [📦 Giao hàng]          │
├─────────────────────────────────────────┤
│  Soạn tin nhắn:                         │
│  ┌─────────────────────────────────┐    │
│  │ Chào Mai, shop vừa về mẫu mới... │    │
│  └─────────────────────────────────┘    │
│  [ Sao chép & Ghi nhận ✓ ]             │
└─────────────────────────────────────────┘
```

- Nhấn **chip gợi ý** để điền nhanh template theo ngành — tên và sản phẩm tự điền
- Sửa nội dung tuỳ ý trước khi sao chép
- Nhấn **"Sao chép & Ghi nhận"** → sao chép vào clipboard + ghi lịch sử liên hệ

**Quy trình hoàn chỉnh:**
```
Nhấn "Nhắn tin" → Chọn gợi ý ngành (tuỳ chọn) → Sửa nội dung
  ↓
Nhấn "Sao chép & Ghi nhận"
  ↓
Mở Zalo / Facebook / SMS → Dán → Gửi
  ↓
App tự cập nhật lịch hẹn → Khách xuống "Sắp tới"
```

Hoặc nhanh hơn: **Vuốt phải** thẻ trực tiếp = đánh dấu đã nhắn ngay.

---

### 7. Bảo hành sản phẩm

Trường **Ngày hết bảo hành** có thể thêm khi tạo hoặc chỉnh sửa khách hàng.

**Badge xuất hiện tự động** trên thẻ khách khi:
- 🟡 Còn **≤ 30 ngày** → badge vàng "BH: X ngày"
- 🔴 Còn **≤ 7 ngày** → badge đỏ (khẩn cấp)

Dùng chip **🔧 Bảo hành** trong gợi ý nhanh để nhắn khách gia hạn/chăm sóc.

---

### 8. Tìm kiếm

Thanh tìm kiếm luôn hiển thị trên màn hình chính:
- Tìm theo **tên**, **SĐT**, **sản phẩm**
- Kết quả realtime khi gõ
- Nhấn ✕ để xoá và trở về danh sách chính

---

### 9. Xem tất cả khách

Nhấn tab **danh sách** ở navigation bar:
- Lọc nhanh: `Tất cả` · `Mới` · `Tiềm năng` · `Nóng` · `Đã chốt`
- Kéo xuống để refresh

---

### 10. Thống kê

Nhấn tab **thống kê** để xem:
- Lượt liên hệ / số đơn chốt theo tháng (vuốt qua lại giữa các tháng)
- **Tỷ lệ chuyển đổi** với progress bar màu
- **Streak** — số ngày liên tiếp dùng app
- **Top sản phẩm** được hỏi nhiều nhất

---

### 11. Thông báo nhắc nhở

Vào **Cài đặt → Thông báo**:

1. **Bật/tắt** thông báo hàng ngày
2. Chọn **giờ nhắc** (chạm vào giờ để thay đổi)
3. Chọn **âm thanh**: Mặc định / Im lặng
4. Bật/tắt **Rung** (độc lập với âm thanh)
5. Nhấn **"Gửi thử thông báo"** để kiểm tra ngay

| Âm | Rung | Hành vi |
|---|---|---|
| Mặc định | Tắt | Chỉ âm thanh thông báo |
| Mặc định | Bật | Âm thanh + rung |
| Im lặng | Tắt | Chỉ hiện thông báo |
| Im lặng | Bật | Rung, không âm |

> **Thông minh:** App chỉ gửi thông báo khi bạn **chưa mở app** trong ngày và **có khách cần liên hệ**. Khi mở app lại, lịch tự cập nhật.

---

### 12. Mẫu tin nhắn tuỳ chỉnh

Vào **Cài đặt → Mẫu tin nhắn**:
- Chỉnh sửa nội dung mẫu mặc định
- Dùng `{tên}` và `{sản_phẩm}` để tự điền thông tin khách
- Nhấn **"Lưu"** — áp dụng ngay

```
Chào {tên}, shop mình đang có deal mới cho {sản_phẩm} ạ.
Anh/chị có muốn mình gửi thêm thông tin không? 🙏
```

---

### 13. Sao lưu & Xuất dữ liệu

Vào **Cài đặt → Sao lưu dữ liệu**:

```
┌───────────────────────────────────────┐
│  🛡️ Dữ liệu đã an toàn               │
│     Lần cuối: 17/04/2026              │
├───────────────────────────────────────┤
│  [ ☁️ Sao lưu ngay ]                  │
│  [ 📊 Xuất CSV (Excel) ]              │
├───────────────────────────────────────┤
│  🔄 Khôi phục từ sao lưu              │
└───────────────────────────────────────┘
```

**Sao lưu JSON (khuyến nghị):**
1. Nhấn **"Sao lưu ngay"** → chia sẻ qua Drive/Zalo/Gmail
2. File: `so_khach_backup_YYYYMMDD.json`
3. Banner cập nhật thành "Dữ liệu đã an toàn" ngay sau khi lưu

**Xuất CSV (mở bằng Excel):**
1. Nhấn **"Xuất CSV (Excel)"** → chia sẻ 2 file cùng lúc
2. `so_khach_customers_YYYYMMDD.csv` — toàn bộ khách hàng + thông tin bảo hành
3. `so_khach_interactions_YYYYMMDD.csv` — lịch sử tương tác

**Tự động sao lưu:**
App tự xuất backup JSON **1 lần/ngày** khi mở — lưu tại thư mục Documents.

**Khôi phục:**
1. Nhấn **"Khôi phục từ sao lưu"**
2. Chọn file `.json`
3. Xác nhận — dữ liệu được khôi phục hoàn toàn

> ⚠️ Khôi phục sẽ **xoá toàn bộ** dữ liệu hiện tại và thay bằng dữ liệu trong file.

---

### 14. PIN lock

Vào **Cài đặt → Bảo mật → Khoá PIN**:
- **Bật**: thiết lập mã 4 số → xác nhận lại → PIN được lưu (SHA-256)
- **Tắt**: chuyển toggle OFF ngay, không cần xác nhận
- **Đổi mã**: nhập mã cũ → thiết lập mã mới

App yêu cầu nhập PIN mỗi khi mở lại từ nền.

---

### 15. Giao diện & Ngôn ngữ

**Dark mode** — Cài đặt → Giao diện:
- `Theo hệ thống` (mặc định) / `Sáng` / `Tối`

**Ngôn ngữ** — Cài đặt → Ngôn ngữ:
- Tiếng Việt / English — chuyển ngay không cần restart

---

### 16. Hướng dẫn sử dụng trong app

Vào **Cài đặt → Hướng dẫn sử dụng** để xem 5 mục collapsible:
1. Thêm & quản lý khách
2. Quy trình nhắn tin hàng ngày
3. Trạng thái và ý nghĩa
4. Xem thống kê
5. Sao lưu & khôi phục

---

## 💡 Mẹo sử dụng hiệu quả

- **Sáng mỗi ngày** xử lý hết phần "Cần liên hệ ngay" — vuốt phải để làm nhanh
- Dùng **chip gợi ý ngành** khi soạn tin — tiết kiệm thời gian gõ
- Đặt **Nóng** cho khách đang hỏi nhiều — nhắc sau 1 ngày
- Sau chốt đơn **đừng xoá khách** — app tự nhắc chăm sóc sau 7 ngày
- Nhập **ngày hết bảo hành** khi bán để nhận badge nhắc nhở tự động
- Backup ít nhất **1 lần/tuần** bằng nút "Sao lưu ngay", lưu trên Drive
- Xuất CSV định kỳ để có bản tóm tắt mở được bằng Excel

---

## 🗂️ Cấu trúc dự án

```
lib/
├── main.dart                        # Entry point, theme, lifecycle
├── models/
│   ├── customer.dart                # Customer model + warranty helpers
│   └── interaction.dart             # Interaction log model
├── database/
│   └── database_helper.dart         # SQLite CRUD + migration v3
├── services/
│   ├── customer_service.dart        # Business logic layer
│   ├── backup_service.dart          # JSON backup + CSV export
│   ├── notification_service.dart    # Smart local notifications
│   ├── pin_service.dart             # PIN hash + verify
│   └── app_lifecycle_service.dart   # Foreground/background tracking
├── screens/
│   ├── splash_screen.dart           # Animated splash + onboarding 3 slides
│   ├── home_screen.dart             # Main screen + insight banner + swipe
│   ├── add_customer_screen.dart     # Add customer + warranty date picker
│   ├── edit_customer_screen.dart    # Edit customer + warranty date picker
│   ├── customer_detail_screen.dart  # Detail + call + message + quick templates
│   ├── all_customers_screen.dart    # All customers + filter
│   ├── stats_screen.dart            # Monthly stats + streak + top products
│   ├── settings_screen.dart         # Backup UX + notif + PIN + theme…
│   ├── pin_screen.dart              # PIN entry/setup/change screen
│   └── guide_screen.dart            # In-app user guide
├── widgets/
│   ├── customer_card.dart           # Swipeable tile + phone chip + warranty badge
│   └── status_badge.dart           # Colored status chip
├── l10n/
│   └── app_localizations.dart       # vi/en string map
└── utils/
    ├── constants.dart               # Keys, colors, defaults
    └── date_utils.dart              # Date formatting helpers
```

---

## 🗄️ Cơ sở dữ liệu

Dữ liệu lưu **100% trên thiết bị** bằng SQLite. Tự động migration khi nâng cấp.

```sql
-- Khách hàng (DB version 3)
customers (id, name, phone, note, product, status,
           created_at, last_contact_at, next_action_at,
           warranty_end_date)   -- thêm ở v2.2

-- Lịch sử tương tác
interactions (id, customer_id, content, created_at)

-- Cài đặt key-value
settings (key TEXT PRIMARY KEY, value TEXT)
-- Keys: message_template, notification_enabled, notification_hour,
--       notification_minute, notification_sound, notification_vibrate,
--       pin_hash, theme_mode, locale, last_backup_date,
--       onboarding_done
```

**Migration tự động:**
- v1 → v2: thêm cột `phone`
- v2 → v3: thêm cột `warranty_end_date`

---

## 📦 Dependencies

| Package | Phiên bản | Mục đích |
|---|---|---|
| `sqflite` | ^2.3.2 | SQLite database |
| `path` | ^1.9.0 | Database file path |
| `intl` | ^0.20.2 | Format ngày tháng |
| `share_plus` | ^10.0.0 | Chia sẻ file sao lưu / CSV |
| `file_picker` | ^8.0.3 | Chọn file JSON import |
| `path_provider` | ^2.1.3 | Đường dẫn lưu file |
| `flutter_local_notifications` | ^17.2.2 | Thông báo hàng ngày |
| `timezone` | ^0.9.4 | Timezone-aware scheduling |
| `crypto` | ^3.0.3 | SHA-256 cho PIN hash |
| `url_launcher` | ^6.2.5 | Gọi điện (tel: scheme) |
| `permission_handler` | ^11.0.1 | Quyền CALL_PHONE |
| `flutter_launcher_icons` | ^0.14.3 | Generate app icon |

---

## ❌ Ngoài phạm vi (Non-Goals)

Ứng dụng **KHÔNG** có và **KHÔNG** dự kiến có:
- Cloud sync / đăng nhập tài khoản
- Đồng bộ nhiều thiết bị
- Gửi tin nhắn tự động
- AI / báo cáo phức tạp
- Email / CRM tích hợp

> Đây là **công cụ hành động hàng ngày**, không phải CRM.

---

## 📄 Giấy phép

MIT License — Sử dụng tự do cho mục đích cá nhân và thương mại.

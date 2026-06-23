# 📱 Sổ Khách — Implementation Specification (v2.1)

## 1. 🎯 Product Definition

**Product Name:** Sổ Khách (Customer Notebook)
**Version:** 2.1.0
**Platform:** Android (primary), iOS (secondary)

**Goal:** Offline-first mobile tool for small business owners to remember customers and know when to follow up.

**Core Value:**
> "Never forget a customer. Always know who to message next."

**Principles:**
- Offline-first, no login, no backend
- Daily action tool — NOT a CRM
- Every feature must answer: *"Does this help the user act faster?"*

---

## 2. ⚙️ Technical Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | SQLite via `sqflite` |
| State management | `setState` + `ValueNotifier` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Security | SHA-256 PIN via `crypto` |
| Backup | JSON export/import via `share_plus` + `file_picker` |
| i18n | Manual `AppLocalizations` (vi/en) |
| Icons | `flutter_launcher_icons` |

---

## 3. 🗄️ Database Schema

### Table: `customers`

```sql
CREATE TABLE customers (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  name            TEXT NOT NULL,
  phone           TEXT,
  note            TEXT,
  product         TEXT,
  status          TEXT,
  created_at      INTEGER,
  last_contact_at INTEGER,
  next_action_at  INTEGER
);
```

### Table: `interactions`

```sql
CREATE TABLE interactions (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER,
  content     TEXT,
  created_at  INTEGER
);
```

### Table: `settings`

```sql
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT
);
```

**Known setting keys (`AppConstants`):**

| Key | Type | Default | Mô tả |
|---|---|---|---|
| `message_template` | String | mẫu mặc định | Mẫu tin nhắn tuỳ chỉnh |
| `notification_enabled` | bool string | `"false"` | Bật/tắt thông báo |
| `notification_hour` | int string | `"9"` | Giờ nhắc |
| `notification_minute` | int string | `"0"` | Phút nhắc |
| `notification_sound` | String | `"default"` | `"default"` / `"silent"` |
| `notification_vibrate` | bool string | `"true"` | Bật/tắt rung |
| `pin_hash` | String | `""` | SHA-256 hash của PIN (rỗng = không có PIN) |
| `theme_mode` | String | `"system"` | `"system"` / `"light"` / `"dark"` |
| `locale` | String | `"vi"` | `"vi"` / `"en"` |
| `last_backup_date` | String | `""` | `"YYYYMMDD"` |
| `onboarding_done` | bool string | `"false"` | Đã xem onboarding |

---

## 4. 🧠 Core Business Logic

### 4.1 Customer Status

| Value | Label (vi) | Follow-up delay |
|---|---|---|
| `new` | Mới | +1 ngày |
| `warm` | Tiềm năng | +2 ngày |
| `hot` | Nóng | +1 ngày |
| `closed` | Đã chốt | +7 ngày |

### 4.2 On Customer Creation
```
created_at      = now
last_contact_at = now
next_action_at  = now + 1 day
status          = "new"
```

### 4.3 On "Message Sent"
```
last_contact_at = now
next_action_at  = now + delay[status]
→ Ghi 1 dòng interactions: "Đã nhắn tin"
```

### 4.4 On "Mark as Sold"
```
status          = "closed"
last_contact_at = now
next_action_at  = now + 7 days
→ Ghi 1 dòng interactions: "Đã chốt đơn"
```

### 4.5 Data Queries

```sql
-- Cần liên hệ ngay
SELECT * FROM customers
WHERE next_action_at <= :now
ORDER BY next_action_at ASC;

-- Sắp tới
SELECT * FROM customers
WHERE next_action_at > :now
ORDER BY next_action_at ASC;

-- Thống kê tháng: số lần liên hệ
SELECT COUNT(*) FROM interactions
WHERE created_at BETWEEN :startOfMonth AND :endOfMonth;

-- Top sản phẩm
SELECT product, COUNT(*) as cnt FROM customers
WHERE product IS NOT NULL AND product != ''
GROUP BY product ORDER BY cnt DESC LIMIT 5;
```

---

## 5. 📱 Screens

| Screen | File | Mô tả |
|---|---|---|
| Splash + Onboarding | `splash_screen.dart` | Animated logo, 3 onboarding slides (1 lần duy nhất), điều hướng tới PIN hoặc Home |
| Home | `home_screen.dart` | Danh sách Cần liên hệ + Sắp tới, search, swipe gestures, streak chip |
| Thêm khách | `add_customer_screen.dart` | Form thêm mới (tên bắt buộc, phone/product/note tuỳ chọn) |
| Sửa khách | `edit_customer_screen.dart` | Form chỉnh sửa toàn bộ thông tin + trạng thái |
| Chi tiết | `customer_detail_screen.dart` | Avatar, info, nhắn tin, chốt đơn, lịch sử tương tác |
| Tất cả khách | `all_customers_screen.dart` | Toàn bộ khách + filter 5 trạng thái + search |
| Thống kê | `stats_screen.dart` | Tháng/năm picker, lượt liên hệ, đơn chốt, conversion %, streak, top sản phẩm |
| Cài đặt | `settings_screen.dart` | Tất cả cài đặt: sao lưu, thông báo, mẫu tin, PIN, giao diện, ngôn ngữ |
| PIN | `pin_screen.dart` | Nhập PIN (unlock/verify/setup/confirm/change) |
| Hướng dẫn | `guide_screen.dart` | 5 mục collapsible hướng dẫn sử dụng |

---

## 6. 🛎️ Notification System

### 6.1 Architecture

```
NotificationService (singleton)
  ├── scheduleSmartReminder()   ← gọi mỗi ngày khi mở app
  ├── sendTestNotification()    ← gửi ngay cho user test
  ├── _buildDetails()           ← build AndroidNotificationDetails
  ├── _scheduleAt()             ← dùng zonedSchedule
  └── onAppResumed()            ← reschedule khi app về foreground
```

### 6.2 Smart Content

Phân tích danh sách khách cần liên hệ:
1. **Hot** (nóng) → *"🔥 Có X khách NÓNG đang chờ!"*
2. **Warm** (tiềm năng) → *"⚡ X khách tiềm năng cần liên hệ"*
3. **Chỉ new/closed** → *"📋 Bạn có X khách cần liên hệ hôm nay"*
4. **Không có khách** → không gửi thông báo

### 6.3 Sound & Vibration

| Sound | Vibrate | Android channel | Hành vi |
|---|---|---|---|
| default | false | `so_khach_default_novib` | Âm thông báo hệ thống |
| default | true | `so_khach_default_vib` | Âm + rung |
| silent | false | `so_khach_silent_novib` | Chỉ hiện banner |
| silent | true | `so_khach_silent_vib` | Rung, không âm |

> Android notification channel settings bất biến sau khi tạo lần đầu. Mỗi combo sound×vibrate dùng channel ID riêng để đảm bảo setting luôn đúng.

### 6.4 Foreground Skip

`AppLifecycleService` track trạng thái app. `scheduleSmartReminder()` kiểm tra: nếu app đang foreground → không schedule lại → thông báo không bắn khi user đang dùng app.

---

## 7. 🔐 PIN Lock

### 7.1 Flow

```
Bật PIN:
  Settings toggle ON
    → PinScreen(setup)   → nhập 4 số
    → PinScreen(confirm) → nhập lại để xác nhận
    → setPin(entered)    → lưu SHA-256 hash vào DB
    → pop(true) × 2      → Settings nhận result, setState(_pinEnabled=true)

Tắt PIN:
  Settings toggle OFF
    → removePin()        → xóa hash khỏi DB
    → setState(_pinEnabled=false) ngay lập tức

Đổi PIN:
  Settings → "Đổi mã PIN"
    → PinScreen(change)  → xác minh mã cũ
    → PinScreen(setup)   → nhập mã mới
    → PinScreen(confirm) → xác nhận
    → setPin(newPin)

Mở khoá:
  SplashScreen → hasPin() == true
    → PinScreen(unlock)  → nhập đúng → HomeScreen
```

### 7.2 Security

- Hash: `SHA-256(pin + "so_khach_salt_2025")`
- Lưu: `settings.pin_hash`
- Không lưu plain-text PIN ở bất kỳ đâu
- `verifyPin("")` trả về `true` nếu không có PIN (backward-compatible)

---

## 8. 💾 Backup System

### 8.1 Export

```json
{
  "customers": [{ "id": 1, "name": "...", ... }],
  "interactions": [{ "id": 1, "customer_id": 1, ... }]
}
```
→ File: `so_khach_backup.json` → share sheet

### 8.2 Auto Backup

- Trigger: mỗi lần mở app, so sánh `last_backup_date` với ngày hôm nay
- Lưu: `Downloads/so_khach_backup_YYYYMMDD.json`
- Silent — không hiện dialog

### 8.3 Import

1. Chọn file JSON → parse → validate keys
2. Xoá toàn bộ DB hiện tại
3. Insert lại từ file
4. App reload

---

## 9. 🌐 Internationalisation

- `AppLocalizations` thủ công trong `lib/l10n/app_localizations.dart`
- Locale lưu vào DB (`settings.locale`)
- `localeNotifier` (`ValueNotifier<Locale>`) để thay đổi live không cần restart
- Hai ngôn ngữ: `vi` (mặc định), `en`

---

## 10. 🚫 Non-Goals

| Tính năng | Lý do |
|---|---|
| Cloud sync / login | Phức tạp, tốn server, ngoài scope |
| Gửi tin tự động | Spam, vi phạm platform policy |
| AI / analytics phức tạp | Không cần thiết ở scale nhỏ |
| Multi-user / phân quyền | Ngoài use case |
| Calendar sync | Làm phức tạp core flow |

---

## 11. 🧠 Key Principles

> This is NOT a CRM. This is a **daily action tool**.

- Thành công: user mở app mỗi ngày và hành động ngay
- Thất bại: app trở thành nơi lưu trữ thụ động

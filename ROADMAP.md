# Salenote — Trợ lý kinh doanh cá nhân

> **Web trước, app sau.** Mọi tính năng mới được thử trên web, ổn định rồi port sang Flutter.

## Chiến lược

| Giai đoạn | Mục tiêu | Trạng thái |
|-----------|----------|------------|
| **Phase 0** | Web đồng bộ app Sổ Khách (chăm khách) | ✅ Xong |
| **Phase 1** | Pivot Salenote: Sản phẩm + Ghi đơn + Dashboard tiền | ✅ Xong (web) |
| **Phase 2** | Nguồn khách, liên kết dữ liệu, công nợ chi tiết | ✅ Xong (web) |
| **Phase 3** | Port Salenote sang Flutter app | ✅ Xong (core + v2.1) |
| **Phase 4** | Trợ lý cá nhân — web v2.1 (W0–W7) | ✅ Xong (web + Flutter) |

## Phase 4 — Trợ lý kinh doanh cá nhân (web v2.1)

- [x] **W0** Định vị & copy (Hôm nay, Sổ khách, Tiền của tôi, Ai nợ tôi)
- [x] **W1** Home action-first (TodaySummaryBar, Sổ khách collapsible)
- [x] **W2** Mục tiêu tháng (goalService, Cài đặt, GoalProgressCard)
- [x] **W3** Ai nợ tôi (debtService, DebtsPage)
- [x] **W4** Tồn kho → việc hôm nay (restock actions)
- [x] **W5** Segment SP + batch nhắn
- [x] **W6** Chi phí & lãi thật (Dexie v6, backup v3)
- [x] **W7** Giọng trợ lý + polish Tiền của tôi
- [x] Port W0–W7 sang Flutter

## Phase 3 — Port sang Flutter app

- [x] DB v4–v7: products, orders, source, inventory, shipping, expenses
- [x] Ghi đơn có tiền, dashboard doanh số
- [x] Backup JSON v3 tương thích web
- [x] Sync web v2.1 (W0–W7)

## Phase 2 — Mở rộng

- [x] Nguồn khách, liên kết dữ liệu, tồn kho
- [x] Công nợ chi tiết / nhắc thu (web: trang Ai nợ tôi)
- [ ] Đính kèm ảnh/HĐ (hoãn)

## Phase 5 — Tối ưu hiệu năng danh sách

- [x] **Web** Phân trang DB (Sổ khách), lazy load khách (Đơn hàng), infinite scroll (picker/modal)
- [x] **Flutter** Cuộn tải thêm: Sổ khách, Sản phẩm, Đơn hàng, Ai nợ tôi, Home, Ghi đơn, ProductPicker (20/lần từ DB hoặc RAM)
- [ ] **Flutter** Infinite scroll picker sản phẩm (form khách/đơn) — dùng modal tìm kiếm
- [ ] **Cả hai** Cache/tối ưu insights (giảm full table scan khi >5k bản ghi)

## Chạy web

```bash
cd web
npm install
npm run dev
```

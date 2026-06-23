# Salenote — Sổ Sale Cá Nhân

> **Web trước, app sau.** Mọi tính năng mới được thử trên web, ổn định rồi port sang Flutter.

## Chiến lược

| Giai đoạn | Mục tiêu | Trạng thái |
|-----------|----------|------------|
| **Phase 0** | Web đồng bộ app Sổ Khách (chăm khách) | ✅ Xong |
| **Phase 1** | Pivot Salenote: Sản phẩm + Ghi đơn + Dashboard tiền | ✅ Xong (web) |
| **Phase 2** | Nguồn khách, liên kết dữ liệu, công nợ chi tiết | 🔄 Đang làm (web) |
| **Phase 3** | Port Salenote sang Flutter app | ✅ Xong (core) |

## Phase 3 — Port sang Flutter app

- [x] DB v4: products, orders, source, product_id, inventory
- [x] Ghi đơn có tiền, dashboard doanh số
- [x] Backup JSON v2 tương thích web (`salenote_backup_*.json`)
- [ ] Push notification + PIN (app đã có, giữ nguyên)

## Phase 0 — Parity web

- [x] IndexedDB local-first, khách, chăm sóc, thống kê hành vi
- [x] UI web (sidebar, bảng, dashboard)
- [x] Hướng dẫn sử dụng

## Phase 1 — Salenote core (web)

- [x] Bảng `products` (giá vốn, giá bán, hoa hồng mặc định)
- [x] Bảng `orders` (khách + SP + SL + giá + TT thanh toán)
- [x] Ghi đơn có số tiền (thay chốt đơn rỗng)
- [x] Home: doanh thu / lợi nhuận / HH / số đơn / công nợ (hôm nay + tháng)
- [x] Trang Sản phẩm, Đơn hàng, Thống kê tiền
- [x] Backup JSON v2 (kèm products + orders)

## Phase 2 — Mở rộng

- [x] Nguồn khách (Facebook, Zalo, TikTok…)
- [x] Liên kết khách ↔ sản phẩm ↔ đơn (`product_id`, sync khi ghi đơn)
- [x] Thống kê doanh thu theo nguồn
- [x] Tổng kết bán hàng trên chi tiết khách
- [x] Tồn kho tuỳ chọn theo SP (track_inventory, trừ kho khi ghi đơn)
- [ ] Công nợ chi tiết / nhắc thu
- [ ] Đính kèm ảnh/HĐ (hoãn — không ưu tiên hiện tại)

## Chạy web

```bash
cd web
npm install
npm run dev
```

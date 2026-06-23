# Salenote Web — Sổ Sale Cá Nhân

PWA local-first: chăm khách, ghi đơn (sắp tới), biết tiền (sắp tới).

## Chạy dev

```bash
npm install
npm run dev
```

Mở http://localhost:5173

## Build

```bash
npm run build
npm run preview
```

## Phase 0 (hiện tại)

Đồng bộ với app Flutter `../app`:

- Khách hàng CRUD + trạng thái + bảo hành
- Home: cần liên hệ / sắp tới
- Nhắn tin (mẫu + sao chép), chốt đơn, timeline
- Thống kê tháng, streak
- Backup/khôi phục JSON (format tương thích app)
- Theme sáng/tối

## Stack

- Vite + React 19 + TypeScript
- Tailwind CSS 4
- Dexie (IndexedDB)
- React Router 7

## Dữ liệu

Lưu trong IndexedDB `salenote`. Export JSON dùng schema:

```json
{
  "customers": [...],
  "interactions": [...]
}
```

Tương thích import từ app mobile Sổ Khách.

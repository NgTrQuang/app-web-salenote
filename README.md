# Salenote — Sổ Sale Cá Nhân

Monorepo phát triển **web trước, app sau**.

| Thư mục | Mô tả |
|---------|--------|
| [`web/`](web/) | **Salenote PWA** — nơi phát triển chính (React + IndexedDB) |
| [`app/`](app/) | Flutter mobile Sổ Khách v2.2 — giữ ổn định đến khi port từ web |

## Bắt đầu (web)

```bash
cd web
npm install
npm run dev
```

## Roadmap

Xem [ROADMAP.md](ROADMAP.md).

## Định vị

> Chăm khách, ghi đơn, biết tiền — dữ liệu trên máy bạn.

- **Phase 0** (đang làm): Web đồng bộ tính năng chăm khách từ app
- **Phase 1**: Sản phẩm + đơn hàng + dashboard tiền (web trước)
- **Phase 3**: Port sang Flutter app

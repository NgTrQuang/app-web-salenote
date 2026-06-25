import type { Customer, Order } from '@/types';
import { PAYMENT_LABELS, orderDebt, orderRevenue } from '@/types';
import { formatMoney } from './money';
import { getShopSettings, type ShopSettings } from './shopSettings';
import {
  resolveShippingAddress,
  resolveShippingName,
  resolveShippingPhone,
} from './shippingUtils';

export interface BillData {
  shop: ShopSettings;
  order: Order;
  customer: Customer;
  revenue: number;
  debt: number;
  issuedAt: number;
  shippingName: string;
  shippingPhone: string;
  shippingAddress: string;
}

const NOTO_REGULAR_URL = '/fonts/NotoSans-Regular.ttf';
const NOTO_BOLD_URL = '/fonts/NotoSans-Bold.ttf';

let fontsPromise: Promise<{ regular: string; bold: string }> | null = null;

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]!);
  return btoa(binary);
}

async function loadBillFonts(): Promise<{ regular: string; bold: string }> {
  if (!fontsPromise) {
    fontsPromise = Promise.all([
      fetch(NOTO_REGULAR_URL).then((r) => {
        if (!r.ok) throw new Error('Không tải được font PDF');
        return r.arrayBuffer();
      }),
      fetch(NOTO_BOLD_URL).then((r) => {
        if (!r.ok) throw new Error('Không tải được font PDF');
        return r.arrayBuffer();
      }),
    ]).then(([regularBuf, boldBuf]) => ({
      regular: arrayBufferToBase64(regularBuf),
      bold: arrayBufferToBase64(boldBuf),
    }));
  }
  return fontsPromise;
}

export async function buildBillData(customer: Customer, order: Order): Promise<BillData> {
  const shop = await getShopSettings();
  return {
    shop,
    order,
    customer,
    revenue: orderRevenue(order),
    debt: orderDebt(order),
    issuedAt: Date.now(),
    shippingName: resolveShippingName(order, customer),
    shippingPhone: resolveShippingPhone(order, customer),
    shippingAddress: resolveShippingAddress(order, customer),
  };
}

export function billFilename(order: Order): string {
  const d = new Date(order.created_at);
  const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
  return `bill-${order.id ?? 'new'}-${date}.pdf`;
}

export function formatBillPaymentLabel(order: Order): string {
  return PAYMENT_LABELS[order.payment_status];
}

function splitLines(doc: import('jspdf').jsPDF, text: string, maxWidth: number): string[] {
  return doc.splitTextToSize(text, maxWidth) as string[];
}

/** Tạo PDF trực tiếp từ dữ liệu — không dùng html2canvas (tránh lỗi Tailwind oklch). */
export async function buildBillPdfBlob(data: BillData): Promise<Blob> {
  const [{ jsPDF }, fonts] = await Promise.all([import('jspdf'), loadBillFonts()]);
  const doc = new jsPDF({ unit: 'mm', format: 'a4', orientation: 'portrait' });

  doc.addFileToVFS('NotoSans-Regular.ttf', fonts.regular);
  doc.addFileToVFS('NotoSans-Bold.ttf', fonts.bold);
  doc.addFont('NotoSans-Regular.ttf', 'NotoSans', 'normal');
  doc.addFont('NotoSans-Bold.ttf', 'NotoSans', 'bold');

  const { shop, order, revenue, debt, shippingName, shippingPhone, shippingAddress } = data;
  const pageW = doc.internal.pageSize.getWidth();
  const margin = 18;
  const contentW = pageW - margin * 2;
  let y = 20;

  const setNormal = (size = 10) => {
    doc.setFont('NotoSans', 'normal');
    doc.setFontSize(size);
    doc.setTextColor(30, 41, 59);
  };
  const setBold = (size = 10) => {
    doc.setFont('NotoSans', 'bold');
    doc.setFontSize(size);
    doc.setTextColor(30, 41, 59);
  };
  const setMuted = (size = 9) => {
    doc.setFont('NotoSans', 'normal');
    doc.setFontSize(size);
    doc.setTextColor(100, 116, 139);
  };

  setBold(16);
  doc.text(shop.shopName.toUpperCase(), pageW / 2, y, { align: 'center' });
  y += 7;

  if (shop.shopPhone.trim()) {
    setMuted(10);
    doc.text(`SĐT: ${shop.shopPhone.trim()}`, pageW / 2, y, { align: 'center' });
    y += 6;
  }

  setBold(11);
  doc.setTextColor(100, 116, 139);
  doc.text('PHIẾU BÁN HÀNG', pageW / 2, y + 4, { align: 'center' });
  y += 10;

  const createdLabel = new Date(order.created_at).toLocaleString('vi-VN');
  setMuted(9);
  doc.text(`Mã đơn #${order.id ?? '—'} · ${createdLabel}`, pageW / 2, y, { align: 'center' });
  y += 8;

  doc.setDrawColor(203, 213, 225);
  doc.line(margin, y, pageW - margin, y);
  y += 8;

  const infoLine = (label: string, value: string, boldValue = false) => {
    setMuted(10);
    doc.text(`${label} `, margin, y);
    const labelW = doc.getTextWidth(`${label} `);
    if (boldValue) setBold(10);
    else setNormal(10);
    const lines = splitLines(doc, value, contentW - labelW);
    doc.text(lines, margin + labelW, y);
    y += Math.max(lines.length * 5, 6);
  };

  infoLine('Khách hàng:', shippingName, true);
  if (shippingPhone) infoLine('SĐT:', shippingPhone);
  if (shippingAddress) infoLine('Địa chỉ:', shippingAddress);

  y += 4;
  const colX = {
    product: margin,
    qty: margin + contentW * 0.52,
    price: margin + contentW * 0.65,
    total: margin + contentW * 0.82,
  };

  doc.setFillColor(248, 250, 252);
  doc.rect(margin, y - 4, contentW, 8, 'F');
  setBold(9);
  doc.text('Sản phẩm', colX.product, y);
  doc.text('SL', colX.qty, y);
  doc.text('Đơn giá', colX.price, y);
  doc.text('Thành tiền', pageW - margin, y, { align: 'right' });
  y += 8;

  setNormal(10);
  const productLines = splitLines(doc, order.product_name, contentW * 0.48);
  doc.text(productLines, colX.product, y);
  doc.text(String(order.quantity), colX.qty, y);
  doc.text(formatMoney(order.unit_sell_price), colX.price, y);
  doc.text(formatMoney(revenue), pageW - margin, y, { align: 'right' });
  y += Math.max(productLines.length * 5, 7) + 4;

  doc.line(margin, y, pageW - margin, y);
  y += 8;

  const totalRow = (label: string, value: string, opts?: { bold?: boolean; red?: boolean }) => {
    if (opts?.bold) setBold(10);
    else setNormal(10);
    if (opts?.red) doc.setTextColor(185, 28, 28);
    else doc.setTextColor(30, 41, 59);
    doc.text(label, margin, y);
    doc.text(value, pageW - margin, y, { align: 'right' });
    y += 6;
  };

  totalRow('Tổng cộng', formatMoney(revenue), { bold: true });
  totalRow('Đã thu', formatMoney(order.paid_amount));
  if (debt > 0) totalRow('Còn nợ', formatMoney(debt), { bold: true, red: true });
  totalRow('Thanh toán', formatBillPaymentLabel(order));

  if (order.note?.trim()) {
    y += 2;
    setMuted(10);
    const noteLines = splitLines(doc, `Ghi chú: ${order.note.trim()}`, contentW);
    doc.text(noteLines, margin, y);
    y += noteLines.length * 5;
  }

  y = Math.max(y + 10, 260);
  setMuted(8);
  doc.text('Phiếu bán hàng — không phải hóa đơn GTGT. Cảm ơn quý khách!', pageW / 2, y, {
    align: 'center',
  });

  return doc.output('blob');
}

export function downloadBillPdf(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.style.display = 'none';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export async function exportBillPdfFromData(data: BillData, filename: string): Promise<void> {
  const blob = await buildBillPdfBlob(data);
  downloadBillPdf(blob, filename);
}

export async function shareBillPdfFile(blob: Blob, filename: string): Promise<boolean> {
  const file = new File([blob], filename, { type: 'application/pdf' });
  if (navigator.share && navigator.canShare?.({ files: [file] })) {
    await navigator.share({ files: [file], title: filename });
    return true;
  }
  return false;
}

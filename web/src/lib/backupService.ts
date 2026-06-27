import { exportAll, importAll, setSetting } from './db';
import { SETTING_KEYS, STATUS_LABELS, sourceLabel } from './constants';
import type { BackupData } from '@/types';
import { orderCommission, orderDebt, orderProfit, orderRevenue } from '@/types';

const BACKUP_VERSION = 3;

export async function downloadBackup(): Promise<void> {
  const data = await exportAll();
  const payload: BackupData = {
    version: BACKUP_VERSION,
    customers: data.customers,
    interactions: data.interactions,
    products: data.products,
    orders: data.orders,
    expenses: data.expenses,
  };
  const json = JSON.stringify(payload, null, 2);
  const blob = new Blob([json], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const stamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const a = document.createElement('a');
  a.href = url;
  a.download = `salenote_backup_${stamp}.json`;
  a.click();
  URL.revokeObjectURL(url);
  await setSetting(SETTING_KEYS.lastBackupDate, stamp);
}

export async function restoreFromFile(file: File): Promise<void> {
  const text = await file.text();
  const data = JSON.parse(text) as BackupData;
  if (!Array.isArray(data.customers) || !Array.isArray(data.interactions)) {
    throw new Error('File backup không hợp lệ');
  }
  await importAll({
    customers: data.customers,
    interactions: data.interactions,
    products: data.products ?? [],
    orders: data.orders ?? [],
    expenses: data.expenses ?? [],
  });
}

export async function exportCsv(): Promise<void> {
  const data = await exportAll();
  const idToName = new Map(data.customers.map((c) => [c.id!, c.name]));
  const stamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');

  const customerLines = [
    'Tên,SĐT,Nguồn,Sản phẩm,Trạng thái,Lần liên hệ cuối,Ngày nhắc tiếp,Ghi chú,Hết bảo hành',
    ...data.customers.map((r) =>
      [
        csvCell(r.name),
        csvCell(r.phone),
        csvCell(r.source ? sourceLabel(r.source) : ''),
        csvCell(r.product),
        csvCell(STATUS_LABELS[r.status] ?? r.status),
        csvCell(msToDate(r.last_contact_at)),
        csvCell(msToDate(r.next_action_at)),
        csvCell(r.note),
        csvCell(r.warranty_end_date ? msToDate(r.warranty_end_date) : ''),
      ].join(','),
    ),
  ].join('\n');

  const interactionLines = [
    'Khách,Nội dung,Thời gian',
    ...data.interactions.map((r) =>
      [
        csvCell(idToName.get(r.customer_id) ?? ''),
        csvCell(r.content),
        csvCell(msToDate(r.created_at)),
      ].join(','),
    ),
  ].join('\n');

  const orderLines = [
    'Khách,Sản phẩm,SL,Doanh thu,Lợi nhuận,Hoa hồng,Công nợ,TT thanh toán,Ngày',
    ...data.orders.map((r) =>
      [
        csvCell(idToName.get(r.customer_id) ?? ''),
        csvCell(r.product_name),
        csvCell(String(r.quantity)),
        csvCell(String(orderRevenue(r))),
        csvCell(String(orderProfit(r))),
        csvCell(String(orderCommission(r))),
        csvCell(String(orderDebt(r))),
        csvCell(r.payment_status),
        csvCell(msToDate(r.created_at)),
      ].join(','),
    ),
  ].join('\n');

  downloadText(`\uFEFF${customerLines}`, `salenote_customers_${stamp}.csv`, 'text/csv');
  downloadText(`\uFEFF${interactionLines}`, `salenote_interactions_${stamp}.csv`, 'text/csv');
  if (data.orders.length > 0) {
    downloadText(`\uFEFF${orderLines}`, `salenote_orders_${stamp}.csv`, 'text/csv');
  }
}

function csvCell(value: string | null | undefined): string {
  const s = value ?? '';
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function msToDate(ms: number | null | undefined): string {
  if (!ms) return '';
  return new Date(ms).toLocaleDateString('vi-VN');
}

function downloadText(content: string, filename: string, type: string): void {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

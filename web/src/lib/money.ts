/** Format số tiền VND */
export function formatMoney(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0,
  }).format(amount);
}

/** Parse input tiền từ chuỗi (bỏ dấu chấm/phẩy) */
export function parseMoneyInput(value: string): number {
  const cleaned = value.replace(/[^\d]/g, '');
  return cleaned ? parseInt(cleaned, 10) : 0;
}

export function formatMoneyInput(amount: number): string {
  if (!amount) return '';
  return new Intl.NumberFormat('vi-VN').format(amount);
}

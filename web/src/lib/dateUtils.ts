export function formatDate(ms: number): string {
  return new Date(ms).toLocaleDateString('vi-VN');
}

export function formatDateTime(ms: number): string {
  const d = new Date(ms);
  const time = d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
  return `${time} ${formatDate(ms)}`;
}

function calendarDaysDiff(a: Date, b: Date): number {
  const aDate = new Date(a.getFullYear(), a.getMonth(), a.getDate());
  const bDate = new Date(b.getFullYear(), b.getMonth(), b.getDate());
  return Math.round((aDate.getTime() - bDate.getTime()) / 86400000);
}

export function relativeTime(ms: number): string {
  const dt = new Date(ms);
  const now = new Date();
  const days = calendarDaysDiff(now, dt);

  if (days < 0) {
    const futureDays = -days;
    if (futureDays === 0) return 'Hôm nay';
    if (futureDays === 1) return 'Ngày mai';
    return `Còn ${futureDays} ngày`;
  }
  if (days === 0) return 'Hôm nay';
  if (days === 1) return 'Hôm qua';
  if (days < 7) return `${days} ngày trước`;
  if (days < 30) return `${Math.floor(days / 7)} tuần trước`;
  return formatDate(ms);
}

export function nextActionLabel(ms: number): string {
  const dt = new Date(ms);
  const now = new Date();
  const days = calendarDaysDiff(dt, now);

  if (days > 0) return 'Cần liên hệ ngay';
  const futureDays = -days;
  if (futureDays === 0) return 'Hôm nay';
  if (futureDays === 1) return 'Ngày mai';
  return `Còn ${futureDays} ngày`;
}

export function monthRange(year: number, month: number): { start: number; end: number } {
  const start = new Date(year, month - 1, 1).getTime();
  const end = new Date(year, month, 1).getTime();
  return { start, end };
}

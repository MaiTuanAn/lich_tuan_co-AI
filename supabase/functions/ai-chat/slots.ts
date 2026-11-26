// Thuật toán tìm khung giờ trống: thuần hàm, không phụ thuộc mạng/DB.
// Mọi thời điểm là "giờ treo tường" (wall time) của người dùng, quy đổi ra
// số phút kể từ 1970-01-01T00:00 (coi như UTC) để tính toán cho đơn giản.

export type Interval = [number, number]; // [start, end) tính bằng phút

const STEP_MIN = 30; // các khung giờ gợi ý nằm trên mốc :00 và :30
const MAX_SCAN_DAYS = 15;

/** "2026-11-26T09:00" hoặc "2026-11-26T09:00:00.000" -> số phút; sai định dạng -> NaN */
export function toMin(s: string): number {
  const m = /^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})/.exec(s ?? '');
  if (!m) return NaN;
  return Date.parse(`${m[1]}T${m[2]}:00Z`) / 60000;
}

/** số phút -> "YYYY-MM-DDTHH:mm" */
export function fromMin(min: number): string {
  return new Date(min * 60000).toISOString().slice(0, 16);
}

const overlaps = (a: Interval, b: Interval) => a[0] < b[1] && a[1] > b[0];

/**
 * Tìm tối đa `max` khung giờ trống dài `dur` phút trong [from, to].
 * Mỗi ngày chỉ được đánh dấu trong khung [startHour, endHour].
 * Ưu tiên khung sớm nhất của từng ngày khác nhau để người dùng có lựa chọn đa dạng.
 */
export function findFreeSlots(
  busy: Interval[],
  from: number,
  to: number,
  dur: number,
  startHour: number,
  endHour: number,
  max = 3,
): Interval[] {
  const perDay: Interval[][] = [];
  const firstDay = Math.floor(from / 1440) * 1440;

  for (let day = firstDay, i = 0; day <= to && i < MAX_SCAN_DAYS; day += 1440, i++) {
    const winStart = Math.max(day + startHour * 60, from);
    const winEnd = Math.min(day + endHour * 60, to);
    const slots: Interval[] = [];

    for (let s = Math.ceil(winStart / STEP_MIN) * STEP_MIN; s + dur <= winEnd; s += STEP_MIN) {
      const cand: Interval = [s, s + dur];
      if (!busy.some((b) => overlaps(b, cand))) slots.push(cand);
    }
    if (slots.length > 0) perDay.push(slots);
  }

  const picked: Interval[] = [];

  // Vòng 1: khung sớm nhất của mỗi ngày
  for (const slots of perDay) {
    if (picked.length < max) picked.push(slots[0]);
  }
  // Vòng 2: nếu chưa đủ, lấy thêm khung khác (không chồng lên khung đã chọn)
  for (const slots of perDay) {
    for (const cand of slots) {
      if (picked.length >= max) break;
      if (!picked.some((p) => overlaps(p, cand))) picked.push(cand);
    }
  }

  return picked.sort((a, b) => a[0] - b[0]);
}

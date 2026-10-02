export const LAUNCH_DAY = "2026-10-02";
export function utcDay(date = new Date()) {
  return date.toISOString().slice(0, 10);
}
export function validDay(day: string) {
  return (
    /^\d{4}-\d{2}-\d{2}$/.test(day) &&
    !Number.isNaN(Date.parse(day)) &&
    new Date(day).toISOString().slice(0, 10) === day &&
    day >= LAUNCH_DAY &&
    day <= utcDay()
  );
}
export function weekStart(day: string) {
  const d = new Date(day + "T00:00:00Z");
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return utcDay(d);
}

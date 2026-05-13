// NOAA Solar 簡易版・東京（35.6762, 139.6503）固定 MVP
// Flutter 側 lib/utils/sunrise_calculator.dart と挙動を揃える。
// 設計書: docs/mvp_specs/B2_morning_reminder.md v0.5 §5.2

const TOKYO_LAT = 35.6762;
const TOKYO_LON = 139.6503;
const JST_OFFSET_HOURS = 9;

function toJulian(date: Date): number {
  return date.getTime() / 86400000 + 2440587.5;
}

function toDays(date: Date): number {
  return toJulian(date) - 2451545.0;
}

function deg2rad(d: number): number {
  return (d * Math.PI) / 180;
}
function rad2deg(r: number): number {
  return (r * 180) / Math.PI;
}

function solarMeanAnomaly(d: number): number {
  return deg2rad(357.5291 + 0.98560028 * d);
}

function eclipticLongitude(M: number): number {
  const C =
    deg2rad(1.9148) * Math.sin(M) +
    deg2rad(0.02) * Math.sin(2 * M) +
    deg2rad(0.0003) * Math.sin(3 * M);
  const P = deg2rad(102.9372);
  return M + C + P + Math.PI;
}

function declination(L: number): number {
  const e = deg2rad(23.4397);
  return Math.asin(Math.sin(e) * Math.sin(L));
}

function julianFromDays(d: number): Date {
  return new Date((d + 2451545.0 - 2440587.5) * 86400000);
}

function hourAngle(h: number, phi: number, dec: number): number {
  return Math.acos(
    (Math.sin(h) - Math.sin(phi) * Math.sin(dec)) /
      (Math.cos(phi) * Math.cos(dec)),
  );
}

function solarTransitJ(ds: number, M: number, L: number): number {
  return 2451545.0 + ds + 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
}

function approxTransit(Ht: number, lw: number, n: number): number {
  return 0.0009 + (Ht + lw) / (2 * Math.PI) + n;
}

function julianCycle(d: number, lw: number): number {
  return Math.round(d - 0.0009 - lw / (2 * Math.PI));
}

// 観測高度 -0.833 度（標準的な日の出/日没）
const H0 = deg2rad(-0.833);

function computeSunTimes(
  date: Date,
  lat: number,
  lon: number,
): { sunrise: Date; sunset: Date } {
  const lw = deg2rad(-lon);
  const phi = deg2rad(lat);
  const d = toDays(date);
  const n = julianCycle(d, lw);
  const ds = approxTransit(0, lw, n);
  const M = solarMeanAnomaly(ds);
  const L = eclipticLongitude(M);
  const dec = declination(L);
  const Jnoon = solarTransitJ(ds, M, L);
  const w = hourAngle(H0, phi, dec);
  const a = approxTransit(w, lw, n);
  const Jset = solarTransitJ(a, M, L);
  const Jrise = Jnoon - (Jset - Jnoon);
  return {
    sunrise: julianFromDays(Jrise - 2451545.0),
    sunset: julianFromDays(Jset - 2451545.0),
  };
}

export function sunriseFor(dateJst: Date): Date {
  // JST 当日 0:00 の UTC を渡すと、その日の日の出 UTC が返る
  // 渡される dateJst は「JST 当日の任意時刻」想定。日付部分のみ使う。
  const jstMidnightUtc = new Date(
    Date.UTC(
      dateJst.getUTCFullYear(),
      dateJst.getUTCMonth(),
      dateJst.getUTCDate(),
      -JST_OFFSET_HOURS,
      0,
      0,
    ),
  );
  return computeSunTimes(jstMidnightUtc, TOKYO_LAT, TOKYO_LON).sunrise;
}

export function recommendedSendAt(dateJst: Date): Date {
  const sr = sunriseFor(dateJst);
  return new Date(sr.getTime() - 30 * 60 * 1000);
}

export function bestTimeWindow(dateJst: Date): { start: Date; end: Date } {
  const sr = sunriseFor(dateJst);
  return {
    start: new Date(sr.getTime() - 30 * 60 * 1000),
    end: new Date(sr.getTime() + 30 * 60 * 1000),
  };
}

// JST 日付（YYYY-MM-DD）を返すヘルパ
export function jstDateString(now: Date): string {
  const jst = new Date(now.getTime() + JST_OFFSET_HOURS * 3600 * 1000);
  const y = jst.getUTCFullYear();
  const m = String(jst.getUTCMonth() + 1).padStart(2, '0');
  const d = String(jst.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function jstNow(now: Date = new Date()): {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  dayOfWeek: number; // 0=Sun ... 6=Sat
} {
  const jst = new Date(now.getTime() + JST_OFFSET_HOURS * 3600 * 1000);
  return {
    year: jst.getUTCFullYear(),
    month: jst.getUTCMonth() + 1,
    day: jst.getUTCDate(),
    hour: jst.getUTCHours(),
    minute: jst.getUTCMinutes(),
    dayOfWeek: jst.getUTCDay(),
  };
}

// scenario 判定（優先度: hot/cold > rainy > scenery > weekend/weekday > sunny）
// 設計書: docs/mvp_specs/B2_morning_reminder.md v0.5 §3.5 / §5.1

export type Season = 'spring' | 'summer' | 'autumn' | 'winter';
export type Scenario =
  | 'sunny'
  | 'rainy'
  | 'cold'
  | 'hot'
  | 'scenery'
  | 'weekend'
  | 'weekday';

export type Weather = {
  maxTempC: number;
  minTempC: number;
  precipProbability: number; // 0.0-1.0
};

export function computeSeason(month: number): Season {
  if (month >= 3 && month <= 5) return 'spring';
  if (month >= 6 && month <= 8) return 'summer';
  if (month >= 9 && month <= 11) return 'autumn';
  return 'winter';
}

export function pickScenario(args: {
  weather: Weather | null;
  sceneryEnabled: boolean;
  season: Season;
  dayOfWeek: number; // 0=Sun ... 6=Sat
}): Scenario {
  const { weather, sceneryEnabled, season, dayOfWeek } = args;

  if (weather) {
    // 優先度1: 気温
    if (weather.maxTempC >= 28) return 'hot';
    const coldThreshold = season === 'winter' ? 0 : 5;
    if (weather.minTempC <= coldThreshold) return 'cold';

    // 優先度2: 降水
    if (weather.precipProbability >= 0.6) return 'rainy';
  }
  // weather=null（API 失敗）の場合は天気軸スキップして scenery 以降の判定に進む

  // 優先度3: 季節風景フラグ
  if (sceneryEnabled) return 'scenery';

  // 優先度4: 曜日
  if (dayOfWeek === 0 || dayOfWeek === 6) return 'weekend';
  return 'weekday';
}

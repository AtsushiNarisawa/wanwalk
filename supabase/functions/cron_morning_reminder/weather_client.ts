// OpenWeatherMap One Call API 3.0 ラッパ + b2_weather_cache UPSERT
// 東京固定（35.6762, 139.6503）
// 設計書: docs/mvp_specs/B2_morning_reminder.md v0.5 §5.4

// deno-lint-ignore-file no-explicit-any
import type { SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import type { Weather } from './scenario_picker.ts';

const TOKYO_LAT = 35.6762;
const TOKYO_LON = 139.6503;
const OWM_ENDPOINT = 'https://api.openweathermap.org/data/3.0/onecall';

export async function fetchTodayWeather(args: {
  supabase: SupabaseClient;
  observedDate: string; // 'YYYY-MM-DD' (JST)
  apiKey: string | undefined;
}): Promise<Weather | null> {
  const { supabase, observedDate, apiKey } = args;

  // 1. cache 確認
  const { data: cached } = await supabase
    .from('b2_weather_cache')
    .select('max_temp_c, min_temp_c, precip_probability')
    .eq('observed_date', observedDate)
    .maybeSingle();
  if (cached) {
    return {
      maxTempC: Number(cached.max_temp_c),
      minTempC: Number(cached.min_temp_c),
      precipProbability: Number(cached.precip_probability),
    };
  }

  if (!apiKey) {
    console.warn('OPENWEATHERMAP_API_KEY unset — weather fetch skipped');
    return null;
  }

  // 2. OWM 呼び出し
  const url = `${OWM_ENDPOINT}?lat=${TOKYO_LAT}&lon=${TOKYO_LON}&exclude=current,minutely,hourly,alerts&units=metric&appid=${apiKey}`;
  let raw: any;
  try {
    const res = await fetch(url);
    if (!res.ok) {
      const text = await res.text();
      console.error('owm_fetch_failed', res.status, text.slice(0, 200));
      return null;
    }
    raw = await res.json();
  } catch (e) {
    console.error('owm_fetch_exception', String(e));
    return null;
  }

  const today = raw?.daily?.[0];
  if (!today || typeof today.temp?.max !== 'number') {
    console.error('owm_unexpected_shape');
    return null;
  }
  const weather: Weather = {
    maxTempC: Number(today.temp.max),
    minTempC: Number(today.temp.min),
    precipProbability: Number(today.pop ?? 0),
  };

  // 3. cache UPSERT
  const { error: cacheErr } = await supabase
    .from('b2_weather_cache')
    .upsert(
      {
        observed_date: observedDate,
        max_temp_c: weather.maxTempC,
        min_temp_c: weather.minTempC,
        precip_probability: weather.precipProbability,
        raw_response: raw,
        fetched_at: new Date().toISOString(),
      },
      { onConflict: 'observed_date' },
    );
  if (cacheErr) {
    console.error('weather_cache_upsert_failed', cacheErr.message);
  }

  return weather;
}

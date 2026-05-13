// supabase/functions/cron_morning_reminder/index.ts
//
// 設計書: docs/mvp_specs/B2_morning_reminder.md v0.5 §5.1
// 役割: pg_cron が毎時 0 分に起動 → 当日天気＋scenery_flag＋曜日で scenario 判定 →
//       notification_templates から文言取得 → send_push EF を fetch で呼ぶ
// 認証: verify_jwt: true（service_role JWT 必須・pg_net.http_post から呼ぶ）

// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import { fetchTodayWeather } from './weather_client.ts';
import {
  pickScenario,
  computeSeason,
  type Scenario,
  type Season,
} from './scenario_picker.ts';
import { recommendedSendAt, jstDateString, jstNow } from './sunrise.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const SEND_PUSH_URL = `${SUPABASE_URL}/functions/v1/send_push`;
const OWM_API_KEY = Deno.env.get('OPENWEATHERMAP_API_KEY');

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function jsonResp(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

type Target = {
  user_id: string;
  morning_reminder_enabled: boolean;
  morning_reminder_mode: 'auto' | 'fixed_time';
  morning_reminder_time: string; // '06:00:00'
  morning_reminder_frequency: 'daily' | 'weekdays' | 'weekends';
  notification_granted: boolean;
  timezone: string;
};

function frequencyMatchesToday(
  freq: Target['morning_reminder_frequency'],
  dayOfWeek: number,
): boolean {
  if (freq === 'daily') return true;
  const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
  if (freq === 'weekdays') return !isWeekend;
  return isWeekend; // weekends
}

function computeSendAtUtc(target: Target, nowUtc: Date): Date | null {
  const jst = jstNow(nowUtc);
  // JST 当日 0:00 の UTC
  const jstMidnightUtc = new Date(
    Date.UTC(jst.year, jst.month - 1, jst.day, -9, 0, 0),
  );
  if (target.morning_reminder_mode === 'fixed_time') {
    const [hh, mm] = target.morning_reminder_time
      .split(':')
      .map((s) => parseInt(s, 10));
    // JST hh:mm の UTC
    return new Date(Date.UTC(jst.year, jst.month - 1, jst.day, hh - 9, mm, 0));
  }
  // auto: 日の出 -30 分（東京固定 MVP）
  return recommendedSendAt(jstMidnightUtc);
}

function shouldSendInThisHour(sendAtUtc: Date, nowUtc: Date): boolean {
  // 毎時 0 分起動。当該 60 分窓 [now, now+60min) に sendAt が入るか。
  // 起動遅延を考慮して [now - 5min, now + 60min) で許容。
  const start = nowUtc.getTime() - 5 * 60 * 1000;
  const end = nowUtc.getTime() + 60 * 60 * 1000;
  const t = sendAtUtc.getTime();
  return t >= start && t < end;
}

async function alreadySentToday(
  supabase: SupabaseClient,
  userId: string,
  jstDate: string,
): Promise<boolean> {
  // JST 当日 0:00 の UTC
  const [y, m, d] = jstDate.split('-').map((s) => parseInt(s, 10));
  const dayStartUtc = new Date(Date.UTC(y, m - 1, d, -9, 0, 0)).toISOString();
  const { count, error } = await supabase
    .from('notification_log')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('category', 'morning_reminder')
    .gte('created_at', dayStartUtc);
  if (error) {
    console.error('already_sent_today_query_failed', userId, error.message);
    return false;
  }
  return (count ?? 0) > 0;
}

async function getTemplate(
  supabase: SupabaseClient,
  key: string,
): Promise<{ title: string; body: string } | null> {
  const { data, error } = await supabase
    .from('notification_templates')
    .select('title, body')
    .eq('key', key)
    .eq('is_active', true)
    .maybeSingle();
  if (error) {
    console.error('template_query_failed', key, error.message);
    return null;
  }
  return data;
}

async function getSceneryEnabled(
  supabase: SupabaseClient,
  month: number,
): Promise<boolean> {
  const { data, error } = await supabase
    .from('b2_scenery_flags')
    .select('scenery_enabled')
    .eq('month', month)
    .maybeSingle();
  if (error) {
    console.error('scenery_flag_query_failed', month, error.message);
    return false;
  }
  return Boolean(data?.scenery_enabled);
}

async function invokeSendPush(args: {
  userId: string;
  title: string;
  body: string;
  templateKey: string;
}): Promise<{ ok: boolean; status: number; body: string }> {
  const res = await fetch(SEND_PUSH_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      user_id: args.userId,
      category: 'morning_reminder',
      title: args.title,
      body: args.body,
      data: {
        deep_link: 'wanwalk://home?section=today_recommend',
        template_key: args.templateKey,
      },
    }),
  });
  const text = await res.text();
  return { ok: res.ok, status: res.status, body: text.slice(0, 500) };
}

Deno.serve(async (req: Request) => {
  // POST のみ受け付け（GET でも返すと pg_cron デバッグしやすいが、副作用が冪等でないので 405）
  if (req.method !== 'POST' && req.method !== 'GET') {
    return jsonResp(405, { error: 'method_not_allowed' });
  }

  const dryRunHeader = req.headers.get('x-dry-run');
  const dryRun = dryRunHeader === '1' || req.method === 'GET';

  const nowUtc = new Date();
  const jst = jstNow(nowUtc);
  const jstDate = jstDateString(nowUtc);
  const season: Season = computeSeason(jst.month);

  // 1. 当日天気
  const weather = await fetchTodayWeather({
    supabase,
    observedDate: jstDate,
    apiKey: OWM_API_KEY,
  });

  // 2. scenery_enabled
  const sceneryEnabled = await getSceneryEnabled(supabase, jst.month);

  // 3. 配信対象取得
  const { data: targets, error: tErr } = await supabase
    .from('v_morning_reminder_targets')
    .select(
      'user_id, morning_reminder_enabled, morning_reminder_mode, morning_reminder_time, morning_reminder_frequency, notification_granted, timezone',
    );
  if (tErr) {
    return jsonResp(500, { error: 'targets_query_failed', detail: tErr.message });
  }

  const stats = {
    total_targets: targets?.length ?? 0,
    skipped_frequency: 0,
    skipped_time_window: 0,
    skipped_already_sent: 0,
    sent: 0,
    failed: 0,
    dry_run: dryRun,
    season,
    scenery_enabled: sceneryEnabled,
    weather_available: weather !== null,
    jst_now: `${jstDate} ${String(jst.hour).padStart(2, '0')}:${String(jst.minute).padStart(2, '0')}`,
  };

  const sampleResults: any[] = [];

  for (const target of (targets ?? []) as Target[]) {
    // 4. 曜日チェック
    if (!frequencyMatchesToday(target.morning_reminder_frequency, jst.dayOfWeek)) {
      stats.skipped_frequency++;
      continue;
    }

    // 5. sendAt 計算 + 1 時間窓判定
    const sendAt = computeSendAtUtc(target, nowUtc);
    if (!sendAt || !shouldSendInThisHour(sendAt, nowUtc)) {
      stats.skipped_time_window++;
      continue;
    }

    // 6. 重複送信防止（24h 以内）
    const already = await alreadySentToday(supabase, target.user_id, jstDate);
    if (already) {
      stats.skipped_already_sent++;
      continue;
    }

    // 7. scenario 判定
    let scenario: Scenario = pickScenario({
      weather,
      sceneryEnabled,
      season,
      dayOfWeek: jst.dayOfWeek,
    });

    // 8. 文言取得 → fallback
    let templateKey = `notif.b2.${season}.${scenario}`;
    let tpl = await getTemplate(supabase, templateKey);
    if (!tpl) {
      const fallbackKey = `notif.b2.${season}.sunny`;
      console.warn('template_missing_fallback', templateKey, '->', fallbackKey);
      templateKey = fallbackKey;
      scenario = 'sunny';
      tpl = await getTemplate(supabase, fallbackKey);
    }
    if (!tpl) {
      stats.failed++;
      sampleResults.push({
        user_id: target.user_id,
        result: 'no_template',
        season,
        scenario,
      });
      continue;
    }

    if (dryRun) {
      stats.sent++;
      if (sampleResults.length < 10) {
        sampleResults.push({
          user_id: target.user_id,
          dry_run: true,
          template_key: templateKey,
          send_at_utc: sendAt.toISOString(),
          title: tpl.title,
        });
      }
      continue;
    }

    // 9. send_push 呼び出し
    const r = await invokeSendPush({
      userId: target.user_id,
      title: tpl.title,
      body: tpl.body,
      templateKey,
    });
    if (r.ok) {
      stats.sent++;
    } else {
      stats.failed++;
    }
    if (sampleResults.length < 10) {
      sampleResults.push({
        user_id: target.user_id,
        template_key: templateKey,
        send_push_status: r.status,
        ok: r.ok,
      });
    }
  }

  return jsonResp(200, { stats, sample: sampleResults });
});

-- B2: 28 文言 seed + scenery_flags 12 月 seed
-- 設計書: docs/mvp_specs/B2_morning_reminder.md v0.5 §3.4 (CEO 確定 28 文言) / §4.3 (4月+11月のみ true)
-- 文言修正は CEO 承認必須。ON CONFLICT で idempotent

-- ============================================================
-- 1) notification_templates: 28 文言（春×7 + 夏×7 + 秋×7 + 冬×7）
-- ============================================================

INSERT INTO public.notification_templates (key, category, season, scenario, title, body) VALUES
-- 春
('notif.b2.spring.sunny',   'morning_reminder', 'spring', 'sunny',
 '春の朝、愛犬と外の空気を感じに',
 '日差しが心地よくなる時間です。少しずつ暖かくなる季節を、愛犬と一緒に。'),
('notif.b2.spring.rainy',   'morning_reminder', 'spring', 'rainy',
 '今朝は雨予報。屋根のあるルートへ',
 '商店街や駅前アーケードなら、雨でも愛犬とのお散歩が楽しめます。'),
('notif.b2.spring.cold',    'morning_reminder', 'spring', 'cold',
 '春の朝はまだ冷えます',
 '日が昇る頃を狙って、暖かくなった散歩道へ。愛犬の足元にもご注意を。'),
('notif.b2.spring.hot',     'morning_reminder', 'spring', 'hot',
 '春の日中は意外と暑くなります',
 '朝の涼しいうちに、愛犬と一日のスタートを切りませんか。'),
('notif.b2.spring.scenery', 'morning_reminder', 'spring', 'scenery',
 '桜の季節、愛犬と歩く特別な道',
 '花びらが舞う散歩道は今だけ。WanWalk で近くの桜ルートを探せます。'),
('notif.b2.spring.weekend', 'morning_reminder', 'spring', 'weekend',
 '春の週末、少し遠出してみませんか',
 'いつもより少し遠くの公式ルートで、愛犬と新しい景色を。'),
('notif.b2.spring.weekday', 'morning_reminder', 'spring', 'weekday',
 '15分の朝散歩でも、十分です',
 '短くても、愛犬と外の空気を吸う時間は一日の活力に。'),

-- 夏
('notif.b2.summer.sunny',   'morning_reminder', 'summer', 'sunny',
 '夏の朝、涼しいうちに散歩へ',
 '日が昇り切る前のひととき。愛犬の足元を守るためにも早朝がおすすめ。'),
('notif.b2.summer.rainy',   'morning_reminder', 'summer', 'rainy',
 '夏の雨は涼を運びます',
 'アスファルトが熱くなる前に、雨上がりの散歩を。タオルの準備もお忘れなく。'),
('notif.b2.summer.cold',    'morning_reminder', 'summer', 'cold',
 '曇り空の朝、夏なのに涼しい',
 '肌寒い朝こそ、愛犬と気持ちよく歩ける貴重な時間です。'),
('notif.b2.summer.hot',     'morning_reminder', 'summer', 'hot',
 '今日の最高気温は 30 度超え',
 'アスファルトが熱くなる前に。日陰の多いルートで愛犬の安全を第一に。'),
('notif.b2.summer.scenery', 'morning_reminder', 'summer', 'scenery',
 '夏の朝、緑が一番美しい時間',
 '朝露に濡れた葉が陽光を受ける今だけの景色を、愛犬と一緒に。'),
('notif.b2.summer.weekend', 'morning_reminder', 'summer', 'weekend',
 '夏の早朝、避暑地のルートへ',
 '箱根や軽井沢の高原ルートは、夏でも涼しく愛犬と歩けます。'),
('notif.b2.summer.weekday', 'morning_reminder', 'summer', 'weekday',
 '夏の朝は短く、効率よく',
 '日が昇る前の 15 分で、愛犬と涼しい散歩を済ませてしまいましょう。'),

-- 秋
('notif.b2.autumn.sunny',   'morning_reminder', 'autumn', 'sunny',
 '秋晴れの朝、愛犬と歩きませんか',
 '乾いた空気と澄んだ陽光。一年で最も気持ちのいい散歩日和です。'),
('notif.b2.autumn.rainy',   'morning_reminder', 'autumn', 'rainy',
 '秋の長雨、足元にご注意を',
 '落ち葉が滑りやすくなっています。愛犬と無理せずゆっくり歩いて。'),
('notif.b2.autumn.cold',    'morning_reminder', 'autumn', 'cold',
 '朝の冷え込みが増してきました',
 '愛犬も人も、上着を一枚足して。秋の朝散歩は冬支度の始まり。'),
('notif.b2.autumn.hot',     'morning_reminder', 'autumn', 'hot',
 '残暑の朝、まだまだ油断禁物',
 '9 月でも日中は 28 度超えの予報。涼しい朝の時間を有効に。'),
('notif.b2.autumn.scenery', 'morning_reminder', 'autumn', 'scenery',
 '紅葉の季節、愛犬と歩く絶景ルート',
 '箱根や日光の紅葉ルートは今が見頃。WanWalk で近くの紅葉スポットを。'),
('notif.b2.autumn.weekend', 'morning_reminder', 'autumn', 'weekend',
 '秋の週末、遠出に最適な季節',
 '気温も湿度もちょうど良い秋は、愛犬と少し遠くまで足を延ばす絶好の時期。'),
('notif.b2.autumn.weekday', 'morning_reminder', 'autumn', 'weekday',
 '秋の朝、深呼吸の時間を',
 '忙しい一日の前に、愛犬と 15 分だけ。澄んだ空気がリセットしてくれます。'),

-- 冬
('notif.b2.winter.sunny',   'morning_reminder', 'winter', 'sunny',
 '冬の朝、冷えた空気が気持ちいい',
 '日差しが暖かくなる時間を狙って。愛犬との散歩で一日を温かく始めましょう。'),
('notif.b2.winter.rainy',   'morning_reminder', 'winter', 'rainy',
 '今朝は雨／雪予報',
 '無理せず屋根のあるルートへ。アーケードや駅前広場なら愛犬と安全に。'),
('notif.b2.winter.cold',    'morning_reminder', 'winter', 'cold',
 '今朝の最低気温は 0 度を下回ります',
 '愛犬にも防寒を。短毛種は服を着せて、足先のケアもお忘れなく。'),
('notif.b2.winter.hot',     'morning_reminder', 'winter', 'hot',
 '冬の晴れた朝は意外と暖か',
 '気温が 10 度を超える今朝は、愛犬と少し長めの散歩日和です。'),
('notif.b2.winter.scenery', 'morning_reminder', 'winter', 'scenery',
 '冬の朝、空気が一番澄む時間',
 '遠くの山並みまで見える冬の朝。愛犬と絶景ルートを歩いてみませんか。'),
('notif.b2.winter.weekend', 'morning_reminder', 'winter', 'weekend',
 '冬の週末、朝陽が昇ってから出かけよう',
 '日が出てから散歩に出れば、冬でも体が温まりやすい時間に。愛犬とゆったり歩く週末を。'),
('notif.b2.winter.weekday', 'morning_reminder', 'winter', 'weekday',
 '冬の朝散歩は短時間でも十分',
 '10 分でも外の冷気を浴びれば、愛犬の体内時計はリセット。一日が始まります。')

ON CONFLICT (key) DO UPDATE SET
  title = EXCLUDED.title,
  body = EXCLUDED.body,
  category = EXCLUDED.category,
  season = EXCLUDED.season,
  scenario = EXCLUDED.scenario,
  is_active = true,
  updated_at = now();

-- ============================================================
-- 2) b2_scenery_flags: 12 ヶ月 seed（4月/11月のみ true）
-- ============================================================

INSERT INTO public.b2_scenery_flags (season, month, scenery_enabled, note) VALUES
  ('winter', 1,  false, NULL),
  ('winter', 2,  false, NULL),
  ('spring', 3,  false, NULL),
  ('spring', 4,  true,  '桜開花期間（CEO 確定 ON・v0.5）'),
  ('spring', 5,  false, '公開後 CMO/CEO 判断で ON 検討（新緑）'),
  ('summer', 6,  false, '公開後 CMO/CEO 判断で ON 検討（紫陽花）'),
  ('summer', 7,  false, NULL),
  ('summer', 8,  false, NULL),
  ('autumn', 9,  false, NULL),
  ('autumn', 10, false, '公開後 CMO/CEO 判断で ON 検討（紅葉初期）'),
  ('autumn', 11, true,  '紅葉ピーク（CEO 確定 ON・v0.5）'),
  ('winter', 12, false, NULL)
ON CONFLICT (season, month) DO UPDATE SET
  scenery_enabled = EXCLUDED.scenery_enabled,
  note = EXCLUDED.note,
  updated_at = now();

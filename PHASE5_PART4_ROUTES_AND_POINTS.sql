-- =====================================================
-- PHASE 5 PART 4: ユーザー作成ルート + GPS座標
-- =====================================================
-- test1@example.com: 8件の散歩ルート（公開2件）
-- test2@example.com: 5件の散歩ルート（公開3件）
-- test3@example.com: 3件の散歩ルート（公開1件）
-- 合計: 16件のルート、各ルート20-30のGPS座標
-- =====================================================

DO $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
  v_user3_id UUID;
  v_dog1_id UUID;
  v_dog2_id UUID;
  v_dog3_id UUID;
  v_route_id UUID;
  v_base_lat NUMERIC;
  v_base_lng NUMERIC;
  v_point_count INTEGER;
  v_distance NUMERIC;
  v_duration INTEGER;
BEGIN

-- =====================================================
-- ユーザーIDとドッグIDを取得
-- =====================================================
SELECT id INTO v_user1_id FROM auth.users WHERE email = 'test1@example.com';
SELECT id INTO v_user2_id FROM auth.users WHERE email = 'test2@example.com';
SELECT id INTO v_user3_id FROM auth.users WHERE email = 'test3@example.com';

SELECT id INTO v_dog1_id FROM public.dogs WHERE user_id = v_user1_id LIMIT 1;
SELECT id INTO v_dog2_id FROM public.dogs WHERE user_id = v_user2_id LIMIT 1;
SELECT id INTO v_dog3_id FROM public.dogs WHERE user_id = v_user3_id LIMIT 1;

-- =====================================================
-- test1@example.com のルート（8件）
-- =====================================================

-- ルート1: 代々木公園の朝散歩（公開）
v_route_id := gen_random_uuid();
v_base_lat := 35.6704;
v_base_lng := 139.6939;
v_point_count := 25;
v_distance := 2500.0;
v_duration := 30;

INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
VALUES (
  v_route_id,
  v_user1_id,
  v_dog1_id,
  '代々木公園の朝散歩',
  '爽やかな朝、愛犬と一緒に代々木公園を散策しました。桜の木の下を歩いて気持ちよかったです。',
  v_distance,
  v_duration,
  NOW() - INTERVAL '7 days',
  NOW() - INTERVAL '7 days' + INTERVAL '30 minutes',
  true,
  '代々木公園',
  '東京都',
  NOW() - INTERVAL '7 days'
);

-- GPS座標を生成（円形ルート）
FOR i IN 0..v_point_count-1 LOOP
  INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
  VALUES (
    v_route_id,
    v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.005),
    v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.005),
    10.0 + (RANDOM() * 5),
    5.0,
    1.2 + (RANDOM() * 0.5),
    NOW() - INTERVAL '7 days' + (i * INTERVAL '72 seconds'),
    i
  );
END LOOP;

-- ルート2: 井の頭公園（公開）
v_route_id := gen_random_uuid();
v_base_lat := 35.7019;
v_base_lng := 139.5802;
v_point_count := 30;
v_distance := 3200.0;
v_duration := 40;

INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
VALUES (
  v_route_id,
  v_user1_id,
  v_dog1_id,
  '井の頭公園の午後散歩',
  '池の周りをぐるっと一周。鴨やカモメがたくさんいました。',
  v_distance,
  v_duration,
  NOW() - INTERVAL '5 days',
  NOW() - INTERVAL '5 days' + INTERVAL '40 minutes',
  true,
  '井の頭公園',
  '東京都',
  NOW() - INTERVAL '5 days'
);

FOR i IN 0..v_point_count-1 LOOP
  INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
  VALUES (
    v_route_id,
    v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.007),
    v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.007),
    15.0 + (RANDOM() * 5),
    5.0,
    1.5 + (RANDOM() * 0.5),
    NOW() - INTERVAL '5 days' + (i * INTERVAL '80 seconds'),
    i
  );
END LOOP;

-- ルート3-8: 非公開ルート（短めのルート）
FOR route_num IN 3..8 LOOP
  v_route_id := gen_random_uuid();
  v_base_lat := 35.6704 + ((route_num - 3) * 0.01);
  v_base_lng := 139.6939 + ((route_num - 3) * 0.01);
  v_point_count := 15 + (route_num * 2);
  v_distance := 1000.0 + (route_num * 200);
  v_duration := 15 + (route_num * 3);

  INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
  VALUES (
    v_route_id,
    v_user1_id,
    v_dog1_id,
    '近所の散歩 #' || route_num,
    'いつもの散歩コース。今日も元気いっぱいでした。',
    v_distance,
    v_duration,
    NOW() - (route_num || ' days')::INTERVAL,
    NOW() - (route_num || ' days')::INTERVAL + (v_duration || ' minutes')::INTERVAL,
    false,
    '自宅周辺',
    '東京都',
    NOW() - (route_num || ' days')::INTERVAL
  );

  FOR i IN 0..v_point_count-1 LOOP
    INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
    VALUES (
      v_route_id,
      v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.003),
      v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.003),
      5.0 + (RANDOM() * 3),
      5.0,
      1.0 + (RANDOM() * 0.3),
      NOW() - (route_num || ' days')::INTERVAL + (i * ((v_duration * 60) / v_point_count) || ' seconds')::INTERVAL,
      i
    );
  END LOOP;
END LOOP;

-- =====================================================
-- test2@example.com のルート（5件、公開3件）
-- =====================================================

-- ルート1: お台場海浜公園（公開）
v_route_id := gen_random_uuid();
v_base_lat := 35.6301;
v_base_lng := 139.7738;
v_point_count := 28;
v_distance := 3500.0;
v_duration := 45;

INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
VALUES (
  v_route_id,
  v_user2_id,
  v_dog2_id,
  'お台場海浜公園で海沿い散歩',
  'レインボーブリッジを見ながらの海沿い散歩。風が気持ちよかった！',
  v_distance,
  v_duration,
  NOW() - INTERVAL '6 days',
  NOW() - INTERVAL '6 days' + INTERVAL '45 minutes',
  true,
  'お台場海浜公園',
  '東京都',
  NOW() - INTERVAL '6 days'
);

FOR i IN 0..v_point_count-1 LOOP
  INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
  VALUES (
    v_route_id,
    v_base_lat + (i * 0.0002),
    v_base_lng + (SIN(i * 0.3) * 0.002),
    2.0 + (RANDOM() * 2),
    5.0,
    1.3 + (RANDOM() * 0.4),
    NOW() - INTERVAL '6 days' + (i * INTERVAL '96 seconds'),
    i
  );
END LOOP;

-- ルート2: 砧公園（公開）
v_route_id := gen_random_uuid();
v_base_lat := 35.6329;
v_base_lng := 139.6178;
v_point_count := 26;
v_distance := 2800.0;
v_duration := 35;

INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
VALUES (
  v_route_id,
  v_user2_id,
  v_dog2_id,
  '砧公園の広い芝生でのんびり',
  '広い芝生でたくさん走り回りました。他のワンちゃんとも遊べて楽しかった！',
  v_distance,
  v_duration,
  NOW() - INTERVAL '4 days',
  NOW() - INTERVAL '4 days' + INTERVAL '35 minutes',
  true,
  '砧公園',
  '東京都',
  NOW() - INTERVAL '4 days'
);

FOR i IN 0..v_point_count-1 LOOP
  INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
  VALUES (
    v_route_id,
    v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.006),
    v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.006),
    12.0 + (RANDOM() * 4),
    5.0,
    1.6 + (RANDOM() * 0.6),
    NOW() - INTERVAL '4 days' + (i * INTERVAL '81 seconds'),
    i
  );
END LOOP;

-- ルート3: 駒沢オリンピック公園（公開）
v_route_id := gen_random_uuid();
v_base_lat := 35.6283;
v_base_lng := 139.6648;
v_point_count := 32;
v_distance := 4000.0;
v_duration := 50;

INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
VALUES (
  v_route_id,
  v_user2_id,
  v_dog2_id,
  '駒沢オリンピック公園でジョギング',
  'ジョギングコースを一緒に走りました。体力がついてきた！',
  v_distance,
  v_duration,
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days' + INTERVAL '50 minutes',
  true,
  '駒沢オリンピック公園',
  '東京都',
  NOW() - INTERVAL '2 days'
);

FOR i IN 0..v_point_count-1 LOOP
  INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
  VALUES (
    v_route_id,
    v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.008),
    v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.008),
    8.0 + (RANDOM() * 3),
    5.0,
    2.0 + (RANDOM() * 0.8),
    NOW() - INTERVAL '2 days' + (i * INTERVAL '94 seconds'),
    i
  );
END LOOP;

-- ルート4-5: 非公開ルート
FOR route_num IN 4..5 LOOP
  v_route_id := gen_random_uuid();
  v_base_lat := 35.6301 + ((route_num - 4) * 0.015);
  v_base_lng := 139.7738 + ((route_num - 4) * 0.015);
  v_point_count := 18 + (route_num * 3);
  v_distance := 1500.0 + (route_num * 300);
  v_duration := 20 + (route_num * 5);

  INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
  VALUES (
    v_route_id,
    v_user2_id,
    v_dog2_id,
    '夕方の散歩 #' || route_num,
    '夕焼けが綺麗な時間帯の散歩。',
    v_distance,
    v_duration,
    NOW() - (route_num || ' days')::INTERVAL,
    NOW() - (route_num || ' days')::INTERVAL + (v_duration || ' minutes')::INTERVAL,
    false,
    '自宅周辺',
    '東京都',
    NOW() - (route_num || ' days')::INTERVAL
  );

  FOR i IN 0..v_point_count-1 LOOP
    INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
    VALUES (
      v_route_id,
      v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.004),
      v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.004),
      6.0 + (RANDOM() * 3),
      5.0,
      1.1 + (RANDOM() * 0.4),
      NOW() - (route_num || ' days')::INTERVAL + (i * ((v_duration * 60) / v_point_count) || ' seconds')::INTERVAL,
      i
    );
  END LOOP;
END LOOP;

-- =====================================================
-- test3@example.com のルート（3件、公開1件）
-- =====================================================

-- ルート1: 上野公園（公開）
v_route_id := gen_random_uuid();
v_base_lat := 35.7148;
v_base_lng := 139.7738;
v_point_count := 24;
v_distance := 2200.0;
v_duration := 28;

INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
VALUES (
  v_route_id,
  v_user3_id,
  v_dog3_id,
  '上野公園で文化的な散歩',
  '美術館や博物館の周りを散歩。文化的な雰囲気を楽しみました。',
  v_distance,
  v_duration,
  NOW() - INTERVAL '3 days',
  NOW() - INTERVAL '3 days' + INTERVAL '28 minutes',
  true,
  '上野公園',
  '東京都',
  NOW() - INTERVAL '3 days'
);

FOR i IN 0..v_point_count-1 LOOP
  INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
  VALUES (
    v_route_id,
    v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.005),
    v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.005),
    11.0 + (RANDOM() * 4),
    5.0,
    1.3 + (RANDOM() * 0.5),
    NOW() - INTERVAL '3 days' + (i * INTERVAL '70 seconds'),
    i
  );
END LOOP;

-- ルート2-3: 非公開ルート
FOR route_num IN 2..3 LOOP
  v_route_id := gen_random_uuid();
  v_base_lat := 35.7148 + ((route_num - 2) * 0.012);
  v_base_lng := 139.7738 + ((route_num - 2) * 0.012);
  v_point_count := 16 + (route_num * 2);
  v_distance := 1200.0 + (route_num * 200);
  v_duration := 18 + (route_num * 4);

  INSERT INTO public.routes (id, user_id, dog_id, title, description, distance, duration, started_at, ended_at, is_public, area, prefecture, created_at)
  VALUES (
    v_route_id,
    v_user3_id,
    v_dog3_id,
    '平日の散歩 #' || route_num,
    '仕事の後のリフレッシュ散歩。',
    v_distance,
    v_duration,
    NOW() - (route_num || ' days')::INTERVAL,
    NOW() - (route_num || ' days')::INTERVAL + (v_duration || ' minutes')::INTERVAL,
    false,
    '自宅周辺',
    '東京都',
    NOW() - (route_num || ' days')::INTERVAL
  );

  FOR i IN 0..v_point_count-1 LOOP
    INSERT INTO public.route_points (route_id, latitude, longitude, altitude, accuracy, speed, timestamp, sequence_number)
    VALUES (
      v_route_id,
      v_base_lat + (COS(2 * PI() * i / v_point_count) * 0.003),
      v_base_lng + (SIN(2 * PI() * i / v_point_count) * 0.003),
      7.0 + (RANDOM() * 2),
      5.0,
      1.0 + (RANDOM() * 0.3),
      NOW() - (route_num || ' days')::INTERVAL + (i * ((v_duration * 60) / v_point_count) || ' seconds')::INTERVAL,
      i
    );
  END LOOP;
END LOOP;

END $$;

-- =====================================================
-- 検証クエリ
-- =====================================================
SELECT 
  u.email,
  COUNT(r.id) AS route_count,
  SUM(CASE WHEN r.is_public THEN 1 ELSE 0 END) AS public_routes,
  ROUND(AVG(r.distance), 2) AS avg_distance,
  ROUND(AVG(r.duration), 2) AS avg_duration
FROM public.profiles u
LEFT JOIN public.routes r ON u.id = r.user_id
WHERE u.email IN ('test1@example.com', 'test2@example.com', 'test3@example.com')
GROUP BY u.email
ORDER BY u.email;

-- route_pointsの件数確認
SELECT 
  r.title,
  COUNT(rp.id) AS point_count,
  MIN(rp.sequence_number) AS min_seq,
  MAX(rp.sequence_number) AS max_seq
FROM public.routes r
JOIN public.route_points rp ON r.id = rp.route_id
GROUP BY r.id, r.title
ORDER BY r.created_at DESC
LIMIT 10;

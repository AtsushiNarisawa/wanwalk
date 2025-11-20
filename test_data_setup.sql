-- ================================================================
-- WanMap テストデータセットアップスクリプト
-- ================================================================
-- 実行前の注意: 既存のデータがすべて削除されます
-- ================================================================

-- ステップ1: 既存データの削除（外部キー制約を考慮した順序）
DELETE FROM photos;
DELETE FROM comments;
DELETE FROM favorites;
DELETE FROM route_points;
DELETE FROM routes;
DELETE FROM trip_plans;
DELETE FROM dogs;
DELETE FROM users;

-- ================================================================
-- ステップ2: テストユーザーの作成
-- ================================================================
-- 注意: Supabase Authで実際にユーザーを作成する必要があります
-- このスクリプトはusersテーブルのプロファイル情報のみを準備します

-- テストユーザー1: test1@example.com (メインテストユーザー)
-- テストユーザー2: test2@example.com (いいね・コメント用)
-- テストユーザー3: test3@example.com (追加ユーザー)

-- ================================================================
-- ステップ3: テストルートデータの作成
-- ================================================================

-- ルート1: 箱根の短い散歩（公開・写真あり）
INSERT INTO routes (
  id,
  user_id,
  title,
  description,
  distance,
  duration,
  start_time,
  end_time,
  is_public,
  prefecture,
  area,
  thumbnail_url,
  like_count,
  created_at
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'USER_ID_1', -- 実際のユーザーIDに置き換え
  '芦ノ湖畔の朝散歩',
  '芦ノ湖の美しい湖畔を愛犬と一緒にのんびり散歩しました。早朝の静けさと富士山の眺めが最高でした。',
  2500.0,
  1800,
  NOW() - INTERVAL '5 days',
  NOW() - INTERVAL '5 days' + INTERVAL '30 minutes',
  true,
  '神奈川県',
  'hakone',
  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
  15,
  NOW() - INTERVAL '5 days'
);

-- ルート2: 箱根の長距離ハイキング（公開・写真多数）
INSERT INTO routes (
  id,
  user_id,
  title,
  description,
  distance,
  duration,
  start_time,
  end_time,
  is_public,
  prefecture,
  area,
  thumbnail_url,
  like_count,
  created_at
) VALUES (
  '00000000-0000-0000-0000-000000000002',
  'USER_ID_1',
  '大涌谷から早雲山のハイキング',
  '大涌谷の絶景を楽しみながら早雲山まで登りました。愛犬も元気いっぱい！硫黄の香りが印象的でした。',
  5200.0,
  4500,
  NOW() - INTERVAL '3 days',
  NOW() - INTERVAL '3 days' + INTERVAL '75 minutes',
  true,
  '神奈川県',
  'hakone',
  'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800',
  23,
  NOW() - INTERVAL '3 days'
);

-- ルート3: 箱根湯本の街歩き（公開）
INSERT INTO routes (
  id,
  user_id,
  title,
  description,
  distance,
  duration,
  start_time,
  end_time,
  is_public,
  prefecture,
  area,
  thumbnail_url,
  like_count,
  created_at
) VALUES (
  '00000000-0000-0000-0000-000000000003',
  'USER_ID_1',
  '箱根湯本温泉街さんぽ',
  '箱根湯本の温泉街を散策。お土産屋さんを見ながらのんびり歩きました。愛犬も温泉街の雰囲気を楽しんでいました。',
  1800.0,
  1200,
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days' + INTERVAL '20 minutes',
  true,
  '神奈川県',
  'hakone',
  'https://images.unsplash.com/photo-1528164344705-47542687000d?w=800',
  8,
  NOW() - INTERVAL '2 days'
);

-- ルート4: 箱根の森林浴（公開）
INSERT INTO routes (
  id,
  user_id,
  title,
  description,
  distance,
  duration,
  start_time,
  end_time,
  is_public,
  prefecture,
  area,
  thumbnail_url,
  like_count,
  created_at
) VALUES (
  '00000000-0000-0000-0000-000000000004',
  'USER_ID_2', -- 別ユーザー
  '仙石原の森林浴トレイル',
  '仙石原の美しい森の中をトレッキング。マイナスイオンたっぷりで愛犬も大喜び。',
  3500.0,
  2700,
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day' + INTERVAL '45 minutes',
  true,
  '神奈川県',
  'hakone',
  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800',
  12,
  NOW() - INTERVAL '1 day'
);

-- ルート5: プライベートルート（非公開・テスト用）
INSERT INTO routes (
  id,
  user_id,
  title,
  description,
  distance,
  duration,
  start_time,
  end_time,
  is_public,
  prefecture,
  area,
  like_count,
  created_at
) VALUES (
  '00000000-0000-0000-0000-000000000005',
  'USER_ID_1',
  '自宅周辺の散歩',
  'いつもの散歩コース。愛犬のお気に入りルートです。',
  1200.0,
  900,
  NOW() - INTERVAL '6 hours',
  NOW() - INTERVAL '6 hours' + INTERVAL '15 minutes',
  false,
  '神奈川県',
  'hakone',
  5,
  NOW() - INTERVAL '6 hours'
);

-- ================================================================
-- ステップ4: ルートポイントデータ（GPSトラック）
-- ================================================================

-- ルート1のポイント（芦ノ湖畔 - 簡略版）
INSERT INTO route_points (route_id, latitude, longitude, altitude, sequence_number, recorded_at) VALUES
('00000000-0000-0000-0000-000000000001', 35.2043, 139.0248, 723.0, 1, NOW() - INTERVAL '5 days'),
('00000000-0000-0000-0000-000000000001', 35.2048, 139.0252, 724.0, 2, NOW() - INTERVAL '5 days' + INTERVAL '5 minutes'),
('00000000-0000-0000-0000-000000000001', 35.2053, 139.0258, 725.0, 3, NOW() - INTERVAL '5 days' + INTERVAL '10 minutes'),
('00000000-0000-0000-0000-000000000001', 35.2058, 139.0264, 726.0, 4, NOW() - INTERVAL '5 days' + INTERVAL '15 minutes'),
('00000000-0000-0000-0000-000000000001', 35.2063, 139.0270, 727.0, 5, NOW() - INTERVAL '5 days' + INTERVAL '20 minutes'),
('00000000-0000-0000-0000-000000000001', 35.2068, 139.0275, 728.0, 6, NOW() - INTERVAL '5 days' + INTERVAL '25 minutes'),
('00000000-0000-0000-0000-000000000001', 35.2073, 139.0280, 729.0, 7, NOW() - INTERVAL '5 days' + INTERVAL '30 minutes');

-- ルート2のポイント（大涌谷〜早雲山 - 簡略版）
INSERT INTO route_points (route_id, latitude, longitude, altitude, sequence_number, recorded_at) VALUES
('00000000-0000-0000-0000-000000000002', 35.2443, 139.0206, 1044.0, 1, NOW() - INTERVAL '3 days'),
('00000000-0000-0000-0000-000000000002', 35.2450, 139.0215, 1060.0, 2, NOW() - INTERVAL '3 days' + INTERVAL '10 minutes'),
('00000000-0000-0000-0000-000000000002', 35.2458, 139.0225, 1080.0, 3, NOW() - INTERVAL '3 days' + INTERVAL '20 minutes'),
('00000000-0000-0000-0000-000000000002', 35.2465, 139.0235, 1100.0, 4, NOW() - INTERVAL '3 days' + INTERVAL '30 minutes'),
('00000000-0000-0000-0000-000000000002', 35.2473, 139.0245, 1120.0, 5, NOW() - INTERVAL '3 days' + INTERVAL '40 minutes'),
('00000000-0000-0000-0000-000000000002', 35.2480, 139.0255, 1140.0, 6, NOW() - INTERVAL '3 days' + INTERVAL '50 minutes'),
('00000000-0000-0000-0000-000000000002', 35.2488, 139.0265, 1160.0, 7, NOW() - INTERVAL '3 days' + INTERVAL '60 minutes'),
('00000000-0000-0000-0000-000000000002', 35.2495, 139.0275, 1180.0, 8, NOW() - INTERVAL '3 days' + INTERVAL '70 minutes');

-- ================================================================
-- ステップ5: 写真データ
-- ================================================================

-- ルート1の写真
INSERT INTO photos (route_id, url, caption, latitude, longitude, created_at) VALUES
('00000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200', '芦ノ湖と富士山の絶景', 35.2043, 139.0248, NOW() - INTERVAL '5 days'),
('00000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1200', '湖畔の散歩道', 35.2053, 139.0258, NOW() - INTERVAL '5 days' + INTERVAL '10 minutes'),
('00000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200', '朝の静けさ', 35.2068, 139.0275, NOW() - INTERVAL '5 days' + INTERVAL '25 minutes');

-- ルート2の写真
INSERT INTO photos (route_id, url, caption, latitude, longitude, created_at) VALUES
('00000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=1200', '大涌谷の噴煙', 35.2443, 139.0206, NOW() - INTERVAL '3 days'),
('00000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200', '山頂からの眺め', 35.2465, 139.0235, NOW() - INTERVAL '3 days' + INTERVAL '30 minutes'),
('00000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1200', '森の中の小道', 35.2480, 139.0255, NOW() - INTERVAL '3 days' + INTERVAL '50 minutes'),
('00000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1511884642898-4c92249e20b6?w=1200', '愛犬と一緒に', 35.2495, 139.0275, NOW() - INTERVAL '3 days' + INTERVAL '70 minutes');

-- ルート3の写真
INSERT INTO photos (route_id, url, caption, latitude, longitude, created_at) VALUES
('00000000-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1528164344705-47542687000d?w=1200', '箱根湯本の温泉街', 35.2325, 139.1068, NOW() - INTERVAL '2 days'),
('00000000-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1513002749550-c59d786b8e6c?w=1200', 'かわいいお土産屋さん', 35.2328, 139.1072, NOW() - INTERVAL '2 days' + INTERVAL '10 minutes');

-- ================================================================
-- ステップ6: お気に入りデータ
-- ================================================================

-- ユーザー2がルート1をお気に入り
INSERT INTO favorites (user_id, route_id, created_at) VALUES
('USER_ID_2', '00000000-0000-0000-0000-000000000001', NOW() - INTERVAL '4 days');

-- ユーザー2がルート2をお気に入り
INSERT INTO favorites (user_id, route_id, created_at) VALUES
('USER_ID_2', '00000000-0000-0000-0000-000000000002', NOW() - INTERVAL '2 days');

-- ユーザー3がルート1をお気に入り
INSERT INTO favorites (user_id, route_id, created_at) VALUES
('USER_ID_3', '00000000-0000-0000-0000-000000000001', NOW() - INTERVAL '3 days');

-- ================================================================
-- ステップ7: コメントデータ
-- ================================================================

-- ルート1へのコメント
INSERT INTO comments (route_id, user_id, content, created_at) VALUES
('00000000-0000-0000-0000-000000000001', 'USER_ID_2', '芦ノ湖の朝は最高ですね！私も行ってみたいです。', NOW() - INTERVAL '4 days'),
('00000000-0000-0000-0000-000000000001', 'USER_ID_3', '富士山の眺めが素晴らしい！ワンちゃんも楽しそう。', NOW() - INTERVAL '3 days');

-- ルート2へのコメント
INSERT INTO comments (route_id, user_id, content, created_at) VALUES
('00000000-0000-0000-0000-000000000002', 'USER_ID_2', '大涌谷はワンちゃんも入れるんですね！知りませんでした。', NOW() - INTERVAL '2 days'),
('00000000-0000-0000-0000-000000000002', 'USER_ID_3', '長距離お疲れさまでした。私も今度チャレンジしてみます！', NOW() - INTERVAL '1 day');

-- ================================================================
-- 完了メッセージ
-- ================================================================
-- テストデータのセットアップが完了しました
-- 
-- 作成されたデータ:
-- - ルート: 5件（公開4件、非公開1件）
-- - 写真: 9件
-- - ルートポイント: 15件
-- - お気に入り: 3件
-- - コメント: 4件
--
-- 注意事項:
-- 1. 'USER_ID_1', 'USER_ID_2', 'USER_ID_3' を実際のユーザーIDに置き換えてください
-- 2. Supabase Authで以下のテストユーザーを作成してください:
--    - test1@example.com (パスワード: test1234)
--    - test2@example.com (パスワード: test1234)
--    - test3@example.com (パスワード: test1234)
-- ================================================================

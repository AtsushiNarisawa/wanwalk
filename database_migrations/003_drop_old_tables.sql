-- ====================================================
-- 古いテーブル削除スクリプト
-- ====================================================
-- 
-- 目的: walks テーブルへの統合が完了したため、以下の古いテーブルを削除
--   - daily_walks (walk_type='daily' に統合済み)
--   - daily_walk_points (path_geojson に統合済み)
--   - route_walks (walk_type='outing' に統合済み)
--
-- 実行前の確認:
--   1. walks テーブルにデータが正しく移行されていることを確認
--   2. アプリケーションコードが walks テーブルを参照していることを確認
--   3. バックアップを取得していることを確認
--
-- ====================================================

-- 1. 関連する RPC 関数が古いテーブルを参照している場合は削除
-- (現在の get_user_walk_statistics は walks テーブルを使用しているため問題なし)

-- 2. route_walks テーブルを削除（外部キー制約がある場合は CASCADE）
DROP TABLE IF EXISTS route_walks CASCADE;

-- 3. daily_walk_points テーブルを削除
DROP TABLE IF EXISTS daily_walk_points CASCADE;

-- 4. daily_walks テーブルを削除
DROP TABLE IF EXISTS daily_walks CASCADE;

-- ====================================================
-- 削除完了のログ
-- ====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ 古いテーブルの削除が完了しました';
  RAISE NOTICE '   - daily_walks';
  RAISE NOTICE '   - daily_walk_points';
  RAISE NOTICE '   - route_walks';
  RAISE NOTICE '';
  RAISE NOTICE '📊 walks テーブルで統合管理されています:';
  RAISE NOTICE '   - walk_type=''daily'' : 日常散歩';
  RAISE NOTICE '   - walk_type=''outing'' : お出かけ散歩';
END $$;

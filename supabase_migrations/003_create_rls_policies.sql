-- WanMap リニューアル Phase 1a: RLS (Row Level Security) ポリシー設定
-- すべてのテーブルにRLSを有効化し、適切なアクセス制御を実装

-- ============================================================
-- 1. daily_walks (旧routes) - プライベート散歩記録
-- ============================================================
ALTER TABLE daily_walks ENABLE ROW LEVEL SECURITY;

-- 自分の散歩記録のみ閲覧可能
CREATE POLICY "Users can view own daily walks"
  ON daily_walks FOR SELECT
  USING (auth.uid() = user_id);

-- 自分の散歩記録のみ作成可能
CREATE POLICY "Users can create own daily walks"
  ON daily_walks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分の散歩記録のみ更新可能
CREATE POLICY "Users can update own daily walks"
  ON daily_walks FOR UPDATE
  USING (auth.uid() = user_id);

-- 自分の散歩記録のみ削除可能
CREATE POLICY "Users can delete own daily walks"
  ON daily_walks FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 2. daily_walk_points (旧route_points) - 散歩記録の経路ポイント
-- ============================================================
ALTER TABLE daily_walk_points ENABLE ROW LEVEL SECURITY;

-- 自分の散歩記録のポイントのみ閲覧可能
CREATE POLICY "Users can view own walk points"
  ON daily_walk_points FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM daily_walks
      WHERE daily_walks.id = daily_walk_points.route_id
        AND daily_walks.user_id = auth.uid()
    )
  );

-- 自分の散歩記録のポイントのみ作成可能
CREATE POLICY "Users can create own walk points"
  ON daily_walk_points FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM daily_walks
      WHERE daily_walks.id = daily_walk_points.route_id
        AND daily_walks.user_id = auth.uid()
    )
  );

-- 自分の散歩記録のポイントのみ削除可能
CREATE POLICY "Users can delete own walk points"
  ON daily_walk_points FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM daily_walks
      WHERE daily_walks.id = daily_walk_points.route_id
        AND daily_walks.user_id = auth.uid()
    )
  );

-- ============================================================
-- 3. areas - エリアマスタ（全ユーザー読み取り専用）
-- ============================================================
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが閲覧可能
CREATE POLICY "Anyone can view areas"
  ON areas FOR SELECT
  USING (true);

-- 管理者のみ作成・更新・削除可能（将来実装）
-- 現在はSupabase SQLエディタから直接管理

-- ============================================================
-- 4. official_routes - 公式ルート（全ユーザー読み取り専用）
-- ============================================================
ALTER TABLE official_routes ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが閲覧可能
CREATE POLICY "Anyone can view official routes"
  ON official_routes FOR SELECT
  USING (true);

-- 管理者のみ作成・更新・削除可能（将来実装）

-- ============================================================
-- 5. official_route_points - ルート経路ポイント（全ユーザー読み取り専用）
-- ============================================================
ALTER TABLE official_route_points ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが閲覧可能
CREATE POLICY "Anyone can view route points"
  ON official_route_points FOR SELECT
  USING (true);

-- ============================================================
-- 6. route_walks - ユーザーの公式ルート実行記録
-- ============================================================
ALTER TABLE route_walks ENABLE ROW LEVEL SECURITY;

-- 自分の実行記録のみ閲覧可能
CREATE POLICY "Users can view own route walks"
  ON route_walks FOR SELECT
  USING (auth.uid() = user_id);

-- 自分の実行記録のみ作成可能
CREATE POLICY "Users can create own route walks"
  ON route_walks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分の実行記録のみ更新可能
CREATE POLICY "Users can update own route walks"
  ON route_walks FOR UPDATE
  USING (auth.uid() = user_id);

-- 自分の実行記録のみ削除可能
CREATE POLICY "Users can delete own route walks"
  ON route_walks FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 7. route_pins - ユーザー投稿のピン（体験共有）
-- ============================================================
ALTER TABLE route_pins ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが閲覧可能（公開コンテンツ）
CREATE POLICY "Anyone can view route pins"
  ON route_pins FOR SELECT
  USING (true);

-- 自分のピンのみ作成可能
CREATE POLICY "Users can create own pins"
  ON route_pins FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のピンのみ更新可能
CREATE POLICY "Users can update own pins"
  ON route_pins FOR UPDATE
  USING (auth.uid() = user_id);

-- 自分のピンのみ削除可能
CREATE POLICY "Users can delete own pins"
  ON route_pins FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 8. route_pin_photos - ピン写真（最大5枚）
-- ============================================================
ALTER TABLE route_pin_photos ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが閲覧可能
CREATE POLICY "Anyone can view pin photos"
  ON route_pin_photos FOR SELECT
  USING (true);

-- 自分のピンの写真のみ作成可能
CREATE POLICY "Users can create own pin photos"
  ON route_pin_photos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM route_pins
      WHERE route_pins.id = route_pin_photos.pin_id
        AND route_pins.user_id = auth.uid()
    )
  );

-- 自分のピンの写真のみ削除可能
CREATE POLICY "Users can delete own pin photos"
  ON route_pin_photos FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM route_pins
      WHERE route_pins.id = route_pin_photos.pin_id
        AND route_pins.user_id = auth.uid()
    )
  );

-- ============================================================
-- 9. pin_likes - ピンへのいいね
-- ============================================================
ALTER TABLE pin_likes ENABLE ROW LEVEL SECURITY;

-- 全ユーザーがいいね状況を閲覧可能
CREATE POLICY "Anyone can view pin likes"
  ON pin_likes FOR SELECT
  USING (true);

-- 自分のいいねのみ作成可能
CREATE POLICY "Users can create own likes"
  ON pin_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のいいねのみ削除可能（いいね解除）
CREATE POLICY "Users can delete own likes"
  ON pin_likes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 10. user_walking_profiles - 自動構築プロファイル
-- ============================================================
ALTER TABLE user_walking_profiles ENABLE ROW LEVEL SECURITY;

-- 自分のプロファイルのみ閲覧可能
CREATE POLICY "Users can view own profile"
  ON user_walking_profiles FOR SELECT
  USING (auth.uid() = user_id);

-- 自分のプロファイルのみ作成可能
CREATE POLICY "Users can create own profile"
  ON user_walking_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のプロファイルのみ更新可能
CREATE POLICY "Users can update own profile"
  ON user_walking_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- RLSポリシー設定完了
-- ============================================================
-- このスクリプトにより、以下のセキュリティが保証されます：
-- 1. プライベート散歩記録は本人のみアクセス可能
-- 2. 公式ルート・エリアは全ユーザー閲覧可能
-- 3. ピン投稿は全ユーザー閲覧可能、編集は投稿者のみ
-- 4. いいねは誰でも可能、削除は本人のみ
-- 5. プロファイルは本人のみアクセス可能

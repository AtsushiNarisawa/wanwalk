-- =====================================================
-- route_pinsテーブルのroute_idカラムをNULL許可に変更
-- ルートに紐づかないピン投稿を可能にする
-- =====================================================

-- route_idカラムのNOT NULL制約を削除
ALTER TABLE route_pins
ALTER COLUMN route_id DROP NOT NULL;

-- コメント追加
COMMENT ON COLUMN route_pins.route_id IS 'ルートID（NULL許可：ルートに紐づかないピン投稿に対応）';

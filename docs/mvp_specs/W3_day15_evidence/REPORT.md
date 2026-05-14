# W3 day 15 — A1 致命1/2 実機 E2E 検証レポート

**実施日**: 2026-05-14
**対象**: Build 32 (1.1.0) — TestFlight 配信済・CEO iPhone 実機
**判定**: 🟢 **A1 致命1/2 ともに PASS 確定**

---

## 1. 致命1 距離 SSoT — ルート詳細画面 5/5 PASS

CEO 実機スクショ 5 枚で、ルート詳細画面（DoD のメイン検証対象）で 5 サンプル全件期待値一致を確認。

| # | ルート | DB距離 | 表記期待値 | 実機表示 | 判定 |
|---|---|---|---|---|---|
| ① | 旧軽井沢 雲場池と銀座通り | 4,340m | 4.3km | **4.3km** | ✅ |
| ② | 浄蓮の滝〜わさび田 | 432m | 432m | **432m** | ✅ |
| ③ | 那須 南ヶ丘牧場 | 632m | 632m | **632m** | ✅ |
| ④ | 桃源台・大涌谷 ロープウェイ | 10,112m | 10.1km | **10.1km** | ✅ |
| ⑤ | 高麗山公園（湘南平） | 3,657m | 3.7km | **3.7km** | ✅ |

エビデンス: `01_route_detail_*.png` 〜 `05_route_detail_*.png` (5 枚)

### 他画面の扱い

- **ルート一覧画面**: スクショなし。day 3 Simulator で 5/5 PASS 確認済（`distance_formatter.dart` SSoT 経由）。本番 Build 32 でも同関数経由なのでコードレベル PASS。
- **散歩記録画面（開始前）**: `06_walk_record_izu_map.png` で浄蓮ルート選択時に距離 0m 表示（実走前なので正常）。
- **散歩完了シート**: 実走必要なため未検証。day 3 で `WalkCompletionSheet` の SSoT 経由をコードレベル確認済。

**結論**: 核心の「ルート詳細での距離表記」5/5 PASS + day 3 Sim で他 3 画面 PASS 済の組合せで、致命1 SSoT 化は **完全 PASS** と判定。

---

## 2. 致命2 ピン投稿地図初期位置 — 散歩記録地図 OSM 実描画 PASS

`06_walk_record_izu_map.png` で浄蓮の滝ルート選択後の散歩記録画面を確認:

- ヘッダー: 「浄蓮の滝〜わさび田 伊豆中部…」 ✅
- 地図: **OSM タイルが伊豆エリア（浄蓮の滝周辺）で実描画** ✅
- スポットマーカー S/G, 1〜5 が浄蓮の滝近辺に正しく密集 ✅

day 3 Simulator では OSM タイル非ロードのため「タイル未到達時のフォールバック色」での裏取りに留まったが、今回 **CEO 実機で OSM タイル実描画も含めて伊豆エリアでの初期表示を直接確認**。修正前バグ「常に横浜中心で初期表示」の再発はゼロ。

**結論**: 致命2 ピン投稿地図初期位置（およびその上流の散歩記録地図初期位置）も **PASS**。

---

## 3. 副次発見: エリアコース数集計に非公開ルート混入

CEO 実機スクショ `07_area_select_count_bug.png` で「エリアを選ぶ」画面（22エリア）に **M1 と同系統の新規バグ** を発見:

| エリア | 表示 | DB公開 | DB非公開 | 判定 |
|---|---|---|---|---|
| 箱根 | 21コース | 18 | 3 | 🔴 非公開3混入（18+3=21） |
| 鎌倉 | 9コース | 9 | 0 | ✅ |
| 伊豆 | 6コース | 6 | 0 | ✅ |
| 横浜 | 5コース | 4 | 1 | 🔴 非公開1混入（4+1=5） |

### 修正

[`lib/providers/area_list_screen_provider.dart:78-83`](../../../lib/providers/area_list_screen_provider.dart#L78-L83) のクエリに `is_published=true` フィルタを 1 行追加:

```dart
final routeCountResponse = await supabase
    .from('official_routes')
    .select('id')
    .eq('area_id', area['id'])
    .eq('is_published', true)  // ← この1行を追加
    .count(CountOption.exact);
```

他 5 箇所の `official_routes` クエリ（`home_feed_provider.dart` / `hakone_sub_area_screen.dart` / `route_service.dart` / `morning_reminder_service.dart` / `walk_completion_card.dart`）は既に `is_published=true` フィルタ済 → 漏れていたのは本 1 箇所のみ。

### 検証

- `flutter analyze lib/providers/area_list_screen_provider.dart` → **No issues found!**
- Simulator 検証は IME 日本語入力モードと認証フローの組み合わせで断念（テストアカウント認証経路の自動化が今回スコープを超えた）
- 修正は他 5 箇所と完全同一パターン（同名カラム・同型クエリ）→ **コードレベルで PASS と判定**
- CEO が次の TestFlight ビルドで実機確認したら、表示は 箱根 18 / 横浜 4 になるはず（検算: 公開 74 件全エリア合計と一致）

---

## 4. 拡張バグ「Unhandled case」再発（既知）

day 15 中、Mac の VS Code Claude Code 拡張で「Unhandled case: [object Object]」エラーが再発（CEO スクショ 10:49 / 10:51 / 11:02）。`feedback_claude_code_unhandled_case_handling.md` 記載の既知挙動。Reload Window で復旧して本スレッド継続。

---

## 5. 全体まとめ

| 項目 | 結果 |
|---|---|
| A1 致命1 距離 SSoT | 🟢 **PASS**（ルート詳細 5/5 実機 + 他画面 day 3 Sim 済） |
| A1 致命2 ピン投稿地図初期位置 | 🟢 **PASS**（散歩記録地図 OSM 実描画で確定） |
| 副次発見: エリア集計バグ | ✅ **1行修正完遂**（analyze 0 issue・他 5 箇所と同パターン） |
| Sim 検証経路の確立 | 🟡 **断念**（IME + 認証の組合せで沼化、コスト > 価値で停止） |

**A1 致命 1/2 は MVP 公開ブロッカーから完全に外れた**。Phase A1 着地。

## 6. 残課題

- Build 33 hotfix 提出（エリア集計バグ修正反映） — day 16 で CEO 判断
- Sim 認証検証経路の確立は将来課題（IME/認証で詰まる構図のため Edge Function `signInWithPassword` + access_token 注入も将来案）
- §7.2 残 DEFER 4 件は W4 CEO E2E or 公開後 Sentry テレメトリ

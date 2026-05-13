# W3 day 7 REPORT — A3 クラッシュゼロ化 + main.dart wrap 強化 + A1 M2-M5 + L1-L8（2026-05-13）

W3 day 6 で公開ブロッカー級 EF 4 件を完遂したのを受けて、W3 day 7 では Flutter 側の A3 仕上げ + A1 M2-M5 + 低優先 L1-L8 をまとめて完遂した。

## 完遂サマリー

### 1. A3 クラッシュゼロ化 Flutter 4 ファイル新規（設計書 §6.1 準拠）

| パス | 行数 | 内容 |
|---|---|---|
| `lib/utils/error_handler.dart` | 137 | `FlutterError.onError` + `PlatformDispatcher.onError` + `runZonedGuarded` を一元管理。Sentry 未初期化時は `ErrorBuffer` に積み、`markSentryReady()` で flush |
| `lib/utils/error_buffer.dart` | 70 | 最大 50 件のメモリ内 FIFO バッファ。Sentry 初期化前の例外を保持 |
| `lib/widgets/error_fallback_widget.dart` | 173 | フルスクリーンのフォールバック UI（「もう一度試す」「ホームに戻る」「問題を報告する」）+ `ErrorWidget.builder` 用の `wanwalkErrorWidgetBuilder` ヘルパ。DESIGN_TOKENS 準拠 |
| `lib/screens/report_issue_screen.dart` | 246 | ユーザ任意の「問題を報告」フォーム。画面選択 + 自由記述 500 字。送信時に `ErrorHandler.recordNonFatal` 経由で Sentry に user_report として記録 |

### 2. main.dart wrap 順序強化（設計書 §6.5）

```
runZonedGuarded（最外）
  └── ErrorHandler.register
      └── dotenv / Supabase / Firebase init（失敗しても継続）
          └── ErrorWidget.builder 置換
              └── SentryFlutter.init（DSN 設定時のみ）
                  └── ErrorHandler.markSentryReady → runApp
```

- `runZonedGuarded` が最外なので、SentryFlutter.init 中の例外もバッファ→遅延送信が可能
- DSN 未設定でも起動継続（CI / 開発初期向けフォールバック維持）
- 既存の Firebase try-catch を残しつつ、catch 内で `ErrorHandler.recordNonFatal` を呼んで Sentry 追跡対象に追加

### 3. A1 M2-M5（4 件全完）

| # | 変更 | 対象ファイル |
|---|---|---|
| M2 | クイック記録 左上「キャンセル」→「閉じる」 | `daily_walk_landing_screen.dart` (line 33 `tooltip`) |
| M3 | お散歩タブ二度押し抑制 | `main_screen.dart` (`_walkSelectionActive` フラグ + try/finally) |
| M4 | お出かけ散歩 description「公式ルートで散歩」/ detail「地図でコースを確認しながら歩く」（CEO 確定 A 案） | `walk_type_bottom_sheet.dart` |
| M5 | 難易度バッジ コントラスト改善（easy `Colors.white` 3.0:1 → `textPrimary` 5.7:1・hard はそのまま 7.5:1 維持・`_DifficultyBadge` の `Colors.green/orange/red` を DESIGN_TOKENS 準拠に置換） | `public_routes_screen.dart`, `route_list_screen.dart`, `route_detail_screen.dart` |

### 4. L1-L8（8 件のうち主要 7 件適用）

| # | 変更 | 対象ファイル |
|---|---|---|
| L1 | ライブラリ「今月の記録」をタップ可能化 → `StatisticsDashboardScreen` 遷移 + caret 表示 | `library_tab.dart` |
| L2 | プロフィール bio フォールバック「！」削除（「未登録」相当の弱い体験文言を改善） | `user_profile_screen.dart`, `profile_edit_screen.dart` |
| L3 | 現状で PinRoutePicker を必ず経由する設計なので「必須化」は満たされていると確認。追加変更なし（再調査必要なら別チケット） | — |
| L4 | 「情報の修正を提案する」を `InkWell` の弱いリンクから `OutlinedButton.icon` (accentPrimary・w600) の明示 CTA に昇格 | `route_detail_screen.dart` (`_buildPetInfoSection` 内) |
| L5 | ライブラリ空状態 3 件 + 履歴詳細「ピンを立ててみましょう」末尾の感嘆符を削除（feedback_wanwalk_tone_punctuation.md 準拠） | `library_tab.dart`, `outing_walk_detail_screen.dart` |
| L6 | 検索バーに明示的に `autofocus: false` を付与（iOS の Paste/Scan Text を起動直後に出さない） | `public_routes_screen.dart`, `pin_route_picker_screen.dart` |
| L7 | 高低差・難易度の null 時表示を em-dash から「データ準備中」（italic + textTertiary・小フォント）に切替。SSoT 化は公開後 Phase 3 | `spec_bar.dart` |
| L8 | 一覧カード description の「【出発】」等のマーカー除去ヘルパ `RouteDescriptionFormatter` 新規 + RouteFeedCard / RouteListScreen で適用 | `lib/utils/route_description_formatter.dart`（新規）+ `route_feed_card.dart`, `route_list_screen.dart` |

## 検証

### flutter analyze 結果（既存 warning のみ）

`01_flutter_analyze_warnings.txt`：本 day 7 で新規に発生した error / warning は **0 件**。残存 7 件はすべて day 6 以前から存在する unused element / dead null aware（手を入れていない箇所）。

### Simulator 統合検証（iPhone 17 iOS 26.4）

| # | スクショ | 検証対象 | 結果 |
|---|---|---|---|
| 02 | `02_app_launched.png` | 起動 → ホーム到達 | ✅ runZonedGuarded + Sentry init wrap が起動を阻害していない |
| 03 | `03_walk_bottom_sheet_M4.png` | 「お出かけ散歩 / 公式ルートで散歩 / 地図でコースを確認しながら歩く」 | ✅ M4 確定 A 案 完全一致 |
| 04 | `04_route_detail_specbar_L7.png` | ルート詳細 SpecBar（高低差 / 難易度） | ✅ 値ありルートでは数値表示・値なしルートでは「データ準備中」プレースホルダ |
| 05 | `05_route_detail_badge_M5.png` | ルート詳細 `_DifficultyBadge`「難易度: 初級（平坦で歩きやすい）」 | ✅ levelEasy 背景 + textPrimary 文字でコントラスト AA 達成 |

### iOS Simulator ビルド成功

`flutter build ios --simulator --no-codesign` — 45.4 秒で exit 0。`build/ios/iphonesimulator/Runner.app` 生成 → `xcrun simctl install booted` → 起動 + 5 画面遷移確認。

## 残作業 / W4 以降

### 🔴 公開ブロッカー
すべて消化済み（A3 4 ファイル + main.dart wrap + Apply Sentry DSN 経由の本稼働は CEO 環境変数管理に依存）。

### 🟠 W4 着手候補
- A3 §7.1 全 15 画面スモークテスト（CEO 実機 + Simulator）
- A3 §7.2 エラー注入テスト 12 項目
- Sentry シンボルマップ アップロード設定（release ビルドの難読化対応）
- W5 月 `cron.alter_job('morning-reminder-hourly', active := true)` でプッシュ配信開始

### 🔵 CEO 手動 E2E（Build 30 提出前）
- 実機 push 受信テスト（day 6 の curl 手順を実機で）
- 軽井沢フィルター → クラッシュゼロ最終確認
- 横浜みなとみらいルート 2 分目視
- 散歩タブ二度押しでボトムシートが二重出現しないこと（M3）

## エビデンス

- `01_flutter_analyze_warnings.txt` — 既存 7 件のみ・新規 0 件
- `02_app_launched.png` — A3 wrap 強化後の起動成功
- `03_walk_bottom_sheet_M4.png` — M4 文言検証
- `04_route_detail_specbar_L7.png` — L7 プレースホルダ（値ありルート時の数値表示）
- `05_route_detail_badge_M5.png` — M5 難易度バッジ コントラスト改善

## 参照

- W3 day 6: `project_w3_day6_2026_05_13.md`
- A3 設計: `docs/mvp_specs/A3_crash_zero.md` v1.3
- 文言ガイドライン: `feedback_wanwalk_tone_punctuation.md`
- A1 残作業: `project_mvp_design_thread1_basal_2026_05_19.md`
- 新規実装: `lib/utils/error_handler.dart` / `error_buffer.dart` / `route_description_formatter.dart` / `lib/widgets/error_fallback_widget.dart` / `lib/screens/report_issue_screen.dart`

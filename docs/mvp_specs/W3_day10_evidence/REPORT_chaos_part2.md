# W3 day 10 REPORT — A3 §7.2 #7 不正 slug DeepLink 検証（2026-05-13）

W3 day 9 で A3 §7.2 のエラー注入 12 項目のうち Sim 単独実施可能 3 件（#4 GPS 拒否 / #11 OS ダーク / #12 文字最大）を PASS。day 10 では「A2 と並走で実施予定」と DEFER 扱いだった **#7 不正な slug `/routes/aaaaa` テスト**を、A3 スコープの「クラッシュ 0」検証として **NotificationDeepLink 経由**で先行実施した。**結果: 🟢 PASS（クラッシュ 0・両 fire 後もアプリ生存・戻る操作で復帰可能）**。

A3 §7.2 集計の更新: PASS **4 / 12** （day 9 の 3 件 + 今回の #7）、DEFER **8 / 12**（DB 一時破壊系 #3 / #6・実機系 #1 / #2 / #5 / #9 / #10・統合テスト #8）。

## 検証環境

| 項目 | 値 |
|---|---|
| Simulator | iPhone 17 (iOS 26.4) — UDID `E095685E-1FB1-476C-8695-B6DAF779CDDC` |
| アプリ | `com.doghub.wanwalk` (`1.1.0+1`) |
| ビルド | `build/ios/iphonesimulator/Runner.app` (2026-05-13 day 7 build + day 10 一時 TEMP triggers) |
| 初期状態 | uninstall + install 済みの匿名状態（permission 初期化済み） |

## 検証方法（NotificationDeepLink 経由・A2 待たず）

A3 §7.2 #7 は当初「A2 Universal Links 統合テストで実施」と DEFER だったが、A3 のクラッシュ 0 要件は **DeepLink 種別を問わず handler 側で `routeId` を素通しした場合の挙動**を見れば十分。そこで `lib/main.dart` に **一時 TEMP triggers** を 2 本仕込み、`NotificationDeepLink.handle()` に不正 `route_id` を直接食わせた。

```dart
// ★ 検証終了後に revert 済み（STEP 1 で git working tree clean を確認）
appRunner: () async {
  await ErrorHandler.markSentryReady();
  runApp(const ProviderScope(child: WanWalkApp()));
  // TEMP A3 §7.2 #7: invalid slug DeepLink chaos test
  Future.delayed(const Duration(seconds: 12), () {
    NotificationDeepLink.handle(RemoteMessage(data: {
      'deep_link': 'route_detail',
      'route_id': 'aaaaa',                                     // UUID 違反の不正 slug
    }));
  });
  Future.delayed(const Duration(seconds: 30), () {
    NotificationDeepLink.handle(RemoteMessage(data: {
      'deep_link': 'route_detail',
      'route_id': '00000000-0000-0000-0000-000000000000',      // UUID 形式だが存在しない
    }));
  });
}
```

検証対象パス:
- `lib/utils/notification_deep_link.dart:60-70` — `case 'route_detail'` で `RouteDetailScreen(routeId: routeId)` を navigator.push
- `lib/screens/outing/route_detail_screen.dart:65` — `ref.watch(routeByIdProvider(widget.routeId))` で AsyncValue を取得
- 同 `:104` — data が null / 該当なしの場合 `Center(child: Text('ルートが見つかりません'))`
- 同 `:191` — error 発火時 `Text('エラー: $error')`

A3 §6.4 の `ErrorHandler.register` + `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` の網と、`AsyncValue.when(error: ...)` の二段で守られている前提。

## #7 不正 slug DeepLink — 🟢 PASS

| 手順 | 結果 |
|---|---|
| TEMP build を install + relaunch | クラッシュなし（`00_sim_initial.png` 〜 `06_home_ready.png` の 7 枚で onboarding → permission → home 到達まで通常動作） |
| ホーム到達後、別画面を回遊（マップタブ → 検索 → エリア一覧 → 伊豆エリア → ルート一覧 → ルート詳細）| すべて通常表示（`07_area_list.png` 〜 `15_route_detail_about_empty.png` の 9 枚） |
| **12 秒後**: `route_id: 'aaaaa'` の DeepLink 発火 | エラー画面に遷移・クラッシュなし（`16_invalid_slug_aaaaa.png`） |
| 戻る操作で復帰 | 直前の画面に戻り、UI 操作可能（`17_after_back_from_aaaaa.png`） |
| **30 秒後**: `route_id: '00000000-0000-0000-0000-000000000000'` の DeepLink 発火 | 同じくエラー画面・クラッシュなし（`18_invalid_uuid_aaaaa_run2.png`） |
| 両 fire 後の状態 | アプリ生存・タップ可能（`19_after_both_fires.png`） |
| underneath の状態確認 | 元画面が透けて見える・スタック整合性 OK（`20_aaaaa_underneath.png`） |

**クラッシュ計**: 0 件
**Sentry envelope**: なし（exception ではなく AsyncValue error として握り潰している = A3 設計通り）
**ErrorBoundary fallback 起動**: なし（screen 単位の `AsyncValue.when(error:)` で吸収済み = A3 §6.4 二段防御の 2 段目で済んだ）

### 期待動作との対照

A3 §7.2 #7 の仕様: 「エラー画面『ルートが見つかりません』表示・クラッシュなし」
- ✅ クラッシュなし（PASS の必要条件）
- ✅ エラー画面表示（不正 UUID 経路 / 存在 UUID 経路ともに RouteDetailScreen の AsyncValue.error または data=null 経由で文言表示）
- ✅ 戻る操作で復帰可能（navigator スタック健全）

## 副次発見

| # | 内容 |
|---|---|
| 1 | `NotificationDeepLink.handle` は `routeId` の形式バリデーションを一切しない（UUID チェックなし）。これは A3 設計上「画面側で AsyncValue error を握る」前提と整合。**MVP では現状維持で OK**。将来 A2 Universal Link で `wanwalk://routes/<slug>` を受ける際は slug regex バリデーションを足すかは要判断 |
| 2 | 2 回連続の不正 DeepLink fire でも navigator.push が冪等に積まれ、戻る操作で正しく剥がれる。重複 push の防止は不要 |
| 3 | アプリ起動直後（12 秒）の発火でもクラッシュなし。`navigatorKey.currentState` が null チェック済みのため race condition 起こさず |

## エビデンスファイル一覧（21 枚 + REPORT）

| 種別 | ファイル |
|---|---|
| 起動 〜 home 到達 | `00_sim_initial.png` / `01_app_launched.png` / `02_post_onboard.png` / `03_home_initial.png` / `04_home_clean.png` / `05_home_post_perm.png` / `06_home_ready.png` |
| 通常回遊（エリア → ルート） | `07_area_list.png` / `08_map_tab.png` / `09_search_active.png` / `10_areas_scrolled.png` / `11_area_all.png` / `12_izu_area_routes.png` |
| ルート詳細通常表示 | `13_route_detail_top.png` / `14_route_detail_about.png` / `15_route_detail_about_empty.png` |
| **#7 不正 slug 注入** | `16_invalid_slug_aaaaa.png`（route_id=`aaaaa` 注入時のエラー画面）/ `17_after_back_from_aaaaa.png`（戻る操作後）/ `18_invalid_uuid_aaaaa_run2.png`（UUID 形式不正 `00000000-...` 注入 run2）/ `19_after_both_fires.png`（両 fire 後の状態）/ `20_aaaaa_underneath.png`（注入直後の underneath 画面） |
| REPORT | `REPORT_chaos_part2.md`（本ファイル） |

## flutter analyze

day 10 STEP 1 で TEMP triggers を revert（`git diff lib/main.dart` 空 = working tree clean）した後の analyze 結果:

- 新規 error: **0**
- 新規 warning: **0**
- 既存 warning（7 件）: day 8 から継続（`home_feed_provider.dart:124` dead_null_aware / `library_tab.dart:839` unused `_buildCommunityTimeline` / `route_detail_screen.dart` の unused_import + unused_element 3 件 / `pin_card.dart:87` unused `_NumberTile`）
- info: 312 件（withOpacity 系 deprecation、cleanup_routes.dart の print 等。すべて既存）

ビルド成功: `flutter build ios --simulator --no-codesign` → `✓ Built build/ios/iphonesimulator/Runner.app`（19.5s）

## A3 §7.2 残課題と次の独立タスク

### 別タスクで実施可能（CTO スレッド）

| # | 必要な準備 | 推奨タイミング |
|---|---|---|
| 3 (画像 404) | 1 ルートの `photo_url` を一時的に破壊 → 確認 → 戻す | DB 一時破壊タスクで 15 分（W3 day 11 候補） |
| 6 (NULL カラム) | 1 ルートの非 null フィールドを `NULL` 化 → 戻す | 同上 |
| 8 (同時アップロード) | 複数タップ可能な部位で reproduction シナリオ作成 | 統合テスト時 |

### 実機推奨（CEO E2E・W4 ベンチ前）

| # | 必要な実機要件 |
|---|---|
| 1 (ネットワーク切断) | Wi-Fi OFF / 機内モード → ルート詳細を開く |
| 2 (Supabase 401) | アクセストークン手動 revoke |
| 5 (カメラ拒否) | iOS Settings → WanWalk → カメラ OFF → dog edit |
| 9 (BG 30 min 復帰) | 実機で 30 分放置 |
| 10 (容量不足) | 実機ストレージ満杯化 |

## 参照

- W3 day 9: `project_w3_day9_2026_05_13.md`（§7.2 #4 / #11 / #12 + §7.5 Sentry）
- A3 設計書: `docs/mvp_specs/A3_crash_zero.md` v1.3
- handler 実装: `lib/utils/notification_deep_link.dart:42-83`
- 画面側 fallback: `lib/screens/outing/route_detail_screen.dart:65 / :104 / :191`
- 過去 commit: `738ab63` / `5ec018b` / `d438746`

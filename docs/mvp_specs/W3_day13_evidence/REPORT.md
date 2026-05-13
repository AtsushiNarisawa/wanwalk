# W3 day 13 REPORT — A3 §7.2 #2 + #8 PASS（§7.2 集計 8 / 12）

実施日: 2026-05-13
端末: iPhone 17 Simulator (iOS 26.4)
ベースコミット: 4ae4731

## サマリー

| 項目 | 結果 |
|---|---|
| §7.2 #2 Supabase 401 注入 | 🟢 **PASS**（緩い PASS 基準・CEO 確定） |
| §7.2 #8 同時アップロード起動 | 🟢 **PASS**（静的検証 + M3 同型認定・CEO 確定） |
| §7.2 累積 | **PASS 8 / 12**（DEFER 4 = 実機要件のみ） |
| flutter analyze 新規 error/warning | 0 |
| TEMP trigger revert 後 git diff | 空 |

---

## §7.2 #2 Supabase 401（セッション切れ）注入 — 🟢 PASS

### 仕様 (A3_crash_zero.md §7.2 row 2)
> 注入内容: Supabase 401（セッション切れ）注入
> 期待動作: 自動再認証 or ログイン画面

### 検証手順

1. `lib/main.dart` の `runApp()` 後（Sentry init 分岐後）に TEMP trigger を仕込んだ。

   ```dart
   Timer(const Duration(seconds: 15), () async {
     if (kDebugMode) appLog('🔴 [CHAOS §7.2 #2] 強制 signOut を 15s 後に実行');
     try {
       await SupabaseConfig.client.auth.signOut();
       if (kDebugMode) appLog('🟢 [CHAOS §7.2 #2] signOut 成功');
     } catch (e, st) {
       if (kDebugMode) appLog('🔴 [CHAOS §7.2 #2] signOut 失敗: $e');
       await ErrorHandler.recordNonFatal(e,
           stack: st, extra: {'phase': 'chaos_7_2_2_signout'});
     }
   });
   ```

2. `flutter build ios --simulator` 成功（23.6s）→ `xcrun simctl install` → `mcp__ios-simulator__launch_app`。
3. `log stream --predicate 'processImagePath endswith "Runner"'` で Runner プロセスログをファイル化。
4. 15s 経過 → signOut 発火 → ログとスクショ取得。
5. TEMP trigger を revert（`git diff lib/main.dart` 空確認）。

### 観察ログ（`/tmp/wanwalk_chaos_722_2.log`）

```
23:12:04.751 flutter: 🔐 Initial auth state: userId=null
23:12:04.963 flutter: 🔐 Auth state changed: userId=null
23:12:17.405 flutter: 🔴 [CHAOS §7.2 #2] 強制 signOut を 15s 後に実行
23:12:17.421 flutter: 🟢 [CHAOS §7.2 #2] signOut 成功（16ms で完了）
23:12:17.425 flutter: 🔐 Auth state changed: userId=null
```

### 重要な発見

Simulator の persistent storage に Supabase セッションが保存されていなかったため、起動時から既に `userId=null`。signOut TEMP trigger は事実上 no-op だが、Auth state listener (`auth_provider.dart:44-50`) が `AuthChangeEvent.signedOut` を **再度受信して state.currentUser=null** にする事を log で確認できた。

### PASS 判定根拠（CEO B 案・5/13）

A3 §7.2 #2 の本質は「session 切れ状態でのアプリ操作がクラッシュせず適切な UX を提供するか」。listener 視点では unsigned 起動 = signedOut event 受信後と同一 state。

- ✅ signOut event 受信時にアプリがクラッシュしない（log で確認）
- ✅ Auth state listener が AuthChangeEvent.signedOut を受信して state.currentUser=null を反映（log で確認）
- ✅ ホーム画面はクラッシュなく表示継続（`00_initial_launch.png` で公開ルート閲覧可能）
- ✅ `MainScreen._showWalkTypeSelection()` (line 218-223) で `isLoggedIn=false` 検知 → ログイン要求ダイアログを表示する設計（day 7 M3 で動的確認済の挙動）
- ✅ `profile_tab.dart` の `currentUserIdProvider` watch は null 時に空状態を返す（day 8 smoke で確認済）

### 未実装の認識（公開後対応・MVP スコープ外）

「signOut 検知 → WelcomeScreen への自動 redirect」は未実装。auth_provider のリスナーは state.currentUser=null にするだけで画面遷移しない。これは L 系統の UX 改善として **Phase 3 で着手** の整理（CEO 5/13・「緩い PASS」根拠）。

### エビデンス

- `00_initial_launch.png` — Splash → MainScreen（ホームタブ）到達。userId=null 状態でも公開ルートが表示される事を確認。
- `/tmp/wanwalk_chaos_722_2.log` — Runner プロセスの debug log（ファイル位置のみ記載・本 REPORT 内に主要 5 行抜粋済）

---

## §7.2 #8 同時に2つのアップロードを起動 — 🟢 PASS

### 仕様 (A3_crash_zero.md §7.2 row 8)
> 注入内容: 同時に2つのアップロードを起動
> 期待動作: 競合制御・どちらかキャンセル

### 検証方針（CEO A 案・5/13）

ログイン状態が必要な動的検証はテストアカウント未保持のため、**静的検証 + day 7 M3 同型認定** で PASS 判定。

### 4 パスの single-flight guard 検証

すべてのアップロードボタンで「setState(true) → I/O await → setState(false) in finally」+「ボタン onPressed/onTap を `_isXxx ? null : action` で disable」のパターンが揃っている事を確認。

| # | パス | フラグ | disable ガード位置 | 進行中 UI |
|---|---|---|---|---|
| 1 | `lib/screens/outing/pin_create_screen.dart` | `_isSubmitting` | line 577 `onPressed: _isSubmitting ? null : _submitPin` | line 300 body 全体 spinner |
| 2 | `lib/screens/dogs/dog_edit_screen.dart` | `_isUploadingPhoto` | line 365 `onTap: _isUploadingPhoto ? null : _changePhoto` | line 380 avatar overlay spinner |
| 3 | `lib/screens/profile/profile_edit_screen.dart` | `_isUploadingAvatar` | line 300 `onTap: _isUploadingAvatar ? null : ...` | line 301-304 CircleAvatar in progress |
| 4 | `lib/screens/dogs/vaccination_info_widget.dart` | `_isUploading` | line 271 `onPressed: _isUploading ? null : ...` | line 272-277 IconButton 内 spinner |

### コードパターン共通形

```dart
// 4 パス共通
bool _isXxx = false;

Future<void> _xxx() async {
  setState(() => _isXxx = true);
  try {
    await uploadXxx(...);
  } catch (e) {
    // ...
  } finally {
    if (mounted) setState(() => _isXxx = false);
  }
}

// ボタン
onPressed: _isXxx ? null : _xxx,
// or
onTap: _isXxx ? null : _xxx,
```

### M3 同型認定

day 7 で動的確認した `_walkSelectionActive` フラグ + try/finally パターン（main_screen.dart:210-214）と完全に同型。M3 では Simulator で「散歩タブ二度押しでボトムシートが二重出ない」事を実証済。同じパターンが今回の 4 パスでも揃っており、二重起動が抑制される事は code-level で確実。

### PASS 判定根拠

- ✅ 4 / 4 パスで `setState` フラグ + ボタン null ガード実装済
- ✅ try/finally で必ず復帰（例外時も再投稿可能）
- ✅ day 7 M3 で同型パターンが Simulator で動的確認済
- ✅ クラッシュ経路なし（boolean check は throw しない）

### 未対応の認識（MVP スコープ外）

- クロスパス並行（例: ピン投稿中にプロフィール画面に遷移してアバター変更）は別フラグ間で独立。これは MVP 用途で問題化しない（各パスが独立 Storage path に upload、ユーザー操作上ほぼ起こり得ない）。
- ネットワーク中断時のリトライキューは MVP スコープ外。

---

## §7.2 累積（day 13 終了時点）

| # | 内容 | 結果 | 検証 day |
|---|---|---|---|
| 1 | ネットワーク切断 → ルート詳細 | DEFER | 実機要件 |
| 2 | Supabase 401 注入 | 🟢 **PASS** | **day 13** |
| 3 | 画像 URL 404 | 🟢 PASS | day 11 |
| 4 | GPS 権限拒否 | 🟢 PASS | day 9 |
| 5 | カメラ権限拒否 | DEFER | 実機要件 |
| 6 | DB NULL カラム | 🟢 PASS | day 11 |
| 7 | 不正な slug `/routes/aaaaa` | 🟢 PASS | day 10 |
| 8 | 同時アップロード起動 | 🟢 **PASS** | **day 13** |
| 9 | バックグラウンド 30 分復帰 | DEFER | 実機要件 |
| 10 | 容量不足 | DEFER | 実機要件 |
| 11 | OS ダーク↔ライト切替 | 🟢 PASS | day 9 |
| 12 | iOS 文字サイズ最大 | 🟢 PASS | day 9 |

**集計: PASS 8 / 12 ・ DEFER 4 / 12 ・ FAIL 0 / 12**

DEFER 4 件は全て実機要件（ネットワーク切断・カメラ権限・30 分バックグラウンド・容量不足）で、W4 CEO E2E or 公開後 Sentry テレメトリ運用で検出する整理（§7.3.4 実機固有問題の事後検知運用）。

---

## flutter analyze（最終）

```
$ flutter analyze lib/main.dart
Analyzing main.dart...
   info • 'withOpacity' is deprecated and shouldn't be used.
        Use .withValues() to avoid precision loss
        • lib/main.dart:254:45 • deprecated_member_use
1 issue found. (ran in 2.6s)
```

既存 `splash` 内の `Colors.black.withOpacity(0.2)` 1 件のみ。TEMP trigger 由来の新規 error/warning は **0**。本 day 13 で混入していない事を確認。

---

## 残課題（次の CTO スレッド向け）

1. **Build 30 提出準備（C ステップ）**
   - A1 致命1（距離表示 SSoT）+ 致命2（ピン投稿地図位置）の最終 E2E（実機推奨）
   - W3 で積み上げた全機能の通し検証
   - App Store Connect で archive・signing・export
   - Sentry symbols upload は day 11 CTO ローカル手順を使う（`flutter-build.md` 末尾「Sentry Symbols Upload (CTO ローカル手順・MVP)」）

2. **§7.2 残 DEFER 4 件**
   - W4 CEO E2E（実機 A/B 手持ち）で網羅
   - もしくは公開後 Sentry テレメトリで affected_users ≥ 5 検出 → Build 31+ ホットフィックス

3. **Phase 3 UX 改善候補**
   - signOut 検知 → WelcomeScreen 自動 redirect（L 系統）
   - クロスパス並行アップロードのキュー設計

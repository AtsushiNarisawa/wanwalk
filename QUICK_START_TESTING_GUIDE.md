# Quick Start Testing Guide
## 4-Tab UI Implementation

**Status:** ✅ Implementation Complete - Ready for Testing

---

## What Was Done

### ✅ Completed Changes:

1. **Created New Files:**
   - `lib/providers/user_provider.dart` - User authentication provider
   - `lib/screens/main/tabs/profile_tab.dart` - Profile tab with full functionality

2. **Modified Files:**
   - `lib/screens/main/main_screen.dart` - Changed from 5 tabs to 4 tabs
   - `lib/main.dart` - Now navigates to MainScreen instead of HomeScreen

3. **Tab Structure (4 tabs):**
   - ホーム (Home) - おでかけ散歩優先
   - マップ (Map) - おでかけ散歩中心
   - 散歩記録 (Records) - 日常散歩+統計+バッジ統合
   - プロフィール (Profile) - アカウント管理

---

## How to Test

### Step 1: Build & Run

```bash
cd /home/user/webapp/wanmap_v2
flutter clean
flutter pub get
flutter run
```

Or for release build:
```bash
flutter build apk --release
```

### Step 2: Visual Verification

**Check BottomNavigationBar:**
- [ ] 4 tabs visible at bottom
- [ ] Icons: home, map, directions_walk, person
- [ ] Labels: ホーム, マップ, 散歩記録, プロフィール

**Check Each Tab:**

**Tab 1 - ホーム:**
- [ ] Logo + "WanMap" in AppBar
- [ ] おすすめエリア section (horizontal scroll)
- [ ] 人気の公式ルート section
- [ ] クイックアクション (2x2 grid, 4 buttons)

**Tab 2 - マップ:**
- [ ] Map placeholder with text
- [ ] FAB (Floating Action Button) "おでかけ散歩" at bottom-right
- [ ] Search and location icons in AppBar

**Tab 3 - 散歩記録:**
- [ ] 今日の統計 card (gradient background, white button)
- [ ] 総合統計 (2x2 grid: Level, Distance, Walks, Areas)
- [ ] バッジコレクション section with "すべて見る" button
- [ ] 最近の散歩 section

**Tab 4 - プロフィール:**
- [ ] User info card (gradient background, avatar, level, XP bar)
- [ ] 2 social stat cards (フォロワー, フォロー中)
- [ ] Menu list (9 items including logout)

### Step 3: Navigation Testing

**From ホーム tab:**
- [ ] Tap "エリアを探す" → Opens AreaListScreen
- [ ] Tap "ルート検索" → Opens RouteSearchScreen
- [ ] Tap "日常の散歩" → Opens DailyWalkingScreen
- [ ] Tap "散歩履歴" → Opens WalkHistoryScreen

**From 散歩記録 tab:**
- [ ] Tap "散歩を開始" button → Opens DailyWalkingScreen
- [ ] Tap "すべて見る" (badges) → Opens BadgeListScreen
- [ ] Tap "すべて見る" (walks) → Opens WalkHistoryScreen

**From プロフィール tab:**
- [ ] Tap "プロフィール編集" → Opens ProfileEditScreen
- [ ] Tap "愛犬の管理" → Opens DogListScreen
- [ ] Tap "お気に入り" → Opens SavedScreen
- [ ] Tap "通知設定" → Opens NotificationsScreen
- [ ] Tap "設定" → Opens SettingsScreen
- [ ] Tap "利用規約" → Opens TermsOfServiceScreen
- [ ] Tap "プライバシーポリシー" → Opens PrivacyPolicyScreen
- [ ] Tap "ログアウト" → Shows confirmation dialog → Logs out

### Step 4: Edge Cases

**Not Logged In:**
- [ ] 散歩記録 tab shows "ログインして散歩記録を確認しましょう"
- [ ] プロフィール tab shows "ログインしてプロフィールを確認"

**Network Issues:**
- [ ] Turn off WiFi and check error messages
- [ ] Should show "読み込みに失敗しました" messages

**Overflow Prevention:**
- [ ] Scroll through all tabs without overflow errors
- [ ] Check on small screen devices (e.g., small Android phones)

---

## Troubleshooting

### Issue: "HomeScreen not found"
**Solution:** Clear build cache
```bash
cd /home/user/webapp/wanmap_v2
flutter clean
flutter pub get
flutter run
```

### Issue: "currentUserIdProvider not found"
**Solution:** Make sure `user_provider.dart` was created
```bash
ls -la lib/providers/user_provider.dart
```

### Issue: "ProfileTab not found"
**Solution:** Make sure `profile_tab.dart` was created
```bash
ls -la lib/screens/main/tabs/profile_tab.dart
```

### Issue: Tabs not switching
**Solution:** Check MainScreen implementation
```bash
grep -n "IndexedStack" lib/screens/main/main_screen.dart
```

### Issue: Overflow errors
**Solution:** All tabs use SingleChildScrollView - check implementation
```bash
grep -n "SingleChildScrollView" lib/screens/main/tabs/*.dart
```

---

## Performance Checks

### Memory Usage:
- [ ] Tab switching should be instant (IndexedStack preserves state)
- [ ] No memory leaks when switching tabs repeatedly

### Loading Performance:
- [ ] Providers should load data only once per tab
- [ ] Subsequent tab switches should not reload data

### UI Responsiveness:
- [ ] No jank or stuttering during scrolling
- [ ] Animations should be smooth (60fps)

---

## Known Limitations

### Phase 2 Features (Not Yet Implemented):
- Map functionality is placeholder only
- Official routes section shows "準備中です"
- Badge icons are placeholder (emoji_events icon)
- Social counts show "0" (not yet connected to backend)

### These Are Expected:
- Empty states in some sections (no data yet)
- Placeholder UI for map
- Test data may need to be created in Supabase

---

## Success Criteria

✅ **Minimum Requirements:**
1. App builds without errors
2. All 4 tabs are visible and switchable
3. No overflow errors when scrolling
4. Navigation from each tab works
5. Login/logout flow works

✅ **Ideal State:**
1. All of the above PLUS:
2. Providers load data successfully
3. User profile displays correctly
4. Statistics show real numbers
5. Badge collection shows progress
6. Dark mode works throughout

---

## Next Actions After Testing

### If Everything Works:
1. ✅ Mark implementation as complete
2. 📋 Create test user accounts in Supabase
3. 📊 Verify database schema matches code
4. 🎨 Fine-tune UI spacing/colors if needed
5. 📝 Update documentation

### If Issues Found:
1. 🐛 Document specific error messages
2. 📸 Take screenshots of problems
3. 🔍 Check console logs for errors
4. 💬 Report issues with reproduction steps
5. 🔧 Fix issues iteratively

---

## Quick Commands Reference

```bash
# Clean build
flutter clean && flutter pub get && flutter run

# Build release APK
flutter build apk --release

# Check for errors
flutter analyze

# View logs
flutter logs

# Hot restart
# Press 'R' in terminal where flutter run is active

# Hot reload
# Press 'r' in terminal where flutter run is active
```

---

## Contact & Support

**Report Issues:**
Include:
1. Error message (full stack trace)
2. Screenshot of the problem
3. Steps to reproduce
4. Device/emulator info

**Questions:**
Refer to:
- `UI_REDESIGN_COMPLETION_REPORT.md` - Full implementation details
- `APP_NAVIGATION_MAP.md` - Navigation structure
- Phase 5-5 documentation

---

**Last Updated:** 2025-11-23
**Version:** 1.0 (4-Tab UI Implementation)

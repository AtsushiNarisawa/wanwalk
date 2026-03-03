# WanWalk QA Bug Report
## Comprehensive Quality Assurance Results
**Date**: 2026-03-02
**Reviewed by**: AI QA Engineer
**Scope**: Full codebase review (~42,500 lines of Dart code, 150+ files)

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 4     |
| High     | 12    |
| Medium   | 14    |
| Low      | 8     |
| Design   | 6     |
| **Total** | **44** |

---

## Critical Bugs (Must fix before release)

### BUG-C01: Duplicate `currentUserIdProvider` causes Riverpod conflict
- **Severity**: Critical
- **Screen**: App-wide (auth, home providers)
- **Files**: `lib/providers/auth_provider.dart:147`, `lib/providers/home_provider.dart:40`
- **Reproduction**: Both files declare `final currentUserIdProvider = Provider<String?>((ref) { ... })`. Import both in a single file or indirectly through providers.
- **Expected**: Single source of truth for current user ID
- **Actual**: Duplicate provider definition. Depending on which is imported, the user ID may come from different sources (one watches `authProvider`, the other reads `Supabase.instance.client.auth.currentUser?.id` directly). This can cause authentication state desynchronization.
- **Cause**: Copy-paste error; `home_provider.dart` duplicates the provider from `auth_provider.dart`
- **Fix**: Remove the duplicate from `home_provider.dart` and import from `auth_provider.dart`

### BUG-C02: Table name mismatch `users` vs `profiles` causes data loss
- **Severity**: Critical
- **Screen**: Auth (signup), Profile (view/edit)
- **Files**:
  - `auth_service.dart:73` inserts to `'users'` table (via `SupabaseTables.users`)
  - `profile_provider.dart:36` reads from `'profiles'` table
  - `profile_edit_screen.dart:51,106` reads/writes to `'profiles'` table
- **Reproduction**: Sign up a new user, then navigate to Profile tab
- **Expected**: Profile data (display_name, bio) appears
- **Actual**: Profile shows blank/null because auth writes to `users` but profile reads from `profiles`. User data exists in `users` but is never found in `profiles`.
- **Cause**: Two separate tables (`users` and `profiles`) exist in Supabase but signup only creates a row in `users`. Profile screen only reads from `profiles`.
- **Fix**: Either (a) create a trigger in Supabase to auto-populate `profiles` on user creation, or (b) update signup to also insert into `profiles`, or (c) unify to one table

### BUG-C03: Storage bucket name mismatch `profile-avatars` vs `user-avatars`
- **Severity**: Critical
- **Screen**: Profile Edit
- **Files**:
  - `supabase_config.dart:60` defines `SupabaseBuckets.userAvatars = 'user-avatars'`
  - `profile_edit_screen.dart:206,211` uses `'profile-avatars'` (hardcoded)
- **Reproduction**: Try to upload an avatar photo in Profile Edit
- **Expected**: Avatar uploads to the correct bucket
- **Actual**: Upload will fail with "bucket not found" if only one of the buckets exists in Supabase. The constant `SupabaseBuckets.userAvatars` is never used.
- **Cause**: Hardcoded bucket name doesn't match the constant
- **Fix**: Use `SupabaseBuckets.userAvatars` constant consistently, and verify which bucket actually exists in Supabase

### BUG-C04: `walk_detail_service` reads wrong column names from DB
- **Severity**: Critical
- **Screen**: Outing Walk Detail (history)
- **File**: `lib/services/walk_detail_service.dart:27-39`
- **Reproduction**: View an outing walk detail from history
- **Expected**: Walk detail shows correct duration and distance
- **Actual**: The service queries `duration_minutes` and `routes!inner(distance_km, area)` from the `walks` table, but `walk_save_service.dart` saves data as `duration_seconds` and `distance_meters`. Additionally, the `routes!inner` join assumes columns (`distance_km`, `area`, `estimated_time_minutes`, `difficulty`) that may not exist in the `official_routes` or `routes` tables. The foreign key relationship `routes` may not match the actual FK on `walks.route_id -> official_routes.id`.
- **Cause**: Schema mismatch between write and read services
- **Fix**: Align column names in `walk_detail_service.dart` to match actual DB schema (`duration_seconds`, `distance_meters`, correct FK relation)

---

## High Bugs (Fix before release)

### BUG-H01: `Navigator.of(context).pushReplacement()` is not a valid method
- **Severity**: High
- **Screen**: Login, Signup, Splash
- **Files**: `login_screen.dart:45`, `signup_screen.dart:49`, `main.dart:133`
- **Reproduction**: Successful login or signup
- **Expected**: Navigates to MainScreen replacing current screen
- **Actual**: Runtime crash - `pushReplacement` is not a method on `NavigatorState`. The correct method is `pushReplacement` does exist in Flutter but requires a `Route` argument. However, the code passes a `MaterialPageRoute` which should work. **Re-evaluation**: This is actually valid Flutter API. Downgrading - no bug here.
- **Status**: Re-evaluated - **Not a bug** (Flutter API is correct)

### BUG-H01 (revised): `.single()` calls can crash on empty results
- **Severity**: High
- **Screen**: Multiple (Auth, Dog, Route, Walk, Spot Review)
- **Files**:
  - `auth_service.dart:195` - `getUserProfile()` using `.single()` throws if user not found
  - `route_service.dart:20` - `saveRoute()` `.select().single()` throws if insert fails
  - `route_service.dart:78` - `getRouteDetail()` `.single()` throws if route deleted
  - `walk_detail_service.dart:39` - `.single()` throws if walk not found
  - `dog_service.dart:120,158,180` - `.single()` throws on missing dog records
  - `spot_review_service.dart:114,145` - `.single()` on reviews
  - `walk_save_service.dart:51,109` - `.single()` after insert
  - `route_pin_provider.dart:183` - `.single()` when creating pin
- **Reproduction**: Delete a record in Supabase, then try to view it
- **Expected**: Graceful "not found" handling
- **Actual**: Unhandled exception crash. `.single()` throws `PostgrestException` when 0 or 2+ rows returned
- **Cause**: `.single()` used where `.maybeSingle()` should be used (for queries), or error handling is missing around insert+select chains
- **Fix**: Replace `.single()` with `.maybeSingle()` for queries; wrap insert chains in try-catch

### BUG-H02: `walk_save_service.getWalkHistory()` joins on non-existent FK `routes`
- **Severity**: High
- **Screen**: Walk History
- **File**: `walk_save_service.dart:219`
- **Code**: `.select('*, routes(name, distance_km)')`
- **Reproduction**: View walk history
- **Expected**: History list with route names
- **Actual**: The `walks` table has `route_id` pointing to `official_routes`, but this query tries to join `routes` (a different table for user-created routes). This will fail with a PostgREST error about missing foreign key relationship.
- **Cause**: Wrong table name in the join
- **Fix**: Change to `official_routes(name, distance_meters)` or use the correct FK relationship name

### BUG-H03: `DailyWalkingScreen` missing `dispose()` - MapController leak
- **Severity**: High
- **Screen**: Daily Walking
- **File**: `daily_walking_screen.dart`
- **Reproduction**: Start daily walk, go back, start again repeatedly
- **Expected**: MapController is properly disposed
- **Actual**: `_mapController` (line 31) is never disposed. The class has no `dispose()` override. This causes a memory leak each time the screen is opened. Same issue in `WalkingScreen` (outing).
- **Cause**: Missing `dispose()` method
- **Fix**: Add `@override void dispose() { _mapController.dispose(); super.dispose(); }`

### BUG-H04: `WalkingScreen` has unguarded print statements in production
- **Severity**: High
- **Screen**: Outing Walking
- **File**: `walking_screen.dart:53-62`
- **Reproduction**: Start any outing walk
- **Expected**: Debug output only in debug builds
- **Actual**: 417+ `print()` statements across the codebase are NOT wrapped in `if (kDebugMode)`. These will appear in production builds, potentially exposing user data (emails, IDs) and degrading performance.
- **Cause**: Missing `kDebugMode` guards
- **Fix**: Wrap all print statements in `if (kDebugMode)` or use a proper logger

### BUG-H05: Auth signup creates user but may fail silently on profile insertion
- **Severity**: High
- **Screen**: Signup
- **File**: `auth_service.dart:70-78`
- **Reproduction**: Sign up when the `users` table has restrictive RLS policies
- **Expected**: User created in both auth and users table atomically
- **Actual**: Supabase auth signup succeeds first (line 52), then separately inserts into `users` table (line 73). If the second insert fails (RLS, network), the auth user exists but has no profile. No rollback mechanism exists.
- **Cause**: Non-atomic two-step operation without rollback
- **Fix**: Use a Supabase database trigger for profile creation, or add error handling to delete auth user if profile creation fails

### BUG-H06: `HomeTab` has hardcoded Hakone logic that crashes with empty areas
- **Severity**: High
- **Screen**: Home
- **File**: `home_tab.dart:460-485`
- **Reproduction**: Load home screen when there are no areas starting with '箱根'
- **Expected**: Shows available areas gracefully
- **Actual**: When `hakoneSubAreas` is empty and `nonHakoneAreas` is also empty, `hakoneArea` becomes null and the screen shows "エリアが登録されていません". But the `_FeaturedAreaCard` widget expects `area.name` and `area.prefecture` properties (line 1678-1694), and any area that's a generic `Map` instead of `Area` object would crash.
- **Cause**: Hardcoded business logic tied to specific area names
- **Fix**: Make the featured area logic dynamic rather than Hakone-specific

### BUG-H07: `HomeTab._FeaturedAreaCard` accepts `dynamic area` - no type safety
- **Severity**: High
- **Screen**: Home
- **File**: `home_tab.dart:1601` - `final dynamic area;`
- **Reproduction**: Pass an object without `.name` or `.prefecture` properties
- **Expected**: Type-safe area data
- **Actual**: Using `dynamic` type means any property access (`area.name`, `area.prefecture`) is unchecked at compile time. If a different type is passed, it crashes at runtime.
- **Cause**: Loose typing
- **Fix**: Change to `final Area area;`

### BUG-H08: HomeTab async operation in `onTap` callback (Hakone area)
- **Severity**: High
- **Screen**: Home
- **File**: `home_tab.dart:498-530`
- **Reproduction**: Tap the Hakone featured area card
- **Expected**: Navigate to sub-area screen with route counts
- **Actual**: The `onTap` callback runs async Supabase queries (line 505-520) to count routes per sub-area. During this time there's no loading indicator, the user can tap again (double navigation), and if the context becomes invalid before navigation, it will crash. Also, `hakoneArea!.id == 'hakone_group'` check on line 500 uses a forced unwrap.
- **Cause**: Async work in UI callback without loading state
- **Fix**: Add loading state, prevent double-tap, use proper async handler

### BUG-H09: Notification pagination doesn't accumulate results
- **Severity**: High
- **Screen**: Notifications
- **File**: `notifications_screen.dart:43-47`
- **Reproduction**: Scroll down in notifications to load more
- **Expected**: New notifications are appended to existing list
- **Actual**: `_loadMore()` just increases `_offset` and triggers `notificationsProvider(params)` with the new offset. However, `FutureProvider.family` with a new offset parameter creates a **new** provider, replacing the old data. The previous notifications disappear and only the new page is shown.
- **Cause**: Provider recreated on each offset change instead of accumulating
- **Fix**: Use a `StateNotifier` pattern that accumulates pages, or use `AsyncNotifier` with list state

### BUG-H10: `AuthState.copyWith` doesn't allow setting `currentUser` to null
- **Severity**: High
- **Screen**: Auth (Logout)
- **File**: `auth_provider.dart:25`
- **Code**: `currentUser: currentUser ?? this.currentUser`
- **Reproduction**: Log out
- **Expected**: `currentUser` becomes null after logout
- **Actual**: The `copyWith` method uses `??` which means passing `null` for `currentUser` keeps the old value. However, `signOut()` on line 105 creates a new `AuthState(isLoading: false)` which does set it to null. But any other code using `copyWith(currentUser: null)` would fail to clear it.
- **Cause**: Standard Dart copyWith pattern issue with nullable fields
- **Fix**: Use a sentinel value or a separate boolean to track explicit null

### BUG-H11: Email validation is too weak
- **Severity**: High  
- **Screen**: Login, Signup
- **Files**: `login_screen.dart:168`, `signup_screen.dart:191`
- **Reproduction**: Enter "a@b" as email
- **Expected**: Validation rejects incomplete emails
- **Actual**: Both login and signup only check `value.contains('@')`. Strings like `"@"`, `"a@"`, `"@b"` all pass validation. The password reset screen (line 40) uses a proper regex. Inconsistent validation across screens.
- **Cause**: Weak validation regex
- **Fix**: Use the same regex as `password_reset_screen.dart`: `r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'`

### BUG-H12: `walk_save_service.getWalkHistory` casts response unsafely
- **Severity**: High
- **Screen**: Walk History
- **File**: `walk_save_service.dart:233`
- **Code**: `(walks as List).length`
- **Reproduction**: Call getWalkHistory when Supabase returns unexpected format
- **Expected**: Safe handling of response
- **Actual**: Force casting `walks as List` without null check. If the query fails or returns null, this throws a runtime exception.
- **Cause**: Missing null safety
- **Fix**: Use `(walks as List?)?.length ?? 0`

---

## Medium Bugs (Fix in next sprint)

### BUG-M01: 226 uses of deprecated `withOpacity()` API
- **Severity**: Medium
- **Screen**: All screens
- **Reproduction**: Compile with Flutter 3.27+ (strict deprecation warnings)
- **Expected**: Uses `Color.withValues()` or `Color.fromRGBO()`
- **Actual**: `Color.withOpacity()` is deprecated in newer Flutter versions. 226 occurrences across the codebase.
- **Fix**: Replace with `color.withValues(alpha: 0.X)` or `Color.fromRGBO()`

### BUG-M02: `PasswordResetScreen` directly calls Supabase bypassing AuthProvider
- **Severity**: Medium
- **Screen**: Password Reset
- **File**: `password_reset_screen.dart:60`
- **Reproduction**: Reset password
- **Expected**: Uses `authProvider.resetPassword()` for consistency
- **Actual**: Calls `Supabase.instance.client.auth.resetPasswordForEmail()` directly, bypassing the auth provider and service layer. This means auth state isn't updated, and the loading/error states in AuthProvider aren't used.
- **Cause**: Inconsistent architecture pattern
- **Fix**: Use `ref.read(authProvider.notifier).resetPassword(email)`

### BUG-M03: Password reset redirect URL is a placeholder
- **Severity**: Medium
- **Screen**: Password Reset
- **File**: `password_reset_screen.dart:62`
- **Code**: `redirectTo: 'https://wanwalk.app/auth/reset-password'`
- **Reproduction**: Send password reset email, click the link
- **Expected**: Deep link opens the app to set new password
- **Actual**: The URL is a TODO placeholder. The deep link won't work unless the app has URL scheme handling configured.
- **Fix**: Configure proper deep link handling and update the redirect URL

### BUG-M04: `map_screen.dart` recursive timer without explicit cancellation
- **Severity**: Medium
- **Screen**: Map
- **File**: `map_screen.dart:481-491`
- **Reproduction**: Start recording on map, navigate away
- **Expected**: Timer stops cleanly
- **Actual**: `_startPointUpdateTimer()` uses `Future.delayed` recursively. While it checks `mounted`, there's no way to cancel the pending `Future.delayed` when navigating away. If the screen is removed from the widget tree between the delay and execution, `mounted` check works but there may be brief window issues.
- **Cause**: Using `Future.delayed` recursion instead of a `Timer.periodic`
- **Fix**: Use `Timer.periodic` with proper cancellation in `dispose()`

### BUG-M05: `AuthException.statusCode` is `String?` not `int`
- **Severity**: Medium
- **Screen**: Password Reset
- **File**: `password_reset_screen.dart:87-88`
- **Code**: `case '400':` / `case '429':`
- **Reproduction**: Trigger a 400 or 429 error from Supabase
- **Expected**: Error message displayed
- **Actual**: `AuthException.statusCode` may return the code as a `String?` in some Supabase versions. The `switch` statement compares strings, which should work, but if the Supabase SDK version returns `int`, the comparison fails silently and falls to the default case.
- **Cause**: Potential SDK version mismatch
- **Fix**: Add logging to verify the actual type of `statusCode`

### BUG-M06: `LoginScreen` uses hardcoded background color, not theme-aware
- **Severity**: Medium
- **Screen**: Login
- **File**: `login_screen.dart:82`
- **Code**: `backgroundColor: WanMapColors.backgroundLight`
- **Reproduction**: Switch to dark mode, open login screen
- **Expected**: Dark background
- **Actual**: Always uses light background. `SignupScreen` has the same issue (line 88: `Color(0xFFF8F9FA)`). Both screens don't adapt to dark mode.
- **Cause**: Hardcoded light-mode colors
- **Fix**: Use `isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight`

### BUG-M07: `_RecentPinCard._formatTimeAgo()` is defined but never used
- **Severity**: Medium
- **Screen**: Home
- **File**: `home_tab.dart:1394-1411`
- **Reproduction**: N/A (dead code)
- **Expected**: Time ago shown on pin cards
- **Actual**: The method exists but is never called in the card's build method. Pin post dates are not displayed to users.
- **Cause**: Unfinished implementation
- **Fix**: Either use `_formatTimeAgo(widget.pin.createdAt)` in the card UI, or remove the dead code

### BUG-M08: `_AreaCard` width constraint doesn't adapt to parent layout
- **Severity**: Medium
- **Screen**: Home
- **File**: `home_tab.dart:1094`
- **Code**: `width: isHorizontal ? double.infinity : 160`
- **Reproduction**: Open home screen on a narrow device
- **Expected**: Area cards adapt to screen width
- **Actual**: When `isHorizontal` is false, width is hardcoded to 160px. But in the current usage (line 548-574), the card is wrapped in `Expanded`, so the hardcoded width is overridden. However, if used standalone, it would be fixed width.
- **Cause**: Inconsistent sizing approach
- **Fix**: Remove hardcoded width when used inside `Expanded`

### BUG-M09: Social features (follow/unfollow, timeline, user search) not implemented
- **Severity**: Medium
- **Screen**: Social/Profile
- **Files**: Various
- **Reproduction**: Try to find social features in the app
- **Expected**: User search, follow/unfollow, timeline as specified in requirements
- **Actual**: Social features have been removed/commented out. The home tab comment says "フォロー機能削除: 通知ボタンを非表示" (Follow feature removed). No social screen exists.
- **Cause**: Feature removed but still in requirements
- **Fix**: Either implement social features or update requirements to remove them

### BUG-M10: Badge system not implemented
- **Severity**: Medium
- **Screen**: Library/Badges
- **Files**: No dedicated badge screen found
- **Reproduction**: Try to find badges in the app
- **Expected**: Badge conditions, display, new notifications
- **Actual**: No badge screen, no badge model, no badge provider. Only references are in the library tab comment and some minor mentions. The requirements list "Badges (conditions, display, new notifications)" but implementation is missing.
- **Fix**: Implement badge system or defer from requirements

### BUG-M11: `DailyWalkingScreen._finishWalking()` accesses `gpsState` after `stopRecording()`
- **Severity**: Medium
- **Screen**: Daily Walk
- **File**: `daily_walking_screen.dart:183,206-207`
- **Reproduction**: Finish a daily walk
- **Expected**: Correct distance and duration saved
- **Actual**: `gpsState` is read (line 183) BEFORE `stopRecording()`, but `gpsState.distance` and `gpsState.elapsedSeconds` (lines 206-207) are used AFTER `stopRecording()` which resets the state. The `ref.read(gpsProviderRiverpod)` gets a snapshot, but if `stopRecording` clears state synchronously, the snapshot may be stale. Need to verify if the snapshot is taken before or after state change.
- **Cause**: Potential race condition with state management
- **Fix**: Capture distance/duration BEFORE calling stopRecording()

### BUG-M12: `HomeTab` async operation fetches route count inside `build()` method
- **Severity**: Medium
- **Screen**: Home
- **File**: `home_tab.dart:505-520`
- **Reproduction**: Open home tab with Hakone areas
- **Expected**: Route counts loaded efficiently
- **Actual**: For each Hakone sub-area, a separate Supabase query is made inside the `onTap` callback, which runs sequentially in a for loop. With many sub-areas, this creates N+1 query problem and poor UX (no loading indicator).
- **Fix**: Pre-fetch route counts using a provider, or use a single aggregate RPC call

### BUG-M13: `walk_detail_service.dart` references non-standard columns
- **Severity**: Medium
- **Screen**: Outing Walk Detail
- **File**: `walk_detail_service.dart:28-35`
- **Reproduction**: View any outing walk detail
- **Expected**: Correct data loaded
- **Actual**: References `duration_minutes`, `routes!inner(distance_km, estimated_time_minutes, difficulty, area)`. The `walks` table stores `duration_seconds` (per save service). The FK join name `routes` may not exist (actual FK is to `official_routes`). Column names like `distance_km` and `area` may not exist in the official_routes table.
- **Cause**: Schema assumptions don't match actual DB structure
- **Fix**: Verify DB schema and align column names

### BUG-M14: `walk_save_service.dart:219` joins `routes` table instead of `official_routes`
- **Severity**: Medium
- **Screen**: Walk History
- **File**: `walk_save_service.dart:219`
- **Code**: `.select('*, routes(name, distance_km)')`
- **Reproduction**: Fetch walk history
- **Expected**: Joins to official routes data
- **Actual**: The `walks.route_id` column points to `official_routes` but this select tries to join `routes` (user-created routes table). PostgREST will fail if no FK relationship named `routes` exists.
- **Fix**: Use the correct FK relationship name

---

## Low Bugs (Fix when convenient)

### BUG-L01: `AuthSelectionScreen` "ログインせずに続ける" just pops the screen
- **Severity**: Low
- **Screen**: Auth Selection
- **File**: `auth_selection_screen.dart:146`
- **Reproduction**: Open auth selection, tap "ログインせずに続ける"
- **Expected**: Navigate to main screen in guest mode
- **Actual**: Just calls `Navigator.of(context).pop()`, which goes back to wherever the user came from. If they were on the splash screen, this might leave them nowhere.
- **Fix**: Navigate to MainScreen in guest mode

### BUG-L02: Logo container widths differ across auth screens
- **Severity**: Low
- **Screen**: Auth Selection, Login, Signup
- **Files**: auth_selection_screen.dart (120x120), login_screen.dart (100x100), signup_screen.dart (80x80)
- **Reproduction**: Navigate between auth screens
- **Expected**: Consistent branding
- **Actual**: Logo sizes are inconsistent: 120px on auth selection, 100px on login, 80px on signup
- **Fix**: Use a shared constant or widget

### BUG-L03: `_RecentPinCard` initializes like/comment state in `initState` via `Future.microtask`
- **Severity**: Low
- **Screen**: Home
- **File**: `home_tab.dart:1213-1222`
- **Reproduction**: Scroll home screen rapidly
- **Expected**: Stable initialization
- **Actual**: Uses `Future.microtask` in `initState` to call providers. This is fragile - if the widget is removed before the microtask executes, it may access a disposed ref. Using `WidgetsBinding.instance.addPostFrameCallback` would be safer.
- **Fix**: Use `addPostFrameCallback` or handle in the build method

### BUG-L04: `_AreaCard._getGradientColor` only handles 5 area names
- **Severity**: Low
- **Screen**: Home
- **File**: `home_tab.dart:1077-1085`
- **Reproduction**: Add an area that doesn't match any of the 5 conditions
- **Expected**: Each area has a distinct color
- **Actual**: Only 横浜, 鎌倉, 江ノ島, 伊豆, 熱海 have specific colors. All other areas default to `WanMapColors.primary`, making them visually identical.
- **Fix**: Use a hash-based color selection for dynamic variety

### BUG-L05: Multiple backup files in codebase
- **Severity**: Low
- **Screen**: N/A
- **File**: `lib/screens/routes/route_detail_screen.dart.backup2`
- **Reproduction**: N/A
- **Expected**: Clean codebase
- **Actual**: Backup files remain in the repository
- **Fix**: Remove .backup files and add to .gitignore

### BUG-L06: `Scaffold` nested inside `Scaffold` in several screens
- **Severity**: Low
- **Screen**: Home, Library (via MainScreen's IndexedStack)
- **File**: `main_screen.dart:272` + `home_tab.dart:57`
- **Reproduction**: Open home tab
- **Expected**: Single scaffold
- **Actual**: `MainScreen` has a `Scaffold`, and `HomeTab` also has its own `Scaffold`. This causes nested scrolling contexts and potential AppBar duplication.
- **Fix**: Either remove inner scaffolds or remove the outer scaffold's body wrapper

### BUG-L07: `BottomNavigationBar` index mismatch when tapping center tab
- **Severity**: Low
- **Screen**: Main Navigation
- **File**: `main_screen.dart:51-53`
- **Reproduction**: Tap the center "お散歩" tab repeatedly
- **Expected**: Tab highlight returns to previous tab after bottom sheet
- **Actual**: When center tab (index 2) is tapped, the bottom sheet appears but `_selectedIndex` is never changed to 2 and never restored. The `Container()` placeholder (line 42) is shown if somehow the index becomes 2 without the guard.
- **Fix**: Add visual feedback or temporary highlighting for the center tab

### BUG-L08: `FlutterMap` tile layer uses OpenStreetMap without proper attribution
- **Severity**: Low
- **Screen**: Home, Daily Walk, Outing Walk, Map
- **Files**: Multiple files using `'https://tile.openstreetmap.org/{z}/{x}/{y}.png'`
- **Reproduction**: Any map display
- **Expected**: OSM attribution displayed
- **Actual**: OpenStreetMap tiles require attribution. The `FlutterMap` widget doesn't include `RichAttributionWidget`.
- **Fix**: Add proper OSM attribution overlay

---

## Design Issues (Noted, do not fix now)

### DESIGN-01: Inconsistent widget library usage
- Only 2 out of 150+ files import from `wanmap_widgets.dart`. The widget library exists but is barely used across screens.

### DESIGN-02: Heavy screens (1000+ lines)
- 6 screens exceed 900 lines (`route_detail_screen.dart`: 1897, `home_tab.dart`: 1715, etc.). These should be broken into smaller widgets.

### DESIGN-03: Mixed usage of `WanMapSpacing` constants
- Some files use `WanMapSpacing.lg`, others use `WanMapSpacing.large`. Two naming conventions coexist.

### DESIGN-04: Dark mode support is inconsistent
- Login/Signup screens hardcode light background. Other screens properly check `isDark`.

### DESIGN-05: No loading/empty/error state standardization
- Each screen implements its own loading spinner, empty state, and error message. No shared pattern.

### DESIGN-06: Excessive debug logging in production
- 417 unguarded `print()` statements will appear in release builds, potentially exposing user data.

---

## Supabase DB/Storage Issues

1. **Table mismatch**: `users` table (auth_service) vs `profiles` table (profile screens) - see BUG-C02
2. **Storage bucket mismatch**: `user-avatars` (constant) vs `profile-avatars` (hardcoded) - see BUG-C03
3. **FK relationship**: `walks.route_id` -> `official_routes` but queries try to join `routes` table - see BUG-H02
4. **Column names**: `walk_detail_service` expects `duration_minutes` but save service writes `duration_seconds` - see BUG-C04
5. **Missing tables/columns**: `walk_detail_service` expects `area`, `difficulty`, `estimated_time_minutes` in the routes join
6. **RPC functions used**: `get_recent_pins`, `get_areas_simple`, `get_routes_by_area_geojson`, `get_route_by_id_geojson`, `get_all_routes_geojson`, `get_monthly_popular_official_routes`, `get_pin_location`, `bookmark_pin`, `unbookmark_pin`, `like_pin`, `unlike_pin`, `get_outing_walk_history`, `get_daily_walk_history`, `find_nearby_routes` - all need to be verified they exist in Supabase

---

## Recommended Fix Priority

### Phase 1 - Critical (Before any testing)
1. BUG-C01: Remove duplicate `currentUserIdProvider`
2. BUG-C02: Fix `users`/`profiles` table mismatch
3. BUG-C03: Fix storage bucket name mismatch
4. BUG-C04: Fix column name mismatches in walk_detail_service

### Phase 2 - High (Before release)
1. BUG-H01: Replace `.single()` with `.maybeSingle()` where appropriate
2. BUG-H02: Fix FK join in walk_save_service
3. BUG-H03: Add `dispose()` to walking screens
4. BUG-H04: Guard all print statements with kDebugMode
5. BUG-H05: Fix auth signup non-atomic profile creation
6. BUG-H06-H08: Fix HomeTab Hakone logic and type safety
7. BUG-H09: Fix notification pagination
8. BUG-H10: Fix AuthState.copyWith null handling
9. BUG-H11: Strengthen email validation
10. BUG-H12: Fix unsafe list cast

### Phase 3 - Medium (Next sprint)
- All Medium bugs

### Phase 4 - Low (When convenient)
- All Low bugs

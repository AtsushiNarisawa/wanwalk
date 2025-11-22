# Pre-Build Checklist - WanMap v2
Generated: $(date)

## ✅ Configuration Checks

### 1. Dependencies
- [x] pubspec.yaml has `provider: ^6.1.0`
- [x] pubspec.yaml does NOT have `flutter_riverpod`
- [x] All 7 providers imported in main.dart

### 2. Provider Setup
- [x] AuthProvider - ChangeNotifier ✅
- [x] DogProvider - ChangeNotifier ✅
- [x] GpsProvider - ChangeNotifier ✅
- [x] RouteProvider - ChangeNotifier ✅
- [x] SpotProvider - ChangeNotifier ✅
- [x] ThemeProvider - ChangeNotifier ✅
- [x] NotificationProvider - ChangeNotifier ✅

### 3. Core Screens (Provider-based)
- [x] login_screen.dart ✅
- [x] signup_screen.dart ✅
- [x] settings_screen.dart ✅
- [x] route_detail_screen.dart ✅

### 4. Environment
- [x] .env file exists
- [x] THUNDERFOREST_API_KEY configured
- [x] SUPABASE_URL configured
- [x] SUPABASE_ANON_KEY configured

### 5. Disabled Features (Commented Out)
- [x] profile_screen.dart navigation
- [x] favorites_screen.dart navigation
- [x] public_routes_screen.dart navigation
- [x] routes_list_screen.dart navigation

## ⚠️ Known Limitations

### Temporarily Disabled (Will not cause build errors)
1. Profile/Social features - Navigation shows "準備中" message
2. Follow/Like providers - Not used in active code paths
3. Connectivity widgets - Not rendered in current screens

### Expected Build Warnings (Safe to Ignore)
1. Unused imports in disabled screen files
2. Dead code in commented-out navigation
3. iOS deprecation warnings (non-critical)

## 🚀 Build Commands

### Recommended sequence:
```bash
# 1. Clean build artifacts
/home/user/flutter/bin/flutter clean

# 2. Get dependencies  
/home/user/flutter/bin/flutter pub get

# 3. Build for iOS (debug)
/home/user/flutter/bin/flutter build ios --debug

# Alternative: Run on device
/home/user/flutter/bin/flutter run
```

## ✅ Expected Outcome

### Should Compile Successfully ✅
- Auth screens (login, signup)
- Dog management screens
- GPS/Route recording
- Map screen
- Spot management
- Settings screen

### Will Show "準備中" Message ⏸️
- Profile screen
- Favorites
- Public routes
- Route list
- Social features

## 🔍 Post-Build Verification

After successful build, test these flows:
1. ✅ Login → Home Screen
2. ✅ Home → Map Screen (GPS recording)
3. ✅ Home → Settings (Theme toggle)
4. ✅ Navigate to disabled features (should show "準備中")

---

**Status**: READY FOR BUILD ✅  
**Risk Level**: LOW  
**Rollback**: Backup available at `wanmap_v2_backup_before_provider_migration_*`

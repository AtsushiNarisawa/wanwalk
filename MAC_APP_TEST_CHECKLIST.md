# Mac App Test Checklist
**Date**: 2025-11-27
**Purpose**: Verify Supabase RPC function restoration

## Test Procedure

### 1. App Restart
```bash
cd ~/projects/webapp/wanwalk
# Option A: Hot Restart (if app is already running)
# Press 'R' key in terminal

# Option B: Full Restart
flutter run
```

### 2. Expected Results

#### ✅ Console Logs (Should See)
```
✅ Successfully fetched 3 areas
🏞️ Area list loaded: 3
- 箱根 (35.2328, 139.0268)
- 横浜 (35.4437, 139.638)
- 鎌倉 (35.3192, 139.5503)
```

#### ❌ Error Logs (Should NOT See)
```
❌ PostgrestException: column a.location does not exist
❌ Failed to fetch areas
❌ type 'Null' is not a subtype of type 'num'
```

### 3. UI Verification

#### Home Screen
- [ ] **おすすめエリア** section displays
- [ ] Area cards visible (箱根, 横浜 cards minimum)
- [ ] No error message shown

#### Area List Screen
- [ ] Navigate: Home → **エリアを探す** button
- [ ] 3 area cards displayed:
  - 箱根
  - 横浜
  - 鎌倉
- [ ] No loading error
- [ ] No blank screen

### 4. Other Issues to Check

#### Known Warnings (OK to Ignore)
```
⚠️ Error getting user statistics: PostgrestException
   → get_user_walk_statistics function unimplemented (low priority)

⚠️ Error fetching outing walk history: type 'Null' is not a subtype
   → Separate issue, not related to areas
```

## Test Results

### Date: _______
### Tester: Atsushi

#### Console Output
```
[Paste console output here]
```

#### Screenshots
- [ ] Home screen
- [ ] Area list screen
- [ ] Error messages (if any)

#### Status
- [ ] ✅ Test Passed - All areas displayed correctly
- [ ] ❌ Test Failed - Issue: _______________

## Notes

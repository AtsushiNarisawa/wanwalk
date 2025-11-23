# Phase 5 Testing Guide - Badge System & Social Features

## 🎯 Overview

This guide helps you test the completed Phase 5 features including:
- ✅ Badge System (17 badges in 5 categories)
- ✅ Favorites & Bookmarks
- ✅ User Follow System
- ✅ Notifications
- ✅ Statistics Dashboard

## 📋 Prerequisites

Before testing, ensure all 3 SQL parts have been executed successfully:
1. ✅ PHASE5_PART1_TABLES_AND_FUNCTIONS.sql
2. ✅ PHASE5_PART2_BADGES.sql
3. ⏳ PHASE5_PART3_TEST_DATA_FIXED.sql (Execute this now!)

## 🔧 Step-by-Step Database Setup

### Step 1: Execute Part 3 SQL (Test Data)

**File:** `PHASE5_PART3_TEST_DATA_FIXED.sql`

**How to execute:**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy the entire contents of `PHASE5_PART3_TEST_DATA_FIXED.sql`
4. Paste into SQL Editor
5. Click "Run"

**Key Fixes in This Version:**
- ✅ Fixed pin_type values to match CHECK constraint: `'scenery'`, `'shop'`, `'encounter'`, `'other'`
- ✅ Previous values like 'scenic_spot', 'dog_friendly_cafe' were causing errors

**What this SQL does:**
1. Creates 3 test user profiles with display names
2. Inserts 22 daily_walks records (10 + 7 + 5)
3. Inserts 12 route_pins with correct pin_types
4. Inserts 4 route_favorites
5. Inserts 5 pin_bookmarks
6. Inserts 5 user_follows relationships
7. Inserts 5 test notifications
8. Automatically triggers badge unlocks based on activity

**Expected Results:**
```
Test users created: 3
Daily walks inserted: 22
Route pins inserted: 12
Route favorites: 4
Pin bookmarks: 5
User follows: 5
Notifications: 5
Badges unlocked: (varies based on activity)
```

### Step 2: Verify Data Insertion

Run these verification queries in Supabase SQL Editor:

```sql
-- Check test users
SELECT id, email, display_name FROM users WHERE email LIKE 'test%@example.com';

-- Check daily walks
SELECT user_id, COUNT(*) as walk_count, SUM(distance_meters) as total_distance
FROM daily_walks 
WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%@example.com')
GROUP BY user_id;

-- Check route pins
SELECT user_id, COUNT(*) as pin_count, array_agg(DISTINCT pin_type) as pin_types
FROM route_pins
WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%@example.com')
GROUP BY user_id;

-- Check unlocked badges
SELECT u.email, b.name_ja, ub.unlocked_at
FROM user_badges ub
JOIN users u ON ub.user_id = u.id
JOIN badge_definitions b ON ub.badge_id = b.id
WHERE u.email LIKE 'test%@example.com'
ORDER BY u.email, ub.unlocked_at DESC;

-- Check statistics
SELECT * FROM get_user_statistics('a0000000-0000-0000-0000-000000000001'::UUID);
```

## 👥 Test Accounts

Three test accounts are created with the following UUIDs:

| Email | UUID | Display Name | Walks | Pins |
|-------|------|--------------|-------|------|
| test1@example.com | `a0000000-0000-0000-0000-000000000001` | テストユーザー1 | 10 | 5 |
| test2@example.com | `a0000000-0000-0000-0000-000000000002` | テストユーザー2 | 7 | 4 |
| test3@example.com | `a0000000-0000-0000-0000-000000000003` | テストユーザー3 | 5 | 3 |

### Social Relationships

**Follows:**
- User1 → follows → User2, User3
- User2 → follows → User1, User3
- User3 → follows → User1

**Favorites:**
- User1: Route 1, Route 2
- User2: Route 1, Route 3

**Bookmarks:**
- User1: Pin 1, Pin 2
- User2: Pin 1, Pin 3
- User3: Pin 1

## 🎮 Flutter App Testing Checklist

### 1. Badge System Testing

**Access:** Profile Screen → バッジコレクション button

**What to test:**
- [ ] Badge Collection Screen displays correctly
- [ ] 5 category tabs (距離, エリア, ピン, ソーシャル, 特別)
- [ ] Badge cards show lock/unlock states
- [ ] Tier colors display correctly (Bronze, Silver, Gold, Platinum)
- [ ] Progress indicators show correct percentages
- [ ] Tapping on a badge shows details

**Test Users:**
- **test1@example.com**: Should have multiple badges unlocked (10 walks)
- **test2@example.com**: Should have some badges unlocked (7 walks)
- **test3@example.com**: Should have fewer badges (5 walks)

### 2. Statistics Dashboard Testing

**Access:** Profile Screen → 統計ダッシュボード button

**What to test:**
- [ ] Level display shows current level and progress
- [ ] Experience bar animates correctly
- [ ] Badge summary shows unlocked count
- [ ] Statistics cards display:
  - Total walks count
  - Total distance (formatted in km)
  - Areas visited count
  - Pins created count
  - Followers count
  - Following count
- [ ] All numbers match database data

**Expected Values for test1@example.com:**
- Walks: 10
- Distance: ~35,000m (35km)
- Pins: 5
- Followers: 2 (User2, User3)
- Following: 2 (User2, User3)

### 3. Profile Screen Integration

**Access:** Bottom Navigation → Profile Tab

**What to test:**
- [ ] New buttons visible: バッジコレクション, 統計ダッシュボード
- [ ] Buttons navigate to correct screens
- [ ] Back navigation works properly
- [ ] UI layout is clean and consistent

### 4. Notification System Testing

**Access:** (When notification feature is implemented in UI)

**What to test:**
- [ ] Notifications are stored in database
- [ ] Unread count is accurate
- [ ] Read/unread states toggle correctly
- [ ] Different notification types display properly:
  - `follow`: New follower notifications
  - `badge_unlock`: Badge achievement notifications

**Test Data:**
- User1 has 2 unread notifications
- User2 has 1 unread notification

### 5. Favorites & Bookmarks Testing

**Access:** (When favorites/bookmarks UI is implemented)

**What to test:**
- [ ] Favorite routes are saved and retrieved
- [ ] Bookmarked pins are saved and retrieved
- [ ] Add/remove favorites works
- [ ] Add/remove bookmarks works
- [ ] Favorites sync across devices

## 🐛 Common Issues & Solutions

### Issue 1: No badges unlocked for test users

**Solution:**
```sql
-- Manually trigger badge check
SELECT check_and_unlock_badges('a0000000-0000-0000-0000-000000000001'::UUID);
SELECT check_and_unlock_badges('a0000000-0000-0000-0000-000000000002'::UUID);
SELECT check_and_unlock_badges('a0000000-0000-0000-0000-000000000003'::UUID);
```

### Issue 2: Statistics returning null or zero

**Verify data exists:**
```sql
-- Check if walks exist
SELECT COUNT(*) FROM daily_walks WHERE user_id = 'a0000000-0000-0000-0000-000000000001'::UUID;

-- Check if pins exist
SELECT COUNT(*) FROM route_pins WHERE user_id = 'a0000000-0000-0000-0000-000000000001'::UUID;
```

### Issue 3: route_pins CHECK constraint error

**Error:** `new row for relation "route_pins" violates check constraint "route_pins_pin_type_check"`

**Solution:** Make sure you're using the FIXED version of Part 3 SQL that uses correct pin_type values:
- ✅ Use: `'scenery'`, `'shop'`, `'encounter'`, `'other'`
- ❌ Don't use: `'scenic_spot'`, `'dog_friendly_cafe'`, etc.

### Issue 4: Foreign key constraint violation

**Error:** `insert or update on table "daily_walks" violates foreign key constraint`

**Solution:** Ensure user profiles exist in `users` table before inserting walks. Part 3 SQL handles this automatically.

## 📊 Badge Unlock Criteria Reference

### Distance Badges (距離バッジ)
- 散歩デビュー: 1+ walks
- 散歩マスター: 10+ walks
- 散歩レジェンド: 50+ walks
- 散歩の達人: 100+ walks

### Area Badges (エリアバッジ)
- エリア探検家: 3+ different areas
- エリアコレクター: 10+ different areas
- エリアマスター: 20+ different areas
- 全国踏破: 47 areas (all prefectures)

### Pin Badges (ピンバッジ)
- スポット発見者: 5+ pins created
- スポットハンター: 20+ pins created
- スポットマスター: 50+ pins created
- スポットレジェンド: 100+ pins created

### Social Badges (ソーシャルバッジ)
- フレンドリー: 5+ followers
- 人気者: 20+ followers
- インフルエンサー: 50+ followers
- カリスマ: 100+ followers

### Special Badges (特別バッジ)
- アーリーアダプター: Be among first 1000 users
- ベテラン: Account age 365+ days
- パーフェクト: Complete all other badges
- 愛犬家: Create 10+ pins in dog parks
- 写真家: Create 20+ photo spot pins

## 🎉 Next Steps

After successful testing:

1. **Document any bugs found** in Flutter app
2. **Take screenshots** of working features
3. **Test edge cases** (no data, lots of data, etc.)
4. **Verify performance** with larger datasets
5. **Plan Phase 6 features** based on testing feedback

## 📝 Notes

- All test data uses fixed UUIDs for consistency
- Test users can be reset by re-running Part 3 SQL
- Badge unlock logic runs automatically on data insertion
- RPC functions handle all complex queries efficiently

---

**Last Updated:** 2025-01-22
**SQL Files Version:** FIXED (pin_type constraint resolved)
**Status:** ✅ Ready for Testing

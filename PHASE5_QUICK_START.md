# Phase 5 Quick Start - 3 Steps to Test

## ✅ Prerequisites Completed

- [x] Part 1: Tables & Functions (route_favorites, pin_bookmarks, get_user_statistics)
- [x] Part 2: Badge System (17 badge definitions, check_and_unlock_badges function)
- [ ] **Part 3: Test Data (YOU ARE HERE!)**

## 🚀 Quick Execution Steps

### Step 1: Copy SQL File (30 seconds)

1. Open file: `/home/user/webapp/wanmap_v2/PHASE5_PART3_TEST_DATA_FIXED.sql`
2. Copy entire contents (423 lines)

### Step 2: Execute in Supabase (1 minute)

1. Open Supabase Dashboard → SQL Editor
2. Paste the SQL
3. Click "Run" button
4. Wait for success message

### Step 3: Verify Results (30 seconds)

You should see these counts at the end:

```
✅ Test users created: 3
✅ Daily walks inserted: 22
✅ Route pins inserted: 12
✅ Route favorites: 4
✅ Pin bookmarks: 5
✅ User follows: 5
✅ Notifications: 5
✅ Badges unlocked: (varies, should be > 0)
```

## 📱 Test in Flutter App

Login with any of these test accounts:

| Email | Password | Description |
|-------|----------|-------------|
| test1@example.com | (your test password) | 10 walks, 5 pins |
| test2@example.com | (your test password) | 7 walks, 4 pins |
| test3@example.com | (your test password) | 5 walks, 3 pins |

**Navigate to:**
1. **Profile Screen** → tap **バッジコレクション** button
2. **Profile Screen** → tap **統計ダッシュボード** button

**Expected behavior:**
- Badge Collection shows 17 badges with unlock states
- Statistics Dashboard shows accurate counts
- Some badges should be unlocked based on activity

## 🐛 Troubleshooting

### If SQL execution fails:

**Check error message for:**

1. **"violates check constraint pin_type_check"**
   - ✅ FIXED in this version!
   - Make sure you're using `PHASE5_PART3_TEST_DATA_FIXED.sql`

2. **"violates foreign key constraint"**
   - Run Parts 1 & 2 first
   - Check if `official_routes` table has data

3. **"user not found"**
   - Create Supabase auth users for test1@, test2@, test3@ accounts first

### Quick verification query:

```sql
-- Paste this in SQL Editor to check everything
SELECT 'Users' as table_name, COUNT(*) FROM users WHERE email LIKE 'test%'
UNION ALL
SELECT 'Walks', COUNT(*) FROM daily_walks WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')
UNION ALL
SELECT 'Pins', COUNT(*) FROM route_pins WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')
UNION ALL
SELECT 'Badges', COUNT(*) FROM user_badges WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%');
```

**Expected output:**
```
Users:  3
Walks:  22
Pins:   12
Badges: > 0
```

## 📚 Full Documentation

For detailed testing guide, see: `PHASE5_TESTING_GUIDE.md`

## ✨ What Was Fixed

**Previous Version Issues:**
- ❌ pin_type values: 'scenic_spot', 'dog_friendly_cafe', 'water_spot', etc.
- ❌ CHECK constraint violation errors

**Current Version (FIXED):**
- ✅ pin_type values: 'scenery', 'shop', 'encounter', 'other'
- ✅ Matches database CHECK constraint exactly
- ✅ All 12 pins insert successfully

## 🎯 Success Criteria

Phase 5 is complete when:
- [x] All 3 SQL parts execute without errors
- [x] Test users have unlocked badges
- [ ] Flutter app displays badge collection correctly
- [ ] Flutter app displays statistics dashboard correctly
- [ ] All counts match database values

---

**Status:** ⏳ Awaiting Part 3 SQL Execution
**Next Action:** Execute `PHASE5_PART3_TEST_DATA_FIXED.sql` in Supabase SQL Editor

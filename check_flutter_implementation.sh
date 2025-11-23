#!/bin/bash

# ============================================================
# Flutter実装状況の包括的確認
# Phase 1 - Phase 5 の全機能確認
# ============================================================

echo "========================================="
echo "PHASE 1-5 Flutter実装状況確認"
echo "========================================="
echo ""

# ============================================================
# 1. Phase 1: 基本機能の画面
# ============================================================
echo "========================================="
echo "1. PHASE 1: 基本機能の画面"
echo "========================================="

echo "Phase 1 必須画面:"
for screen in "login_screen" "signup_screen" "home_screen" "daily_walk_view" "map_screen" "profile_screen"; do
    if find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "✓ ${screen}.dart 存在"
    else
        echo "✗ ${screen}.dart 不足"
    fi
done

echo ""

# ============================================================
# 2. Phase 2: エリア機能
# ============================================================
echo "========================================="
echo "2. PHASE 2: エリア機能"
echo "========================================="

echo "Phase 2 必須画面:"
for screen in "area_list_screen" "area_detail_screen" "official_route_screen"; do
    if find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "✓ ${screen}.dart 存在"
    else
        echo "✗ ${screen}.dart 不足"
    fi
done

echo ""

# ============================================================
# 3. Phase 3: 検索機能（Phase 5に統合）
# ============================================================
echo "========================================="
echo "3. PHASE 3: 検索機能"
echo "========================================="

echo "Phase 3 必須画面:"
for screen in "search_screen" "search_results_screen"; do
    if find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "✓ ${screen}.dart 存在"
    else
        echo "✗ ${screen}.dart 不足"
    fi
done

echo ""

# ============================================================
# 4. Phase 4: 履歴機能
# ============================================================
echo "========================================="
echo "4. PHASE 4: 履歴機能"
echo "========================================="

echo "Phase 4 必須画面:"
for screen in "history_screen" "trip_detail_screen" "trip_edit_screen"; do
    if find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "✓ ${screen}.dart 存在"
    else
        echo "✗ ${screen}.dart 不足"
    fi
done

echo ""

# ============================================================
# 5. Phase 5: ソーシャル機能
# ============================================================
echo "========================================="
echo "5. PHASE 5: ソーシャル機能"
echo "========================================="

echo "Phase 5 ソーシャル必須画面:"
for screen in "user_profile_screen" "followers_screen" "following_screen" "notifications_screen"; do
    if find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "✓ ${screen}.dart 存在"
    else
        echo "✗ ${screen}.dart 不足"
    fi
done

echo ""

# ============================================================
# 6. Phase 5: バッジシステム
# ============================================================
echo "========================================="
echo "6. PHASE 5: バッジシステム"
echo "========================================="

echo "Phase 5 バッジ必須画面:"
for screen in "badge_list_screen" "badge_detail_screen"; do
    if find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "✓ ${screen}.dart 存在"
    else
        echo "✗ ${screen}.dart 不足"
    fi
done

echo ""

echo "Phase 5 バッジ必須Provider:"
for provider in "badge_provider"; do
    if find lib/providers -name "${provider}.dart" | grep -q .; then
        echo "✓ ${provider}.dart 存在"
    else
        echo "✗ ${provider}.dart 不足"
    fi
done

echo ""

echo "Phase 5 バッジ必須Service:"
for service in "badge_service"; do
    if find lib/services -name "${service}.dart" | grep -q .; then
        echo "✓ ${service}.dart 存在"
    else
        echo "✗ ${service}.dart 不足"
    fi
done

echo ""

# ============================================================
# 7. Phase 5: 統計ダッシュボード
# ============================================================
echo "========================================="
echo "7. PHASE 5: 統計ダッシュボード"
echo "========================================="

echo "Phase 5 統計必須画面:"
for screen in "statistics_dashboard_screen"; do
    if find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "✓ ${screen}.dart 存在"
    else
        echo "✗ ${screen}.dart 不足"
    fi
done

echo ""

# ============================================================
# 8. モデル確認
# ============================================================
echo "========================================="
echo "8. モデルファイル"
echo "========================================="

echo "必須モデル:"
for model in "badge" "route_model" "user_model" "trip_model" "notification_model"; do
    if find lib/models -name "${model}.dart" | grep -q .; then
        echo "✓ ${model}.dart 存在"
    else
        echo "✗ ${model}.dart 不足"
    fi
done

echo ""

# ============================================================
# 9. サービス確認
# ============================================================
echo "========================================="
echo "9. サービスファイル"
echo "========================================="

echo "必須サービス:"
for service in "auth_service" "route_service" "badge_service" "social_service" "notification_service"; do
    if find lib/services -name "${service}.dart" | grep -q .; then
        echo "✓ ${service}.dart 存在"
    else
        echo "✗ ${service}.dart 不足"
    fi
done

echo ""

# ============================================================
# 10. Provider確認
# ============================================================
echo "========================================="
echo "10. Providerファイル"
echo "========================================="

echo "必須Provider:"
for provider in "auth_provider" "route_provider" "badge_provider" "social_provider" "notification_provider"; do
    if find lib/providers -name "${provider}.dart" | grep -q .; then
        echo "✓ ${provider}.dart 存在"
    else
        echo "✗ ${provider}.dart 不足"
    fi
done

echo ""

# ============================================================
# 11. 不足機能のリスト化
# ============================================================
echo "========================================="
echo "11. 不足機能のサマリー"
echo "========================================="

echo ""
echo "【Phase 4 履歴機能】"
missing_phase4=0
for screen in "history_screen" "trip_detail_screen" "trip_edit_screen"; do
    if ! find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "  ✗ ${screen}.dart が不足"
        missing_phase4=$((missing_phase4 + 1))
    fi
done

if [ $missing_phase4 -eq 0 ]; then
    echo "  ✓ Phase 4 全画面実装済み"
fi

echo ""
echo "【Phase 3 検索機能】"
missing_phase3=0
for screen in "search_screen" "search_results_screen"; do
    if ! find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "  ✗ ${screen}.dart が不足"
        missing_phase3=$((missing_phase3 + 1))
    fi
done

if [ $missing_phase3 -eq 0 ]; then
    echo "  ✓ Phase 3 全画面実装済み"
fi

echo ""
echo "【Phase 2 エリア機能】"
missing_phase2=0
for screen in "area_list_screen" "area_detail_screen" "official_route_screen"; do
    if ! find lib/screens -name "${screen}.dart" | grep -q .; then
        echo "  ✗ ${screen}.dart が不足"
        missing_phase2=$((missing_phase2 + 1))
    fi
done

if [ $missing_phase2 -eq 0 ]; then
    echo "  ✓ Phase 2 全画面実装済み"
fi

echo ""
echo "========================================="
echo "確認完了"
echo "========================================="

#!/bin/bash

# WanMap セットアップスクリプト
# このスクリプトはローカルで実行可能な設定を自動化します

set -e  # エラーで停止

echo "🚀 WanMap セットアップを開始します..."
echo ""

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# プロジェクトディレクトリ
PROJECT_DIR="/home/user/webapp/wanmap_v2"
cd "$PROJECT_DIR"

echo "📂 プロジェクトディレクトリ: $PROJECT_DIR"
echo ""

# ========================================
# Step 1: 環境変数の確認
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 1: 環境変数の確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env ファイルが存在します${NC}"
    
    # THUNDERFOREST_API_KEYのチェック
    if grep -q "THUNDERFOREST_API_KEY=your-api-key-here" .env; then
        echo -e "${YELLOW}⚠️  THUNDERFOREST_API_KEYが設定されていません${NC}"
        echo ""
        echo "以下のコマンドで設定してください:"
        echo "  nano .env"
        echo ""
        echo "または:"
        echo "  sed -i 's/your-api-key-here/YOUR_ACTUAL_KEY/' .env"
        echo ""
    else
        echo -e "${GREEN}✅ THUNDERFOREST_API_KEYが設定されています${NC}"
    fi
    
    # Supabaseキーのチェック
    if grep -q "SUPABASE_URL=https://jkpenklhrlbctebkpvax.supabase.co" .env; then
        echo -e "${GREEN}✅ SUPABASE_URLが設定されています${NC}"
    else
        echo -e "${RED}❌ SUPABASE_URLが正しく設定されていません${NC}"
    fi
    
    if grep -q "SUPABASE_ANON_KEY=eyJ" .env; then
        echo -e "${GREEN}✅ SUPABASE_ANON_KEYが設定されています${NC}"
    else
        echo -e "${RED}❌ SUPABASE_ANON_KEYが正しく設定されていません${NC}"
    fi
else
    echo -e "${RED}❌ .env ファイルが見つかりません${NC}"
    exit 1
fi

echo ""

# ========================================
# Step 2: Flutterの確認
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 2: Flutter環境の確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# FlutterのPATHを設定
export PATH="$PATH:/home/user/flutter/bin"

if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✅ Flutterが見つかりました${NC}"
    flutter --version | head -1
else
    echo -e "${RED}❌ Flutterが見つかりません${NC}"
    echo ""
    echo "以下のコマンドでPATHに追加してください:"
    echo "  export PATH=\"\$PATH:/home/user/flutter/bin\""
    exit 1
fi

echo ""

# ========================================
# Step 3: 依存関係のインストール
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 3: Flutter依存関係のインストール"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "flutter pub get を実行中..."
if flutter pub get; then
    echo -e "${GREEN}✅ 依存関係のインストールが完了しました${NC}"
else
    echo -e "${RED}❌ 依存関係のインストールに失敗しました${NC}"
    exit 1
fi

echo ""

# ========================================
# Step 4: コード解析
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 4: コード解析"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "flutter analyze を実行中..."
if flutter analyze --no-fatal-infos; then
    echo -e "${GREEN}✅ コード解析が完了しました（エラーなし）${NC}"
else
    echo -e "${YELLOW}⚠️  警告がありますが、実行可能です${NC}"
fi

echo ""

# ========================================
# Step 5: 利用可能なデバイスの確認
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 5: 利用可能なデバイスの確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

flutter devices

echo ""

# ========================================
# セットアップ完了
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 ローカルセットアップが完了しました！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "次のステップ:"
echo ""
echo "1. Thunderforest APIキーを取得し、.envに設定"
echo "   詳細: SETUP_GUIDE_STEP_BY_STEP.md の Step 1"
echo ""
echo "2. Supabaseスキーマを適用"
echo "   詳細: SETUP_GUIDE_STEP_BY_STEP.md の Step 2"
echo ""
echo "3. Supabase Storageバケットを作成"
echo "   詳細: SETUP_GUIDE_STEP_BY_STEP.md の Step 3"
echo ""
echo "4. アプリを起動:"
echo "   flutter run -d chrome  # Chromeで起動"
echo "   flutter run -d \"iPhone 15 Pro\"  # iOS Simulatorで起動"
echo ""
echo "詳細なセットアップ手順:"
echo "  cat SETUP_GUIDE_STEP_BY_STEP.md"
echo ""

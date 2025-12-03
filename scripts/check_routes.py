#!/usr/bin/env python3
"""
推奨ルートデータの妥当性チェックスクリプト

使い方:
  python3 scripts/check_routes.py

必要な環境変数:
  SUPABASE_URL: SupabaseプロジェクトURL
  SUPABASE_KEY: Supabaseサービスロールキー（またはanon key）
"""

import os
import sys
import json
from dataclasses import dataclass
from typing import List, Dict, Any, Optional

try:
    import requests
except ImportError:
    print("❌ requestsモジュールがインストールされていません")
    print("以下のコマンドでインストールしてください:")
    print("  pip3 install requests")
    sys.exit(1)


@dataclass
class RouteIssue:
    """ルートの問題を表すクラス"""
    route_id: str
    route_name: str
    issue_type: str
    issue_description: str
    severity: str  # 'critical', 'warning', 'info'
    
    def __str__(self):
        severity_emoji = {
            'critical': '🔴',
            'warning': '🟡',
            'info': '🔵'
        }
        emoji = severity_emoji.get(self.severity, '⚪')
        return f"{emoji} [{self.severity.upper()}] {self.route_name} ({self.route_id})\n   → {self.issue_type}: {self.issue_description}"


class RouteValidator:
    """推奨ルートの妥当性検証"""
    
    def __init__(self, supabase_url: str, supabase_key: str):
        self.supabase_url = supabase_url.rstrip('/')
        self.supabase_key = supabase_key
        self.headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }
    
    def fetch_all_routes(self) -> List[Dict[str, Any]]:
        """全ての推奨ルートを取得"""
        url = f"{self.supabase_url}/rest/v1/recommended_routes?select=*"
        
        print("📡 Supabaseから推奨ルートデータを取得中...")
        response = requests.get(url, headers=self.headers)
        
        if response.status_code != 200:
            print(f"❌ エラー: ステータスコード {response.status_code}")
            print(f"レスポンス: {response.text}")
            sys.exit(1)
        
        routes = response.json()
        print(f"✅ {len(routes)}件の推奨ルートを取得しました\n")
        return routes
    
    def validate_route(self, route: Dict[str, Any]) -> List[RouteIssue]:
        """単一ルートの妥当性をチェック"""
        issues = []
        route_id = route.get('id', 'unknown')
        route_name = route.get('name', '無名ルート')
        
        # 1. 距離のチェック
        distance = route.get('distance_meters')
        if distance is None:
            issues.append(RouteIssue(
                route_id, route_name,
                '距離データ欠損',
                'distance_metersフィールドが存在しません',
                'critical'
            ))
        elif distance <= 0:
            issues.append(RouteIssue(
                route_id, route_name,
                '異常な距離',
                f'距離が0m以下です: {distance}m',
                'critical'
            ))
        elif distance > 100000:  # 100km超
            issues.append(RouteIssue(
                route_id, route_name,
                '距離が異常に長い',
                f'距離が100kmを超えています: {distance/1000:.1f}km',
                'warning'
            ))
        elif distance < 500:  # 500m未満
            issues.append(RouteIssue(
                route_id, route_name,
                '距離が短すぎる',
                f'距離が500m未満です: {distance}m',
                'warning'
            ))
        
        # 2. 所要時間のチェック
        duration = route.get('estimated_minutes')
        if duration is None:
            issues.append(RouteIssue(
                route_id, route_name,
                '所要時間データ欠損',
                'estimated_minutesフィールドが存在しません',
                'critical'
            ))
        elif duration <= 0:
            issues.append(RouteIssue(
                route_id, route_name,
                '異常な所要時間',
                f'所要時間が0分以下です: {duration}分',
                'critical'
            ))
        elif duration > 600:  # 10時間超
            issues.append(RouteIssue(
                route_id, route_name,
                '所要時間が異常に長い',
                f'所要時間が10時間を超えています: {duration}分 ({duration/60:.1f}時間)',
                'warning'
            ))
        
        # 3. 経路データのチェック
        path_geojson = route.get('path_geojson')
        if not path_geojson:
            issues.append(RouteIssue(
                route_id, route_name,
                '経路データ欠損',
                'path_geojsonフィールドが存在しないか空です',
                'critical'
            ))
        else:
            # GeoJSONの基本構造チェック
            if isinstance(path_geojson, dict):
                if path_geojson.get('type') != 'LineString':
                    issues.append(RouteIssue(
                        route_id, route_name,
                        'GeoJSON形式エラー',
                        f"typeが'LineString'ではありません: {path_geojson.get('type')}",
                        'critical'
                    ))
                
                coordinates = path_geojson.get('coordinates', [])
                if len(coordinates) < 2:
                    issues.append(RouteIssue(
                        route_id, route_name,
                        '経路ポイント不足',
                        f'経路の座標が2点未満です: {len(coordinates)}点',
                        'critical'
                    ))
        
        # 4. 開始/終了位置のチェック
        start_lat = route.get('start_latitude')
        start_lng = route.get('start_longitude')
        end_lat = route.get('end_latitude')
        end_lng = route.get('end_longitude')
        
        if None in [start_lat, start_lng, end_lat, end_lng]:
            issues.append(RouteIssue(
                route_id, route_name,
                '位置データ欠損',
                '開始または終了位置のデータが欠損しています',
                'critical'
            ))
        else:
            # 開始と終了が全く同じ（ループコースでない限り異常）
            if start_lat == end_lat and start_lng == end_lng:
                # ループコースの場合は警告のみ
                if distance and distance > 1000:  # 1km以上のループは正常
                    issues.append(RouteIssue(
                        route_id, route_name,
                        'ループコース',
                        '開始位置と終了位置が同じです（ループコースの可能性）',
                        'info'
                    ))
                else:
                    issues.append(RouteIssue(
                        route_id, route_name,
                        '開始・終了位置が同じ',
                        '開始位置と終了位置が同じで、距離が短いです',
                        'warning'
                    ))
        
        # 5. エリア情報のチェック
        area_id = route.get('area_id')
        if not area_id:
            issues.append(RouteIssue(
                route_id, route_name,
                'エリア未設定',
                'area_idが設定されていません',
                'warning'
            ))
        
        # 6. 説明文のチェック
        description = route.get('description')
        if not description or len(description.strip()) < 10:
            issues.append(RouteIssue(
                route_id, route_name,
                '説明文不足',
                '説明文が短すぎるか存在しません',
                'info'
            ))
        
        return issues
    
    def generate_report(self, all_issues: List[RouteIssue], total_routes: int):
        """検証レポートを生成"""
        print("\n" + "="*80)
        print("📊 推奨ルート妥当性チェック結果")
        print("="*80 + "\n")
        
        # 統計情報
        critical_count = sum(1 for issue in all_issues if issue.severity == 'critical')
        warning_count = sum(1 for issue in all_issues if issue.severity == 'warning')
        info_count = sum(1 for issue in all_issues if issue.severity == 'info')
        
        print(f"📈 総ルート数: {total_routes}")
        print(f"🔴 重大な問題: {critical_count}件")
        print(f"🟡 警告: {warning_count}件")
        print(f"🔵 情報: {info_count}件")
        print(f"✅ 問題なし: {total_routes - len(set(issue.route_id for issue in all_issues))}件\n")
        
        # 重大度別に問題をグループ化
        if critical_count > 0:
            print("\n" + "-"*80)
            print("🔴 重大な問題（削除推奨）")
            print("-"*80)
            for issue in all_issues:
                if issue.severity == 'critical':
                    print(f"\n{issue}")
        
        if warning_count > 0:
            print("\n" + "-"*80)
            print("🟡 警告（確認推奨）")
            print("-"*80)
            for issue in all_issues:
                if issue.severity == 'warning':
                    print(f"\n{issue}")
        
        if info_count > 0:
            print("\n" + "-"*80)
            print("🔵 情報（任意対応）")
            print("-"*80)
            for issue in all_issues:
                if issue.severity == 'info':
                    print(f"\n{issue}")
        
        # 削除推奨リスト
        critical_route_ids = set(issue.route_id for issue in all_issues if issue.severity == 'critical')
        if critical_route_ids:
            print("\n" + "="*80)
            print("🗑️ 削除推奨ルートID一覧")
            print("="*80)
            for route_id in critical_route_ids:
                print(f"  - {route_id}")
            
            print("\n💡 削除SQLスクリプト:")
            print("-"*80)
            print("-- 重大な問題のあるルートを削除")
            for route_id in critical_route_ids:
                print(f"DELETE FROM recommended_routes WHERE id = '{route_id}';")
        
        print("\n" + "="*80)
        print("✅ チェック完了")
        print("="*80 + "\n")


def main():
    """メイン処理"""
    # 環境変数の確認
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_KEY') or os.getenv('SUPABASE_ANON_KEY')
    
    if not supabase_url:
        print("❌ エラー: SUPABASE_URL環境変数が設定されていません")
        print("\n使い方:")
        print("  export SUPABASE_URL='your-supabase-url'")
        print("  export SUPABASE_KEY='your-supabase-key'")
        print("  python3 scripts/check_routes.py")
        sys.exit(1)
    
    if not supabase_key:
        print("❌ エラー: SUPABASE_KEYまたはSUPABASE_ANON_KEY環境変数が設定されていません")
        print("\n使い方:")
        print("  export SUPABASE_URL='your-supabase-url'")
        print("  export SUPABASE_KEY='your-supabase-key'")
        print("  python3 scripts/check_routes.py")
        sys.exit(1)
    
    # 検証実行
    validator = RouteValidator(supabase_url, supabase_key)
    
    # 全ルート取得
    routes = validator.fetch_all_routes()
    
    # 各ルートを検証
    all_issues = []
    for route in routes:
        issues = validator.validate_route(route)
        all_issues.extend(issues)
    
    # レポート生成
    validator.generate_report(all_issues, len(routes))


if __name__ == '__main__':
    main()

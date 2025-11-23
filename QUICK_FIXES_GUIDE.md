# WanMap v2 - クイックフィックスガイド

**作成日**: 2025-11-23  
**目的**: 今すぐできる簡単な修正でアプリの完成度を大幅に向上させる

---

## ✅ 完了した修正

### 1. Thunderforest APIキー設定
**ファイル**: `.env`

**変更内容**:
```bash
# 変更前
THUNDERFOREST_API_KEY=your-api-key-here

# 変更後
THUNDERFOREST_API_KEY=8c3872c6b1d5471a0e8c88cc69ed4f
```

**効果**: マップタブで地図タイルが正しく表示されるようになる

**確認方法**:
1. アプリを再起動
2. マップタブに移動
3. 地図が表示されることを確認

---

## 🔧 次に修正すべき項目（優先度順）

### Priority 1: ナビゲーション復活（30分で完了）

#### 修正1: ProfileTab - フォロワー/フォロー機能
**ファイル**: `lib/screens/main/tabs/profile_tab.dart`

**現在の問題**:
```dart
// 現在: スナックバーで「準備中」と表示
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('フォロワー/フォロー機能は準備中です'))
);
```

**修正方法**:
```dart
// 修正後: 実装済み画面へナビゲート

// 1. インポート追加（ファイル冒頭）
import '../../social/followers_screen.dart';
import '../../social/following_screen.dart';

// 2. フォロワー数タップ時のコード修正（147行目付近）
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FollowersScreen(userId: currentUser.id),
    ),
  );
},

// 3. フォロー中数タップ時のコード修正（164行目付近）
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FollowingScreen(userId: currentUser.id),
    ),
  );
},
```

**期待される効果**:
- フォロワー数をタップ → フォロワー一覧画面表示
- フォロー中数をタップ → フォロー中一覧画面表示

---

#### 修正2: ProfileTab - 設定画面
**ファイル**: `lib/screens/main/tabs/profile_tab.dart`

**現状**: 設定画面（SettingsScreen）は未実装のため、準備中表示は正しい

**Phase 2で実装予定**:
```dart
// 将来の実装（Phase 2）
class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // テーマ切り替え
          ListTile(
            title: const Text('ダークモード'),
            trailing: Switch(
              value: ref.watch(themeProvider) == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),
          // その他の設定項目
        ],
      ),
    );
  }
}
```

---

#### 修正3: ProfileTab - プロフィール編集画面
**ファイル**: `lib/screens/main/tabs/profile_tab.dart`

**現状**: プロフィール編集画面（ProfileEditScreen）は未実装

**Phase 2で実装予定**:
```dart
// 将来の実装（Phase 2）
class ProfileEditScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        children: [
          // アバター画像変更
          Center(
            child: Stack(
              children: [
                CircleAvatar(radius: 50),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 表示名入力
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '表示名'),
          ),
          // 自己紹介入力
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '自己紹介'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickImage() async {
    // Supabase Storage へ画像アップロード
  }
  
  Future<void> _saveProfile() async {
    // プロフィール更新処理
  }
}
```

---

#### 修正4: ProfileTab - 愛犬管理画面
**ファイル**: `lib/screens/main/tabs/profile_tab.dart`

**現状**: 愛犬管理画面（DogListScreen）は未実装

**Phase 2で実装予定** - dog_provider.dart を使用

---

#### 修正5: RecordsTab - お気に入り画面
**ファイル**: `lib/screens/main/tabs/records_tab.dart`

**現在の問題**:
```dart
// 現在: スナックバーで「準備中」と表示
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('お気に入り一覧は準備中です'))
);
```

**修正方法**:
```dart
// 修正後: 実装済み画面へナビゲート

// 1. インポート追加（ファイル冒頭）
import '../../routes/favorites_screen.dart';

// 2. お気に入りアイコンタップ時のコード修正（45行目付近）
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
  );
},
```

**期待される効果**:
- お気に入りアイコンタップ → お気に入りルート一覧画面表示

---

#### 修正6: RecordsTab - バッジ一覧画面
**ファイル**: `lib/screens/main/tabs/records_tab.dart`

**現状**: バッジ一覧画面（BadgeListScreen）は未実装

**Phase 2で実装予定**:
```dart
// 将来の実装（Phase 2）
class BadgeListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(allBadgesProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('バッジコレクション')),
      body: badgesAsync.when(
        data: (badges) {
          return DefaultTabController(
            length: 6, // All, Distance, Area, Pin, Social, Special
            child: Column(
              children: [
                TabBar(tabs: [/* ... */]),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBadgeGrid(badges),
                      // その他のタブ
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラー: $e')),
      ),
    );
  }
  
  Widget _buildBadgeGrid(List<Badge> badges) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        return BadgeCard(badge: badges[index]);
      },
    );
  }
}
```

---

#### 修正7: WalkHistoryScreen - 散歩詳細画面
**ファイル**: `lib/screens/history/walk_history_screen.dart`

**現状**: 散歩詳細画面（WalkDetailScreen）は未実装

**Phase 2で実装予定**:
```dart
// 将来の実装（Phase 2）
class WalkDetailScreen extends ConsumerWidget {
  final String walkId;
  
  const WalkDetailScreen({super.key, required this.walkId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walkAsync = ref.watch(walkDetailProvider(walkId));
    
    return Scaffold(
      appBar: AppBar(title: const Text('散歩の詳細')),
      body: walkAsync.when(
        data: (walk) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // 地図表示
                SizedBox(
                  height: 300,
                  child: FlutterMap(/* 経路を表示 */),
                ),
                // 統計情報
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatRow('距離', '${walk.distanceKm} km'),
                      _buildStatRow('時間', '${walk.durationMinutes} 分'),
                      _buildStatRow('平均速度', '${walk.avgSpeedKmh} km/h'),
                    ],
                  ),
                ),
                // 投稿したピン一覧
                if (walk.pins.isNotEmpty) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('投稿したピン', style: TextStyle(fontSize: 18)),
                  ),
                  ...walk.pins.map((pin) => PinCard(pin: pin)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラー: $e')),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

---

### Priority 2: 統計データエラー修正（1-2時間）

#### 問題の詳細
**エラーメッセージ**:
```
Error getting user statistics: type 'Null' is not a subtype of type 'int'
```

**原因**:
1. `get_user_walk_statistics` RPC は動作するが、walks テーブルが存在しないため全て0を返す
2. UserStatistics モデルが NULL を許容していない可能性

#### 解決策A: NULL安全処理追加（即座に対応可能）

**ファイル**: `lib/services/user_statistics_service.dart`

**修正方法**:
```dart
// 修正前
Future<UserStatistics> getUserStatistics(String userId) async {
  final response = await _supabase.rpc(
    'get_user_walk_statistics',
    params: {'p_user_id': userId},
  );
  
  return UserStatistics.fromJson(response);
}

// 修正後（NULL安全処理）
Future<UserStatistics> getUserStatistics(String userId) async {
  try {
    final response = await _supabase.rpc(
      'get_user_walk_statistics',
      params: {'p_user_id': userId},
    );
    
    if (response == null) {
      // データがない場合はゼロ値のオブジェクトを返す
      return UserStatistics.empty();
    }
    
    // NULL値を0に変換
    final safeData = {
      'total_walks': response['total_walks'] ?? 0,
      'total_outing_walks': response['total_outing_walks'] ?? 0,
      'total_distance_km': (response['total_distance_km'] ?? 0.0).toDouble(),
      'total_duration_hours': (response['total_duration_hours'] ?? 0.0).toDouble(),
      'areas_visited': response['areas_visited'] ?? 0,
      'routes_completed': response['routes_completed'] ?? 0,
      'pins_created': response['pins_created'] ?? 0,
      'pins_liked_count': response['pins_liked_count'] ?? 0,
      'followers_count': response['followers_count'] ?? 0,
      'following_count': response['following_count'] ?? 0,
    };
    
    return UserStatistics.fromJson(safeData);
  } catch (e) {
    print('Error getting user statistics: $e');
    // エラー時もゼロ値のオブジェクトを返す
    return UserStatistics.empty();
  }
}
```

**UserStatisticsモデルにemptyコンストラクタ追加**:

**ファイル**: `lib/models/user_statistics.dart`

```dart
class UserStatistics {
  final int totalWalks;
  final int totalOutingWalks;
  final double totalDistanceKm;
  final double totalDurationHours;
  final int areasVisited;
  final int routesCompleted;
  final int pinsCreated;
  final int pinsLikedCount;
  final int followersCount;
  final int followingCount;

  const UserStatistics({
    required this.totalWalks,
    required this.totalOutingWalks,
    required this.totalDistanceKm,
    required this.totalDurationHours,
    required this.areasVisited,
    required this.routesCompleted,
    required this.pinsCreated,
    required this.pinsLikedCount,
    required this.followersCount,
    required this.followingCount,
  });

  // ゼロ値のインスタンスを返すファクトリ
  factory UserStatistics.empty() {
    return const UserStatistics(
      totalWalks: 0,
      totalOutingWalks: 0,
      totalDistanceKm: 0.0,
      totalDurationHours: 0.0,
      areasVisited: 0,
      routesCompleted: 0,
      pinsCreated: 0,
      pinsLikedCount: 0,
      followersCount: 0,
      followingCount: 0,
    );
  }

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalWalks: json['total_walks'] as int? ?? 0,
      totalOutingWalks: json['total_outing_walks'] as int? ?? 0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      totalDurationHours: (json['total_duration_hours'] as num?)?.toDouble() ?? 0.0,
      areasVisited: json['areas_visited'] as int? ?? 0,
      routesCompleted: json['routes_completed'] as int? ?? 0,
      pinsCreated: json['pins_created'] as int? ?? 0,
      pinsLikedCount: json['pins_liked_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
    );
  }
}
```

**期待される効果**:
- エラーメッセージが消える
- ProfileTab が正常に表示される
- 統計データがすべて0として表示される（walks データがないため）

---

#### 解決策B: walksテーブル作成（Phase 1で対応）

**Phase 1 で実装予定** - データベーススキーマに含まれる

---

### Priority 3: README更新（10分）

**ファイル**: `README.md`

**追加すべき内容**:
```markdown
## 🚀 現在の状態（2025-11-23）

### ✅ 動作確認済み
- 4タブUI（ホーム/マップ/記録/プロフィール）
- 認証システム（ログイン/サインアップ）
- 地図表示（Thunderforest タイル）
- プロフィール表示

### ⚠️ データ不足により動作未確認
- 散歩記録機能（walks テーブル未作成）
- ピン投稿機能（pins テーブル未作成）
- ソーシャル機能（データ不足）

### 🔧 次のステップ
詳細は `CURRENT_STATUS_AND_ROADMAP.md` を参照

## 📱 動作確認方法

### テストアカウント
- email: test1@example.com / password: test123
- email: test2@example.com / password: test123
- email: test3@example.com / password: test123

### ビルド・実行
```bash
# 依存関係インストール
flutter pub get

# iOS Simulator で実行
flutter run

# Android Emulator で実行
flutter run
```
```

---

## 📋 修正チェックリスト

### 即座に対応可能（30分以内）

- [x] Thunderforest APIキー設定（完了）
- [ ] ProfileTab - フォロワー/フォロー ナビゲーション修正
- [ ] RecordsTab - お気に入り ナビゲーション修正
- [ ] UserStatistics NULL安全処理追加
- [ ] README更新

### Phase 2 で対応（3-4日）

- [ ] SettingsScreen 実装
- [ ] ProfileEditScreen 実装
- [ ] DogListScreen 実装
- [ ] BadgeListScreen 実装
- [ ] WalkDetailScreen 実装

### Phase 1 で対応（データベース）

- [ ] walks テーブル作成
- [ ] pins テーブル作成
- [ ] 必要なRPC関数作成
- [ ] テストデータ投入

---

## 🎯 まとめ

### 今日中にできること
1. ✅ Thunderforest APIキー設定（完了）
2. ナビゲーション修正（2箇所、10分）
3. NULL安全処理追加（20分）
4. README更新（5分）

**合計時間: 約35分で完了**

### 明日から始めること
1. データベーススキーマ設計（Phase 1）
2. テーブル作成とマイグレーション実行
3. RPC関数実装

### 1週間後の目標
- Phase 1 完全完了
- Phase 2 開始（UI/UX修正）
- アプリの基本動作が全て動く状態

---

**最終更新**: 2025-11-23

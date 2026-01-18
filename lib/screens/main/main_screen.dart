import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../widgets/active_walk_banner.dart';
import 'tabs/home_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/profile_tab.dart';
import '../daily/daily_walk_landing_screen.dart';

/// MainScreen - 新UI（BottomNavigationBar採用）
/// 
/// アプリの本来の目的を重視:
/// PRIMARY: おでかけ散歩 - 公式ルート、エリア、コミュニティ
/// SECONDARY: 日常の散歩 - プライベート記録
/// 
/// 5つのタブ:
/// 1. ホーム - おでかけ散歩優先（エリア、公式ルート）
/// 2. マップ - おでかけ散歩中心のマップ機能
/// 3. お散歩 - 散歩開始の統一入口（日常散歩・お出かけ散歩）
/// 4. ライブラリ - 日常の散歩+統計+バッジ統合
/// 5. プロフィール - アカウント管理
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  // タブページのリスト
  // タブページリスト（動的生成）
  List<Widget> _buildPages() {
    return [
      const HomeTab(),
      const MapTab(),
      Container(), // お散歩タブ（ボトムシート表示のため空）
      const LibraryTab(),
      const ProfileTab(),
    ];
  }

  // タブ切り替え
  void _onItemTapped(int index) {
    // お散歩タブ（index 2）の場合はボトムシート表示
    if (index == 2) {
      _showWalkTypeSelection();
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  /// 散歩タイプ選択ボトムシート
  void _showWalkTypeSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ハンドル
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // タイトル
                Text(
                  'お散歩を開始',
                  style: WanMapTypography.headlineSmall.copyWith(
                    color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '散歩のタイプを選択してください',
                  style: WanMapTypography.bodyMedium.copyWith(
                    color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 日常散歩ボタン
                _buildWalkButton(
                  context: context,
                  isDark: isDark,
                  icon: Icons.pets,
                  title: '日常散歩',
                  description: '自由に歩く',
                  color: WanMapColors.accent,
                  isFilled: true,
                  onTap: () {
                    Navigator.pop(context);
                    // 日常散歩開始画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyWalkLandingScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // お出かけ散歩ボタン
                _buildWalkButton(
                  context: context,
                  isDark: isDark,
                  icon: Icons.luggage,
                  title: 'お出かけ散歩',
                  description: 'ルートを選んで歩く',
                  color: WanMapColors.primary,
                  isFilled: false,
                  onTap: () {
                    Navigator.pop(context);
                    // マップタブへ遷移
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 散歩ボタンウィジェット
  Widget _buildWalkButton({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isFilled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isFilled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: WanMapTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: WanMapTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 28, color: color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: WanMapTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: WanMapTypography.bodySmall.copyWith(
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 18, color: color),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _buildPages(); // 動的に生成

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      // AppBarは各タブで個別に実装（タブごとに最適化）
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      // 散歩中バナー（BottomNavigationBarの上に表示）
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 散歩中バナー
          const ActiveWalkBanner(),
          // BottomNavigationBar
          BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: WanMapColors.accent,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[500],
        backgroundColor: isDark 
            ? WanMapColors.cardDark 
            : Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: WanMapTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: WanMapTypography.caption,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            activeIcon: Icon(Icons.home, size: 28),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined, size: 28),
            activeIcon: Icon(Icons.map, size: 28),
            label: 'マップ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined, size: 32),
            activeIcon: Icon(Icons.pets, size: 32),
            label: 'お散歩',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 28),
            activeIcon: Icon(Icons.history, size: 28),
            label: 'ライブラリ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'プロフィール',
          ),
        ],
          ),
        ],
      ),
    );
  }
}

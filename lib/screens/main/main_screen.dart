import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../widgets/active_walk_banner.dart';
import 'tabs/home_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/records_tab.dart';
import 'tabs/profile_tab.dart';

/// MainScreen - 新UI（BottomNavigationBar採用）
/// 
/// アプリの本来の目的を重視:
/// PRIMARY: おでかけ散歩 - 公式ルート、エリア、コミュニティ
/// SECONDARY: 日常の散歩 - プライベート記録
/// 
/// 4つのタブ:
/// 1. ホーム - おでかけ散歩優先（エリア、公式ルート）
/// 2. マップ - おでかけ散歩中心のマップ機能
/// 3. ライブラリ - 日常の散歩+統計+バッジ統合
/// 4. プロフィール - アカウント管理
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  // タブページのリスト
  static const List<Widget> _pages = [
    HomeTab(),
    MapTab(),
    RecordsTab(),
    ProfileTab(),
  ];

  // タブ切り替え
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      // AppBarは各タブで個別に実装（タブごとに最適化）
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
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
            icon: Icon(Icons.directions_walk_outlined, size: 28),
            activeIcon: Icon(Icons.directions_walk, size: 28),
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

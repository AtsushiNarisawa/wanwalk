import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import 'tabs/home_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/profile_tab.dart';
import '../daily/daily_walk_landing_screen.dart';

/// MainScreen - ビジュアル重視の新UI（BottomNavigationBar採用）
/// 
/// アプリの本来の目的を重視:
/// PRIMARY: おでかけ散歩 - 公式ルート、エリア、コミュニティ
/// SECONDARY: 日常の散歩 - プライベート記録
/// 
/// 4つのタブ:
/// 1. ホーム - ビジュアル重視（マップ、最新ピン、人気ルート）
/// 2. ルート - お出かけ散歩のマップ機能
/// 3. クイック記録 - 日常の散歩を始める・履歴を見る
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
    DailyWalkLandingScreen(),
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
      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.route_outlined, size: 28),
            activeIcon: Icon(Icons.route, size: 28),
            label: 'ルート',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fiber_manual_record_outlined, size: 28),
            activeIcon: Icon(Icons.fiber_manual_record, size: 28),
            label: 'クイック記録',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}

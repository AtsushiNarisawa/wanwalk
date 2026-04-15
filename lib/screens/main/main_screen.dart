import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../services/onboarding_service.dart';
import '../../utils/logger.dart';
import '../../widgets/active_walk_banner.dart';
import 'tabs/home_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/walk_type_bottom_sheet.dart';
import '../daily/daily_walk_landing_screen.dart';
import '../routes/public_routes_screen.dart';
import '../pin/pin_route_picker_screen.dart';
import '../../providers/official_routes_screen_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_selection_screen.dart';

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

  // コーチマーク用 GlobalKeys
  final _keyNavHome = GlobalKey();
  final _keyNavMap = GlobalKey();
  final _keyNavWalk = GlobalKey();
  final _keyNavLibrary = GlobalKey();
  final _keyNavProfile = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 初回起動時にコーチマークを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
    });
  }

  /// 初回起動チェック → コーチマーク表示
  Future<void> _checkAndShowOnboarding() async {
    final completed = await OnboardingService.isCoachMarkCompleted();
    appLog('🎓 CoachMark completed: $completed');
    if (!completed && mounted) {
      // 権限ダイアログ等が出る時間を十分に待ってからコーチマークを表示
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        appLog('🎓 Showing coach marks...');
        _showCoachMarks();
      }
    }
  }

  /// コーチマークを表示
  void _showCoachMarks() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targets = <TargetFocus>[
      // Step 1: ホームタブ
      _buildTarget(
        key: _keyNavHome,
        identify: 'home',
        title: 'ホーム',
        description: 'おすすめエリアや人気ルートを\nチェックできます',
        icon: Icons.home,
        isFirst: true,
      ),
      // Step 2: マップタブ
      _buildTarget(
        key: _keyNavMap,
        identify: 'map',
        title: 'マップ',
        description: '周辺のルートやスポットを\n地図で探せます',
        icon: Icons.map,
      ),
      // Step 3: お散歩タブ（メイン機能）
      _buildTarget(
        key: _keyNavWalk,
        identify: 'walk',
        title: 'お散歩',
        description: 'ここから散歩を始められます！\n日常散歩・お出かけ散歩を選べます',
        icon: PhosphorIcons.dog(),
        isHighlight: true,
      ),
      // Step 4: ライブラリタブ
      _buildTarget(
        key: _keyNavLibrary,
        identify: 'library',
        title: 'ライブラリ',
        description: '散歩の履歴や統計を\n確認できます',
        icon: Icons.history,
      ),
      // Step 5: プロフィールタブ
      _buildTarget(
        key: _keyNavProfile,
        identify: 'profile',
        title: 'プロフィール',
        description: '愛犬の情報やアカウントを\n管理できます',
        icon: Icons.person,
        isLast: true,
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: isDark
          ? WanWalkColors.backgroundDark
          : const Color(0xFF3D2F2B),
      opacityShadow: 0.85,
      textSkip: 'スキップ',
      textStyleSkip: WanWalkTypography.bodyMedium.copyWith(
        color: Colors.white.withValues(alpha: 0.8),
        fontWeight: FontWeight.bold,
      ),
      paddingFocus: 8,
      pulseEnable: true,
      onFinish: () {
        OnboardingService.markCoachMarkCompleted();
      },
      onSkip: () {
        OnboardingService.markCoachMarkCompleted();
        return true;
      },
    ).show(context: context);
  }

  /// 個別ターゲットの作成
  TargetFocus _buildTarget({
    required GlobalKey key,
    required String identify,
    required String title,
    required String description,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
    bool isHighlight = false,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      alignSkip: Alignment.topRight,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      enableTargetTab: true,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          padding: const EdgeInsets.only(bottom: 20),
          child: _CoachMarkContent(
            title: title,
            description: description,
            icon: icon,
            stepIndex: isFirst ? 0 : isLast ? 4 : isHighlight ? 2 : -1,
            totalSteps: 5,
            isFirst: isFirst,
            isLast: isLast,
            isHighlight: isHighlight,
          ),
        ),
      ],
    );
  }

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

  /// 散歩タイプ選択ボトムシート（WalkTypeBottomSheetに統一）
  void _showWalkTypeSelection() async {
    // ログインチェック：散歩記録にはログインが必要
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    final result = await WalkTypeBottomSheet.show(context);
    if (result == null || !mounted) return;

    switch (result) {
      case 'daily':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyWalkLandingScreen()),
        );
        break;
      case 'outing':
        ref.read(sortOptionProvider.notifier).state = RouteSortOption.distanceAsc;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PublicRoutesScreen()),
        );
        break;
      case 'pin_only':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PinRoutePickerScreen()),
        );
        break;
    }
  }

  /// ログインが必要な場合のダイアログ表示
  void _showLoginRequiredDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? WanWalkColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.login, color: WanWalkColors.primary),
            const SizedBox(width: 8),
            Text(
              'ログインが必要です',
              style: TextStyle(
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          '散歩を記録するにはログインが必要です。\nログインすると散歩の距離や時間を保存できます。',
          style: TextStyle(
            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: TextStyle(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthSelectionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WanWalkColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ログイン'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _buildPages(); // 動的に生成

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
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
        selectedItemColor: WanWalkColors.accent,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[500],
        backgroundColor: isDark
            ? WanWalkColors.cardDark
            : Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: WanWalkTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: WanWalkTypography.caption,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined, size: 28),
            activeIcon: SizedBox(key: _keyNavHome, child: const Icon(Icons.home, size: 28)),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavMap, child: const Icon(Icons.map_outlined, size: 28)),
            activeIcon: const Icon(Icons.map, size: 28),
            label: 'マップ',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavWalk, child: Icon(PhosphorIcons.personSimpleWalk(), size: 30)),
            activeIcon: Icon(PhosphorIcons.personSimpleWalk(PhosphorIconsStyle.fill), size: 30),
            label: 'お散歩',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavLibrary, child: const Icon(Icons.history, size: 28)),
            activeIcon: const Icon(Icons.history, size: 28),
            label: 'ライブラリ',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavProfile, child: const Icon(Icons.person_outline, size: 28)),
            activeIcon: const Icon(Icons.person, size: 28),
            label: 'プロフィール',
          ),
        ],
          ),
        ],
      ),
    );
  }
}

/// コーチマーク吹き出しの中身ウィジェット
class _CoachMarkContent extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final int stepIndex;
  final int totalSteps;
  final bool isFirst;
  final bool isLast;
  final bool isHighlight;

  const _CoachMarkContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.stepIndex,
    required this.totalSteps,
    required this.isFirst,
    required this.isLast,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // アイコン
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isHighlight
                ? WanWalkColors.accent
                : WanWalkColors.primary.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        // タイトル
        Text(
          title,
          style: WanWalkTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // 説明文
        Text(
          description,
          style: WanWalkTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // ステップインジケーター（ドット）
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isCurrent = (isFirst && index == 0) ||
                (isLast && index == 4) ||
                (isHighlight && index == 2) ||
                (!isFirst && !isLast && !isHighlight && index == stepIndex);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // 操作ヒント
        Text(
          isLast ? 'タップして始めましょう！' : 'タップして次へ',
          style: WanWalkTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

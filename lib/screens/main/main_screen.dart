import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_icons.dart';
import '../../config/wanwalk_typography.dart';
import '../../services/onboarding_service.dart';
import '../../services/app_review_service.dart';
import '../../utils/logger.dart';
import '../../widgets/active_walk_banner.dart';
import 'tabs/home_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/profile_tab.dart';
import '../routes/public_routes_screen.dart';
import '../../providers/official_routes_screen_provider.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../providers/analytics_provider.dart';

/// MainScreen - 新UI（BottomNavigationBar採用）
///
/// アプリの本来の目的を重視:
/// PRIMARY: おでかけ散歩 - 公式ルート、エリア、コミュニティ
/// SECONDARY: 日常の散歩 - プライベート記録
///
/// 5つのタブ:
/// 1. ホーム - おでかけ散歩優先（エリア、公式ルート）
/// 2. マップ - おでかけ散歩中心のマップ機能
/// 3. お散歩 - お出かけ散歩（公式ルート一覧）への直行入口。
///    日常散歩は一覧上部の副リンク、ピン投稿はマップ/散歩中の文脈に集約（案A 2026-06-15）
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A11: アプリ kill/クラッシュで中断した散歩記録があれば復元し、
      // ActiveWalkBanner から復帰できるようにする。
      ref.read(gpsProviderRiverpod.notifier).restoreIfAny();
      // レビュー促進: セッション数をカウント（初回セッション除外の判定に使う）
      AppReviewService.instance.recordLaunch();
      // 初回起動時にコーチマークを表示
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
        description: 'ここから公式ルートで\nお散歩を始められます',
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
    // お散歩タブ（index 2）は「お出かけ散歩＝公式ルート一覧」へ直行（案A）
    if (index == 2) {
      _openWalkEntry();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // M3: お散歩タブ二度押しで遷移が二重発火するのを抑制
  bool _walkEntryActive = false;

  /// 案A（2026-06-15）: お散歩タブ→公式ルート一覧（お出かけ散歩）へ直行。
  /// 旧3択シート（お出かけ/日常/ピン投稿のみ）を廃止し、北極星=体験到達への
  /// 最短動線に一本化。日常散歩は一覧上部の副リンク、ピン投稿はマップ/散歩中の
  /// 文脈アクションに集約済み（機能ロスなし）。
  /// §8: ログイン必須は撤廃済み。匿名サインインは walking_screen の散歩開始時に付与。
  void _openWalkEntry() async {
    if (_walkEntryActive) return;
    _walkEntryActive = true;

    // GA4: お散歩タブからの入口計測（6月末ベンチで他入口と比較）
    unawaited(ref.read(analyticsServiceProvider).logWalkTabOpen());
    // 現在地から近い順で提示
    ref.read(sortOptionProvider.notifier).state = RouteSortOption.distanceAsc;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PublicRoutesScreen()),
      );
    } finally {
      _walkEntryActive = false;
    }
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
          // §7 Phosphor Regular のみ。active 状態は塗りつぶし(Fill)でなく
          // selectedItemColor(深緑) + ラベル太字で表現する。
          BottomNavigationBarItem(
            icon: Icon(WanWalkIcons.house, size: 28),
            activeIcon: SizedBox(key: _keyNavHome, child: Icon(WanWalkIcons.house, size: 28)),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavMap, child: Icon(WanWalkIcons.mapTrifold, size: 28)),
            activeIcon: Icon(WanWalkIcons.mapTrifold, size: 28),
            label: 'マップ',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavWalk, child: Icon(WanWalkIcons.personWalk, size: 30)),
            activeIcon: Icon(WanWalkIcons.personWalk, size: 30),
            label: 'お散歩',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavLibrary, child: Icon(WanWalkIcons.clockCounterClockwise, size: 28)),
            activeIcon: Icon(WanWalkIcons.clockCounterClockwise, size: 28),
            label: 'ライブラリ',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(key: _keyNavProfile, child: Icon(WanWalkIcons.user, size: 28)),
            activeIcon: Icon(WanWalkIcons.user, size: 28),
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

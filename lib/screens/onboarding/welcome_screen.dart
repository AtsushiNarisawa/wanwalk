import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_icons.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/push_notification_provider.dart';
import '../../services/onboarding_service.dart';
import '../main/main_screen.dart';
import 'pre_permission_screen.dart';

/// ウェルカムスライド画面
/// 初回起動時にアプリの価値を3枚のスライドで伝える
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // §7 Phosphor Regular のみ。アクセント色は accentPrimary(深緑) に統一。
  static final _slides = [
    _SlideData(
      icon: WanWalkIcons.path,
      iconColor: WanWalkColors.accentPrimary,
      title: '新しい散歩コースを発見',
      description: '公式ルートで愛犬との散歩が\nもっと楽しくなります',
      subText: '箱根・湘南・鎌倉など人気エリアのルートを収録',
    ),
    _SlideData(
      icon: WanWalkIcons.roadHorizon,
      iconColor: WanWalkColors.accentPrimary,
      title: '現地ではアプリが道案内',
      description: '知らない土地でも、見どころや\n愛犬と入れる一軒を見逃さない',
      subText: '選んだコースを現地で静かに案内',
    ),
    _SlideData(
      icon: WanWalkIcons.images,
      iconColor: WanWalkColors.accentPrimary,
      title: '歩いた一日を振り返る',
      description: '公式ルートで歩いた記録を\n写真とともに残せます',
      subText: '日常の散歩もまとめて見返せます',
    ),
  ];

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWelcome();
    }
  }

  Future<void> _completeWelcome() async {
    await OnboardingService.markWelcomeCompleted();
    if (!mounted) return;

    // B1 §3.1: ウェルカム完了直後にプリ許可画面を 1 度だけ挟む。
    // OS 既許可・拒否済・14 日以内に「あとで」した場合はスキップ。
    final permService = ref.read(notificationPermissionServiceProvider);
    final shouldShow = await permService.shouldShowPrePrompt();
    if (!mounted) return;

    if (shouldShow) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PrePermissionScreen()),
      );
      if (!mounted) return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // スキップボタン
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _completeWelcome,
                  child: Text(
                    'スキップ',
                    style: WanWalkTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanWalkColors.textSecondaryDark
                          : WanWalkColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
            // スライドコンテンツ
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _SlideContent(
                    data: _slides[index],
                    isDark: isDark,
                  );
                },
              ),
            ),
            // ドットインジケーター + ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // ドットインジケーター
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? WanWalkColors.accentPrimary
                              : (isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // 次へ / 始めるボタン
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _goToNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WanWalkColors.accentPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'WanWalkを始める'
                            : '次へ',
                        style: WanWalkTypography.buttonLarge.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// スライドデータ
class _SlideData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String subText;

  const _SlideData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.subText,
  });
}

/// スライドコンテンツウィジェット
class _SlideContent extends StatelessWidget {
  final _SlideData data;
  final bool isDark;

  const _SlideContent({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン（大きめの丸）
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 72,
              color: data.iconColor,
            ),
          ),
          const SizedBox(height: 48),
          // タイトル
          Text(
            data.title,
            style: WanWalkTypography.headlineLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? WanWalkColors.textPrimaryDark
                  : WanWalkColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 説明文
          Text(
            data.description,
            style: WanWalkTypography.bodyLarge.copyWith(
              fontSize: 17,
              height: 1.6,
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // サブテキスト
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data.subText,
              style: WanWalkTypography.bodySmall.copyWith(
                color: data.iconColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

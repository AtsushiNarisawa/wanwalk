import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import 'contact_support_screen.dart';

/// ヘルプ・サポート画面
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanWalkColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text(
          'ヘルプ・サポート',
          style: WanWalkTypography.heading2,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(WanWalkSpacing.medium),
        children: [
          // お問い合わせボタン
          _buildContactButton(context, isDark),
          const SizedBox(height: WanWalkSpacing.large),

          // よくある質問セクション
          _buildSectionHeader('よくある質問', isDark),
          const SizedBox(height: WanWalkSpacing.small),
          _buildFAQCard(isDark, children: [
            _buildFAQItem(
              context,
              isDark,
              question: 'WanWalkとは何ですか？',
              answer:
                  'WanWalkは、愛犬との散歩ルートを記録・共有できるアプリです。他のユーザーのおすすめルートを見つけたり、散歩中の写真を投稿したりできます。',
            ),
            const Divider(height: 1),
            _buildFAQItem(
              context,
              isDark,
              question: '散歩ルートの記録方法は？',
              answer:
                  'ホーム画面下部の「散歩」ボタンをタップして「散歩を開始」を選択すると、GPSで自動的にルートが記録されます。散歩が終わったら「散歩を終了」をタップしてください。',
            ),
            const Divider(height: 1),
            _buildFAQItem(
              context,
              isDark,
              question: 'ピン（写真投稿）の使い方は？',
              answer:
                  '散歩中に撮影ボタンをタップすると、その場所に写真とコメントを投稿できます。投稿したピンは「みんなのピン」に表示され、他のユーザーと共有されます。',
            ),
            const Divider(height: 1),
            _buildFAQItem(
              context,
              isDark,
              question: 'プライバシー設定について',
              answer:
                  '設定画面からプロフィール情報の公開範囲を変更できます。位置情報は散歩記録時のみ使用され、リアルタイムで共有されることはありません。',
            ),
            const Divider(height: 1),
            _buildFAQItem(
              context,
              isDark,
              question: 'アカウントの削除方法は？',
              answer:
                  'プロフィール画面 → 設定 → 「アカウント削除」から手続きできます。削除後、投稿したルートやピンも全て削除されます。',
            ),
          ]),
          const SizedBox(height: WanWalkSpacing.large),

          // 使い方ガイドセクション
          _buildSectionHeader('使い方ガイド', isDark),
          const SizedBox(height: WanWalkSpacing.small),
          _buildGuideCard(isDark, children: [
            _buildGuideItem(
              context,
              isDark,
              icon: Icons.map_outlined,
              title: 'マップの使い方',
              description: 'エリアごとのおすすめルートを探す',
            ),
            const Divider(height: 1),
            _buildGuideItem(
              context,
              isDark,
              icon: Icons.directions_walk,
              title: '散歩の記録',
              description: 'GPSで散歩ルートを自動記録',
            ),
            const Divider(height: 1),
            _buildGuideItem(
              context,
              isDark,
              icon: Icons.photo_camera,
              title: 'ピンの投稿',
              description: '散歩中の写真をシェア',
            ),
            const Divider(height: 1),
            _buildGuideItem(
              context,
              isDark,
              icon: Icons.favorite_outline,
              title: 'お気に入り管理',
              description: '気に入ったルートを保存',
            ),
          ]),
          const SizedBox(height: WanWalkSpacing.large),

          // アプリ情報
          _buildSectionHeader('アプリ情報', isDark),
          const SizedBox(height: WanWalkSpacing.small),
          _buildInfoCard(isDark),
        ],
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, bool isDark) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: WanWalkColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: WanWalkSpacing.medium,
          horizontal: WanWalkSpacing.large,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.support_agent, size: 24),
      label: Text(
        'お問い合わせ',
        style: WanWalkTypography.heading3.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.small),
      child: Text(
        title,
        style: WanWalkTypography.heading2.copyWith(
          color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFAQCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildFAQItem(
    BuildContext context,
    bool isDark, {
    required String question,
    required String answer,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: WanWalkSpacing.medium,
          vertical: WanWalkSpacing.small,
        ),
        title: Text(
          question,
          style: WanWalkTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
          ),
        ),
        iconColor: WanWalkColors.accent,
        collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WanWalkSpacing.medium,
              0,
              WanWalkSpacing.medium,
              WanWalkSpacing.medium,
            ),
            child: Text(
              answer,
              style: WanWalkTypography.body.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildGuideItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.medium,
        vertical: WanWalkSpacing.small,
      ),
      leading: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.small),
        decoration: BoxDecoration(
          color: WanWalkColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: WanWalkColors.accent,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: WanWalkTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        description,
        style: WanWalkTypography.body.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.pets,
                color: WanWalkColors.accent,
                size: 32,
              ),
              const SizedBox(width: WanWalkSpacing.small),
              Text(
                'WanWalk',
                style: WanWalkTypography.headlineLarge.copyWith(
                  color: WanWalkColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanWalkSpacing.medium),
          Text(
            'Version 1.0.0',
            style: WanWalkTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.small),
          Text(
            'by DogHub 箱根',
            style: WanWalkTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.medium),
          Text(
            '愛犬との散歩をもっと楽しく',
            style: WanWalkTypography.caption.copyWith(
              color: isDark ? Colors.white60 : Colors.black45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

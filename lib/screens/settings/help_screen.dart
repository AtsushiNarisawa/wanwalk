import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import 'contact_support_screen.dart';

/// ヘルプ・サポート画面
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: Text(
          'ヘルプ・サポート',
          style: WanMapTypography.heading2,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(WanMapSpacing.medium),
        children: [
          // お問い合わせボタン
          _buildContactButton(context, isDark),
          const SizedBox(height: WanMapSpacing.large),

          // よくある質問セクション
          _buildSectionHeader('よくある質問', isDark),
          const SizedBox(height: WanMapSpacing.small),
          _buildFAQCard(isDark, children: [
            _buildFAQItem(
              context,
              isDark,
              question: 'WanMapとは何ですか？',
              answer:
                  'WanMapは、愛犬との散歩ルートを記録・共有できるアプリです。他のユーザーのおすすめルートを見つけたり、散歩中の写真を投稿したりできます。',
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
          const SizedBox(height: WanMapSpacing.large),

          // 使い方ガイドセクション
          _buildSectionHeader('使い方ガイド', isDark),
          const SizedBox(height: WanMapSpacing.small),
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
          const SizedBox(height: WanMapSpacing.large),

          // アプリ情報
          _buildSectionHeader('アプリ情報', isDark),
          const SizedBox(height: WanMapSpacing.small),
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
        backgroundColor: WanMapColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: WanMapSpacing.medium,
          horizontal: WanMapSpacing.large,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.support_agent, size: 24),
      label: Text(
        'お問い合わせ',
        style: WanMapTypography.heading3.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.small),
      child: Text(
        title,
        style: WanMapTypography.heading2.copyWith(
          color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFAQCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
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
          horizontal: WanMapSpacing.medium,
          vertical: WanMapSpacing.small,
        ),
        title: Text(
          question,
          style: WanMapTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
          ),
        ),
        iconColor: WanMapColors.accent,
        collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WanMapSpacing.medium,
              0,
              WanMapSpacing.medium,
              WanMapSpacing.medium,
            ),
            child: Text(
              answer,
              style: WanMapTypography.body.copyWith(
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
        color: isDark ? WanMapColors.cardDark : Colors.white,
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
        horizontal: WanMapSpacing.medium,
        vertical: WanMapSpacing.small,
      ),
      leading: Container(
        padding: const EdgeInsets.all(WanMapSpacing.small),
        decoration: BoxDecoration(
          color: WanMapColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: WanMapColors.accent,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: WanMapTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        description,
        style: WanMapTypography.body.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.pets,
                color: WanMapColors.accent,
                size: 32,
              ),
              const SizedBox(width: WanMapSpacing.small),
              Text(
                'WanMap',
                style: WanMapTypography.heading1.copyWith(
                  color: WanMapColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            'Version 1.0.0',
            style: WanMapTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.small),
          Text(
            'by DogHub 箱根',
            style: WanMapTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            '愛犬との散歩をもっと楽しく',
            style: WanMapTypography.caption.copyWith(
              color: isDark ? Colors.white60 : Colors.black45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

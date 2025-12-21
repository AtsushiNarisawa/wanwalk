// ==================================================
// Privacy Policy Screen for WanWalk v2
// ==================================================
// Author: AI Assistant
// Created: 2025-11-21
// Purpose: Display privacy policy
// ==================================================

import 'package:flutter/material.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: WanMapSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              Text(
                'WanMap プライバシーポリシー',
                style: WanMapTypography.headlineLarge.copyWith(
                  color: WanMapColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: WanMapSpacing.sm),

              // 更新日
              Text(
                '最終更新日: 2025年11月21日',
                style: WanMapTypography.bodySmall.copyWith(
                  color: WanMapColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: WanMapSpacing.xl),

              _buildSection(
                '個人情報の収集',
                'WanMap（以下「当社」）は、本サービスの利用に際して、以下の個人情報を収集します。\n\n'
                '• メールアドレス\n'
                '• ユーザー名\n'
                '• プロフィール情報（任意）\n'
                '• GPS位置情報\n'
                '• 散歩ルートデータ\n'
                '• 投稿した写真・コメント\n'
                '• デバイス情報（OS、機種名、アプリバージョン等）\n'
                '• 利用状況データ（アクセス日時、閲覧履歴等）',
              ),

              _buildSection(
                '個人情報の利用目的',
                '当社は、収集した個人情報を以下の目的で利用します。\n\n'
                '1. 本サービスの提供・運営のため\n'
                '2. ユーザーからのお問い合わせに回答するため\n'
                '3. ユーザーが利用中のサービスの新機能、更新情報、キャンペーン等の案内のため\n'
                '4. メンテナンス、重要なお知らせなど必要に応じたご連絡のため\n'
                '5. 利用規約に違反したユーザーや、不正・不当な目的でサービスを利用しようとするユーザーの特定をし、ご利用をお断りするため\n'
                '6. ユーザーにご自身の登録情報の閲覧や変更、削除、ご利用状況の閲覧を行っていただくため\n'
                '7. サービスの改善や新サービスの開発のため\n'
                '8. その他、上記利用目的に付随する目的',
              ),

              _buildSection(
                '個人情報の第三者提供',
                '当社は、次に掲げる場合を除いて、あらかじめユーザーの同意を得ることなく、第三者に個人情報を提供することはありません。\n\n'
                '1. 法令に基づく場合\n'
                '2. 人の生命、身体または財産の保護のために必要がある場合であって、本人の同意を得ることが困難であるとき\n'
                '3. 公衆衛生の向上または児童の健全な育成の推進のために特に必要がある場合であって、本人の同意を得ることが困難であるとき\n'
                '4. 国の機関もしくは地方公共団体またはその委託を受けた者が法令の定める事務を遂行することに対して協力する必要がある場合であって、本人の同意を得ることにより当該事務の遂行に支障を及ぼすおそれがあるとき',
              ),

              _buildSection(
                'GPS位置情報の取り扱い',
                '本サービスでは、散歩ルートの記録機能を提供するため、ユーザーの位置情報を取得します。\n\n'
                '• 位置情報は、ルート記録中のみ取得されます\n'
                '• 位置情報は、ユーザーが明示的に記録を開始した場合のみ保存されます\n'
                '• 公開設定を「非公開」にしたルートの位置情報は、他のユーザーには表示されません\n'
                '• 位置情報の取得は、ユーザーがいつでも停止することができます\n'
                '• 保存された位置情報は、ユーザー自身で削除することができます',
              ),

              _buildSection(
                '写真・画像の取り扱い',
                'ユーザーが投稿した写真・画像について、以下の点にご注意ください。\n\n'
                '• 投稿された写真は、ルートと一緒に他のユーザーに公開される場合があります\n'
                '• 写真には、Exif情報（撮影日時、位置情報等）が含まれる場合があります\n'
                '• 当社は、不適切な写真を削除する権利を有します\n'
                '• 著作権や肖像権を侵害する写真の投稿は禁止します',
              ),

              _buildSection(
                'Cookie（クッキー）等の利用',
                '本サービスでは、ユーザーの利便性向上およびサービスの改善のために、Cookieおよび類似の技術を使用することがあります。\n\n'
                'Cookieによって収集される情報には、以下が含まれる場合があります：\n'
                '• ブラウザの種類とバージョン\n'
                '• オペレーティングシステム\n'
                '• 参照元のウェブサイト\n'
                '• アクセス日時\n'
                '• IPアドレス\n\n'
                'ユーザーは、ブラウザの設定によってCookieの受け入れを拒否することができますが、その場合、本サービスの一部機能が利用できなくなる可能性があります。',
              ),

              _buildSection(
                '個人情報の安全管理',
                '当社は、個人情報の漏えい、滅失またはき損の防止その他の個人情報の安全管理のために必要かつ適切な措置を講じます。\n\n'
                '具体的には：\n'
                '• SSL/TLSによる通信の暗号化\n'
                '• ファイアウォールの設置\n'
                '• アクセス制御の実施\n'
                '• 定期的なセキュリティ監査\n'
                '• 従業員への教育・研修',
              ),

              _buildSection(
                '個人情報の開示',
                'ユーザーは、当社に対し、個人情報保護法の定めるところにより、自己の個人情報の開示を請求することができます。\n\n'
                '開示請求は、以下の方法で受け付けます：\n'
                '• アプリ内の「設定」→「個人情報の管理」\n'
                '• 当社の問い合わせ窓口へのメール\n\n'
                '開示請求には、本人確認のための書類の提出が必要な場合があります。',
              ),

              _buildSection(
                '個人情報の訂正および削除',
                'ユーザーは、当社の保有する自己の個人情報が誤った情報である場合には、訂正、追加または削除を請求することができます。\n\n'
                '• プロフィール情報は、アプリ内で随時変更可能です\n'
                '• アカウント削除を希望する場合は、設定画面から実行できます\n'
                '• アカウント削除後、個人情報は原則として速やかに削除されます\n'
                '• ただし、法令に基づき保存が義務付けられているデータは、所定の期間保管されます',
              ),

              _buildSection(
                '個人情報の利用停止等',
                'ユーザーは、当社が、個人情報を利用目的の範囲を超えて取り扱っている場合、または不正な手段により取得した場合には、利用の停止または消去を請求することができます。',
              ),

              _buildSection(
                '子供のプライバシー',
                '当社は、13歳未満の子供から意図的に個人情報を収集することはありません。\n\n'
                '保護者の方へ：\n'
                'お子様が保護者の同意なく個人情報を提供したと思われる場合は、速やかに当社までご連絡ください。適切な措置を講じます。',
              ),

              _buildSection(
                'プライバシーポリシーの変更',
                '当社は、必要に応じて、本プライバシーポリシーを変更することがあります。\n\n'
                '• 変更後のプライバシーポリシーは、本ページに掲載した時点から効力を生じます\n'
                '• 重要な変更がある場合は、アプリ内通知等でお知らせします\n'
                '• 変更後も本サービスを継続して利用する場合、変更後のプライバシーポリシーに同意したものとみなします',
              ),

              _buildSection(
                'お問い合わせ窓口',
                '本ポリシーに関するお問い合わせは、以下の窓口までお願いいたします。\n\n'
                'サービス名: WanMap\n'
                'メールアドレス: privacy@wanmap.app\n\n'
                '※お問い合わせへの回答には、数日かかる場合があります。',
              ),

              const SizedBox(height: WanMapSpacing.xl),

              // 終わり
              Center(
                child: Text(
                  '以上',
                  style: WanMapTypography.bodyMedium.copyWith(
                    color: WanMapColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: WanMapSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WanMapTypography.headlineSmall.copyWith(
            color: WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        Text(
          content,
          style: WanMapTypography.bodyMedium.copyWith(
            color: WanMapColors.textSecondaryLight,
            height: 1.6,
          ),
        ),
        const SizedBox(height: WanMapSpacing.lg),
      ],
    );
  }
}

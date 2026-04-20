import 'package:flutter/material.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';

/// プライバシーポリシー画面
/// 最終更新: 2026-04-20（Build 31 Phase 2 改訂）
/// - 運営事業者を DogHub（個人事業主・代表 成澤元子）として明記
/// - 連絡先を info@dog-hub.shop に統一
/// - Cookie 章を削除し ATT / IDFA 章に置換
/// - 第三者 SDK 開示追加
/// - 法定代理人同意（16歳未満）を明記
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        title: const Text('プライバシーポリシー', style: WanWalkTypography.wwH2),
        backgroundColor: WanWalkColors.bgPrimary,
        foregroundColor: WanWalkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WanWalkSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WanWalk プライバシーポリシー',
                style: WanWalkTypography.wwH1,
              ),
              const SizedBox(height: WanWalkSpacing.s2),
              Text(
                '最終更新日: 2026年4月20日',
                style: WanWalkTypography.wwCaption,
              ),
              const SizedBox(height: WanWalkSpacing.s6),

              _buildSection(
                '1. 運営事業者',
                'WanWalk（以下「本サービス」）は、以下の事業者が運営しています。\n\n'
                '• 屋号: DogHub\n'
                '• 代表: 成澤元子\n'
                '• 事業形態: 個人事業主\n'
                '• 所在地: 神奈川県足柄下郡箱根町仙石原\n'
                '• お問い合わせ: info@dog-hub.shop',
              ),

              _buildSection(
                '2. 取得する情報',
                '本サービスの提供にあたり、以下の情報を取得します。\n\n'
                '• メールアドレス・ユーザー名・プロフィール情報\n'
                '• 愛犬情報（名前・犬種・年齢等／任意）\n'
                '• GPS位置情報（散歩記録中のみ）\n'
                '• 散歩ルートデータ（距離・時間・軌跡）\n'
                '• ユーザーが投稿した写真・コメント・ピン\n'
                '• デバイス情報（OS種別・機種名・アプリバージョン）\n'
                '• 広告識別子（IDFA等。ATT許可時のみ）\n'
                '• 利用状況データ（アクセス日時・画面遷移履歴）',
              ),

              _buildSection(
                '3. 利用目的',
                '取得した情報は以下の目的で利用します。\n\n'
                '1. 本サービスの提供・運営・改善\n'
                '2. 散歩ルート・ピンの記録と表示\n'
                '3. ユーザーからのお問い合わせへの対応\n'
                '4. 新機能・重要なお知らせの通知\n'
                '5. 利用規約違反の調査・対応\n'
                '6. 匿名化された統計情報の作成（利用分析）\n'
                '7. その他、上記に付随する目的',
              ),

              _buildSection(
                '4. 第三者提供',
                '次の場合を除き、あらかじめ本人の同意を得ることなく個人情報を第三者に提供しません。\n\n'
                '• 法令に基づく場合\n'
                '• 人の生命・身体・財産の保護のために必要であり、本人の同意を得ることが困難なとき\n'
                '• 公衆衛生・児童の健全育成のために特に必要があり、本人の同意を得ることが困難なとき\n'
                '• 国・地方公共団体等の法令事務の遂行に協力する必要があるとき',
              ),

              _buildSection(
                '5. 利用する第三者サービス（SDK等）',
                '本サービスは以下の外部サービスを利用しています。各サービスの取扱いは各社のプライバシーポリシーに従います。\n\n'
                '• Supabase（データベース・認証） — 米国\n'
                '• Apple Sign in with Apple（認証）\n'
                '• Google Sign-In（認証）\n'
                '• OpenStreetMap（地図タイル）\n'
                '• Google Places API（スポット情報・写真取得）\n'
                '• Apple Push Notification service（プッシュ通知）\n\n'
                '一部の情報は上記サービスの所在国（米国等）のサーバーで処理される場合があります。',
              ),

              _buildSection(
                '6. GPS位置情報の取り扱い',
                '散歩記録機能のため、位置情報を取得します。\n\n'
                '• 位置情報は、ユーザーが明示的に記録を開始した場合のみ取得・保存します\n'
                '• バックグラウンド追跡は、散歩記録中のみ行います\n'
                '• 非公開設定にした記録は他のユーザーには表示されません\n'
                '• 位置情報の取得は、OS の設定からいつでも停止できます\n'
                '• 保存済みの記録はアプリ内から削除できます',
              ),

              _buildSection(
                '7. 写真・画像の取り扱い',
                '投稿される写真・画像について以下にご注意ください。\n\n'
                '• 投稿された写真は、ルート・ピンと共に他のユーザーに公開される場合があります\n'
                '• 写真に含まれるExif情報（撮影日時・位置情報）は、投稿前に自動的に削除または匿名化します\n'
                '• 他者が写り込んでいる写真を投稿する際は、必ずご本人の同意を得てください（肖像権）\n'
                '• 著作権を侵害する写真の投稿は禁止します\n'
                '• 不適切と判断した写真は、当方の判断で削除することがあります',
              ),

              _buildSection(
                '8. トラッキングと広告識別子（ATT）',
                'iOS の App Tracking Transparency（ATT）により、他社アプリ・Webサイトをまたいだトラッキングを行う前に、ユーザーの許可を取得します。\n\n'
                '• 現時点では本サービスはクロスアプリ・トラッキングを行っていません\n'
                '• 広告配信・行動履歴に基づくパーソナライゼーションは行っていません\n'
                '• 将来的に広告を導入する場合は、事前に本ポリシーを改訂し、アプリ内で通知します',
              ),

              _buildSection(
                '9. 情報の安全管理',
                '当方は、個人情報の漏えい・滅失・毀損の防止のため、以下の対策を講じます。\n\n'
                '• HTTPS（TLS）による通信の暗号化\n'
                '• Supabase Row Level Security（RLS）によるデータアクセス制御\n'
                '• 権限を持つ者以外がアクセスできない運用\n'
                '• 定期的なセキュリティレビュー',
              ),

              _buildSection(
                '10. 情報の開示・訂正・削除',
                'ご自身の情報について、以下の対応が可能です。\n\n'
                '• プロフィール・愛犬情報: アプリ内「プロフィール」→「編集」から変更\n'
                '• 散歩記録・ピン・写真: アプリ内から個別に削除可能\n'
                '• アカウント削除: アプリ内「設定」→「アカウントを削除」から実行\n'
                '• アカウント削除後、個人情報は原則として速やかに削除します（法令で保存が義務付けられているものを除く）\n'
                '• その他の開示・訂正請求は info@dog-hub.shop へメールでご連絡ください（本人確認のため書類提出をお願いする場合があります）',
              ),

              _buildSection(
                '11. 未成年の利用について',
                '• 16歳未満の方が本サービスを利用する場合は、法定代理人（保護者）の同意を得てください\n'
                '• 13歳未満の方から意図的に個人情報を収集することはありません\n'
                '• 保護者の方で、お子様が同意なく情報を提供したとお気づきの場合は、info@dog-hub.shop までご連絡ください',
              ),

              _buildSection(
                '12. プライバシーポリシーの変更',
                '• 当方は必要に応じて本ポリシーを変更することがあります\n'
                '• 変更後の内容は本画面に掲載した時点から効力を生じます\n'
                '• 重要な変更がある場合は、アプリ内通知または起動時の告知でお知らせします\n'
                '• 変更後も本サービスを継続利用される場合、変更に同意したものとみなします',
              ),

              _buildSection(
                '13. お問い合わせ窓口',
                '本ポリシー・個人情報の取扱いに関するお問い合わせは下記までお願いします。\n\n'
                '• サービス名: WanWalk\n'
                '• 運営: DogHub（代表 成澤元子）\n'
                '• メール: info@dog-hub.shop\n\n'
                '※回答までに数日いただく場合があります。',
              ),

              _buildSection(
                '14. 改訂履歴',
                '• 2026年4月20日: Build 31 Phase 2 改訂（運営事業者明記・連絡先更新・ATT章新設・第三者SDK開示・肖像権文言追加）\n'
                '• 2025年11月21日: 初版公開',
              ),

              const SizedBox(height: WanWalkSpacing.s5),

              Center(
                child: Text('以上', style: WanWalkTypography.wwCaption),
              ),
              const SizedBox(height: WanWalkSpacing.s8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WanWalkSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WanWalkTypography.wwH3),
          const SizedBox(height: WanWalkSpacing.s2),
          Text(
            content,
            style: WanWalkTypography.wwBody.copyWith(height: 1.75),
          ),
        ],
      ),
    );
  }
}

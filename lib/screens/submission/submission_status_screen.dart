import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/submission_constants.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/analytics_provider.dart';
import '../../services/submission_service.dart';

/// 自分の投稿一覧（新しい順）。autoDispose で画面を開くたびに再取得。
final mySubmissionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return const [];
  return SubmissionService().fetchMySubmissions(userId);
});

/// 投稿ステータス画面（投稿プログラム v1 W3）。
///
/// route_submissions を本人で読み、A-4トーンの状態表示。
/// status='question' のときは編集部のおうかがいを表示し「追記する」で返信できる
/// （返信は add_submission_reply RPC 経由・成功で status は reviewing に戻る）。
class SubmissionStatusScreen extends ConsumerStatefulWidget {
  const SubmissionStatusScreen({super.key, this.entryPoint});

  final String? entryPoint;

  @override
  ConsumerState<SubmissionStatusScreen> createState() =>
      _SubmissionStatusScreenState();
}

class _SubmissionStatusScreenState
    extends ConsumerState<SubmissionStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .logSubmitStatusView(entryPoint: widget.entryPoint);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mySubmissionsProvider);

    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: WanWalkColors.bgPrimary,
        foregroundColor: WanWalkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('投稿した道', style: WanWalkTypography.wwH2),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: WanWalkColors.accentPrimary),
        ),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(mySubmissionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            color: WanWalkColors.accentPrimary,
            onRefresh: () async => ref.invalidate(mySubmissionsProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(WanWalkSpacing.s4),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: WanWalkSpacing.s3),
              itemBuilder: (context, i) => _SubmissionCard(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  const _SubmissionCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = (item['status'] ?? '') as String;
    final type = (item['type'] ?? '') as String;
    final proposedName = item['proposed_name'] as String?;
    final editorQuestion = item['editor_question'] as String?;
    final applicantReply = item['applicant_reply'] as String?;
    final editorNotes = item['editor_notes'] as String?;
    final createdAt = item['created_at'] as String?;

    final title = proposedName?.isNotEmpty == true
        ? proposedName!
        : (type == SubmissionType.fieldReport ? '実走報告' : '新しい道の推薦');

    return Container(
      padding: EdgeInsets.all(WanWalkSpacing.s4),
      decoration: BoxDecoration(
        color: WanWalkColors.bgPrimary,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
        border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: status, type: type),
              const Spacer(),
              Text(
                type == SubmissionType.fieldReport ? '実走報告' : '推薦',
                style: WanWalkTypography.wwCaption
                    .copyWith(color: WanWalkColors.textTertiary),
              ),
            ],
          ),
          SizedBox(height: WanWalkSpacing.s2),
          Text(title, style: WanWalkTypography.wwH4),
          if (createdAt != null) ...[
            SizedBox(height: WanWalkSpacing.s1),
            Text(
              _formatDate(createdAt),
              style: WanWalkTypography.wwCaption
                  .copyWith(color: WanWalkColors.textTertiary),
            ),
          ],

          // 編集部のおうかがい（question）
          if (status == 'question' && editorQuestion?.isNotEmpty == true) ...[
            SizedBox(height: WanWalkSpacing.s3),
            _NoticeBox(
              label: '編集部からのおうかがい',
              body: editorQuestion!,
            ),
            SizedBox(height: WanWalkSpacing.s3),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: WanWalkColors.accentPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WanWalkSpacing.radiusSm),
                  ),
                ),
                onPressed: () => _showReplySheet(
                  context,
                  ref,
                  submissionId: item['id'] as String,
                  question: editorQuestion,
                ),
                child: const Text('追記する'),
              ),
            ),
          ],

          // 見送りの理由・編集部メモ
          if (status == 'declined' && editorNotes?.isNotEmpty == true) ...[
            SizedBox(height: WanWalkSpacing.s3),
            _NoticeBox(label: '編集部から', body: editorNotes!),
          ],

          // 自分の追記
          if (applicantReply?.isNotEmpty == true) ...[
            SizedBox(height: WanWalkSpacing.s2),
            Text(
              'あなたの追記: $applicantReply',
              style: WanWalkTypography.wwBodySm
                  .copyWith(color: WanWalkColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.year}年${d.month}月${d.day}日';
  }
}

/// 追記入力シート。
Future<void> _showReplySheet(
  BuildContext context,
  WidgetRef ref, {
  required String submissionId,
  required String question,
}) async {
  final controller = TextEditingController();
  final messenger = ScaffoldMessenger.of(context);
  var sending = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: WanWalkColors.bgPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: WanWalkSpacing.s4,
              right: WanWalkSpacing.s4,
              top: WanWalkSpacing.s4,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                  WanWalkSpacing.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('追記する', style: WanWalkTypography.wwH3),
                SizedBox(height: WanWalkSpacing.s2),
                _NoticeBox(label: '編集部からのおうかがい', body: question),
                SizedBox(height: WanWalkSpacing.s3),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: WanWalkTypography.wwBody,
                  decoration: InputDecoration(
                    hintText: 'お返事を入力してください',
                    hintStyle: WanWalkTypography.wwBody
                        .copyWith(color: WanWalkColors.textTertiary),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WanWalkSpacing.radiusSm),
                      borderSide:
                          const BorderSide(color: WanWalkColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WanWalkSpacing.radiusSm),
                      borderSide:
                          const BorderSide(color: WanWalkColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WanWalkSpacing.radiusSm),
                      borderSide:
                          const BorderSide(color: WanWalkColors.accentPrimary),
                    ),
                  ),
                ),
                SizedBox(height: WanWalkSpacing.s3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: WanWalkColors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(WanWalkSpacing.radiusSm),
                      ),
                    ),
                    onPressed: sending
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            setSheetState(() => sending = true);
                            try {
                              await SubmissionService().submitReply(
                                submissionId: submissionId,
                                reply: text,
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                              ref.invalidate(mySubmissionsProvider);
                              messenger.showSnackBar(
                                const SnackBar(content: Text('お返事を送りました')),
                              );
                            } catch (e) {
                              setSheetState(() => sending = false);
                              final msg = e is SubmissionException
                                  ? e.message
                                  : '送信に失敗しました';
                              messenger.showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          },
                    child: Text(sending ? '送信中...' : '送信する'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.type});

  final String status;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
      ),
      child: Text(
        _statusLabel(status, type),
        style: WanWalkTypography.wwCaption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(WanWalkSpacing.s3),
      decoration: BoxDecoration(
        color: WanWalkColors.accentPrimarySoft,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WanWalkTypography.wwCaption.copyWith(
              color: WanWalkColors.accentPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: WanWalkSpacing.s1),
          Text(body, style: WanWalkTypography.wwBodySm),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(WanWalkSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'まだ投稿はありません',
              style: WanWalkTypography.wwH4,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: WanWalkSpacing.s2),
            Text(
              '散歩の記録から、愛犬と歩いた道を編集部に推薦できます。',
              style: WanWalkTypography.wwBodySm
                  .copyWith(color: WanWalkColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '読み込みに失敗しました',
            style: WanWalkTypography.wwBody
                .copyWith(color: WanWalkColors.textSecondary),
          ),
          SizedBox(height: WanWalkSpacing.s3),
          TextButton(onPressed: onRetry, child: const Text('再読み込み')),
        ],
      ),
    );
  }
}

String _statusLabel(String status, String type) {
  switch (status) {
    case 'received':
    case 'reviewing':
      return '確認中';
    case 'question':
      return 'おうかがい中';
    case 'approved':
      return '掲載準備中';
    case 'published':
      return type == SubmissionType.fieldReport ? '反映されました' : '掲載されました';
    case 'declined':
      return '今回は見送り';
    case 'withdrawn':
      return '取り下げ済み';
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'published':
      return WanWalkColors.semanticSuccess;
    case 'question':
      return WanWalkColors.semanticWarning;
    case 'declined':
    case 'withdrawn':
      return WanWalkColors.textTertiary;
    default:
      return WanWalkColors.accentPrimary;
  }
}

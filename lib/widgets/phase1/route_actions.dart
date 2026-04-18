import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/bookmark_provider.dart';

/// BookmarkButton — ルート詳細で愛犬家が気に入ったルートを保存。
/// 未ログイン時は誘導ダイアログ。認証後は Supabase user_bookmarks に永続化。
class BookmarkButton extends ConsumerStatefulWidget {
  final String routeId;

  const BookmarkButton({super.key, required this.routeId});

  @override
  ConsumerState<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<BookmarkButton> {
  bool _busy = false;

  Future<void> _handleTap(bool currentStatus) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = await toggleBookmark(widget.routeId);
      ref.invalidate(routeBookmarkStatusProvider(widget.routeId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? 'お気に入りに保存しました' : 'お気に入りを解除しました'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WanWalkColors.textPrimary,
        ),
      );
    } on NotLoggedInException {
      if (!mounted) return;
      await _showLoginPrompt();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存に失敗しました: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showLoginPrompt() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WanWalkColors.bgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusLg),
        ),
        title: const Text(
          'お気に入り機能を使うには',
          style: TextStyle(
            fontFamily: 'NotoSerifJP',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: WanWalkColors.textPrimary,
          ),
        ),
        content: Text(
          'ログインするとルートをお気に入りに保存して、\nいつでも呼び出せるようになります。',
          style: WanWalkTypography.wwBodySm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'あとで',
              style: WanWalkTypography.wwBodySm.copyWith(
                color: WanWalkColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 既存のログイン画面へ誘導するフックポイント。
              // 設定 → アカウント → ログイン への動線は既存 UI に委ねる。
            },
            child: const Text(
              '設定を開く',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: WanWalkColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync =
        ref.watch(routeBookmarkStatusProvider(widget.routeId));
    final isSaved = statusAsync.maybeWhen(data: (v) => v, orElse: () => false);

    return _IconAction(
      icon: isSaved
          ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
          : PhosphorIcons.bookmarkSimple(),
      color: isSaved
          ? WanWalkColors.accentPrimary
          : WanWalkColors.textPrimary,
      busy: _busy,
      onTap: () => _handleTap(isSaved),
      tooltip: isSaved ? 'お気に入り解除' : 'お気に入り保存',
    );
  }
}

/// ShareButton — OS共有シートを呼び出すだけ。
class ShareButton extends StatelessWidget {
  final String routeName;
  final String? areaName;
  final String? slug;

  const ShareButton({
    super.key,
    required this.routeName,
    required this.areaName,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return _IconAction(
      icon: PhosphorIcons.shareNetwork(),
      color: WanWalkColors.textPrimary,
      tooltip: '共有',
      onTap: () {
        final areaText = areaName ?? '';
        final url = slug != null
            ? 'https://wanwalk.jp/routes/$slug'
            : 'https://wanwalk.jp/';
        final body = areaText.isNotEmpty
            ? '$routeName - $areaTextの犬連れ散歩コース\n$url'
            : '$routeName\n$url';
        Share.share(body, subject: '$routeName | WanWalk');
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool busy;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: busy ? null : onTap,
        radius: 24,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WanWalkColors.accentPrimary,
                  ),
                )
              : Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

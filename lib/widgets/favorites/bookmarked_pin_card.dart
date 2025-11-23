import 'package:flutter/material.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/user_statistics.dart';

/// 保存したピンカード
class BookmarkedPinCard extends StatelessWidget {
  final BookmarkedPin pin;
  final VoidCallback onTap;
  final VoidCallback onUnbookmark;

  const BookmarkedPinCard({
    super.key,
    required this.pin,
    required this.onTap,
    required this.onUnbookmark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル画像（あれば）
            if (pin.thumbnailUrl != null) _buildThumbnail(isDark),
            
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトルとブックマーク解除ボタン
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pin.title,
                          style: WanMapTypography.heading3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.bookmark,
                          color: WanMapColors.accent,
                        ),
                        onPressed: onUnbookmark,
                        tooltip: '保存から削除',
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.tiny),
                  
                  // ルート名とエリア名
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPinTypeColor(pin.pinType).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pin.pinTypeLabel,
                          style: WanMapTypography.caption.copyWith(
                            color: _getPinTypeColor(pin.pinType),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.small),
                      Expanded(
                        child: Text(
                          '${pin.routeName} · ${pin.areaName}',
                          style: WanMapTypography.caption.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // コメント
                  if (pin.comment != null) ...[
                    const SizedBox(height: WanMapSpacing.small),
                    Text(
                      pin.comment!,
                      style: WanMapTypography.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: WanMapSpacing.small),
                  
                  // ユーザー名といいね数
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pin.userName,
                        style: WanMapTypography.caption,
                      ),
                      const SizedBox(width: WanMapSpacing.medium),
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pin.likesCount}',
                        style: WanMapTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          pin.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(isDark);
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      child: Icon(
        Icons.image,
        size: 48,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }

  Color _getPinTypeColor(String pinType) {
    switch (pinType) {
      case 'scenery':
        return Colors.blue;
      case 'shop':
        return Colors.orange;
      case 'encounter':
        return Colors.green;
      case 'other':
      default:
        return Colors.grey;
    }
  }
}

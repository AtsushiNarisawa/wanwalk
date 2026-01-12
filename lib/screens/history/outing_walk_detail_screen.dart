import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/walk_history.dart';
import '../../models/route_pin.dart';
import '../../services/walk_pin_service.dart';
import '../outing/pin_detail_screen.dart';

/// お出かけ散歩詳細画面（フルスクリーン）
/// 
/// 構成:
/// - 写真スライダー（PageView + ドットインジケーター）
/// - ルート情報（名前、エリア、日時）
/// - 統計情報（距離、時間、ピン数）
/// - 思い出のピン（NEW）
/// - 削除ボタン（オプション）
class OutingWalkDetailScreen extends ConsumerStatefulWidget {
  final OutingWalkHistory history;

  const OutingWalkDetailScreen({
    super.key,
    required this.history,
  });

  @override
  ConsumerState<OutingWalkDetailScreen> createState() => _OutingWalkDetailScreenState();
}

class _OutingWalkDetailScreenState extends ConsumerState<OutingWalkDetailScreen> {
  final PageController _pageController = PageController();
  final WalkPinService _walkPinService = WalkPinService();
  int _currentPhotoIndex = 0;
  List<RoutePin>? _pins;
  bool _isLoadingPins = true;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// ピンを読み込む
  Future<void> _loadPins() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoadingPins = false;
      });
      return;
    }

    final pins = await _walkPinService.getWalkPins(
      walkId: widget.history.walkId,
      userId: userId,
    );

    if (mounted) {
      setState(() {
        _pins = pins;
        _isLoadingPins = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '散歩の詳細',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 削除ボタン（将来実装）
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
            onPressed: () {
              _showDeleteDialog(context, isDark);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真スライダー
            if (widget.history.photoUrls.isNotEmpty)
              _buildPhotoSlider(isDark)
            else
              _buildNoPhotosPlaceholder(isDark),

            const SizedBox(height: WanMapSpacing.lg),

            // ルート情報
            _buildRouteInfo(isDark),

            const SizedBox(height: WanMapSpacing.lg),

            // 統計情報
            _buildStatistics(isDark),

            const SizedBox(height: WanMapSpacing.xl),

            // 思い出のピン
            _buildPinsSection(isDark),

            const SizedBox(height: WanMapSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// 写真スライダー
  Widget _buildPhotoSlider(bool isDark) {
    return Column(
      children: [
        // PageView
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemCount: widget.history.photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _showFullScreenPhoto(context, index);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.history.photoUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPhotoError(isDark);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: WanMapSpacing.md),

        // ドットインジケーター + カウンター
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ドット
            ...List.generate(
              widget.history.photoUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPhotoIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPhotoIndex == index
                      ? WanMapColors.accent
                      : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: WanMapSpacing.md),
            // カウンター
            Text(
              '${_currentPhotoIndex + 1}/${widget.history.photoUrls.length}',
              style: WanMapTypography.caption.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 写真がない場合のプレースホルダー
  Widget _buildNoPhotosPlaceholder(bool isDark) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
            const SizedBox(height: WanMapSpacing.md),
            Text(
              '写真がありません',
              style: WanMapTypography.bodyLarge.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 写真エラー表示
  Widget _buildPhotoError(bool isDark) {
    return Container(
      color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 48,
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              '画像を読み込めませんでした',
              style: WanMapTypography.bodySmall.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ルート情報
  Widget _buildRouteInfo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ルート名
          Text(
            widget.history.routeName,
            style: WanMapTypography.headlineMedium.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.sm),

          // エリア + 日時
          Row(
            children: [
              // エリア
              Icon(
                Icons.location_on,
                size: 18,
                color: WanMapColors.accent,
              ),
              const SizedBox(width: WanMapSpacing.xs),
              Text(
                widget.history.areaName,
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              // 日時
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              const SizedBox(width: WanMapSpacing.xs),
              Text(
                DateFormat('yyyy年MM月dd日 HH:mm').format(widget.history.walkedAt),
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 統計情報
  Widget _buildStatistics(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '散歩の記録',
            style: WanMapTypography.titleMedium.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),

          // 統計カード
          Container(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.straighten,
                  label: '距離',
                  value: widget.history.formattedDistance,
                  color: Colors.blue,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
                _StatRow(
                  icon: Icons.access_time,
                  label: '時間',
                  value: widget.history.formattedDuration,
                  color: Colors.green,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
                _StatRow(
                  icon: Icons.push_pin,
                  label: '投稿ピン',
                  value: '${widget.history.pinCount}個',
                  color: Colors.orange,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
                _StatRow(
                  icon: Icons.camera_alt,
                  label: '写真',
                  value: '${widget.history.photoCount}枚',
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 思い出のピンセクション
  Widget _buildPinsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションヘッダー
          Row(
            children: [
              Icon(
                Icons.push_pin,
                color: WanMapColors.accent,
                size: 24,
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                '散歩中に見つけた思い出',
                style: WanMapTypography.titleMedium.copyWith(
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: WanMapSpacing.sm),
              if (_pins != null && _pins!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WanMapSpacing.sm,
                    vertical: WanMapSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: WanMapColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_pins!.length}個',
                    style: WanMapTypography.caption.copyWith(
                      color: WanMapColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),

          // ピンリスト
          if (_isLoadingPins)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(WanMapSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_pins == null || _pins!.isEmpty)
            _buildEmptyPinsState(isDark)
          else
            ..._pins!.map((pin) => Padding(
              padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
              child: _WalkPinCard(
                pin: pin,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinDetailScreen(pinId: pin.id),
                    ),
                  );
                },
              ),
            )),
        ],
      ),
    );
  }

  /// ピンが空の場合の表示
  Widget _buildEmptyPinsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? WanMapColors.borderDark : WanMapColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.push_pin_outlined,
            size: 48,
            color: isDark
                ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                : WanMapColors.textSecondaryLight.withOpacity(0.5),
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            '散歩中にピンを投稿していません',
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            '次の散歩で素敵な場所を見つけたら\nピンを立ててみましょう！',
            style: WanMapTypography.bodySmall.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark.withOpacity(0.7)
                  : WanMapColors.textSecondaryLight.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// フルスクリーン写真表示
  void _showFullScreenPhoto(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenPhotoViewer(
          photoUrls: widget.history.photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// 削除確認ダイアログ
  void _showDeleteDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        title: Text(
          '散歩を削除',
          style: WanMapTypography.titleLarge.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'この散歩記録を削除しますか？\nこの操作は取り消せません。',
          style: WanMapTypography.bodyMedium.copyWith(
            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: TextStyle(color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('削除機能は準備中です')),
              );
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// 統計行
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(WanMapSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: Text(
            label,
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: WanMapTypography.titleMedium.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// フルスクリーン写真ビューアー
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.photoUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.photoUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.photoUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.white54),
                        SizedBox(height: 16),
                        Text(
                          '画像を読み込めませんでした',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ピンカードウィジェット
class _WalkPinCard extends StatelessWidget {
  final RoutePin pin;
  final bool isDark;
  final VoidCallback onTap;

  const _WalkPinCard({
    required this.pin,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真（横スクロール）
            if (pin.hasPhotos) _buildPhotoSection(),

            // ピン情報
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ピンタイプバッジ + タイトル
                  Row(
                    children: [
                      _buildPinTypeBadge(),
                      const SizedBox(width: WanMapSpacing.sm),
                      Expanded(
                        child: Text(
                          pin.title,
                          style: WanMapTypography.bodyLarge.copyWith(
                            color: isDark
                                ? WanMapColors.textPrimaryDark
                                : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // コメント
                  if (pin.comment.isNotEmpty) ...[
                    const SizedBox(height: WanMapSpacing.sm),
                    Text(
                      pin.comment,
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: WanMapSpacing.sm),

                  // 投稿時刻 + いいね・コメント数
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        pin.relativeTime,
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      // いいね数
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        '${pin.likesCount}',
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.md),
                      // コメント数
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        '${pin.commentsCount}',
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
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

  /// 写真セクション
  Widget _buildPhotoSection() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pin.photoUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : WanMapSpacing.xs,
              right: index == pin.photoUrls.length - 1 ? 0 : WanMapSpacing.xs,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                topRight: index == pin.photoUrls.length - 1
                    ? const Radius.circular(16)
                    : Radius.zero,
              ),
              child: Image.network(
                pin.photoUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark
                        ? WanMapColors.backgroundDark
                        : WanMapColors.backgroundLight,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// ピンタイプバッジ
  Widget _buildPinTypeBadge() {
    Color badgeColor;
    IconData badgeIcon;

    switch (pin.pinType) {
      case PinType.scenery:
        badgeColor = Colors.blue;
        badgeIcon = Icons.landscape;
        break;
      case PinType.shop:
        badgeColor = Colors.orange;
        badgeIcon = Icons.store;
        break;
      case PinType.encounter:
        badgeColor = Colors.green;
        badgeIcon = Icons.pets;
        break;
      case PinType.facility:
        badgeColor = Colors.purple;
        badgeIcon = Icons.business;
        break;

      case PinType.other:
        badgeColor = Colors.grey;
        badgeIcon = Icons.more_horiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.sm,
        vertical: WanMapSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            pin.pinType.label,
            style: WanMapTypography.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

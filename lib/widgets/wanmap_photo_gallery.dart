import 'package:flutter/material.dart';
import '../config/wanmap_colors.dart';
import '../config/wanmap_spacing.dart';

/// WanMap フォトギャラリーウィジェット
/// Instagram風のグリッド表示

enum WanMapGalleryLayout {
  grid2, // 2列グリッド
  grid3, // 3列グリッド
  masonry, // マソンリーレイアウト
}

class WanMapPhotoGallery extends StatelessWidget {
  final List<String> imageUrls;
  final WanMapGalleryLayout layout;
  final Function(int)? onImageTap;
  final double spacing;
  final double aspectRatio;

  const WanMapPhotoGallery({
    super.key,
    required this.imageUrls,
    this.layout = WanMapGalleryLayout.grid3,
    this.onImageTap,
    this.spacing = WanMapSpacing.xs,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (layout) {
      case WanMapGalleryLayout.grid2:
        return _buildGrid(context, crossAxisCount: 2);
      case WanMapGalleryLayout.grid3:
        return _buildGrid(context, crossAxisCount: 3);
      case WanMapGalleryLayout.masonry:
        return _buildMasonry(context);
    }
  }

  Widget _buildGrid(BuildContext context, {required int crossAxisCount}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return _buildImageItem(context, index);
      },
    );
  }

  Widget _buildMasonry(BuildContext context) {
    // 簡易的なマソンリーレイアウト（2列）
    final leftImages = <int>[];
    final rightImages = <int>[];

    for (int i = 0; i < imageUrls.length; i++) {
      if (i % 2 == 0) {
        leftImages.add(i);
      } else {
        rightImages.add(i);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftImages
                .map((index) => Padding(
                      padding: EdgeInsets.only(
                        right: spacing / 2,
                        bottom: spacing,
                      ),
                      child: _buildImageItem(context, index),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: Column(
            children: rightImages
                .map((index) => Padding(
                      padding: EdgeInsets.only(
                        left: spacing / 2,
                        bottom: spacing,
                      ),
                      child: _buildImageItem(context, index),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onImageTap?.call(index),
      child: ClipRRect(
        borderRadius: WanMapSpacing.borderRadiusMD,
        child: AspectRatio(
          aspectRatio: layout == WanMapGalleryLayout.masonry 
              ? aspectRatio 
              : aspectRatio,
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: WanMapColors.textTertiaryLight,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 32,
                  color: WanMapColors.textSecondaryLight,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: WanMapColors.textTertiaryLight,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 単一写真表示ウィジェット（フルスクリーン対応）
class WanMapPhotoViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const WanMapPhotoViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<WanMapPhotoViewer> createState() => _WanMapPhotoViewerState();
}

class _WanMapPhotoViewerState extends State<WanMapPhotoViewer> {
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ページビュー
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // インジケーター
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: WanMapSpacing.xl,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 写真アップロードウィジェット
class WanMapPhotoUpload extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback onAddPhoto;
  final Function(int)? onRemovePhoto;
  final int maxPhotos;

  const WanMapPhotoUpload({
    super.key,
    required this.imageUrls,
    required this.onAddPhoto,
    this.onRemovePhoto,
    this.maxPhotos = 10,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAddMore = imageUrls.length < maxPhotos;

    return Wrap(
      spacing: WanMapSpacing.sm,
      runSpacing: WanMapSpacing.sm,
      children: [
        // 既存の画像
        ...imageUrls.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value;
          
          return Stack(
            children: [
              ClipRRect(
                borderRadius: WanMapSpacing.borderRadiusMD,
                child: Image.network(
                  url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              if (onRemovePhoto != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemovePhoto!(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        
        // 追加ボタン
        if (canAddMore)
          GestureDetector(
            onTap: onAddPhoto,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: WanMapColors.textTertiaryLight,
                borderRadius: WanMapSpacing.borderRadiusMD,
                border: Border.all(
                  color: WanMapColors.textSecondaryLight,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate,
                    size: 32,
                    color: WanMapColors.textSecondaryLight,
                  ),
                  const SizedBox(height: WanMapSpacing.xxs),
                  Text(
                    '${imageUrls.length}/$maxPhotos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: WanMapColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

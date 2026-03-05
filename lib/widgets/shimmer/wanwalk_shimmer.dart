import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/wanwalk_colors.dart';

/// WanWalk共通Shimmerウィジェット
/// 
/// スケルトンローディングに使用する基本Shimmerコンポーネント
class WanWalkShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const WanWalkShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: isDark 
            ? WanWalkColors.backgroundDark.withOpacity(0.3)
            : Colors.grey[300]!,
        highlightColor: isDark 
            ? WanWalkColors.backgroundDark.withOpacity(0.5)
            : Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

/// カード型Shimmer
class CardShimmer extends StatelessWidget {
  final double? height;
  final int count;
  final EdgeInsetsGeometry? padding;

  const CardShimmer({
    super.key,
    this.height,
    this.count = 3,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: padding ?? const EdgeInsets.only(bottom: 16),
          child: WanWalkShimmer(
            width: double.infinity,
            height: height ?? 180,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// リストタイル型Shimmer
class ListTileShimmer extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry? padding;

  const ListTileShimmer({
    super.key,
    this.count = 5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              // アイコン部分
              WanWalkShimmer(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(width: 12),
              // テキスト部分
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WanWalkShimmer(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    WanWalkShimmer(
                      width: 200,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 画像カード型Shimmer（ピン投稿用）
class ImageCardShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final int count;

  const ImageCardShimmer({
    super.key,
    this.width,
    this.height,
    this.count = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == 0 ? 8 : 0,
              left: index == 1 ? 8 : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 画像部分
                WanWalkShimmer(
                  width: width ?? double.infinity,
                  height: height ?? 140,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 8),
                // タイトル
                WanWalkShimmer(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                // サブテキスト
                WanWalkShimmer(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// エリアカード型Shimmer
class AreaCardShimmer extends StatelessWidget {
  final int count;
  final bool isFeatured;

  const AreaCardShimmer({
    super.key,
    this.count = 3,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      // 大きな特集カード
      return Column(
        children: [
          WanWalkShimmer(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
    
    // 通常のエリアカード（横2列）
    return Column(
      children: List.generate(
        (count / 2).ceil(),
        (rowIndex) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: List.generate(
              2,
              (colIndex) {
                final index = rowIndex * 2 + colIndex;
                if (index >= count) return const SizedBox.shrink();
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: colIndex == 0 ? 8 : 0,
                      left: colIndex == 1 ? 8 : 0,
                    ),
                    child: WanWalkShimmer(
                      width: double.infinity,
                      height: 120,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// ルートカード型Shimmer
class RouteCardShimmer extends StatelessWidget {
  final int count;

  const RouteCardShimmer({
    super.key,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // 地図プレビュー
              WanWalkShimmer(
                width: 100,
                height: 80,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              // テキスト情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WanWalkShimmer(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    WanWalkShimmer(
                      width: 150,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        WanWalkShimmer(
                          width: 60,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(width: 12),
                        WanWalkShimmer(
                          width: 60,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

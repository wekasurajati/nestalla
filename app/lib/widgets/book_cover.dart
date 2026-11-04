import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';

class BookCover extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BoxFit fit;
  final bool showShadow;

  const BookCover({
    super.key,
    required this.image,
    this.width = 160,
    this.height = 240,
    this.aspectRatio,
    this.fit = BoxFit.contain,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final cover = Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.border,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipRRect(borderRadius: AppRadius.border, child: _buildImage()),
    );

    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio!, child: cover);
    }
    return SizedBox(width: width, height: height, child: cover);
  }

  Widget _buildImage() {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: fit,
        errorBuilder: (_, _, _) => const _CoverPlaceholder(),
      );
    }
    if (image.isNotEmpty) {
      return Image.asset(
        image,
        fit: fit,
        errorBuilder: (_, _, _) => const _CoverPlaceholder(),
      );
    }
    return const _CoverPlaceholder();
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;
        final iconSize = shortestSide.isFinite ? shortestSide * 0.3 : 48.0;
        return Container(
          color: AppColors.lightBlue,
          alignment: Alignment.center,
          child: Icon(Icons.menu_book, size: iconSize, color: AppColors.navy),
        );
      },
    );
  }
}

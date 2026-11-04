import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class RatingLabel extends StatelessWidget {
  final double rating;
  final double iconSize;
  final double fontSize;
  final Color? color;

  const RatingLabel({
    super.key,
    required this.rating,
    this.iconSize = 14,
    this.fontSize = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: iconSize, color: AppColors.star),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: fontSize, color: color ?? AppColors.dark),
        ),
      ],
    );
  }
}

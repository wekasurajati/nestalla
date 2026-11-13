import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final int count;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 14,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final IconData icon;
        if (index < fullStars) {
          icon = Icons.star;
        } else if (index == fullStars && hasHalfStar) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: size, color: AppColors.star);
      }),
    );
  }
}

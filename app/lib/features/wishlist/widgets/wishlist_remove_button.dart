import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../providers/wishlist_provider.dart';

class WishlistRemoveButton extends StatelessWidget {
  final int bookId;
  final double size;

  const WishlistRemoveButton({super.key, required this.bookId, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.92),
      shape: AppRadius.shape,
      child: InkWell(
        customBorder: AppRadius.shape,
        onTap: () async {
          await context.read<WishlistProvider>().remove(bookId);
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.favorite, size: size * 0.53, color: AppColors.navy),
        ),
      ),
    );
  }
}

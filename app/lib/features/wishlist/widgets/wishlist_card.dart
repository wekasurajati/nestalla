import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/currency.dart';
import '../../../models/book.dart';
import '../../../widgets/book_cover.dart';
import '../../../widgets/rating_label.dart';
import 'wishlist_remove_button.dart';

class WishlistCard extends StatelessWidget {
  final Book book;

  const WishlistCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.border,
        side: const BorderSide(color: AppColors.grey),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/book/${book.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                BookCover(
                  image: book.image,
                  aspectRatio: 2 / 3,
                  fit: BoxFit.contain,
                  showShadow: false,
                ),
                if (book.oldPrice != null && book.oldPrice! > book.price)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _DiscountBadge(book: book),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: WishlistRemoveButton(bookId: book.id, size: 28),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (book.rating > 0)
                      RatingLabel(
                        rating: book.rating,
                        iconSize: 12,
                        fontSize: 11,
                        color: AppColors.dark.withValues(alpha: 0.7),
                      ),
                    const Spacer(),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatRupiah(book.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        if (book.oldPrice != null && book.oldPrice! > book.price)
                          Text(
                            formatRupiah(book.oldPrice!),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.dark.withValues(alpha: 0.5),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final Book book;

  const _DiscountBadge({required this.book});

  @override
  Widget build(BuildContext context) {
    final oldPrice = book.oldPrice;
    if (oldPrice == null || oldPrice <= book.price) {
      return const SizedBox.shrink();
    }
    final percent = ((oldPrice - book.price) / oldPrice * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: AppRadius.border,
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.background,
        ),
      ),
    );
  }
}

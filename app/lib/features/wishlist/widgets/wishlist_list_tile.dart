import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/currency.dart';
import '../../../models/book.dart';
import '../../../widgets/book_cover.dart';
import '../../../widgets/rating_label.dart';
import 'wishlist_remove_button.dart';

class WishlistListTile extends StatelessWidget {
  final Book book;
  final int index;

  const WishlistListTile({super.key, required this.book, required this.index});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadius.border,
        onTap: () => context.push('/book/${book.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NumberLabel(number: index + 1),
              const SizedBox(width: 10),
              BookCover(
                image: book.image,
                width: 64,
                height: 96,
                fit: BoxFit.contain,
                showShadow: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
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
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.7),
                      ),
                    ),
                    if (book.publisher.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.publisher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    RatingLabel(
                      rating: book.rating,
                      iconSize: 13,
                      fontSize: 11,
                      color: AppColors.dark.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatRupiah(book.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        if (book.oldPrice != null)
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
              const SizedBox(width: 4),
              WishlistRemoveButton(bookId: book.id, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberLabel extends StatelessWidget {
  final int number;

  const _NumberLabel({required this.number});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 96,
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
      ),
    );
  }
}

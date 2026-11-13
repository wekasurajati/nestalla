import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/currency.dart';
import '../../../models/book.dart';
import '../../../widgets/book_cover.dart';
import '../../../widgets/rating_label.dart';

class HomeBookCard extends StatelessWidget {
  static const double width = 132;

  final Book book;

  const HomeBookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.border,
          onTap: () => context.push('/book/${book.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  BookCover(
                    image: book.image,
                    width: width,
                    height: width * 3 / 2,
                    fit: BoxFit.cover,
                  ),
                  if (book.oldPrice != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _DiscountBadge(book: book),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              RatingLabel(
                rating: book.rating,
                iconSize: 12,
                fontSize: 10,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    formatRupiah(book.price),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  if (book.oldPrice != null)
                    Text(
                      formatRupiah(book.oldPrice!),
                      style: TextStyle(
                        fontSize: 10,
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

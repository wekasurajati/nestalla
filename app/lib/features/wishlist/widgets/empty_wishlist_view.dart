import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/currency.dart';
import '../../../models/book.dart';
import '../../../widgets/book_cover.dart';

class EmptyWishlistView extends StatelessWidget {
  final List<Book> popularPicks;

  const EmptyWishlistView({super.key, required this.popularPicks});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = ((screenWidth - 16 - 24) / 3 - 10).clamp(90.0, 140.0);
    final textScale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 2.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.6,
                          height: 140,
                          child: Image.asset(
                            'assets/images/nowishlist.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Container(
                              height: 140,
                              color: AppColors.lightBlue,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.favorite_border,
                                size: 48,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Wishlist kamu masih kosong',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 160,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => context.go('/home'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              minimumSize: Size.zero,
                              shape: AppRadius.shape,
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Jelajahi buku'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _SectionDivider(
                          text: 'atau Jelajahi Buku Populer',
                        ),
                      ],
                    ),
                  ),
                  if (popularPicks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: cardWidth * 1.5 + 104 * textScale,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        itemCount: popularPicks.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, index) => _PopularBookCard(
                          book: popularPicks[index],
                          cardWidth: cardWidth,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String text;

  const _SectionDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.grey)),
      ],
    );
  }
}

class _PopularBookCard extends StatelessWidget {
  final Book book;
  final double cardWidth;

  const _PopularBookCard({required this.book, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/book/${book.id}'),
        child: SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                image: book.image,
                width: cardWidth,
                height: cardWidth * 1.5,
                fit: BoxFit.cover,
                showShadow: false,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import 'home_book_card.dart';

class HomeBookSection extends StatelessWidget {
  final String title;
  final List<Book> books;

  const HomeBookSection({super.key, required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              Text(
                '${books.length} buku',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 310,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => HomeBookCard(book: books[index]),
          ),
        ),
      ],
    );
  }
}

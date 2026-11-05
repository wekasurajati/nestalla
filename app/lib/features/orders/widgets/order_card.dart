import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../models/book.dart';
import '../../../widgets/book_cover.dart';
import '../order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final Book book;

  const OrderCard({super.key, required this.order, required this.book});

  @override
  Widget build(BuildContext context) {
    final meta = [
      book.category,
      if (book.ageRating != null) book.ageRating!,
      if (book.publishedYear != null) '${book.publishedYear}',
    ].join('   ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.border,
        border: Border.all(color: AppColors.grey),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            image: book.image,
            width: 56,
            height: 84,
            showShadow: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.backCircle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Order date: ${_formatDate(order.orderDate)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: 'Status : ',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                    children: [
                      TextSpan(
                        text: order.status.label,
                        style: TextStyle(
                          color: _statusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: () => context.push('/orders/${order.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.background,
                minimumSize: const Size(64, 28),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: AppRadius.shape,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Detail'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day-$month-${d.year}';
  }

  static Color _statusColor(OrderStatus status) => switch (status) {
    OrderStatus.packed => AppColors.blue,
    OrderStatus.shipped => Colors.orange,
    OrderStatus.completed => Colors.green,
    OrderStatus.canceled => Colors.red,
  };
}
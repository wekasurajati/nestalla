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

  /// Dipanggil saat kembali dari halaman detail/ulasan, supaya daftar dimuat ulang.
  final VoidCallback? onReturn;

  const OrderCard({
    super.key,
    required this.order,
    required this.book,
    this.onReturn,
  });

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
                  'Tanggal pemesanan: ${formatOrderDate(order.orderDate)}',
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
                          color: order.status.color,
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
          Column(
            children: [
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.push('/orders/${order.id}');
                    onReturn?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.background,
                    minimumSize: const Size(72, 28),
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
              // Tombol ulasan hanya untuk pesanan yang sudah selesai.
              if (order.status == OrderStatus.completed) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: () async {
                      await context.push('/orders/${order.id}/review');
                      onReturn?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: const BorderSide(color: AppColors.blue),
                      minimumSize: const Size(72, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: AppRadius.shape,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Ulasan'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
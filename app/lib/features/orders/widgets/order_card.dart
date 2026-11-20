import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../widgets/book_cover.dart';
import '../order.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  /// Dipanggil saat kembali dari halaman detail/ulasan, supaya daftar dimuat ulang.
  final VoidCallback? onReturn;

  const OrderCard({
    super.key,
    required this.order,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final otherItemsCount = order.items.length - 1;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: No. pesanan + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderDisplayNumber,
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
            ],
          ),
          const SizedBox(height: 10),
          // Items (vertikal)
          ...order.items.map((item) => _ItemRow(item: item)),
          if (otherItemsCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'dan $otherItemsCount item lainnya',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.backCircle,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              Text(
                'Rp.${order.totalAmount.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})(?!\d))'),
                  (m) => '${m[1]}.',
                )}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tombol ulasan hanya untuk pesanan yang sudah selesai.
          if (order.status == OrderStatus.completed) ...[
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
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            image: item.image,
            width: 40,
            height: 60,
            showShadow: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty ${item.quantity}  •  Rp.${item.price.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})(?!\d))'),
                    (m) => '${m[1]}.',
                  )}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.backCircle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

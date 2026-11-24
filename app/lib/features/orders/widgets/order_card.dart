import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../widgets/book_cover.dart';
import '../order.dart';

String _formatRupiah(num value) {
  return 'Rp.${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})(?!\d))'), (m) => '${m[1]}.')}';
}

class OrderCard extends StatelessWidget {
  final Order order;

  /// Dipanggil saat kembali dari halaman detail/ulasan, supaya daftar dimuat ulang.
  final VoidCallback? onReturn;

  const OrderCard({super.key, required this.order, this.onReturn});

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
          // Baris buku (item pertama) + info pesanan di dalamnya
          _OrderItemRow(
            order: order,
            item: order.items.first,
            onReturn: onReturn,
          ),
          if (otherItemsCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'dan $otherItemsCount item lainnya',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.backCircle,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Tombol ulasan hanya untuk pesanan yang sudah selesai dan masih ada buku yang belum diulas.
          if (order.status == OrderStatus.completed &&
              order.reviewableBookId != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              child: OutlinedButton(
                onPressed: () async {
                  await context.push(
                    '/orders/${order.id}/review?book=${order.reviewableBookId}',
                  );
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

class _OrderItemRow extends StatelessWidget {
  final Order order;
  final OrderItem item;
  final VoidCallback? onReturn;

  const _OrderItemRow({required this.order, required this.item, this.onReturn});

  @override
  Widget build(BuildContext context) {
    const infoStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.dark,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(image: item.image, width: 80, height: 120, showShadow: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul (kiri) + tombol Detail (kanan atas)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
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
              const SizedBox(height: 4),

              // Qty + harga
              Text(
                'Qty ${item.quantity}  •  ${_formatRupiah(item.price)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.backCircle,
                ),
              ),
              const SizedBox(height: 10),

              // Info pesanan, rata kanan
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.orderDisplayNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: infoStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tanggal pemesanan: ${formatOrderDate(order.orderDate)}',
                    style: infoStyle,
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      text: 'Status : ',
                      style: infoStyle,
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
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      text: 'Total  ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                      children: [
                        TextSpan(
                          text: _formatRupiah(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

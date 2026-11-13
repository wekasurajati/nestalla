import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../widgets/book_cover.dart';
import '../checkout_models.dart';
import 'section_card.dart';

class OrderSummaryCard extends StatelessWidget {
  final CheckoutData data;

  const OrderSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ringkasan Pesanan',
      child: Column(
        children: [
          for (final item in data.items) ...[
            _ItemRow(item: item),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          _AmountRow(label: 'Subtotal', value: data.subtotal),
          const SizedBox(height: 4),
          _AmountRow(label: 'Ongkos Kirim', value: data.shippingCost),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.backCircle),
          ),
          _AmountRow(label: 'Total', value: data.total, bold: true),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final CheckoutItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(
          image: item.book.image,
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
                item.book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Jumlah : ${item.quantity}',
                style: const TextStyle(fontSize: 10, color: AppColors.dark),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatRupiah(item.lineTotal),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final int value;
  final bool bold;

  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.dark),
        ),
        Text(
          formatRupiah(value),
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppColors.dark : AppColors.backCircle,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../models/book.dart';

Future<int?> showBuyNowSheet(
  BuildContext context, {
  required Book book,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    backgroundColor: AppColors.background,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    builder: (context) => _BuyNowSheet(book: book),
  );
}

class _BuyNowSheet extends StatefulWidget {
  final Book book;

  const _BuyNowSheet({required this.book});

  @override
  State<_BuyNowSheet> createState() => _BuyNowSheetState();
}

class _BuyNowSheetState extends State<_BuyNowSheet> {
  int _quantity = 1;

  void _decrement() {
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  void _increment() {
    setState(() {
      if (_quantity < widget.book.stock) _quantity++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Beli Sekarang',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Image.network(
                  widget.book.image,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => Container(
                    height: 80,
                    width: 80,
                    color: AppColors.grey,
                    child: const Icon(Icons.menu_book, color: AppColors.navy),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.book.stock} stok tersedia',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: AppRadius.border,
                ),
                child: IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: _quantity <= 1 ? null : _decrement,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: AppRadius.border,
                ),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: AppRadius.border,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _quantity >= widget.book.stock ? null : _increment,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _quantity),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: AppRadius.shape,
              ),
              child: const Text(
                'Beli',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

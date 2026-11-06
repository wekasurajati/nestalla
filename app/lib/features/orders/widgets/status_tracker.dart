import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../order.dart';

/// Langkah status: Dikemas -> Dikirim -> Selesai.
/// Untuk pesanan Dibatalkan, tampil banner merah.
class StatusTracker extends StatelessWidget {
  final OrderStatus status;

  const StatusTracker({super.key, required this.status});

  static const _steps = [
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.canceled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pesanan ini telah dibatalkan.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    final current = _steps.indexOf(status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _Step(label: _steps[i].label, index: i, current: current),
          if (i < _steps.length - 1)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 13),
                height: 2,
                color: i < current ? AppColors.blue : AppColors.grey,
              ),
            ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final int index;
  final int current;

  const _Step({
    required this.label,
    required this.index,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final reached = done || active;

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? AppColors.blue : AppColors.background,
              border: Border.all(
                color: reached ? AppColors.blue : AppColors.grey,
                width: 2,
              ),
            ),
            child: Icon(
              done || (active && index == 2) ? Icons.check : Icons.circle,
              size: done || (active && index == 2) ? 16 : 8,
              color: reached ? AppColors.background : AppColors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: reached ? AppColors.dark : AppColors.backCircle,
            ),
          ),
        ],
      ),
    );
  }
}
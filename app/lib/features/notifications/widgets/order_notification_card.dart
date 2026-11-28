import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../models/order_notification.dart';
import '../../../widgets/book_cover.dart';

class OrderNotificationCard extends StatelessWidget {
  final OrderNotification notification;
  final VoidCallback onTap;

  const OrderNotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = notification.status == 'cancelled';

    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.border,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.border,
            border: Border.all(color: AppColors.grey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 72,
                child: notification.coverImage == null ||
                        notification.coverImage!.isEmpty
                    ? Container(
                        color: AppColors.lightBlue.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.menu_book_outlined,
                          size: 22,
                          color: AppColors.navy,
                        ),
                      )
                    : BookCover(
                        image: notification.coverImage!,
                        width: 48,
                        height: 72,
                        fit: BoxFit.cover,
                        showShadow: false,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No. ${notification.orderNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pesanan ${notification.statusLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCancelled
                            ? Theme.of(context).colorScheme.error
                            : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (notification.carrierName != null &&
                        notification.carrierName!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 14,
                            color: AppColors.dark.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            notification.carrierName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.dark.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDay = DateTime(time.year, time.month, time.day);

    if (notifDay == yesterday) return 'Kemarin';

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month/${time.year}';
  }
}

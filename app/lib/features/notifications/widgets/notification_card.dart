import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../models/app_notification.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

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
            border: Border.all(
              color: AppColors.grey,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _iconFor(notification.type),
                        size: 22,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  if (unread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: AppColors.dark.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.account:
        return Icons.person_add_alt_1_outlined;
      case AppNotificationType.order:
        return Icons.receipt_long_outlined;
      case AppNotificationType.promotion:
        return Icons.local_offer_outlined;
      case AppNotificationType.general:
        return Icons.notifications_none_outlined;
    }
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

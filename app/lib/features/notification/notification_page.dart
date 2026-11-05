import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/header_action_buttons.dart';
import 'widgets/notification_tile.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: const [
          HeaderActionButtons(),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? const _EmptyNotifications()
            : Column(
                children: [
                  if (provider.unreadCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: provider.markAllAsRead,
                          child: const Text('Tandai semua dibaca'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return NotificationTile(
                          notification: item,
                          onTap: () => provider.markAsRead(item.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: AppColors.lightBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informasi seputar akun dan pesananmu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

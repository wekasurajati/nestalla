import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../notifications/models/order_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifications/widgets/notification_card.dart';
import '../notifications/widgets/order_notification_card.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadOnOpen();
    });
  }

  Future<void> _loadOnOpen() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    final provider = context.read<NotificationProvider>();
    await Future.wait([
      provider.load(),
      provider.loadOrderNotifications(token),
    ]);
  }

  Future<void> _refresh() async {
    final provider = context.read<NotificationProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    setState(() => _isRefreshing = true);
    await Future.wait([
      provider.load(),
      provider.loadOrderNotifications(token),
    ]);
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final localItems = provider.items;
    final orderItems = provider.orderNotifications;
    final showLoader = provider.isLoading && localItems.isEmpty && orderItems.isEmpty;
    final showInitialError =
        provider.error != null && localItems.isEmpty && !showLoader;

    final allItems = <Object?>[];
    for (final n in localItems) {
      allItems.add(_LocalEntry(n));
    }
    for (final n in orderItems) {
      allItems.add(_OrderEntry(n));
    }
    allItems.sort((a, b) {
      final da = (a is _LocalEntry ? a.notification.createdAt : a is _OrderEntry ? a.notification.createdAt : DateTime.now());
      final db = (b is _LocalEntry ? b.notification.createdAt : b is _OrderEntry ? b.notification.createdAt : DateTime.now());
      return db.compareTo(da);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.navy,
          child: showLoader
              ? const Center(child: CircularProgressIndicator())
              : showInitialError
                  ? _ErrorNotifications(
                      message: provider.error ?? '',
                      onRetry: provider.refresh,
                    )
                  : Column(
                      children: [
                        if (provider.error != null)
                          _ErrorBanner(
                            message: provider.error ?? '',
                            onRetry: provider.refresh,
                          ),
                        if (_isRefreshing || provider.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        if (allItems.isEmpty)
                          const Expanded(child: _EmptyNotifications())
                        else ...[
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: allItems.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final entry = allItems[index];
                                if (entry == null) return const SizedBox.shrink();

                                if (entry is _LocalEntry) {
                                  return NotificationCard(
                                    notification: entry.notification,
                                    onTap: () => provider.markAsRead(entry.notification.id),
                                  );
                                }
                                if (entry is _OrderEntry) {
                                  return OrderNotificationCard(
                                    notification: entry.notification,
                                    onTap: () => context.push('/orders/${entry.notification.orderId}'),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}

class _LocalEntry {
  final AppNotification notification;
  _LocalEntry(this.notification);
}

class _OrderEntry {
  final OrderNotification notification;
  _OrderEntry(this.notification);
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
              Icons.notifications_none,
              size: 64,
              color: AppColors.navy,
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
          ],
        ),
      ),
    );
  }
}

class _ErrorNotifications extends StatelessWidget {
  const _ErrorNotifications({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: AppColors.lightBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

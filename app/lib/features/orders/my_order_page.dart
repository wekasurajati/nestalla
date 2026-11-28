import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/order_repository.dart';
import '../home/widgets/home_genre_filter.dart';
import 'order.dart';
import 'order_repository.dart';
import 'widgets/order_card.dart';

class MyOrderPage extends StatefulWidget {
  const MyOrderPage({super.key});

  @override
  State<MyOrderPage> createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage> {
  late Future<List<Order>> _ordersFuture;
  OrderStatus? _selectedStatus; // null = All

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() {
      _ordersFuture = context.read<OrderRepository>().getOrders(token: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const _MessageState(
              icon: Icons.error_outline,
             title: 'Gagal memuat pesanan',
             message: 'Silakan coba lagi.',
          );
          }

          final orders = snapshot.data!;
          final visibleOrders = orders
              .where(
                (o) => _selectedStatus == null || o.status == _selectedStatus,
              )
              .toList();

          return Column(
            children: [
              HomeGenreFilter(
                genres: OrderStatus.values.map((e) => e.label).toList(),
                selectedGenre: _selectedStatus?.label,
                onSelected: (label) => setState(() {
                  _selectedStatus = label == null
                      ? null
                      : OrderStatus.values.firstWhere(
                          (e) => e.label == label,
                        );
                }),
              ),
              Expanded(
                child: visibleOrders.isEmpty
                    ? const _MessageState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada pesanan',
                        message: 'Pesanan dengan status ini akan muncul di sini.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visibleOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = visibleOrders[index];
                          return OrderCard(
                            order: order,
                            onReturn: _reload,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.lightBlue),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.dark),
            ),
          ],
        ),
      ),
    );
  }
}

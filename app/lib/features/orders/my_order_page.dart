import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import 'order.dart';
import 'order_data.dart';
import 'widgets/order_card.dart';

class MyOrderPage extends StatefulWidget {
  const MyOrderPage({super.key});

  @override
  State<MyOrderPage> createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage> {
  late final Future<List<Book>> _booksFuture;
  OrderStatus? _selectedStatus; // null = All

  @override
  void initState() {
    super.initState();
    _booksFuture = context.read<BookRepository>().getBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Order',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _MessageState(
              icon: Icons.error_outline,
              title: 'Failed to load orders',
              message: 'Please try again.',
            );
          }

          final booksById = {
            for (final book in snapshot.data ?? const <Book>[]) book.id: book,
          };
          final visibleOrders = dummyOrders
              .where(
                (o) =>
                    booksById.containsKey(o.bookId) &&
                    (_selectedStatus == null || o.status == _selectedStatus),
              )
              .toList();

          return Column(
            children: [
              _StatusFilter(
                selected: _selectedStatus,
                onSelected: (status) =>
                    setState(() => _selectedStatus = status),
              ),
              Expanded(
                child: visibleOrders.isEmpty
                    ? const _MessageState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No orders yet',
                        message: 'Orders with this status will appear here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visibleOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = visibleOrders[index];
                          return OrderCard(
                            order: order,
                            book: booksById[order.bookId]!,
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

class _StatusFilter extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  const _StatusFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _StatusChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final status in OrderStatus.values) ...[
            const SizedBox(width: 8),
            _StatusChip(
              label: status.label,
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.blue,
      backgroundColor: AppColors.lightBlue,
      side: const BorderSide(color: AppColors.blue),
      labelStyle: TextStyle(
        color: selected ? AppColors.background : AppColors.navy,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
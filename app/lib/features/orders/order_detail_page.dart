import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import '../checkout/checkout_models.dart';
import '../checkout/widgets/order_summary_card.dart';
import '../checkout/widgets/section_card.dart';
import 'order.dart';
import 'order_repository.dart';
import 'widgets/status_tracker.dart';

class OrderDetailPage extends StatefulWidget {
  final int? orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<(Order, Book)?> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Order, Book)?> _load() async {
    final orderRepository = context.read<OrderRepository>();
    final bookRepository = context.read<BookRepository>();
    final id = widget.orderId;
    if (id == null) return null;
    final order = await orderRepository.getOrderById(id);
    if (order == null) return null;
    final books = await bookRepository.getBooks();
    for (final book in books) {
      if (book.id == order.bookId) return (order, book);
    }
    return null;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String cancelLabel,
    required String okLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(okLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final repository = context.read<OrderRepository>();
    final ok = await _confirm(
      title: 'Batalkan pesanan?',
      message: 'Pesanan yang dibatalkan tidak dapat dikembalikan.',
      cancelLabel: 'Tidak',
      okLabel: 'Ya, batalkan',
    );
    if (!ok) return;
    await _run(
      () => repository.cancelOrder(order.id),
      'Pesanan berhasil dibatalkan',
    );
  }

  Future<void> _confirmReceived(Order order) async {
    final repository = context.read<OrderRepository>();
    final ok = await _confirm(
      title: 'Pesanan sudah diterima?',
      message: 'Pastikan buku sudah kamu terima dengan baik.',
      cancelLabel: 'Belum',
      okLabel: 'Sudah diterima',
    );
    if (!ok) return;
    await _run(
      () => repository.confirmReceived(order.id),
      'Terima kasih! Pesanan selesai',
    );
  }

  Future<void> _writeReview(Order order) async {
    await context.push('/orders/${order.id}/review');
    if (mounted) _reload();
  }

  Widget? _bottomBar(Order order) {
    final ButtonStyle filled = ElevatedButton.styleFrom(
      backgroundColor: AppColors.navy,
      foregroundColor: AppColors.background,
      minimumSize: const Size.fromHeight(52),
    );

    final Widget? button = switch (order.status) {
      OrderStatus.packed => OutlinedButton(
        onPressed: _busy ? null : () => _cancelOrder(order),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size.fromHeight(52),
        ),
        child: const Text('Batalkan Pesanan'),
      ),
      OrderStatus.shipped => ElevatedButton(
        onPressed: _busy ? null : () => _confirmReceived(order),
        style: filled,
        child: const Text('Pesanan Diterima'),
      ),
      OrderStatus.completed => ElevatedButton(
        onPressed: _busy ? null : () => _writeReview(order),
        style: filled,
        child: const Text('Beri Ulasan'),
      ),
      OrderStatus.canceled => null,
    };
    if (button == null) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: button,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Order, Book)?>(
      future: _future,
      builder: (context, snapshot) {
        final loading =
            snapshot.connectionState == ConnectionState.waiting && !_busy;
        final target = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(child: _BackCircle(onPressed: _back)),
            ),
            title: const Text(
              'Detail Pesanan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : (snapshot.hasError || target == null)
              ? const Center(child: Text('Pesanan tidak ditemukan.'))
              : _buildContent(target.$1, target.$2),
          bottomNavigationBar: target == null ? null : _bottomBar(target.$1),
        );
      },
    );
  }

  Widget _buildContent(Order order, Book book) {
    final data = CheckoutData(
      items: [CheckoutItem(book: book, quantity: order.quantity)],
      shippingCost: order.shippingCost,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionCard(
          title: 'Status Pesanan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'No. pesanan', value: order.orderNumber),
              const SizedBox(height: 4),
              _InfoRow(
                label: 'Tanggal pemesanan',
                value: formatOrderDate(order.orderDate),
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: 'Status',
                value: order.status.label,
                valueColor: order.status.color,
                bold: true,
              ),
              const SizedBox(height: 16),
              StatusTracker(status: order.status),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OrderSummaryCard(data: data),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Informasi Pengiriman',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Nama penerima', value: order.recipientName),
              const SizedBox(height: 4),
              _InfoRow(label: 'Nomor telepon', value: order.phone),
              const SizedBox(height: 8),
              const Text(
                'Alamat',
                style: TextStyle(fontSize: 12, color: AppColors.backCircle),
              ),
              const SizedBox(height: 2),
              Text(
                order.address,
                style: const TextStyle(fontSize: 13, color: AppColors.dark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.backCircle),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }
}

class _BackCircle extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackCircle({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left, size: 24, color: AppColors.backCircle),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/currency.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/order_repository.dart' show OrderRepository;
import '../checkout/payment_webview_page.dart';
import '../checkout/widgets/section_card.dart';
import 'api_order_repository.dart';
import 'order.dart';
import 'widgets/status_tracker.dart';

class OrderDetailPage extends StatefulWidget {
  final int? orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<Order?> _orderFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() {
      _orderFuture = context
          .read<OrderRepository>()
          .getOrderById(token: token, id: widget.orderId!);
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders');
    }
  }

  Future<void> _openPaymentInstructions(Order order) async {
    if (order.snapRedirectUrl == null || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaymentWebViewPage(
          redirectUrl: order.snapRedirectUrl!,
        ),
      ),
    );
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
    if (repository case ApiOrderRepository apiRepo) {
      final ok = await _confirm(
        title: 'Batalkan pesanan?',
        message: 'Pesanan yang dibatalkan tidak dapat dikembalikan.',
        cancelLabel: 'Tidak',
        okLabel: 'Ya, batalkan',
      );
      if (!ok) return;
      await _run(
        () => apiRepo.cancelOrder(order.id),
        'Pesanan berhasil dibatalkan',
      );
    }
  }

  Future<void> _confirmReceived(Order order) async {
    final repository = context.read<OrderRepository>();
    if (repository case ApiOrderRepository apiRepo) {
      final ok = await _confirm(
        title: 'Pesanan sudah diterima?',
        message: 'Pastikan buku sudah kamu terima dengan baik.',
        cancelLabel: 'Belum',
        okLabel: 'Sudah diterima',
      );
      if (!ok) return;
      await _run(
        () => apiRepo.confirmReceived(order.id),
        'Terima kasih! Pesanan selesai',
      );
    }
  }

  Future<void> _writeReview(Order order) async {
    await context.push(
      '/orders/${order.id}/review?book=${order.reviewableBookId}',
    );
    if (mounted) _reload();
  }

  Future<void> _copyResi(String resi) async {
    await Clipboard.setData(ClipboardData(text: resi));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No. resi disalin ke clipboard')),
    );
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
        onPressed: (_busy || order.reviewableBookId == null)
            ? null
            : () => _writeReview(order),
        style: filled,
        child: Text(
          order.reviewableBookId == null ? 'Ulasan Terkirim' : 'Beri Ulasan',
        ),
      ),
      OrderStatus.canceled => null,
      OrderStatus.pending => null,
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
    return FutureBuilder<Order?>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Pesanan tidak ditemukan.'));
        }

        final order = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: _BackCircle(onPressed: _back),
              ),
            ),
            title: const Text(
              'Detail Pesanan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SectionCard(
                title: 'Status Pesanan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'No. pesanan',
                      value: order.orderDisplayNumber,
                    ),
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
              SectionCard(
                title: 'Item Pesanan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.map(
                      (item) => _ItemRow(
                        title: item.title,
                        quantity: item.quantity,
                        price: item.price,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Ringkasan Biaya',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AmountRow(
                      label: 'Subtotal',
                      value: order.totalAmount - order.shippingCost,
                    ),
                    if (order.shippingCost > 0) ...[
                      const SizedBox(height: 4),
                      _AmountRow(
                        label: 'Biaya Pengiriman',
                        value: order.shippingCost,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _AmountRow(
                      label: 'Total',
                      value: order.totalAmount,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Informasi Pengiriman',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Nama penerima',
                      value: order.recipientName,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'Nomor telepon',
                      value: order.phone,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Alamat',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.backCircle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Ekspedisi',
                      value: order.shippingCarrier ?? '-',
                    ),
                    const SizedBox(height: 4),
                    if (order.trackingNumber != null &&
                        order.trackingNumber!.isNotEmpty) ...[
                      Text(
                        'No. Resi:',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.backCircle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              order.trackingNumber!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed:
                                _busy ? null : () => _copyResi(order.trackingNumber!),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text(
                              'Salin',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (order.canShowPaymentInstructions) ...[
                SectionCard(
                  title: 'Pembayaran',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metode pembayaran: ${order.paymentMethodLabel}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed:
                              _busy ? null : () => _openPaymentInstructions(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: AppRadius.shape,
                          ),
                          child: const Text(
                            'Lihat Instruksi Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: _bottomBar(order),
        );
      },
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
          style: TextStyle(
            fontSize: bold ? 13 : 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppColors.dark : AppColors.backCircle,
          ),
        ),
        Text(
          formatRupiah(value),
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: bold ? AppColors.dark : AppColors.backCircle,
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String title;
  final int quantity;
  final int price;

  const _ItemRow({
    required this.title,
    required this.quantity,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty ${quantity}  •  ${formatRupiah(price * quantity)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.backCircle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          child: Icon(
            Icons.chevron_left,
            size: 24,
            color: AppColors.backCircle,
          ),
        ),
      ),
    );
  }
}

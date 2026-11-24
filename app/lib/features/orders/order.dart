import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum OrderStatus { pending, packed, shipped, completed, canceled }

extension OrderStatusStyle on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Belum Dibayar',
    OrderStatus.packed => 'Dikemas',
    OrderStatus.shipped => 'Dikirim',
    OrderStatus.completed => 'Selesai',
    OrderStatus.canceled => 'Dibatalkan',
  };

  Color get color => switch (this) {
    OrderStatus.pending => AppColors.backCircle,
    OrderStatus.packed => AppColors.blue,
    OrderStatus.shipped => Colors.orange,
    OrderStatus.completed => Colors.green,
    OrderStatus.canceled => Colors.red,
  };
}

/// Format tanggal pesanan: dd-MM-yyyy.
String formatOrderDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day-$month-${d.year}';
}

int _toInt(Object? v, [int fallback = 0]) {
  if (v is num) return v.round();
  return num.tryParse(v?.toString() ?? '')?.round() ?? fallback;
}

/// Status dari backend (kolom `status`) -> status di aplikasi.
OrderStatus orderStatusFromApi(String? status) => switch (status) {
  'pending' => OrderStatus.pending,
  'processing' => OrderStatus.packed,
  'shipped' => OrderStatus.shipped,
  'completed' => OrderStatus.completed,
  'cancelled' => OrderStatus.canceled,
  _ => OrderStatus.pending,
};

int? _toIntOpt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return num.tryParse(v.toString())?.toInt();
}

/// Satu item dalam pesanan.
class OrderItem {
  final int bookId;
  final int quantity;
  final int price;
  final String title;
  final String image;
  final bool reviewed;

  const OrderItem({
    required this.bookId,
    this.quantity = 1,
    this.price = 0,
    this.title = '',
    this.image = '',
    this.reviewed = false,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    bookId: _toInt(json['book_id']),
    quantity: _toInt(json['quantity'], 1),
    price: _toInt(json['price']),
    title: json['title'] as String? ?? '',
    image: json['image'] as String? ?? '',
    reviewed: _toInt(json['reviewed']) > 0,
  );
}

/// Model order. Data berasal dari REST API (orders.php).
class Order {
  final int id;
  final String? number;
  final String? merchantOrderId;
  final String paymentStatus; // pending, paid, failed, expired, cancelled
  final int totalAmount;
  final String? snapToken;
  final String? snapRedirectUrl;
  final int? promoId;
  final String? paymentMethod; // bank, ewallet, cod, credit, midtrans
  final DateTime orderDate;
  final OrderStatus status;
  final int shippingCost;
  final int tax;
  final int discountAmount;
  final String recipientName;
  final String phone;
  final String address;
  final List<OrderItem> items;

  const Order({
    required this.id,
    this.number,
    this.merchantOrderId,
    required this.paymentStatus,
    required this.totalAmount,
    this.snapToken,
    this.snapRedirectUrl,
    this.promoId,
    this.paymentMethod,
    required this.orderDate,
    required this.status,
    required this.items,
    this.shippingCost = 0,
    this.tax = 0,
    this.discountAmount = 0,
    this.recipientName = '',
    this.phone = '',
    this.address = '',
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final address = [
      json['address'],
      json['district'],
      json['city'],
      json['province'],
      json['postal_code'],
    ].map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty).join(', ');

    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return Order(
      id: _toInt(json['order_id']),
      number: json['order_number'] as String?,
      merchantOrderId: json['merchant_order_id'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      totalAmount: _toInt(json['total_amount']),
      snapToken: json['snap_token'] as String?,
      snapRedirectUrl: json['snap_redirect_url'] as String?,
      promoId: _toIntOpt(json['promo_id']),
      paymentMethod: json['payment_method'] as String?,
      orderDate: _parseDateTime(json['created_at']),
      status: orderStatusFromApi(json['status'] as String?),
      shippingCost: _toInt(json['shipping_cost']),
      tax: _toInt(json['tax']),
      discountAmount: _toInt(json['discount_amount']),
      recipientName: json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: address.isEmpty ? '' : address,
      items: itemsList,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// Buku pertama di pesanan (dipakai untuk kartu di daftar pesanan).
  int get bookId => items.isEmpty ? 0 : items.first.bookId;

  /// Buku pertama yang belum diulas, atau null kalau semua sudah diulas.
  int? get reviewableBookId =>
      items.where((i) => !i.reviewed).map((i) => i.bookId).firstOrNull;

  /// Nomor pesanan untuk ditampilkan, contoh: LB-2026-0012.
  String get orderNumber => number ?? 'NST-${id.toString().padLeft(5, '0')}';

  /// Nomor pesanan untuk ditampilkan (alias kompatibel versi lama).
  String get orderDisplayNumber => orderNumber;

  /// Apakah pesanan masih menunggu pembayaran (bisa dibuka ulang instruksi pembayaran).
  bool get canShowPaymentInstructions =>
      status == OrderStatus.pending && snapRedirectUrl != null;

  /// Label metode pembayaran untuk ditampilkan.
  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'bank':
        return 'Transfer Bank';
      case 'ewallet':
        return 'E-Wallet';
      case 'cod':
        return 'COD (Bayar di Tempat)';
      case 'credit':
        return 'Kartu Kredit';
      case 'midtrans':
        return 'Midtrans';
      default:
        return paymentMethod ?? '-';
    }
  }

  Order copyWith({
    OrderStatus? status,
    String? paymentMethod,
  }) => Order(
    id: id,
    number: number,
    merchantOrderId: merchantOrderId,
    paymentStatus: paymentStatus,
    totalAmount: totalAmount,
    snapToken: snapToken,
    snapRedirectUrl: snapRedirectUrl,
    promoId: promoId,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    orderDate: orderDate,
    status: status ?? this.status,
    shippingCost: shippingCost,
    tax: tax,
    discountAmount: discountAmount,
    recipientName: recipientName,
    phone: phone,
    address: address,
    items: items,
  );
}

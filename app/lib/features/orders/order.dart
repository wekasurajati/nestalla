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

/// Satu item dalam pesanan.
class OrderItem {
  final int bookId;
  final int quantity;
  final int price;
  final String title;
  final String image;

  const OrderItem({
    required this.bookId,
    required this.quantity,
    required this.price,
    required this.title,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        bookId: _toInt(json['book_id']),
        quantity: _toInt(json['quantity']),
        price: _toInt(json['price']),
        title: json['title'] as String? ?? '',
        image: json['image'] as String? ?? '',
      );
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return num.tryParse(v.toString())?.toInt() ?? 0;
}

int? _toIntOpt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return num.tryParse(v.toString())?.toInt();
}

/// Model order. Data berasal dari REST API (orders.php).
class Order {
  final int id;
  final String orderNumber;
  final String merchantOrderId;
  final String paymentStatus; // pending, paid, failed, expired, cancelled
  final int totalAmount;
  final String? snapToken;
  final String? snapRedirectUrl;
  final int? promoId;
  final String? paymentMethod; // bank, ewallet, cod, credit, midtrans
  final DateTime orderDate;
  final OrderStatus status;
  final int shippingCost;
  final String recipientName;
  final String phone;
  final String address;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.merchantOrderId,
    required this.paymentStatus,
    required this.totalAmount,
    this.snapToken,
    this.snapRedirectUrl,
    this.promoId,
    this.paymentMethod,
    required this.orderDate,
    required this.status,
    required this.shippingCost,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json, Map<int, Map<String, dynamic>> booksMap) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return Order(
      id: _toInt(json['order_id']),
      orderNumber: json['order_number'] as String? ?? '',
      merchantOrderId: json['merchant_order_id'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      totalAmount: _toInt(json['total_amount']),
      snapToken: json['snap_token'] as String?,
      snapRedirectUrl: json['snap_redirect_url'] as String?,
      promoId: _toIntOpt(json['promo_id']),
      paymentMethod: json['payment_method'] as String?,
      orderDate: _parseDateTime(json['created_at']),
      status: _mapPaymentStatusToOrderStatus(json['payment_status'] as String?),
      shippingCost: _toInt(json['shipping_cost']),
      recipientName: json['recipient_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      items: itemsList,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static OrderStatus _mapPaymentStatusToOrderStatus(String? status) {
    switch (status) {
      case 'paid':
        return OrderStatus.packed;
      case 'failed':
      case 'expired':
      case 'cancelled':
        return OrderStatus.canceled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  /// Nomor pesanan untuk ditampilkan.
  String get orderDisplayNumber => orderNumber.isNotEmpty ? orderNumber : 'NST-${id.toString().padLeft(5, '0')}';

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
    orderNumber: orderNumber,
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
    recipientName: recipientName,
    phone: phone,
    address: address,
    items: items,
  );
}

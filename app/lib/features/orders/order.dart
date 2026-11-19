import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum OrderStatus { packed, shipped, completed, canceled }

extension OrderStatusStyle on OrderStatus {
  String get label => switch (this) {
    OrderStatus.packed => 'Dikemas',
    OrderStatus.shipped => 'Dikirim',
    OrderStatus.completed => 'Selesai',
    OrderStatus.canceled => 'Dibatalkan',
  };

  Color get color => switch (this) {
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

/// Status dari backend -> status di aplikasi.
/// pending & processing = Dikemas, cancelled = Dibatalkan.
OrderStatus orderStatusFromApi(String? status) => switch (status) {
  'shipped' => OrderStatus.shipped,
  'completed' => OrderStatus.completed,
  'cancelled' => OrderStatus.canceled,
  _ => OrderStatus.packed,
};

class OrderItem {
  final int bookId;
  final int quantity;
  final int price;
  final bool reviewed;

  const OrderItem({
    required this.bookId,
    this.quantity = 1,
    this.price = 0,
    this.reviewed = false,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    bookId: _toInt(json['book_id']),
    quantity: _toInt(json['quantity'], 1),
    price: _toInt(json['price']),
    reviewed: _toInt(json['reviewed']) > 0,
  );
}

/// Model order. Sengaja ditaruh di folder fitur (bukan models/) supaya tidak
/// mengubah folder bersama. Nilai default untuk ongkir dan data penerima
/// hanya untuk data dummy; data asli datang dari API (lihat fromJson).
class Order {
  final int id;
  final String? number;
  final DateTime orderDate;
  final OrderStatus status;
  final List<OrderItem> items;
  final int shippingCost;
  final int tax;
  final int discountAmount;
  final String recipientName;
  final String phone;
  final String address;

  const Order({
    required this.id,
    required this.orderDate,
    required this.status,
    required this.items,
    this.number,
    this.shippingCost = 4680,
    this.tax = 0,
    this.discountAmount = 0,
    this.recipientName = 'Budi Santoso',
    this.phone = '081234567890',
    this.address = 'Jl. Merdeka No. 10, Kota Contoh, Jawa Timur 60000',
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final address = [
      json['address'],
      json['district'],
      json['city'],
      json['province'],
      json['postal_code'],
    ].map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty).join(', ');

    return Order(
      id: _toInt(json['order_id']),
      number: json['order_number'] as String?,
      orderDate:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      status: orderStatusFromApi(json['status'] as String?),
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingCost: _toInt(json['shipping_cost']),
      tax: _toInt(json['tax']),
      discountAmount: _toInt(json['discount_amount']),
      recipientName: json['recipient_name']?.toString() ?? '-',
      phone: json['phone']?.toString() ?? '-',
      address: address.isEmpty ? '-' : address,
    );
  }

  /// Buku pertama di pesanan (dipakai untuk kartu di daftar pesanan).
  int get bookId => items.isEmpty ? 0 : items.first.bookId;

  /// Buku pertama yang belum diulas, atau null kalau semua sudah diulas.
  int? get reviewableBookId =>
      items.where((i) => !i.reviewed).map((i) => i.bookId).firstOrNull;

  /// Nomor pesanan untuk ditampilkan, contoh: LB-2026-0012.
  String get orderNumber => number ?? 'NST-${id.toString().padLeft(5, '0')}';

  Order copyWith({OrderStatus? status}) => Order(
    id: id,
    number: number,
    orderDate: orderDate,
    status: status ?? this.status,
    items: items,
    shippingCost: shippingCost,
    tax: tax,
    discountAmount: discountAmount,
    recipientName: recipientName,
    phone: phone,
    address: address,
  );
}

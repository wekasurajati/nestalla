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

/// Model order. Sengaja ditaruh di folder fitur (bukan models/) supaya tidak
/// mengubah folder bersama. Nilai default untuk quantity, ongkir, dan data
/// penerima hanya untuk data dummy; nanti datanya dari API.
class Order {
  final int id;
  final int bookId;
  final DateTime orderDate;
  final OrderStatus status;
  final int quantity;
  final int shippingCost;
  final String recipientName;
  final String phone;
  final String address;

  const Order({
    required this.id,
    required this.bookId,
    required this.orderDate,
    required this.status,
    this.quantity = 1,
    this.shippingCost = 4680,
    this.recipientName = 'Budi Santoso',
    this.phone = '081234567890',
    this.address = 'Jl. Merdeka No. 10, Kota Contoh, Jawa Timur 60000',
  });

  /// Nomor pesanan untuk ditampilkan, contoh: NST-00012.
  String get orderNumber => 'NST-${id.toString().padLeft(5, '0')}';

  Order copyWith({OrderStatus? status}) => Order(
    id: id,
    bookId: bookId,
    orderDate: orderDate,
    status: status ?? this.status,
    quantity: quantity,
    shippingCost: shippingCost,
    recipientName: recipientName,
    phone: phone,
    address: address,
  );
}
enum OrderStatus { packed, shipped, completed, canceled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.packed => 'Packed',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.completed => 'Completed',
    OrderStatus.canceled => 'Canceled',
  };
}

/// Model order. Sengaja ditaruh di folder fitur (bukan models/) supaya tidak
/// mengubah folder bersama. Nanti bisa dipindah lewat PR kecil.
class Order {
  final int id;
  final int bookId;
  final DateTime orderDate;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.bookId,
    required this.orderDate,
    required this.status,
  });
}
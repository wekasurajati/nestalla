class OrderNotification {
  final int orderId;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final String? carrierName;
  final String? coverImage;
  final int itemCount;
  final DateTime createdAt;

  const OrderNotification({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    this.carrierName,
    this.coverImage,
    required this.itemCount,
    required this.createdAt,
  });

  factory OrderNotification.fromJson(Map<String, dynamic> json) {
    return OrderNotification(
      orderId: int.parse(json['order_id']?.toString() ?? '0'),
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      carrierName: json['carrier_name'] as String?,
      coverImage: json['cover_image'] as String?,
      itemCount: int.parse(json['item_count']?.toString() ?? '0'),
      createdAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

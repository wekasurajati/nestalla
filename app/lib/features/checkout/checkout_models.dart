import '../../models/book.dart';

class CheckoutItem {
  final Book book;
  final int quantity;

  const CheckoutItem({required this.book, required this.quantity});

  int get lineTotal => book.price * quantity;
}

class CheckoutData {
  final List<CheckoutItem> items;
  final int shippingCost;

  const CheckoutData({required this.items, required this.shippingCost});

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get total => subtotal + shippingCost;
}

class ShippingCarrier {
  final int id;
  final String name;
  final int price;

  const ShippingCarrier({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ShippingCarrier.fromJson(Map<String, dynamic> json) => ShippingCarrier(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
      );
}

class Voucher {
  final String code;
  final int discountAmount;
  final String type;
  final String? description;
  final int? newShippingCost;

  const Voucher({
    required this.code,
    required this.discountAmount,
    required this.type,
    this.description,
    this.newShippingCost,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        code: json['code'] as String? ?? '',
        discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
        type: json['type'] as String? ?? '',
        description: json['description'] as String?,
        newShippingCost: (json['new_shipping_cost'] as num?)?.toInt(),
      );
}

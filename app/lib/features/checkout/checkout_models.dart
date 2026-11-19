import '../../models/book.dart';

class CheckoutItem {
  final Book book;
  final int quantity;

  /// Harga satuan saat pesanan dibuat. Kalau null, pakai harga buku sekarang.
  final int? unitPrice;

  const CheckoutItem({
    required this.book,
    required this.quantity,
    this.unitPrice,
  });

  int get lineTotal => (unitPrice ?? book.price) * quantity;
}

class CheckoutData {
  final List<CheckoutItem> items;
  final int shippingCost;
  final int tax;
  final int discountAmount;

  const CheckoutData({
    required this.items,
    required this.shippingCost,
    this.tax = 0,
    this.discountAmount = 0,
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get total => subtotal - discountAmount + shippingCost + tax;
}

class ShippingInfo {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;

  const ShippingInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
  });
}
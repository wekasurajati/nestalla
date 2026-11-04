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
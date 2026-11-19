import 'order.dart';

/// Data dummy order. Nanti diganti data dari REST API.
final List<Order> dummyOrders = [
  Order(
    id: 1,
    items: [OrderItem(bookId: 1, quantity: 2)],
    orderDate: DateTime(2026, 10, 20),
    status: OrderStatus.shipped,
  ),
  Order(
    id: 2,
    items: [OrderItem(bookId: 2)],
    orderDate: DateTime(2026, 9, 19),
    status: OrderStatus.completed,
  ),
  Order(
    id: 3,
    items: [OrderItem(bookId: 3)],
    orderDate: DateTime(2026, 9, 18),
    status: OrderStatus.completed,
  ),
  Order(
    id: 4,
    items: [OrderItem(bookId: 1)],
    orderDate: DateTime(2026, 10, 25),
    status: OrderStatus.packed,
  ),
  Order(
    id: 5,
    items: [OrderItem(bookId: 2)],
    orderDate: DateTime(2026, 8, 30),
    status: OrderStatus.canceled,
  ),
];
import 'order.dart';

/// Data dummy order. Nanti diganti data dari REST API.
final List<Order> dummyOrders = [
  Order(
    id: 1,
    number: 'NST-00001',
    paymentStatus: 'pending',
    totalAmount: 150000,
    items: [OrderItem(bookId: 1, quantity: 2)],
    orderDate: DateTime(2026, 10, 20),
    status: OrderStatus.shipped,
  ),
  Order(
    id: 2,
    number: 'NST-00002',
    paymentStatus: 'paid',
    totalAmount: 120000,
    items: [OrderItem(bookId: 2)],
    orderDate: DateTime(2026, 9, 19),
    status: OrderStatus.completed,
  ),
  Order(
    id: 3,
    number: 'NST-00003',
    paymentStatus: 'paid',
    totalAmount: 95000,
    items: [OrderItem(bookId: 3)],
    orderDate: DateTime(2026, 9, 18),
    status: OrderStatus.completed,
  ),
  Order(
    id: 4,
    number: 'NST-00004',
    paymentStatus: 'pending',
    totalAmount: 200000,
    items: [OrderItem(bookId: 1)],
    orderDate: DateTime(2026, 10, 25),
    status: OrderStatus.packed,
  ),
  Order(
    id: 5,
    number: 'NST-00005',
    paymentStatus: 'cancelled',
    totalAmount: 80000,
    items: [OrderItem(bookId: 2)],
    orderDate: DateTime(2026, 8, 30),
    status: OrderStatus.canceled,
  ),
];

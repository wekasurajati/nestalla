import 'order.dart';
import 'order_data.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders();
  Future<Order?> getOrderById(int id);

  /// Hanya untuk pesanan berstatus Dikemas.
  Future<void> cancelOrder(int id);

  /// Hanya untuk pesanan berstatus Dikirim.
  Future<void> confirmReceived(int id);
}

/// Data dummy. Nanti diganti ApiOrderRepository yang memanggil REST API.
class DummyOrderRepository implements OrderRepository {
  const DummyOrderRepository();

  @override
  Future<List<Order>> getOrders() async => dummyOrders;

  @override
  Future<Order?> getOrderById(int id) async {
    for (final order in dummyOrders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Future<void> cancelOrder(int id) =>
      _changeStatus(id, from: OrderStatus.packed, to: OrderStatus.canceled);

  @override
  Future<void> confirmReceived(int id) =>
      _changeStatus(id, from: OrderStatus.shipped, to: OrderStatus.completed);

  Future<void> _changeStatus(
    int id, {
    required OrderStatus from,
    required OrderStatus to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final index = dummyOrders.indexWhere((o) => o.id == id);
    if (index == -1 || dummyOrders[index].status != from) {
      throw StateError('Status pesanan tidak dapat diubah');
    }
    dummyOrders[index] = dummyOrders[index].copyWith(status: to);
  }
}
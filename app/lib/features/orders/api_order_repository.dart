import '../../providers/auth_provider.dart';
import '../../repositories/api_client.dart';
import 'order.dart';
import 'order_repository.dart';

/// Order dari backend (backend/api/orders.php). Wajib login (token).
class ApiOrderRepository implements OrderRepository {
  final AuthProvider _auth;

  ApiOrderRepository(this._auth);

  String get _token {
    final token = _auth.token;
    if (token == null) {
      throw const ApiException('Silakan login terlebih dahulu', 401);
    }
    return token;
  }

  @override
  Future<List<Order>> getOrders() async {
    final json = await apiRequest('GET', 'orders.php', token: _token);
    final data = json['data'] as Map<String, dynamic>;
    final orders = data['orders'] as List<dynamic>;
    return orders
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .where((o) => o.items.isNotEmpty)
        .toList();
  }

  @override
  Future<Order?> getOrderById(int id) async {
    try {
      final json = await apiRequest(
        'GET',
        'orders.php?order_id=$id',
        token: _token,
      );
      return Order.fromJson(json['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> cancelOrder(int id) async {
    await apiRequest(
      'POST',
      'orders.php?action=cancel',
      token: _token,
      body: {'order_id': id},
    );
  }

  @override
  Future<void> confirmReceived(int id) async {
    await apiRequest(
      'POST',
      'orders.php?action=confirm',
      token: _token,
      body: {'order_id': id},
    );
  }
}

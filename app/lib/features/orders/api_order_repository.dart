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
  Future<List<Order>> getOrders({required String token}) async {
    final json = await apiRequest('GET', 'orders.php', token: token);
    final data = json['data'] as Map<String, dynamic>;
    final orders = data['orders'] as List<dynamic>;
    return orders
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .where((o) => o.items.isNotEmpty)
        .toList();
  }

  @override
  Future<Order?> getOrderById({required String token, required int id}) async {
    try {
      final json = await apiRequest(
        'GET',
        'orders.php?order_id=$id',
        token: token,
      );
      return Order.fromJson(json['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder({
    required String token,
    required int addressId,
    required int shippingCarrierId,
    String? promoCode,
    String? notes,
    required List<({int bookId, int quantity})> items,
  }) async {
    final json = await apiRequest(
      'POST',
      'orders.php?action=create',
      token: token,
      body: {
        'address_id': addressId,
        'shipping_carrier_id': shippingCarrierId,
        if (promoCode != null) 'promo_code': promoCode,
        if (notes != null) 'notes': notes,
        'items': items
            .map((item) => {
                  'book_id': item.bookId,
                  'quantity': item.quantity,
                })
            .toList(),
      },
    );
    return json['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> checkPayment({
    required String token,
    required int orderId,
  }) async {
    final json = await apiRequest(
      'GET',
      'orders.php?action=check_payment&order_id=$orderId',
      token: token,
    );
    return json['data'] as Map<String, dynamic>;
  }

  /// Batalkan pesanan (hanya untuk pesanan pending/processing).
  Future<void> cancelOrder(int id) async {
    await apiRequest(
      'POST',
      'orders.php?action=cancel',
      token: _token,
      body: {'order_id': id},
    );
  }

  /// Terima pesanan (hanya untuk pesanan shipped).
  Future<void> confirmReceived(int id) async {
    await apiRequest(
      'POST',
      'orders.php?action=confirm',
      token: _token,
      body: {'order_id': id},
    );
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../features/orders/order.dart';
import '../features/notifications/models/order_notification.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders({required String token});
  Future<Order?> getOrderById({required String token, required int id});

  Future<Map<String, dynamic>> createOrder({
    required String token,
    required int addressId,
    required int shippingCarrierId,
    String? promoCode,
    String? notes,
    required List<({int bookId, int quantity})> items,
  });

  Future<Map<String, dynamic>> checkPayment({
    required String token,
    required int orderId,
  });

  Future<List<OrderNotification>> getOrderNotifications(String token);
}

class ApiOrderRepository implements OrderRepository {
  static const _timeout = Duration(seconds: 30);

  Uri _uri([String query = '']) =>
      Uri.parse('${ApiConfig.baseUrl}/orders.php$query');

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Membuat pesanan baru dan mendapatkan Snap token dari Midtrans.
  @override
  Future<Map<String, dynamic>> createOrder({
    required String token,
    required int addressId,
    required int shippingCarrierId,
    String? promoCode,
    String? notes,
    required List<({int bookId, int quantity})> items,
  }) async {
    final body = jsonEncode({
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
    });

    final res = await http.post(
      _uri('?action=create'),
      headers: _headers(token),
      body: body,
    ).timeout(
      _timeout,
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal membuat pesanan');
    }
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Gagal membuat pesanan');
    }
    return json['data'] as Map<String, dynamic>;
  }

  /// Memeriksa status pembayaran pesanan ke server.
  @override
  Future<Map<String, dynamic>> checkPayment({
    required String token,
    required int orderId,
  }) async {
    final res = await http.get(
      _uri('?action=check_payment&order_id=$orderId'),
      headers: _headers(token),
    ).timeout(
      _timeout,
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memeriksa pembayaran');
    }
    return json['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<Order>> getOrders({required String token}) async {
    final res = await http.get(
      _uri(),
      headers: _headers(token),
    ).timeout(
      _timeout,
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat pesanan');
    }
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Gagal memuat pesanan');
    }

    final data = json['data'] as Map<String, dynamic>;
    final ordersList = data['orders'] as List<dynamic>;

    return ordersList.map((o) {
      final orderMap = o as Map<String, dynamic>;
      return Order.fromJson(orderMap);
    }).toList();
  }

  @override
  Future<Order?> getOrderById({required String token, required int id}) async {
    final res = await http.get(
      _uri('?order_id=$id'),
      headers: _headers(token),
    ).timeout(
      _timeout,
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat detail pesanan');
    }
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Gagal memuat detail pesanan');
    }

    final data = json['data'] as Map<String, dynamic>;

    return Order.fromJson(data);
  }

  @override
  Future<List<OrderNotification>> getOrderNotifications(String token) async {
    final res = await http.get(
      _uri('?action=notifications'),
      headers: _headers(token),
    ).timeout(
      _timeout,
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat notifikasi pesanan');
    }
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Gagal memuat notifikasi pesanan');
    }

    final items = json['data']['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => OrderNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

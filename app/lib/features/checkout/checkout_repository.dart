import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../repositories/api_book_repository.dart';
import 'checkout_models.dart';

abstract class CheckoutRepository {
  /// Item yang akan dibeli + ongkos kirim.
  Future<CheckoutData> getCheckoutData();

  /// Daftar ekspedisi dan ongkos kirim tersedia.
  Future<List<ShippingCarrier>> getShippingCarriers({
    String? province,
    String? city,
  });

  /// Memvalidasi dan menerapkan kode voucher.
  Future<Voucher> applyVoucher({
    required String code,
    required int subtotal,
    required int shippingCost,
  });

  /// Membuat order baru.
  Future<void> placeOrder({
    required int addressId,
    required String paymentMethod,
    required List<CheckoutItem> items,
    String? promoCode,
    String? notes,
  });
}

/// Implementasi nyata yang memanggil REST API.
class ApiCheckoutRepository implements CheckoutRepository {
  final BookRepository _bookRepository;

  ApiCheckoutRepository(this._bookRepository);

  Uri _uri([String query = '']) =>
      Uri.parse('${ApiConfig.baseUrl}/checkout.php$query');

  Uri _shippingUri([String query = '']) =>
      Uri.parse('${ApiConfig.baseUrl}/shipping.php$query');

  Uri _promoUri([String query = '']) =>
      Uri.parse('${ApiConfig.baseUrl}/promo.php$query');

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  @override
  Future<CheckoutData> getCheckoutData() async {
    // Diimplementasi nanti bersama order repository
    return CheckoutData(items: const [], shippingCost: 0);
  }

  @override
  Future<List<ShippingCarrier>> getShippingCarriers({
    String? province,
    String? city,
  }) async {
    final queryParams = <String, String>{};
    if (province != null && province.isNotEmpty) {
      queryParams['province'] = province;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }

    final query = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final res = await http
        .get(_shippingUri(query), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat data ekspedisi');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Gagal memuat data ekspedisi');
    }

    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => ShippingCarrier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Voucher> applyVoucher({
    required String code,
    required int subtotal,
    required int shippingCost,
  }) async {
    final body = jsonEncode({
      'code': code,
      'subtotal': subtotal,
      'shipping_cost': shippingCost,
    });

    final res = await http
        .post(_promoUri(), headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      final errorJson = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errorJson['message'] ?? 'Voucher tidak valid');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Voucher tidak valid');
    }

    return Voucher.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> placeOrder({
    required int addressId,
    required String paymentMethod,
    required List<CheckoutItem> items,
    String? promoCode,
    String? notes,
  }) async {
    final body = jsonEncode({
      'address_id': addressId,
      'payment_method': paymentMethod,
      'items': items
          .map(
            (item) => {
              'book_id': item.book.id,
              'quantity': item.quantity,
              'price': item.book.price,
            },
          )
          .toList(),
      if (promoCode != null) 'promo_code': promoCode,
      if (notes != null) 'notes': notes,
    });

    final res = await http
        .post(_uri(), headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Gagal membuat pesanan');
    }
  }
}

/// Data dummy. Diganti ApiCheckoutRepository yang memanggil REST API.
class DummyCheckoutRepository implements CheckoutRepository {
  final BookRepository _bookRepository;

  DummyCheckoutRepository(this._bookRepository);

  @override
  Future<CheckoutData> getCheckoutData() async {
    final book = await _bookRepository.getBookById(1);
    return CheckoutData(
      items: [if (book != null) CheckoutItem(book: book, quantity: 1)],
      shippingCost: 4680,
    );
  }

  @override
  Future<List<ShippingCarrier>> getShippingCarriers({
    String? province,
    String? city,
  }) async {
    return const [];
  }

  @override
  Future<Voucher> applyVoucher({
    required String code,
    required int subtotal,
    required int shippingCost,
  }) async {
    throw Exception('Voucher tidak tersedia dalam mode dummy');
  }

  @override
  Future<void> placeOrder({
    required int addressId,
    required String paymentMethod,
    required List<CheckoutItem> items,
    String? promoCode,
    String? notes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}

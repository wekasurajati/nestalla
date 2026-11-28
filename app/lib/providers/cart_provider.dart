import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import '../models/book.dart';
import 'auth_provider.dart';

class CartProvider extends ChangeNotifier {
  static const _legacyQuantitiesKey = 'cart_quantities';
  static const _timeout = Duration(seconds: 10);

  final AuthProvider _auth;
  final Map<int, int> _quantities = {}; // book_id -> jumlah
  final Map<int, int> _cartIds = {}; // book_id -> cart_id di server
  final Set<int> _selectedIds = {};
  bool _wasLoggedIn;

  /// Pesan error terakhir dari server/jaringan (null jika tidak ada).
  String? lastError;

  CartProvider(SharedPreferences prefs, this._auth)
    : _wasLoggedIn = _auth.isLoggedIn {
    prefs.remove(_legacyQuantitiesKey); // buang data lokal lama
    _auth.addListener(_onAuthChanged);
    if (_wasLoggedIn) refresh();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  Map<int, int> get items => Map.unmodifiable(_quantities);
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  bool contains(int id) => _quantities.containsKey(id);
  bool isSelected(int id) => _selectedIds.contains(id);
  int quantityOf(int id) => _quantities[id] ?? 0;

  int get selectedCount =>
      _selectedIds.where((id) => _quantities.containsKey(id)).length;

  Uri _uri([String query = '']) =>
      Uri.parse('${ApiConfig.baseUrl}/cart.php$query');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_auth.token}',
  };

  int _toInt(dynamic v) => int.tryParse('$v') ?? 0;

  void _onAuthChanged() {
    final now = _auth.isLoggedIn;
    if (now == _wasLoggedIn) return;
    _wasLoggedIn = now;
    if (now) {
      refresh();
    } else {
      _quantities.clear();
      _cartIds.clear();
      _selectedIds.clear();
      notifyListeners();
    }
  }

  /// Ambil keranjang terbaru dari server (semua item dipilih).
  Future<void> refresh() => _load(keepSelection: false);

  Future<void> _load({required bool keepSelection}) async {
    if (!_auth.isLoggedIn) return;
    try {
      final res = await http.get(_uri(), headers: _headers).timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 'success') return;
      final rows = (body['data']['items'] as List).cast<Map<String, dynamic>>();
      _quantities.clear();
      _cartIds.clear();
      for (final row in rows) {
        final bookId = _toInt(row['book_id']);
        _quantities[bookId] = _toInt(row['quantity']);
        _cartIds[bookId] = _toInt(row['cart_id']);
      }
      if (keepSelection) {
        _selectedIds.retainWhere(_quantities.containsKey);
      } else {
        _selectedIds
          ..clear()
          ..addAll(_quantities.keys);
      }
      notifyListeners();
    } catch (_) {
      // biarkan data yang ada
    }
  }

  String _translate(String msg) {
    if (msg.startsWith('Insufficient stock') ||
        msg.startsWith('Cannot add more')) {
      return 'Stok tidak mencukupi';
    }
    return msg;
  }

  Future<bool> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] == 'success') {
        lastError = null;
        return true;
      }
      lastError = _translate('${body['message']}');
      return false;
    } catch (_) {
      lastError = 'Tidak dapat terhubung ke server';
      return false;
    }
  }

  bool _requireLogin() {
    if (_auth.isLoggedIn) return true;
    lastError = 'Silakan login terlebih dahulu';
    return false;
  }

  Future<int?> _cartIdFor(int bookId) async {
    if (!_cartIds.containsKey(bookId)) {
      await _load(keepSelection: true);
    }
    return _cartIds[bookId];
  }

  Future<void> add(int id) async {
    if (!_requireLogin()) return;
    if (_quantities.containsKey(id)) return;
    _quantities[id] = 1;
    _selectedIds.add(id);
    notifyListeners();

    final ok = await _send(
      () => http.post(
        _uri(),
        headers: _headers,
        body: jsonEncode({'book_id': id, 'quantity': 1}),
      ),
    );
    if (ok) {
      await _load(keepSelection: true); // ambil cart_id dari server
    } else {
      _quantities.remove(id);
      _selectedIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> setQuantity(int id, int quantity) async {
    if (!_quantities.containsKey(id)) return;
    if (quantity <= 0) {
      await remove(id);
      return;
    }
    final old = _quantities[id]!;
    if (old == quantity) return;
    _quantities[id] = quantity;
    notifyListeners();

    final cartId = await _cartIdFor(id);
    var ok = false;
    if (cartId != null) {
      ok = await _send(
        () => http.put(
          _uri(),
          headers: _headers,
          body: jsonEncode({'cart_id': cartId, 'quantity': quantity}),
        ),
      );
    }
    if (!ok) {
      _quantities[id] = old;
      notifyListeners();
    }
  }

  Future<void> remove(int id) async {
    final old = _quantities.remove(id);
    if (old == null) return;
    final wasSelected = _selectedIds.remove(id);
    final cartId = _cartIds[id];
    notifyListeners();

    if (cartId == null) return;
    final ok = await _send(
      () => http.delete(_uri('?cart_id=$cartId'), headers: _headers),
    );
    if (ok) {
      _cartIds.remove(id);
    } else {
      _quantities[id] = old;
      if (wasSelected) _selectedIds.add(id);
      notifyListeners();
    }
  }

  Future<void> toggleSelected(int id) async {
    if (!_quantities.containsKey(id)) return;
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  Future<void> toggleAll(bool select) async {
    if (select) {
      _selectedIds.addAll(_quantities.keys);
    } else {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  Future<void> removeSelected() async {
    final ids = Set<int>.of(_selectedIds)
        .where((id) => _quantities.containsKey(id))
        .toList();
    if (ids.isEmpty) return;
    final cartIds = [for (final id in ids) _cartIds[id]];
    for (final id in ids) {
      _quantities.remove(id);
    }
    _selectedIds.clear();
    notifyListeners();

    final results = await Future.wait([
      for (final cartId in cartIds)
        if (cartId != null)
          _send(() => http.delete(_uri('?cart_id=$cartId'), headers: _headers)),
    ]);
    if (results.contains(false)) {
      await _load(keepSelection: false); // sinkronkan ulang jika ada yang gagal
    }
  }

  int selectedTotal(List<Book> books) {
    final byId = <int, int>{};
    for (final book in books) {
      byId[book.id] = book.sellingPrice;
    }
    var total = 0;
    for (final id in _selectedIds) {
      final price = byId[id];
      if (price == null) continue;
      final qty = _quantities[id];
      if (qty == null) continue;
      total += price * qty;
    }
    return total;
  }
}

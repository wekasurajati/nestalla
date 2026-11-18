import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import 'auth_provider.dart';

enum WishlistViewMode { grid, list }

class WishlistProvider extends ChangeNotifier {
  static const _legacyIdsKey = 'wishlist_ids';
  static const _viewModeKey = 'wishlist_view_mode';
  static const _timeout = Duration(seconds: 10);

  final SharedPreferences _prefs;
  final AuthProvider _auth;
  final Set<int> _ids = {};
  WishlistViewMode _viewMode;
  bool _wasLoggedIn;

  /// Pesan error terakhir dari server/jaringan (null jika tidak ada).
  String? lastError;

  WishlistProvider(this._prefs, this._auth)
    : _viewMode = _readViewMode(_prefs),
      _wasLoggedIn = _auth.isLoggedIn {
    _prefs.remove(_legacyIdsKey); // buang data lokal lama
    _auth.addListener(_onAuthChanged);
    if (_wasLoggedIn) refresh();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  Set<int> get ids => Set.unmodifiable(_ids);

  WishlistViewMode get viewMode => _viewMode;

  bool contains(int id) => _ids.contains(id);

  Uri _uri([String query = '']) =>
      Uri.parse('${ApiConfig.baseUrl}/wishlist.php$query');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_auth.token}',
  };

  void _onAuthChanged() {
    final now = _auth.isLoggedIn;
    if (now == _wasLoggedIn) return;
    _wasLoggedIn = now;
    if (now) {
      refresh();
    } else {
      _ids.clear();
      notifyListeners();
    }
  }

  /// Ambil wishlist terbaru dari server.
  Future<void> refresh() async {
    if (!_auth.isLoggedIn) return;
    try {
      final res = await http.get(_uri(), headers: _headers).timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 'success') return;
      final items = (body['data']['items'] as List)
          .cast<Map<String, dynamic>>();
      _ids
        ..clear()
        ..addAll(items.map((e) => int.tryParse('${e['book_id']}') ?? 0));
      notifyListeners();
    } catch (_) {
      // biarkan data yang ada
    }
  }

  Future<bool> _send(
    Future<http.Response> Function() request, {
    Set<String> okMessages = const {},
  }) async {
    try {
      final res = await request().timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = '${body['message']}';
      if (body['status'] == 'success' || okMessages.contains(msg)) {
        lastError = null;
        return true;
      }
      lastError = msg;
      return false;
    } catch (_) {
      lastError = 'Tidak dapat terhubung ke server';
      return false;
    }
  }

  Future<void> toggle(int id) async {
    if (!_auth.isLoggedIn) {
      lastError = 'Silakan login terlebih dahulu';
      return;
    }
    final adding = !_ids.contains(id);
    if (adding) {
      _ids.add(id);
    } else {
      _ids.remove(id);
    }
    notifyListeners();

    final ok = adding
        ? await _send(
            () => http.post(
              _uri(),
              headers: _headers,
              body: jsonEncode({'book_id': id}),
            ),
            okMessages: {'Book already in wishlist'},
          )
        : await _send(
            () => http.delete(_uri('?book_id=$id'), headers: _headers),
            okMessages: {'Item not found in wishlist'},
          );

    if (!ok) {
      // batalkan perubahan lokal
      if (adding) {
        _ids.remove(id);
      } else {
        _ids.add(id);
      }
      notifyListeners();
    }
  }

  Future<void> remove(int id) async {
    if (!_ids.contains(id)) return;
    await toggle(id);
  }

  Future<void> setViewMode(WishlistViewMode mode) async {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
    await _prefs.setString(_viewModeKey, mode.name);
  }

  static WishlistViewMode _readViewMode(SharedPreferences prefs) {
    final value = prefs.getString(_viewModeKey);
    return WishlistViewMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => WishlistViewMode.grid,
    );
  }
}

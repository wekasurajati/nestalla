import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

class CartProvider extends ChangeNotifier {
  static const _quantitiesKey = 'cart_quantities';

  final SharedPreferences _prefs;
  final Map<int, int> _quantities;
  final Set<int> _selectedIds;

  CartProvider(this._prefs)
      : _quantities = _readQuantities(_prefs),
        _selectedIds = {};

  Map<int, int> get items => Map.unmodifiable(_quantities);
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  bool contains(int id) => _quantities.containsKey(id);
  bool isSelected(int id) => _selectedIds.contains(id);
  int quantityOf(int id) => _quantities[id] ?? 0;

  int get selectedCount =>
      _selectedIds.where((id) => _quantities.containsKey(id)).length;

  Future<void> _save() async {
    await _prefs.setString(
      _quantitiesKey,
      jsonEncode(
        _quantities.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  static Map<int, int> _readQuantities(SharedPreferences prefs) {
    final raw = prefs.getString(_quantitiesKey);
    if (raw == null) return <int, int>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(int.tryParse(key) ?? 0, (value as num).toInt()),
    );
  }

  Future<void> add(int id) async {
    if (_quantities.containsKey(id)) return;
    _quantities[id] = 1;
    _selectedIds.add(id);
    notifyListeners();
    await _save();
  }

  Future<void> setQuantity(int id, int quantity) async {
    if (!_quantities.containsKey(id)) return;
    if (quantity <= 0) {
      await remove(id);
      return;
    }
    _quantities[id] = quantity;
    notifyListeners();
    await _save();
  }

  Future<void> remove(int id) async {
    final removed = _quantities.remove(id);
    if (removed == null) return;
    _selectedIds.remove(id);
    notifyListeners();
    await _save();
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
    for (final id in Set<int>.of(_selectedIds)) {
      _quantities.remove(id);
    }
    _selectedIds.clear();
    notifyListeners();
    await _save();
  }

  int selectedTotal(List<Book> books) {
    final byId = <int, int>{};
    for (final book in books) {
      byId[book.id] = book.price;
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

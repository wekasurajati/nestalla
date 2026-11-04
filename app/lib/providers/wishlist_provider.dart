import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WishlistViewMode { grid, list }

class WishlistProvider extends ChangeNotifier {
  static const _idsKey = 'wishlist_ids';
  static const _viewModeKey = 'wishlist_view_mode';

  final SharedPreferences _prefs;
  final Set<int> _ids;
  WishlistViewMode _viewMode;

  WishlistProvider(this._prefs)
    : _ids = (_prefs.getStringList(_idsKey) ?? [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet(),
      _viewMode = _readViewMode(_prefs);

  Set<int> get ids => Set.unmodifiable(_ids);

  WishlistViewMode get viewMode => _viewMode;

  bool contains(int id) => _ids.contains(id);

  Future<void> toggle(int id) async {
    if (!_ids.remove(id)) {
      _ids.add(id);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(int id) async {
    if (_ids.remove(id)) {
      notifyListeners();
      await _save();
    }
  }

  Future<void> setViewMode(WishlistViewMode mode) async {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
    await _prefs.setString(_viewModeKey, mode.name);
  }

  Future<void> _save() {
    return _prefs.setStringList(
      _idsKey,
      _ids.map((id) => id.toString()).toList(),
    );
  }

  static WishlistViewMode _readViewMode(SharedPreferences prefs) {
    final value = prefs.getString(_viewModeKey);
    return WishlistViewMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => WishlistViewMode.grid,
    );
  }
}

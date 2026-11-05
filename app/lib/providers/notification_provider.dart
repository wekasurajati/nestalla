import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  static const _itemsKey = 'app_notifications';

  final SharedPreferences _prefs;
  final List<AppNotification> _items;

  NotificationProvider(this._prefs) : _items = _load(_prefs);

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((item) => !item.isRead).length;

  Future<void> add(AppNotification notification) async {
    _items.removeWhere((item) => item.id == notification.id);
    _items.insert(0, notification);
    notifyListeners();
    await _save();
  }

  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
    await _save();
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    final countBefore = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length == countBefore) return;
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    return _prefs.setStringList(
      _itemsKey,
      _items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  static List<AppNotification> _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_itemsKey) ?? const <String>[];
    final items = <AppNotification>[];

    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          items.add(AppNotification.fromJson(decoded));
        }
      } catch (_) {}
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}

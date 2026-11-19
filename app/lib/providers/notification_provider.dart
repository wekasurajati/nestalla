import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import 'auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._auth, this._repo) {
    _lastToken = _auth.token;
    _auth.addListener(_onAuthChanged);
    if (_lastToken != null) unawaited(load());
  }

  final AuthProvider _auth;
  final ApiNotificationRepository _repo;

  final List<AppNotification> _items = <AppNotification>[];
  bool _isLoading = false;
  String? _error;
  String? _lastToken;

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((item) => !item.isRead).length;

  bool get isLoading => _isLoading;

  String? get error => _error;

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final token = _auth.token;
    if (token == _lastToken) return;
    _lastToken = token;
    if (token == null) {
      _items.clear();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    unawaited(load());
  }

  Future<void> load() async {
    final token = _auth.token;
    if (token == null) {
      _items.clear();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fetched = await _repo.getNotifications(token);
      _items
        ..clear()
        ..addAll(fetched);
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = _message(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> add(AppNotification _) async {
    if (_auth.token == null) return;
    await load();
  }

  Future<void> markAsRead(String id) async {
    final token = _auth.token;
    if (token == null) return;
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1 || _items[index].isRead) return;
    final previous = _items[index];
    _items[index] = previous.copyWith(isRead: true);
    _error = null;
    notifyListeners();
    try {
      final updated = await _repo.markAsRead(token, id);
      _items[index] = updated;
      notifyListeners();
    } catch (e) {
      _items[index] = previous;
      _error = _message(e);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final token = _auth.token;
    if (token == null || unreadCount == 0) return;
    final previous = List<AppNotification>.from(_items);
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    _error = null;
    notifyListeners();
    try {
      await _repo.markAllAsRead(token);
    } catch (e) {
      _items
        ..clear()
        ..addAll(previous);
      _error = _message(e);
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    final token = _auth.token;
    if (token == null) return;
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final removed = _items.removeAt(index);
    _error = null;
    notifyListeners();
    try {
      await _repo.delete(token, id);
    } catch (e) {
      _items.insert(index, removed);
      _error = _message(e);
      notifyListeners();
    }
  }

  static String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

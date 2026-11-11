import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final SharedPreferences _prefs;
  final AuthRepository _repo;

  String? _token;
  Map<String, dynamic>? _user;

  AuthProvider(this._prefs, this._repo) {
    _token = _prefs.getString(_tokenKey);
    final raw = _prefs.getString(_userKey);
    if (raw != null) _user = jsonDecode(raw) as Map<String, dynamic>;
  }

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;

  Future<void> login(String username, String password) async {
    final data = await _repo.login(username, password);
    _token = data['token'] as String;
    _user = Map<String, dynamic>.of(data)..remove('token');
    await _prefs.setString(_tokenKey, _token!);
    await _prefs.setString(_userKey, jsonEncode(_user));
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) {
    return _repo.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? birthDate,
  }) async {
    final data = await _repo.updateProfile(
      _token!,
      fullName: fullName,
      phone: phone,
      birthDate: birthDate,
    );
    _user = Map<String, dynamic>.from(_user ?? {})..addAll(data);
    await _prefs.setString(_tokenKey, _token!);
    await _prefs.setString(_userKey, jsonEncode(_user));
    notifyListeners();
  }

  Future<void> updateProfilePhoto(List<int> bytes, String filename) async {
    final avatar = await _repo.uploadAvatar(_token!, bytes, filename);
    _user = Map<String, dynamic>.from(_user ?? {})..['avatar'] = avatar;
    await _prefs.setString(_tokenKey, _token!);
    await _prefs.setString(_userKey, jsonEncode(_user));
    notifyListeners();
  }

  Future<void> logout() async {
    final tokenLama = _token;
    _token = null;
    _user = null;
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    notifyListeners();
    if (tokenLama != null) {
      await _repo.logout(tokenLama);
    }
  }
}

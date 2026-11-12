import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';

import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const String _webClientId =
      '347952003102-1i1unpugipp7pgjj4r0o3q81mu7arujg.apps.googleusercontent.com';

  final SharedPreferences _prefs;
  final AuthRepository _repo;

  String? _token;
  Map<String, dynamic>? _user;
  bool _googleInitialized = false;

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
    await _applyLoginResult(data);
  }

  Future<void> _applyLoginResult(Map<String, dynamic> data) {
    _token = data['token'] as String;
    _user = Map<String, dynamic>.of(data)..remove('token');
    return Future.wait([
      _prefs.setString(_tokenKey, _token!),
      _prefs.setString(_userKey, jsonEncode(_user)),
    ]).then((_) => notifyListeners());
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

  Future<bool> loginWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
        _googleInitialized = true;
      }
      final auth = await GoogleSignIn.instance.authenticate();
      final idToken = auth.authentication.idToken;
      if (idToken == null) throw Exception('ID Token kosong');
      final data = await _repo.googleLogin(idToken);
      await _applyLoginResult(data);
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return false;
      }
      throw Exception(e.details?.toString() ?? 'Login Google gagal');
    }
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null) {
      throw Exception('Silakan login terlebih dahulu');
    }
    await _repo.changePassword(
      _token!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> forgotPassword(String email) async {
    await _repo.forgotPassword(email);
  }

  Future<String> verifyOtp(String email, String otp) async {
    return await _repo.verifyOtp(email, otp);
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    await _repo.resetPassword(resetToken, newPassword);
  }

  Future<void> updateProfilePhoto(List<int> bytes, String filename) async {
    final avatar = await _repo.uploadAvatar(_token!, bytes, filename);
    _user = Map<String, dynamic>.from(_user ?? {})..['avatar'] = avatar;
    await _prefs.setString(_tokenKey, _token!);
    await _prefs.setString(_userKey, jsonEncode(_user));
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
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

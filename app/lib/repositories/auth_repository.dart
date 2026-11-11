import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth.php?action=login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Login gagal');
    }
    return json['data'] as Map<String, dynamic>;
  }

  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth.php?action=logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // Server tidak terjangkau: jangan melempar error.
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String token, {
    required String fullName,
    String? phone,
    String? birthDate,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth.php?action=update_profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'birth_date': birthDate,
      }),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message']);
    }
    return json['data'] as Map<String, dynamic>;
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth.php?action=register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Pendaftaran gagal');
    }
  }
}

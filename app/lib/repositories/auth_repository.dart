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

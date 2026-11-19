import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Request ke backend (GET/POST). Mengembalikan seluruh body JSON, dan
/// melempar [ApiException] kalau status bukan 200.
Future<Map<String, dynamic>> apiRequest(
  String method,
  String path, {
  String? token,
  Map<String, dynamic>? body,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/$path');
  final headers = <String, String>{
    if (token != null) 'Authorization': 'Bearer $token',
    if (body != null) 'Content-Type': 'application/json',
  };

  final request = method == 'GET'
      ? http.get(uri, headers: headers)
      : http.post(uri, headers: headers, body: jsonEncode(body ?? {}));

  final res = await request.timeout(
    const Duration(seconds: 10),
    onTimeout: () =>
        throw const ApiException('Waktu permintaan habis. Periksa koneksi.'),
  );

  Map<String, dynamic> json;
  try {
    json = jsonDecode(res.body) as Map<String, dynamic>;
  } catch (_) {
    throw ApiException('Respons server tidak valid', res.statusCode);
  }

  if (res.statusCode != 200) {
    throw ApiException(
      json['message']?.toString() ?? 'Terjadi kesalahan',
      res.statusCode,
    );
  }
  return json;
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/app_notification.dart';

class ApiNotificationRepository {
  static const _timeout = Duration(seconds: 10);

  Future<List<AppNotification>> getNotifications(String token) async {
    final data = await _request(
      method: 'GET',
      action: 'list',
      token: token,
      fallbackMessage: 'Gagal memuat notifikasi',
    );
    final items = data['notifications'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppNotification> markAsRead(String token, String id) async {
    final data = await _request(
      method: 'POST',
      action: 'mark_read',
      token: token,
      body: {'id': id},
      fallbackMessage: 'Gagal menandai notifikasi',
    );
    if (data.isEmpty) {
      throw Exception('Data notifikasi tidak ditemukan');
    }
    return AppNotification.fromJson(data);
  }

  Future<int> markAllAsRead(String token) async {
    final data = await _request(
      method: 'POST',
      action: 'mark_all_read',
      token: token,
      fallbackMessage: 'Gagal menandai notifikasi',
    );
    return data['updated'] as int? ?? 0;
  }

  Future<void> delete(String token, String id) async {
    await _request(
      method: 'DELETE',
      action: 'delete',
      token: token,
      body: {'id': id},
      fallbackMessage: 'Gagal menghapus notifikasi',
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String action,
    required String token,
    Map<String, dynamic>? body,
    required String fallbackMessage,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/notifications.php?action=$action',
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});

    late final http.Response res;
    if (method == 'GET') {
      res = await http
          .get(uri, headers: headers)
          .timeout(_timeout, onTimeout: _onTimeout);
    } else if (method == 'POST') {
      res = await http
          .post(uri, headers: headers, body: encodedBody)
          .timeout(_timeout, onTimeout: _onTimeout);
    } else if (method == 'DELETE') {
      res = await http
          .delete(uri, headers: headers, body: encodedBody)
          .timeout(_timeout, onTimeout: _onTimeout);
    } else {
      throw Exception('Method tidak didukung');
    }

    final Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(res.body);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('bentuk respons salah');
      }
      decoded = value;
    } on FormatException {
      throw Exception('Respons server tidak valid');
    }

    if (res.statusCode != 200) {
      throw Exception(decoded['message'] ?? fallbackMessage);
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Data notifikasi tidak valid');
    }
    return data;
  }

  static Future<http.Response> _onTimeout() {
    throw Exception('Waktu permintaan habis. Periksa koneksi.');
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/book.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  @override
  Future<List<Book>> getBooks() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/books.php?action=list'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat daftar buku');
    }
    final data = json['data'] as Map<String, dynamic>;
    final books = data['books'] as List<dynamic>;
    return books.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Book?> getBookById(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/books.php?action=detail&id=$id'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat detail buku');
    }
    final data = json['data'];
    if (data == null) return null;
    return Book.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Book>> searchBooks(String query) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/books.php?action=search&q=${Uri.encodeComponent(query)}'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal mencari buku');
    }
    final data = json['data'] as Map<String, dynamic>;
    final books = data['books'] as List<dynamic>;
    return books.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/books.php?action=categories'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat kategori');
    }
    final data = json['data'] as Map<String, dynamic>;
    final cats = data['categories'] as List<dynamic>;
    return cats.cast<String>();
  }

  @override
  Future<List<Book>> getFeatured() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/books.php?action=featured'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat buku unggulan');
    }
    final data = json['data'] as Map<String, dynamic>;
    final books = data['books'] as List<dynamic>;
    return books.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Book>> getDiscounts() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/books.php?action=discounts'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat penawaran');
    }
    final data = json['data'] as Map<String, dynamic>;
    final books = data['books'] as List<dynamic>;
    return books.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Book>> getNewest() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/books.php?action=newest'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat buku terbaru');
    }
    final data = json['data'] as Map<String, dynamic>;
    final books = data['books'] as List<dynamic>;
    return books.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Book>> getBooksByCategory(String category) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/books.php?action=category&cat=${Uri.encodeComponent(category)}'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu permintaan habis. Periksa koneksi.'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Gagal memuat buku per kategori');
    }
    final data = json['data'] as Map<String, dynamic>;
    final books = data['books'] as List<dynamic>;
    return books.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }
}

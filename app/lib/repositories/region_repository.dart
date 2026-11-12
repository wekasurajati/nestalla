import 'dart:convert';

import 'package:http/http.dart' as http;

class RegionItem {
  final String id;
  final String name;

  const RegionItem({required this.id, required this.name});
}

class PostalOption {
  final String villageName;
  final String postalCode;

  const PostalOption({required this.villageName, required this.postalCode});
}

class RegionRepository {
  static const _baseUrl = 'https://emsifa.github.io/api-wilayah-indonesia/api';
  static const _timeoutSeconds = 10;

  final Map<String, List<RegionItem>> _cache = {};

  static String _toTitleCase(String input) {
    final specialUpper = {'DKI', 'DI', 'NTB', 'NTT'};
    return input
        .split(' ')
        .map((word) {
          if (specialUpper.contains(word)) {
            return word;
          }
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  Future<List<RegionItem>> getProvinces() async {
    final cacheKey = 'provinces';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/provinces.json'),
    ).timeout(const Duration(seconds: _timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data wilayah');
    }

    final List<dynamic> json = jsonDecode(response.body);
    final items = json.map((e) {
      final name = _toTitleCase(e['name'] as String);
      return RegionItem(id: e['id'] as String, name: name);
    }).toList();

    _cache[cacheKey] = items;
    return items;
  }

  Future<List<RegionItem>> getRegencies(String provinceId) async {
    final cacheKey = 'regencies_$provinceId';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/regencies/$provinceId.json'),
    ).timeout(const Duration(seconds: _timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data wilayah');
    }

    final List<dynamic> json = jsonDecode(response.body);
    final items = json.map((e) {
      final name = _toTitleCase(e['name'] as String);
      return RegionItem(id: e['id'] as String, name: name);
    }).toList();

    _cache[cacheKey] = items;
    return items;
  }

  Future<List<RegionItem>> getDistricts(String regencyId) async {
    final cacheKey = 'districts_$regencyId';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/districts/$regencyId.json'),
    ).timeout(const Duration(seconds: _timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data wilayah');
    }

    final List<dynamic> json = jsonDecode(response.body);
    final items = json.map((e) {
      final name = _toTitleCase(e['name'] as String);
      return RegionItem(id: e['id'] as String, name: name);
    }).toList();

    _cache[cacheKey] = items;
    return items;
  }

  Future<List<PostalOption>> getPostalOptions(String districtId) async {
    // TODO: ambil dari backend sendiri. API wilayah tidak menyediakan kode pos.
    return [];
  }
}

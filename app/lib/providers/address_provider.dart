import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../models/address.dart';

class AddressProvider extends ChangeNotifier {
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => List.unmodifiable(_addresses);
  Address? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAddresses(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/addresses.php?action=addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        _addresses = data
            .map((e) => _parseAddress(e as Map<String, dynamic>))
            .toList();
        _addresses.sort((a, b) {
          if (a.isDefault == b.isDefault) return 0;
          return a.isDefault ? -1 : 1;
        });
      } else {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'Gagal memuat alamat');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _addresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress({
    required String token,
    required String recipientName,
    required String phone,
    required String address,
    required String label,
    required String district,
    required String city,
    required String province,
    required String postalCode,
    double? latitude,
    double? longitude,
    required bool isDefault,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = jsonEncode({
        'recipient_name': recipientName,
        'phone': phone,
        'address': address,
        'district': district,
        'city': city,
        'province': province,
        'postal_code': postalCode,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      });

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/addresses.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        final newAddress = Address(
          id: data['address_id'] ?? 0,
          label: label,
          recipientName: recipientName,
          phone: phone,
          address: address,
          district: district,
          city: city,
          province: province,
          postalCode: postalCode,
          latitude: latitude,
          longitude: longitude,
          isDefault: isDefault,
        );
        _addresses.add(newAddress);
        _addresses.sort((a, b) {
          if (a.isDefault == b.isDefault) return 0;
          return a.isDefault ? -1 : 1;
        });
        notifyListeners();
        return true;
      } else {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'Gagal menambahkan alamat');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAddress({
    required String token,
    required int id,
    required String recipientName,
    required String phone,
    required String address,
    required String label,
    required String district,
    required String city,
    required String province,
    required String postalCode,
    double? latitude,
    double? longitude,
    required bool isDefault,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = jsonEncode({
        'recipient_name': recipientName,
        'phone': phone,
        'address': address,
        'district': district,
        'city': city,
        'province': province,
        'postal_code': postalCode,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      });

      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/addresses.php?action=addresses&id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        final index = _addresses.indexWhere((a) => a.id == id);
        if (index != -1) {
          _addresses[index] = Address(
            id: id,
            label: label,
            recipientName: recipientName,
            phone: phone,
            address: address,
            district: district,
            city: city,
            province: province,
            postalCode: postalCode,
            latitude: latitude,
            longitude: longitude,
            isDefault: isDefault,
          );
          _addresses.sort((a, b) {
            if (a.isDefault == b.isDefault) return 0;
            return a.isDefault ? -1 : 1;
          });
        }
        notifyListeners();
        return true;
      } else {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'Gagal memperbarui alamat');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAddress({required String token, required int id}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/addresses.php?action=addresses&id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        _addresses.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      } else {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'Gagal menghapus alamat');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAddress(Address? address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Address? getAddressById(int id) {
    try {
      return _addresses.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearSelection() {
    _selectedAddress = null;
    notifyListeners();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Address _parseAddress(Map<String, dynamic> json) {
    return Address(
      id: json['address_id'] ?? json['id'] ?? 0,
      label: json['label'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
    );
  }
}

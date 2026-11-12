import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../models/address.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/region_repository.dart';
import '../../../widgets/back_button.dart';
import 'map_picker_page.dart';

class AddressFormPage extends StatefulWidget {
  final Address? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _postalCodeManualCtrl = TextEditingController();

  final _repo = RegionRepository();

  double? _latitude;
  double? _longitude;

  String? _provinceId;
  String? _regencyId;
  String? _districtId;
  String? _postalCodeId;

  List<RegionItem> _provinces = [];
  List<RegionItem> _regencies = [];
  List<RegionItem> _districts = [];
  List<PostalOption> _postalOptions = [];

  bool _isLoadingProvinces = true;
  bool _isLoadingRegencies = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingPostal = false;

  String? _provinceError;
  String? _regencyError;
  String? _districtError;
  String? _postalError;

  String _label = 'Rumah';
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadProvinces();
    if (widget.address != null) {
      _nameCtrl.text = widget.address!.recipientName;
      _phoneCtrl.text = widget.address!.phone;
      _addressCtrl.text = widget.address!.address;
      _postalCodeManualCtrl.text = widget.address!.postalCode;
      _label = widget.address!.label;
      _isDefault = widget.address!.isDefault;
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
      _provinceId = null;
      _regencyId = null;
      _districtId = null;
      _postalCodeId = null;
      _resolveEditAddressIds();
    }
  }

  Future<void> _resolveEditAddressIds() async {
    // Cari ID provinsi yang cocok dengan nama provinsi dari alamat tersimpan
    final province = _provinces.firstWhere(
      (p) => p.name.toLowerCase() == widget.address!.province.toLowerCase(),
      orElse: () => _provinces.first,
    );
    setState(() => _provinceId = province.id);

    // Muat dan cari ID kabupaten/kota yang cocok dengan nama city
    await _loadRegencies(province.id);
    final regency = _regencies.firstWhere(
      (r) => r.name.toLowerCase() == widget.address!.city.toLowerCase(),
      orElse: () => _regencies.isNotEmpty ? _regencies.first : province,
    );
    if (_regencies.isNotEmpty) {
      setState(() => _regencyId = regency.id);
    }

    // Muat dan cari ID kecamatan yang cocok dengan nama district
    if (_regencies.isNotEmpty) {
      await _loadDistricts(regency.id);
      final district = _districts.firstWhere(
        (d) => d.name.toLowerCase() == widget.address!.district.toLowerCase(),
        orElse: () => _districts.isNotEmpty ? _districts.first : regency,
      );
      if (_districts.isNotEmpty) {
        setState(() => _districtId = district.id);
      }
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
      _provinceError = null;
      _provinceId = null;
      _regencies = [];
      _regencyId = null;
      _districts = [];
      _districtId = null;
      _postalOptions = [];
      _postalCodeId = null;
    });
    try {
      final items = await _repo.getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = items;
        _isLoadingProvinces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _provinceError = 'Gagal memuat data wilayah';
        _isLoadingProvinces = false;
      });
    }
  }

  Future<void> _loadRegencies(String provinceId) async {
    setState(() {
      _isLoadingRegencies = true;
      _regencyError = null;
      _regencyId = null;
      _regencies = [];
      _districts = [];
      _districtId = null;
      _postalOptions = [];
      _postalCodeId = null;
    });
    try {
      final items = await _repo.getRegencies(provinceId);
      if (!mounted) return;
      setState(() {
        _regencies = items;
        _isLoadingRegencies = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _regencyError = 'Gagal memuat data wilayah';
        _isLoadingRegencies = false;
      });
    }
  }

  Future<void> _loadDistricts(String regencyId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districtError = null;
      _districtId = null;
      _districts = [];
      _postalOptions = [];
      _postalCodeId = null;
    });
    try {
      final items = await _repo.getDistricts(regencyId);
      if (!mounted) return;
      setState(() {
        _districts = items;
        _isLoadingDistricts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _districtError = 'Gagal memuat data wilayah';
        _isLoadingDistricts = false;
      });
    }
  }

  Future<void> _loadPostalOptions(String districtId) async {
    setState(() {
      _isLoadingPostal = true;
      _postalError = null;
      _postalOptions = [];
      _postalCodeId = null;
    });
    try {
      final items = await _repo.getPostalOptions(districtId);
      if (!mounted) return;
      setState(() {
        _postalOptions = items;
        _isLoadingPostal = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _postalError = 'Gagal memuat data wilayah';
        _isLoadingPostal = false;
      });
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final ok = RegExp(r'^\+?[0-9]{9,15}$').hasMatch(value.trim());
    return ok ? null : 'Nomor telepon tidak valid';
  }

  String? _validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode pos wajib diisi';
    }
    if (!RegExp(r'^[0-9]{5}$').hasMatch(value.trim())) {
      return 'Kode pos 5 digit';
    }
    return null;
  }

  InputDecoration _fieldDecoration({
    Widget? suffixIcon,
    String? hint,
    bool readOnly = false,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: AppRadius.border,
      borderSide: BorderSide(color: color),
    );
    final error = Theme.of(context).colorScheme.error;

    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: readOnly
          ? AppColors.grey.withValues(alpha: 0.25)
          : AppColors.background,
      enabledBorder: border(AppColors.grey),
      focusedBorder: border(AppColors.navy),
      errorBorder: border(error),
      focusedErrorBorder: border(error),
    );
  }

  Widget _labelWidget(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.dark),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Nama penerima'),
        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: _fieldDecoration(hint: 'Masukkan nama penerima'),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Nama penerima wajib diisi'
              : null,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Nomor telepon'),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: _fieldDecoration(hint: 'Masukkan nomor telepon'),
          validator: _validatePhone,
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _labelItems() {
    return const [
      DropdownMenuItem(
        value: 'Rumah',
        child: Row(
          children: [
            Icon(Icons.home_outlined, size: 18),
            SizedBox(width: 8),
            Text('Rumah'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'Kantor',
        child: Row(
          children: [
            Icon(Icons.business_outlined, size: 18),
            SizedBox(width: 8),
            Text('Kantor'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'Sekolah',
        child: Row(
          children: [
            Icon(Icons.school_outlined, size: 18),
            SizedBox(width: 8),
            Text('Sekolah'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'Apartemen',
        child: Row(
          children: [
            Icon(Icons.apartment_outlined, size: 18),
            SizedBox(width: 8),
            Text('Apartemen'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'Kost',
        child: Row(
          children: [
            Icon(Icons.bed_outlined, size: 18),
            SizedBox(width: 8),
            Text('Kost'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'Lainnya',
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 18),
            SizedBox(width: 8),
            Text('Lainnya'),
          ],
        ),
      ),
    ];
  }

  Widget _buildLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Label'),
        DropdownButtonFormField<String>(
          value: _label,
          items: _labelItems(),
          onChanged: (v) => setState(() => _label = v ?? 'Rumah'),
          decoration: _fieldDecoration(),
          selectedItemBuilder: (context) => _labelItems()
              .map(
                (item) => Row(
                  children: [const SizedBox(width: 8), Text(item.value ?? '')],
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildProvinceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Provinsi'),
        DropdownButtonFormField<String>(
          value: _provinceId,
          isExpanded: true,
          menuMaxHeight: 300,
          items: _provinces
              .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name),
                  ))
              .toList(),
          onChanged: _isLoadingProvinces || _provinceError != null
              ? null
              : (v) {
                  setState(() => _provinceId = v);
                  if (v != null) {
                    _loadRegencies(v);
                  }
                },
          decoration: _fieldDecoration(
            suffixIcon: _isLoadingProvinces
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            hint: 'Pilih provinsi',
          ),
        ),
        if (_provinceError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.navy),
              const SizedBox(width: 6),
              Text(
                _provinceError!,
                style: const TextStyle(fontSize: 11, color: AppColors.navy),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isLoadingProvinces ? null : _loadProvinces,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRegencyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Kota / Kabupaten'),
        DropdownButtonFormField<String>(
          value: _regencyId,
          isExpanded: true,
          menuMaxHeight: 300,
          items: _regencies
              .map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.name),
                  ))
              .toList(),
          onChanged:
              _provinceId == null ||
                  _isLoadingRegencies ||
                  _regencyError != null
              ? null
              : (v) {
                  setState(() => _regencyId = v);
                  if (v != null) {
                    _loadDistricts(v);
                  }
                },
          decoration: _fieldDecoration(
            suffixIcon: _isLoadingRegencies
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            hint: 'Pilih kota / kabupaten',
            readOnly: _provinceId == null,
          ),
        ),
        if (_regencyError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.navy),
              const SizedBox(width: 6),
              Text(
                _regencyError!,
                style: const TextStyle(fontSize: 11, color: AppColors.navy),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isLoadingRegencies || _provinceId == null
                    ? null
                    : () => _loadRegencies(_provinceId!),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDistrictField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Kecamatan'),
        DropdownButtonFormField<String>(
          value: _districtId,
          isExpanded: true,
          menuMaxHeight: 300,
          items: _districts
              .map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name),
                  ))
              .toList(),
          onChanged:
              _regencyId == null ||
                  _isLoadingDistricts ||
                  _districtError != null
              ? null
              : (v) {
                  setState(() => _districtId = v);
                  if (v != null) {
                    _loadPostalOptions(v);
                  }
                },
          decoration: _fieldDecoration(
            suffixIcon: _isLoadingDistricts
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            hint: 'Pilih kecamatan',
            readOnly: _regencyId == null,
          ),
        ),
        if (_districtError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.navy),
              const SizedBox(width: 6),
              Text(
                _districtError!,
                style: const TextStyle(fontSize: 11, color: AppColors.navy),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isLoadingDistricts || _regencyId == null
                    ? null
                    : () => _loadDistricts(_regencyId!),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPostalCodeField() {
    final hasOptions = _postalOptions.isNotEmpty;

    if (hasOptions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWidget('Kode pos'),
          DropdownButtonFormField<String>(
            value: _postalCodeId,
            isExpanded: true,
            menuMaxHeight: 300,
            items: _postalOptions
                .map(
                  (p) => DropdownMenuItem(
                    value: p.postalCode,
                    child: Text('${p.postalCode} – ${p.villageName}'),
                  ),
                )
                .toList(),
            onChanged: _isLoadingPostal || _postalError != null
                ? null
                : (v) {
                    setState(() => _postalCodeId = v);
                  },
            decoration: _fieldDecoration(
              suffixIcon: _isLoadingPostal
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              hint: 'Pilih kode pos',
            ),
          ),
          if (_postalError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 6),
                Text(
                  _postalError!,
                  style: const TextStyle(fontSize: 11, color: AppColors.navy),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isLoadingPostal || _districtId == null
                      ? null
                      : () => _loadPostalOptions(_districtId!),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ],
        ],
      );
    }

    // Fallback: input manual karena data kode pos tidak tersedia dari API
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Kode pos'),
        TextFormField(
          controller: _postalCodeManualCtrl,
          keyboardType: TextInputType.number,
          maxLength: 5,
          decoration: _fieldDecoration(hint: 'Isi kode pos'),
          validator: _validatePostalCode,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Alamat lengkap'),
        TextFormField(
          controller: _addressCtrl,
          maxLength: 200,
          maxLines: 3,
          decoration: _fieldDecoration(
            hint: 'Nama jalan, nomor rumah, RT/RW, patokan',
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Alamat lengkap wajib diisi'
              : null,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_addressCtrl.text.length}/200',
            style: const TextStyle(fontSize: 11, color: AppColors.dark),
          ),
        ),
      ],
    );
  }

  Widget _buildPinLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget('Lokasi'),
        InkWell(
          onTap: () async {
            final result = await context.push<MapLocation>(
              '/profile/map-picker',
            );
            if (result == null || !mounted) return;
            setState(() {
              _latitude = result.latitude;
              _longitude = result.longitude;
            });
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Lokasi ditandai')));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.grey),
              borderRadius: AppRadius.border,
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, size: 20, color: AppColors.navy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tandai lokasi di peta',
                        style: TextStyle(fontSize: 14, color: AppColors.dark),
                      ),
                      if (_latitude != null && _longitude != null)
                        Text(
                          '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultSwitch() {
    return Row(
      children: [
        Switch(
          value: _isDefault,
          onChanged: (v) => setState(() => _isDefault = v),
          activeThumbColor: AppColors.navy,
        ),
        const SizedBox(width: 8),
        const Text(
          'Jadikan alamat utama',
          style: TextStyle(fontSize: 14, color: AppColors.dark),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || !mounted) return;

      final districtName = _districtId != null
          ? _districts.firstWhere((d) => d.id == _districtId).name
          : '';
      final cityName = _regencyId != null
          ? _regencies.firstWhere((r) => r.id == _regencyId).name
          : '';
      final provinceName = _provinceId != null
          ? _provinces.firstWhere((p) => p.id == _provinceId).name
          : '';
      final postalCode = _postalCodeManualCtrl.text.trim().isNotEmpty
          ? _postalCodeManualCtrl.text.trim()
          : _postalCodeId ?? '';

      final body = jsonEncode({
        'recipient_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'district': districtName,
        'city': cityName,
        'province': provinceName,
        'postal_code': postalCode,
        'label': _label,
        'latitude': _latitude,
        'longitude': _longitude,
        'is_default': _isDefault,
      });

      if (widget.address != null) {
        // Edit mode: PUT
        final res = await http.put(
          Uri.parse(
            '${ApiConfig.baseUrl}/addresses.php?action=addresses&id=${widget.address!.id}',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );

        if (!mounted) return;

        if (res.statusCode != 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          throw Exception(json['message'] ?? 'Gagal memperbarui alamat');
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil diperbarui')),
        );
      } else {
        // Create mode: POST
        final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/addresses.php'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );

        if (!mounted) return;

        if (res.statusCode != 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          throw Exception(json['message'] ?? 'Gagal menyimpan alamat');
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil ditambahkan')),
        );
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAddress() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || widget.address == null || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Alamat?'),
        content: const Text('Yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final res = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/addresses.php?action=addresses&id=${widget.address!.id}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (res.statusCode != 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'Gagal menghapus alamat');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil dihapus')),
      );

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    AppBackButton(onPressed: () => context.pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.address == null
                              ? 'Tambah Alamat'
                              : 'Edit Alamat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 52),
                  ],
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildPhoneField(),
                      const SizedBox(height: 16),
                      _buildLabelField(),
                      const SizedBox(height: 16),
                      _buildProvinceField(),
                      const SizedBox(height: 16),
                      _buildRegencyField(),
                      const SizedBox(height: 16),
                      _buildDistrictField(),
                      const SizedBox(height: 16),
                      _buildPostalCodeField(),
                      const SizedBox(height: 16),
                      _buildAddressField(),
                      const SizedBox(height: 16),
                      _buildPinLocationField(),
                      const SizedBox(height: 16),
                      _buildDefaultSwitch(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.address == null
                                      ? 'Simpan Alamat'
                                      : 'Update Alamat',
                                ),
                        ),
                      ),
                      if (widget.address != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _deleteAddress,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: AppRadius.shape,
                              elevation: 0,
                            ),
                            child: const Text('Hapus Alamat'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _postalCodeManualCtrl.dispose();
    super.dispose();
  }
}

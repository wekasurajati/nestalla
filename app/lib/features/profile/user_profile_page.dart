import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/back_button.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  DateTime? _birthDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user ?? {};
    _nameCtrl.text = (user['full_name'] as String?) ?? '';
    _emailCtrl.text = (user['email'] as String?) ?? '';
    _phoneCtrl.text = (user['phone'] as String?) ?? '';

    final raw = user['birth_date'];
    if (raw is String) {
      final date = DateTime.tryParse(raw);
      if (date != null) {
        _birthDate = date;
        _birthDateCtrl.text = _display(date);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // Tampil di layar: dd/MM/yyyy
  String _display(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  // Dikirim ke server: yyyy-MM-dd
  String _server(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  String _initial() {
    final name = _nameCtrl.text.trim();
    return name.isEmpty ? 'N' : name[0].toUpperCase();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _birthDate = picked;
      _birthDateCtrl.text = _display(picked);
    });
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final ok = RegExp(r'^\+?[0-9]{9,15}$').hasMatch(value.trim());
    return ok ? null : 'Nomor telepon tidak valid';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        birthDate: _birthDate != null ? _server(_birthDate!) : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Gaya field: putih, garis pinggir abu seperti kartu buku
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

  Widget _labeled(String label, Widget field, {String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.dark),
        ),
        const SizedBox(height: 6),
        field,
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(
            note,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _avatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.navy, width: 2),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.lightBlue,
              child: Text(
                _initial(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.navy,
                  size: 18,
                ),
                onPressed: () {
                  // TODO: unggah foto profil
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Segera hadir')));
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Profil Saya',
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
                const SizedBox(height: 40),
                _avatar(),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _labeled(
                        'Nama lengkap',
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: _fieldDecoration(),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama lengkap wajib diisi'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _labeled(
                        'Email',
                        TextFormField(
                          controller: _emailCtrl,
                          readOnly: true,
                          style: TextStyle(
                            color: AppColors.dark.withValues(alpha: 0.7),
                          ),
                          decoration: _fieldDecoration(readOnly: true),
                        ),
                        note: 'Email tidak dapat diubah',
                      ),
                      const SizedBox(height: 16),
                      _labeled(
                        'Nomor telepon',
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration(),
                          validator: _validatePhone,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _labeled(
                        'Tanggal lahir',
                        TextFormField(
                          controller: _birthDateCtrl,
                          readOnly: true,
                          onTap: _pickBirthDate,
                          decoration: _fieldDecoration(
                            hint: 'Lengkapi tanggal lahir Anda',
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
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
                              : const Text('Simpan'),
                        ),
                      ),
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
}

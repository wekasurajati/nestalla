import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../providers/auth_provider.dart';

Future<bool?> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    backgroundColor: AppColors.background,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    builder: (context) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_isSaving) return false;
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) return false;
    if (newPass.length < 6) return false;
    if (newPass == current) return false;
    if (confirm != newPass) return false;
    return true;
  }

  InputDecoration _fieldDecoration({
    required Widget suffixIcon,
    String? errorText,
  }) {
    final errorColor = Theme.of(context).colorScheme.error;
    return InputDecoration(
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.border,
        borderSide: const BorderSide(color: AppColors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.border,
        borderSide: const BorderSide(color: AppColors.navy),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.border,
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.border,
        borderSide: BorderSide(color: errorColor),
      ),
      errorText: errorText,
    );
  }

  String? _validateCurrent(String? v) {
    if (v == null || v.trim().isEmpty) return 'Password terkini wajib diisi';
    return null;
  }

  String? _validateNew(String? v) {
    if (v == null || v.trim().isEmpty) return 'Password baru wajib diisi';
    if (v.trim().length < 6) return 'Kata sandi minimal 6 karakter';
    if (v.trim() == _currentCtrl.text.trim()) return 'Kata sandi baru harus berbeda';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.trim().isEmpty) return 'Konfirmasi password wajib diisi';
    if (v.trim() != _newCtrl.text.trim()) return 'Kata sandi tidak cocok';
    return null;
  }

  void _validateAll() {
    setState(() {});
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    _error = null;
    try {
      await context.read<AuthProvider>().changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? errorText,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.dark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          onChanged: (_) {
            onChanged();
            setState(() {});
          },
          decoration: _fieldDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.grey,
              ),
              onPressed: onToggle,
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final currentError = _validateCurrent(_currentCtrl.text);
    final newError = _validateNew(_newCtrl.text);
    final confirmError = _validateConfirm(_confirmCtrl.text);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              label: 'Masukkan Password Terkini',
              controller: _currentCtrl,
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              errorText: currentError,
              onChanged: _validateAll,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Masukkan Password Baru',
              controller: _newCtrl,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              errorText: newError,
              onChanged: _validateAll,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Konfirmasi Password Baru',
              controller: _confirmCtrl,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              errorText: confirmError,
              onChanged: _validateAll,
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: errorColor, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _canSave ? _save : null,
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: errorColor,
                        side: BorderSide(color: errorColor),
                        shape: AppRadius.shape,
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.push('/forgot-password');
                    },
              child: const Text(
                'Lupa kata sandi?',
                style: TextStyle(color: AppColors.navy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

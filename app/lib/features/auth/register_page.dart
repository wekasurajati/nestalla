import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_logo.dart';
import 'widgets/social_login_row.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // TODO minggu 2: panggil API register
    final username = _usernameCtrl.text.trim();
    await context.read<NotificationProvider>().add(
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Akun berhasil dibuat',
        message:
            'Selamat datang di Nestalla, ${username.isEmpty ? 'Sahabat Nestalla' : username}. '
            'Akunmu sudah aktif dan siap digunakan.',
        createdAt: DateTime.now(),
        type: AppNotificationType.account,
      ),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Akun berhasil dibuat. Silakan masuk.')),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo()),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan isi data diri Anda untuk mendaftar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.dark),
                    ),
                    const SizedBox(height: 24),
                    const Text('Username'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _usernameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v.trim());
                        return ok ? null : 'Masukkan alamat email yang valid';
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Kata sandi'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _hidePassword,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Kata sandi minimal 6 karakter'
                          : null,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Konfirmasi kata sandi'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _hideConfirm,
                      validator: (v) => v != _passwordCtrl.text
                          ? 'Kata sandi tidak cocok'
                          : null,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(_hideConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _hideConfirm = !_hideConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: _submit, child: const Text('Daftar')),
                    const SizedBox(height: 24),
                    const SocialLoginRow(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun?'),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Masuk'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
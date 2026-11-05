import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'widgets/social_login_row.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO minggu 2: panggil API login
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      'Silakan masukkan username dan kata sandi Anda',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.dark),
                    ),
                    const SizedBox(height: 32),
                    const Text('Username'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _usernameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Password'),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Lupa kata sandi?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _submit, child: const Text('Login')),
                    const SizedBox(height: 24),
                    const SocialLoginRow(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Belum punya akun?"),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Daftar'),
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
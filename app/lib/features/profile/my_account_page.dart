import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  // Data dummy. TODO minggu 2: ambil dari API / user yang login.
  final _firstNameCtrl = TextEditingController(text: 'Amartoga');
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(text: 'amartoga@gmail.com');
  final _phoneCtrl = TextEditingController(text: '085350714490');
  final _addressCtrl = TextEditingController();

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _saveProfile() {
    if (_profileKey.currentState!.validate()) {
      // TODO minggu 2: PUT /profile
      _showMessage('Profile updated');
    }
  }

  void _savePassword() {
    if (_passwordKey.currentState!.validate()) {
      // TODO minggu 2: PUT /change-password
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showMessage('Password updated');
    }
  }

  void _logout() {
    // TODO minggu 2: hapus token login
    context.go('/login');
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );

  Widget _passwordField({
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hidden,
      validator: validator,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: AppRadius.border,
      border: Border.all(color: AppColors.grey),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Profile ---
                _card(
                  child: Form(
                    key: _profileKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          size: 64,
                          color: AppColors.dark,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Username',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'amartoga@gmail.com',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('First name'),
                                  TextFormField(
                                    controller: _firstNameCtrl,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'First name is required'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Last name'),
                                  TextFormField(controller: _lastNameCtrl),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Email'),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      final ok = RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      ).hasMatch(v.trim());
                                      return ok ? null : 'Invalid email';
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Phone number'),
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _label('Address'),
                        TextFormField(controller: _addressCtrl, maxLines: 3),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Save changes'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Change Password ---
                _card(
                  child: Form(
                    key: _passwordKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _label('Password'),
                        _passwordField(
                          controller: _currentPassCtrl,
                          hidden: _hideCurrent,
                          onToggle: () =>
                              setState(() => _hideCurrent = !_hideCurrent),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Current password is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _label('New Password'),
                        _passwordField(
                          controller: _newPassCtrl,
                          hidden: _hideNew,
                          onToggle: () => setState(() => _hideNew = !_hideNew),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _label('Confirm new password'),
                        _passwordField(
                          controller: _confirmPassCtrl,
                          hidden: _hideConfirm,
                          onToggle: () =>
                              setState(() => _hideConfirm = !_hideConfirm),
                          validator: (v) => v != _newPassCtrl.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _savePassword,
                          child: const Text('Save changes'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Logout ---
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: AppRadius.shape,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

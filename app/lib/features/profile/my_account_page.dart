import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../providers/auth_provider.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool _notifOn = false;

  void _segeraHadir() {
    // TODO: navigasi ke halaman tujuan
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Segera hadir')));
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    required bool chevron,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 56,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            const SizedBox(width: 8),
            if (trailing != null)
              trailing
            else if (chevron) ...[
              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        context.watch<AuthProvider>().user?['full_name'] as String?;
    final displayName = (fullName == null || fullName.isEmpty)
        ? 'Sahabat Nestalla'
        : fullName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Profil Saya',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Baris profil
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.lightBlue,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color.fromARGB(255, 39, 38, 38),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.grey),
                const SizedBox(height: 24),

                // Daftar menu
                _menuRow(
                  icon: Icons.person_outline,
                  title: 'Profil Saya',
                  chevron: true,
                  onTap: () => context.push('/profile/edit'),
                ),
                const Divider(height: 1, color: AppColors.grey),
                _menuRow(
                  icon: Icons.place_outlined,
                  title: 'Alamat Saya',
                  chevron: true,
                  onTap: _segeraHadir,
                ),
                const Divider(height: 1, color: AppColors.grey),
                _menuRow(
                  icon: Icons.lock_outline,
                  title: 'Ubah Kata Sandi',
                  chevron: true,
                  onTap: _segeraHadir,
                ),
                const Divider(height: 1, color: AppColors.grey),
                _menuRow(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  chevron: true,
                  onTap: _segeraHadir,
                ),
                const Divider(height: 1, color: AppColors.grey),
                SizedBox(
                  height: 56,
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Notifikasi')),
                        const SizedBox(width: 8),
                        Switch(
                          value: _notifOn,
                          onChanged: (value) {
                            // TODO: simpan preferensi notifikasi
                            setState(() => _notifOn = value);
                          },
                          activeThumbColor: AppColors.navy,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.grey),
                const SizedBox(height: 24),

                // Kotak informasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withValues(alpha: 0.15),
                    borderRadius: AppRadius.border,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Jika ada pertanyaan lain, kamu bisa menghubungi kami.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // TODO: buka WhatsApp dengan url_launcher
                          _segeraHadir();
                        },
                        child: const Text(
                          'Hubungi via WhatsApp',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol keluar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Keluar dari akun?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.read<AuthProvider>().logout();
                                if (!mounted) return;
                                context.go('/login');
                              },
                              child: const Text('Keluar'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: AppRadius.shape,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

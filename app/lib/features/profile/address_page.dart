import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/address_card.dart';
import '../../../widgets/back_button.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAddresses();
    });
  }

  Future<void> _loadAddresses() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<AddressProvider>().loadAddresses(token);
  }

  Future<void> _addAddress() async {
    await context.push('/profile/addresses/form');
    if (!mounted) return;
    // Setelah kembali dari form, daftar otomatis terupdate via provider.notifyListeners()
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final addresses = provider.addresses;
    final error = provider.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      AppBackButton(onPressed: () => context.pop()),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Alamat Saya',
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
                  const SizedBox(height: 24),
                  if (error != null && error.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.navy,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => _loadAddresses(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: AppRadius.shape,
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    Expanded(
                      child: addresses.isEmpty
                          ? _buildEmpty(context)
                          : _buildList(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.15),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                    maxHeight: 180,
                  ),
                  child: Image.asset(
                    'assets/images/noaddres.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.location_on_outlined,
                      size: 64,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tambahkan alamat pengiriman',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 180,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _addAddress,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: AppRadius.shape,
                    ),
                    child: const Text(
                      'Tambah Alamat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.15),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final addresses = provider.addresses;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final addr = addresses[index];
              return AddressCard(
                name: addr.recipientName,
                phone: addr.phone,
                address:
                    '${addr.address}, ${addr.district}, ${addr.city}, ${addr.province} ${addr.postalCode}',
                isPrimary: addr.isDefault,
                onTap: () {
                  context.push('/profile/addresses/form?edit=${addr.id}');
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _addAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: AppRadius.shape,
            ),
            child: const Text(
              'Tambah Alamat',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

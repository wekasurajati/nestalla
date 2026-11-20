import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../models/address.dart';
import '../../../providers/address_provider.dart';

Future<Address?> showChangeAddressSheet(BuildContext context) {
  return showModalBottomSheet<Address>(
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
    builder: (context) => const _ChangeAddressSheet(),
  );
}

class _ChangeAddressSheet extends StatefulWidget {
  const _ChangeAddressSheet();

  @override
  State<_ChangeAddressSheet> createState() => _ChangeAddressSheetState();
}

class _ChangeAddressSheetState extends State<_ChangeAddressSheet> {
  Address? _selected;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final addresses = provider.addresses;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
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
            const Text(
              'Pilih Alamat Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
            const SizedBox(height: 16),
            if (addresses.isEmpty)
              const Text(
                'Belum ada alamat tersedia.',
                style: TextStyle(fontSize: 13, color: AppColors.backCircle),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final addr in addresses) ...[
                    _AddressTile(
                      address: addr,
                      isSelected: _selected?.id == addr.id,
                      onTap: () => setState(() => _selected = addr),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                        shape: AppRadius.shape,
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: AppRadius.shape,
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.border,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy.withValues(alpha: 0.05) : AppColors.background,
          border: Border.all(
            color: isSelected ? AppColors.navy : AppColors.grey,
          ),
          borderRadius: AppRadius.border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    address.recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (address.isDefault)
                  const Text(
                    'Utama',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${address.address}, ${address.district}, ${address.city}, ${address.province} ${address.postalCode}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.dark.withValues(alpha: 0.8),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle, color: AppColors.navy, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

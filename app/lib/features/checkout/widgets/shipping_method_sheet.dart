import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/currency.dart';
import '../checkout_models.dart';

Future<ShippingCarrier?> showShippingMethodSheet(
  BuildContext context, {
  required List<ShippingCarrier> carriers,
  required int selectedId,
}) {
  return showModalBottomSheet<ShippingCarrier>(
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
    builder: (context) => _ShippingMethodSheet(
      carriers: carriers,
      selectedId: selectedId,
    ),
  );
}

class _ShippingMethodSheet extends StatefulWidget {
  final List<ShippingCarrier> carriers;
  final int selectedId;

  const _ShippingMethodSheet({
    required this.carriers,
    required this.selectedId,
  });

  @override
  State<_ShippingMethodSheet> createState() => _ShippingMethodSheetState();
}

class _ShippingMethodSheetState extends State<_ShippingMethodSheet> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  @override
  Widget build(BuildContext context) {
    final carriers = widget.carriers;

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
            const Text(
              'Pilih Metode Pengiriman',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            if (carriers.isEmpty)
              const Text(
                'Belum ada metode pengiriman tersedia.',
                style: TextStyle(fontSize: 13, color: AppColors.backCircle),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final carrier in carriers) ...[
                    _CarrierTile(
                      carrier: carrier,
                      isSelected: _selectedId == carrier.id,
                      onTap: () => setState(() => _selectedId = carrier.id),
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
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: _selectedId == null ? null : () {
                        final selected = carriers.firstWhere(
                          (c) => c.id == _selectedId,
                        );
                        Navigator.pop(context, selected);
                      },
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

class _CarrierTile extends StatelessWidget {
  final ShippingCarrier carrier;
  final bool isSelected;
  final VoidCallback onTap;

  const _CarrierTile({
    required this.carrier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.border,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy.withValues(alpha: 0.1) : AppColors.background,
          border: Border.all(
            color: isSelected ? AppColors.navy : AppColors.grey,
          ),
          borderRadius: AppRadius.border,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carrier.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(carrier.price),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.navy : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.navy,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

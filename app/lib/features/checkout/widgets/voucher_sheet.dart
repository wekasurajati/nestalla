import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../checkout_models.dart';
import '../checkout_repository.dart';

Future<Voucher?> showVoucherSheet(
  BuildContext context, {
  required int subtotal,
  required int shippingCost,
}) {
  return showModalBottomSheet<Voucher>(
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
    builder: (context) => _VoucherSheet(
      subtotal: subtotal,
      shippingCost: shippingCost,
    ),
  );
}

class _VoucherSheet extends StatefulWidget {
  final int subtotal;
  final int shippingCost;

  const _VoucherSheet({
    required this.subtotal,
    required this.shippingCost,
  });

  @override
  State<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends State<_VoucherSheet> {
  final _codeController = TextEditingController();
  String? _error;
  bool _isApplying = false;
  Voucher? _appliedVoucher;

  Future<void> _applyVoucher() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplying = true;
      _error = null;
    });

    try {
      final repository = context.read<CheckoutRepository>();
      final voucher = await repository.applyVoucher(
        code: code,
        subtotal: widget.subtotal,
        shippingCost: widget.shippingCost,
      );

      if (!mounted) return;

      setState(() {
        _appliedVoucher = voucher;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
            'Voucher / Promo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kode voucher',
                    errorText: _error,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.border,
                      borderSide: const BorderSide(color: AppColors.backCircle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.border,
                      borderSide: const BorderSide(color: AppColors.backCircle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.border,
                      borderSide: const BorderSide(color: AppColors.navy),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AppRadius.border,
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: AppRadius.border,
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  onFieldSubmitted: (_) => _applyVoucher(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isApplying ? null : _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: AppRadius.shape,
                    ),
                    child: _isApplying
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],
          if (_appliedVoucher != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.05),
                borderRadius: AppRadius.border,
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: AppColors.navy, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appliedVoucher!.code,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _appliedVoucher!.type,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _appliedVoucher),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: AppRadius.shape,
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

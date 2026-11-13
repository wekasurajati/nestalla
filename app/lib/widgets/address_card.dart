import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AddressCard extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AddressCard({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    this.isPrimary = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions = onEdit != null || onDelete != null;

    return Material(
      color: AppColors.background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.border,
        side: const BorderSide(color: AppColors.grey),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hanya untuk alamat utama
              if (isPrimary) ...[
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: AppColors.navy),
                    SizedBox(width: 4),
                    Text(
                      'Utama',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Nama dan telepon
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  Text(
                    '  ·  ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Alamat
              Text(
                address,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark.withValues(alpha: 0.8),
                ),
              ),

              // Aksi (hanya muncul kalau fungsinya diberikan)
              if (hasActions) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.grey),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton(
                        onPressed: onEdit,
                        style: _actionStyle(AppColors.navy),
                        child: const Text('Ubah'),
                      ),
                    if (onDelete != null)
                      TextButton(
                        onPressed: onDelete,
                        style: _actionStyle(
                          Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Hapus'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _actionStyle(Color color) {
    return TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

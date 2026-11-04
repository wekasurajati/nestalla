import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../providers/wishlist_provider.dart';

class WishlistViewToggle extends StatelessWidget {
  final WishlistViewMode value;
  final ValueChanged<WishlistViewMode> onChanged;

  const WishlistViewToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.border,
        side: const BorderSide(color: AppColors.grey),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            icon: Icons.grid_view,
            tooltip: 'Grid view',
            selected: value == WishlistViewMode.grid,
            onTap: () => onChanged(WishlistViewMode.grid),
          ),
          _ViewModeButton(
            icon: Icons.view_list,
            tooltip: 'List view',
            selected: value == WishlistViewMode.list,
            onTap: () => onChanged(WishlistViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? AppColors.navy.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 34,
            child: Icon(icon, size: 18, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

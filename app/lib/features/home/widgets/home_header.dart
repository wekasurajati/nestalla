import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/header_action_buttons.dart';

class HomeHeader extends StatelessWidget {
  final String username;

  const HomeHeader({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppLogo(width: 120),
              Spacer(),
              HeaderActionButtons(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Halo, $username',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mau baca apa hari ini?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          _SearchBar(onTap: () => context.push('/search')),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.border,
        side: const BorderSide(color: AppColors.lightBlue),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: AppColors.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cari judul buku atau penulis...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.dark.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

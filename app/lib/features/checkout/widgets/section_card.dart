import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    this.titleWidget,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.border,
        border: Border.all(color: AppColors.backCircle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget ??
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

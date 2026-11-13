import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: shell.currentIndex,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData outlineIcon;
  final IconData filledIcon;

  const _TabSpec(this.label, this.outlineIcon, this.filledIcon);
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _BottomNavBar({required this.currentIndex, required this.onSelected});

  static const _tabs = <_TabSpec>[
    _TabSpec('Beranda', CupertinoIcons.house, CupertinoIcons.house_fill),
    _TabSpec('Pesanan', CupertinoIcons.doc_text, CupertinoIcons.doc_text_fill),
    _TabSpec('Favorit', CupertinoIcons.heart, CupertinoIcons.heart_fill),
    _TabSpec('Akun', CupertinoIcons.person, CupertinoIcons.person_fill),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(
            _tabs.length,
            (i) => Expanded(
              child: _TabItem(
                spec: _tabs[i],
                selected: currentIndex == i,
                onTap: () => onSelected(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final grey = AppColors.dark.withValues(alpha: 0.75);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Container(height: 3, color: AppColors.navy)
          else
            const SizedBox(height: 3),
          Container(
            width: double.infinity,
            decoration: selected
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.grey.withValues(alpha: 0.4),
                        AppColors.grey.withValues(alpha: 0.0),
                      ],
                    ),
                  )
                : null,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? spec.filledIcon : spec.outlineIcon,
                  size: 24,
                  color: selected ? AppColors.navy : grey,
                ),
                const SizedBox(height: 4),
                Text(
                  spec.label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

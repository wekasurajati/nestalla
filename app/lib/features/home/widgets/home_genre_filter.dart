import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeGenreFilter extends StatelessWidget {
  final List<String> genres;
  final String? selectedGenre;
  final ValueChanged<String?> onSelected;

  const HomeGenreFilter({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _GenreChip(
            label: 'Semua',
            selected: selectedGenre == null,
            onTap: () => onSelected(null),
          ),
          for (final genre in genres) ...[
            const SizedBox(width: 8),
            _GenreChip(
              label: genre,
              selected: selectedGenre == genre,
              onTap: () => onSelected(genre),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.navy,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? AppColors.navy : AppColors.lightBlue,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.background : AppColors.navy,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

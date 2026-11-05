import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/book.dart';
import '../../providers/wishlist_provider.dart';
import '../../repositories/book_repository.dart';
import 'widgets/empty_wishlist_view.dart';
import 'widgets/wishlist_card.dart';
import 'widgets/wishlist_list_tile.dart';
import 'widgets/wishlist_view_toggle.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late final Future<List<Book>> _booksFuture;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _booksFuture = context.read<BookRepository>().getBooks();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorit Saya',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _MessageState(
              icon: Icons.error_outline,
              title: 'Gagal memuat wishlist',
              message: 'Silakan coba lagi.',
            );
          }

          final allBooks = snapshot.data ?? const <Book>[];
          final wishlistBooks = allBooks
              .where((book) => wishlist.contains(book.id))
              .toList();

          if (wishlistBooks.isEmpty) {
            final featuredBooks = allBooks
                .where((book) => book.isFeatured)
                .take(6)
                .toList();
            return EmptyWishlistView(popularPicks: featuredBooks);
          }

          final categories =
              wishlistBooks.map((book) => book.category).toSet().toList()
                ..sort();
          final selectedCategory = categories.contains(_selectedCategory)
              ? _selectedCategory
              : null;
          final visibleBooks = selectedCategory == null
              ? wishlistBooks
              : wishlistBooks
                    .where((book) => book.category == selectedCategory)
                    .toList();

          return Column(
            children: [
              _CategoryFilter(
                categories: categories,
                selected: selectedCategory,
                onSelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: WishlistViewToggle(
                    value: wishlist.viewMode,
                    onChanged: (mode) {
                      context.read<WishlistProvider>().setViewMode(mode);
                    },
                  ),
                ),
              ),
              Expanded(
                child: visibleBooks.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada buku di kategori ini.',
                          style: TextStyle(color: AppColors.dark),
                        ),
                      )
                    : wishlist.viewMode == WishlistViewMode.grid
                    ? _buildGrid(visibleBooks)
                    : _buildList(visibleBooks),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Book> books) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 32.0;
        const crossAxisSpacing = 10.0;
        const mainAxisSpacing = 16.0;
        const detailsHeight = 116.0;
        const columns = 3;
        final itemWidth =
            (constraints.maxWidth -
                horizontalPadding -
                crossAxisSpacing * (columns - 1)) /
            columns;
        final coverHeight = itemWidth * 3 / 2;
        final itemHeight = coverHeight + detailsHeight;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) => WishlistCard(book: books[index]),
        );
      },
    );
  }

  Widget _buildList(List<Book> books) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          WishlistListTile(book: books[index], index: index),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _CategoryChip(
            label: 'Semua',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _CategoryChip(
              label: category,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
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
      side: BorderSide(color: selected ? AppColors.navy : AppColors.lightBlue),
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

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.lightBlue),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.dark),
            ),
          ],
        ),
      ),
    );
  }
}

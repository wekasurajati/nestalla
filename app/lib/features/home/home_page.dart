import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import 'widgets/home_book_section.dart';
import 'widgets/home_genre_filter.dart';
import 'widgets/home_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<Book>> _booksFuture;
  String _username = 'Amortage';
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _booksFuture = context.read<BookRepository>().getBooks();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('username')?.trim();
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() => _username = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<Book>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _MessageState(
                icon: Icons.error_outline,
                title: 'Gagal memuat buku',
                message: 'Silakan coba lagi nanti.',
              );
            }

            final allBooks = snapshot.data ?? const <Book>[];
            if (allBooks.isEmpty) {
              return const _MessageState(
                icon: Icons.menu_book,
                title: 'Belum ada buku',
                message: 'Katalog buku akan segera hadir.',
              );
            }

            final genres = allBooks.map((book) => book.category).toSet().toList()
              ..sort();
            final selectedGenre = genres.contains(_selectedGenre)
                ? _selectedGenre
                : null;

            List<Book> filtered(Iterable<Book> books) => selectedGenre == null
                ? books.toList()
                : books
                      .where((book) => book.category == selectedGenre)
                      .toList();

            final featured = filtered(
              allBooks.where((book) => book.isFeatured),
            );
            final discounts = filtered(
              allBooks.where((book) => book.isDiscount),
            );
            final sortedNewest = allBooks.toList()
              ..sort(
                (a, b) =>
                    (b.publishedYear ?? 0).compareTo(a.publishedYear ?? 0),
              );
            final newest = filtered(sortedNewest);
            final hasSection =
                featured.isNotEmpty ||
                discounts.isNotEmpty ||
                newest.isNotEmpty;

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                HomeHeader(username: _username),
                const SizedBox(height: 4),
                HomeGenreFilter(
                  genres: genres,
                  selectedGenre: selectedGenre,
                  onSelected: (genre) =>
                      setState(() => _selectedGenre = genre),
                ),
                if (!hasSection)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Belum ada buku untuk genre ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.dark),
                    ),
                  )
                else ...[
                  HomeBookSection(title: 'Buku unggulan', books: featured),
                  HomeBookSection(title: 'Penawaran Spesial', books: discounts),
                  HomeBookSection(title: 'Rilis Terbaru', books: newest),
                ],
              ],
            );
          },
        ),
      ),
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

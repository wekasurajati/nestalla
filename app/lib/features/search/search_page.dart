import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import '../../widgets/header_action_buttons.dart';
import 'widgets/search_result_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final Future<List<Book>> _booksFuture;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _booksFuture = context.read<BookRepository>().getBooks();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Book> _filterBooks(List<Book> books) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return books;
    return books.where((book) {
      final title = book.title.toLowerCase();
      final author = book.author.toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();
  }

  void _handleSubmit(List<Book> books) {
    final query = _query.trim();
    if (query.isEmpty) return;
    _focusNode.unfocus();
    if (_filterBooks(books).isEmpty) {
      _showNotFoundDialog(query);
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  Future<void> _showNotFoundDialog(String query) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: AppRadius.shape,
        icon: const Icon(
          Icons.search_off,
          size: 40,
          color: AppColors.lightBlue,
        ),
        title: const Text('Buku tidak ditemukan'),
        content: Text(
          'Tidak ada buku dengan judul "$query". '
          'Coba gunakan kata kunci lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _isDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cari Buku',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: const [HeaderActionButtons(), SizedBox(width: 16)],
      ),
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
            final results = _filterBooks(allBooks);
            final hasQuery = _query.trim().isNotEmpty;

            return Column(
              children: [
                _SearchField(
                  controller: _controller,
                  focusNode: _focusNode,
                  hasQuery: hasQuery,
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: () => _handleSubmit(allBooks),
                  onClear: _clearSearch,
                ),
                if (results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hasQuery
                            ? '${results.length} buku ditemukan'
                            : 'Semua buku (${results.length})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: results.isEmpty
                      ? hasQuery
                            ? _MessageState(
                                icon: Icons.search_off,
                                title: 'Buku tidak ditemukan',
                                message:
                                    'Tidak ada buku dengan judul "$_query". '
                                    'Coba kata kunci lain.',
                              )
                            : const _MessageState(
                                icon: Icons.menu_book,
                                title: 'Belum ada buku',
                                message: 'Katalog buku akan segera hadir.',
                              )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              SearchResultTile(book: results[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hasQuery,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
        style: const TextStyle(fontSize: 14, color: AppColors.dark),
        decoration: InputDecoration(
          hintText: 'Cari judul buku atau penulis...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: AppColors.dark.withValues(alpha: 0.55),
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.navy),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.dark.withValues(alpha: 0.6),
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: AppColors.grey.withValues(alpha: 0.35),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.border,
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.border,
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.border,
            borderSide: BorderSide(color: AppColors.blue, width: 1.5),
          ),
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

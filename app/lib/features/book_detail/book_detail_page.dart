import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/currency.dart';
import '../../models/book.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../repositories/book_repository.dart';
import '../../widgets/back_button.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/rating_label.dart';
import 'widgets/review_card.dart';

class BookDetailPage extends StatefulWidget {
  final int? bookId;

  const BookDetailPage({super.key, this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late Future<Book?> _bookFuture;

  @override
  void initState() {
    super.initState();
    _bookFuture = _loadBook();
  }

  @override
  void didUpdateWidget(covariant BookDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      _bookFuture = _loadBook();
    }
  }

  Future<Book?> _loadBook() {
    final id = widget.bookId;
    return id == null
        ? Future<Book?>.value(null)
        : context.read<BookRepository>().getBookById(id);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _toggleWishlist(Book book) async {
    final wishlist = context.read<WishlistProvider>();
    await wishlist.toggle(book.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wishlist.contains(book.id)
                ? 'Added to wishlist'
                : 'Removed from wishlist',
          ),
        ),
      );
  }

  void _addToCart(Book book) {
    final cart = context.read<CartProvider>();
    if (cart.contains(book.id)) {
      final currentQty = cart.quantityOf(book.id);
      final newQty = (currentQty + 1).clamp(1, book.stock);
      cart.setQuantity(book.id, newQty);
    } else {
      cart.add(book.id);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Ditambahkan ke keranjang'),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Book?>(
          future: _bookFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                title: 'Gagal memuat buku',
                message: 'Silakan coba lagi.',
                onBack: _goBack,
              );
            }
            final book = snapshot.data;
            if (book == null) {
              return _MessageState(
                title: 'Buku tidak ditemukan',
                message: 'Buku yang kamu cari tidak tersedia.',
                onBack: _goBack,
              );
            }
            return _BookDetailContent(
              book: book,
              isWishlisted: wishlist.contains(book.id),
              onToggleWishlist: () => _toggleWishlist(book),
              onAddToCart: () => _addToCart(book),
              onBack: _goBack,
            );
          },
        ),
      ),
    );
  }
}

class _BookDetailContent extends StatelessWidget {
  final Book book;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onAddToCart;
  final VoidCallback onBack;

  const _BookDetailContent({
    required this.book,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onAddToCart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: BookCover(image: book.image)),
                  const SizedBox(height: 20),
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.author,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dark.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(book: book),
                  const SizedBox(height: 16),
                  _PriceRow(book: book),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _WishlistButton(
                        active: isWishlisted,
                        onPressed: onToggleWishlist,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _AddToCartButton(onPressed: onAddToCart)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.grey),
                  const SizedBox(height: 16),
                  const _SectionTitle('Deskripsi'),
                  const SizedBox(height: 10),
                  Text(
                    book.description,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.grey),
                  const SizedBox(height: 16),
                  const _SectionTitle('Ulasan Pelanggan'),
                  const SizedBox(height: 12),
                  if (book.reviews.isEmpty)
                    const Text(
                      'Belum ada review.',
                      style: TextStyle(fontSize: 13, color: AppColors.dark),
                    )
                  else
                    SizedBox(
                      height: 168,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: book.reviews.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, index) =>
                            ReviewCard(review: book.reviews[index]),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.grey),
                ],
              ),
            ),
          ),
        ),
        Positioned(top: 8, left: 16, child: AppBackButton(onPressed: onBack)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Book book;

  const _InfoRow({required this.book});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 12, color: AppColors.dark);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        RatingLabel(
          rating: book.rating,
          iconSize: 16,
          fontSize: 12,
          color: AppColors.dark,
        ),
        Text(book.category, style: textStyle),
        if (book.ageRating != null) Text(book.ageRating!, style: textStyle),
        if (book.publishedYear != null)
          Text('${book.publishedYear}', style: textStyle),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Book book;

  const _PriceRow({required this.book});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        Text(
          formatRupiah(book.price),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        if (book.oldPrice != null)
          Text(
            formatRupiah(book.oldPrice!),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

class _WishlistButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const _WishlistButton({required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.lightBlue),
          shape: AppRadius.shape,
        ),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddToCartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.background,
        minimumSize: const Size.fromHeight(52),
        shape: AppRadius.shape,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      child: const Text('Tambah ke keranjang'),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBack;

  const _MessageState({
    required this.title,
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book,
                  size: 56,
                  color: AppColors.lightBlue,
                ),
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
                const SizedBox(height: 16),
                TextButton(onPressed: onBack, child: const Text('Kembali')),
              ],
            ),
          ),
        ),
        Positioned(top: 8, left: 16, child: AppBackButton(onPressed: onBack)),
      ],
    );
  }
}

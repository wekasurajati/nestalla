import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/currency.dart';
import '../../models/book.dart';
import '../../providers/cart_provider.dart';
import '../../repositories/book_repository.dart';
import '../../widgets/back_button.dart';
import '../../widgets/book_list_tile.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = context.read<BookRepository>().getBooks();
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
              return _MessageState(
                title: 'Gagal memuat keranjang',
                message: 'Silakan coba lagi.',
                onBack: () => context.go('/home'),
              );
            }

            final allBooks = snapshot.data ?? const <Book>[];
            final cart = context.watch<CartProvider>();

            if (cart.items.isEmpty) {
              return Column(
                children: [
                  _Header(onBack: () => context.pop()),
                  const Expanded(child: _EmptyCartView()),
                ],
              );
            }

            return Column(
              children: [
                _Header(onBack: () => context.pop()),
                _ControlBar(
                  cart: cart,
                  onRemoveSelected: () => _confirmRemoveSelected(cart),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _ItemList(books: allBooks, cart: cart),
                ),
                _BottomBar(books: allBooks, cart: cart),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmRemoveSelected(CartProvider cart) async {
    if (cart.selectedCount == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus item?'),
        content: Text(
          '${cart.selectedCount} item akan dihapus dari keranjang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await cart.removeSelected();
    }
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              AppBackButton(onPressed: onBack),
              const SizedBox(width: 12),
              const Text(
                'Keranjang',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.grey),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onRemoveSelected;

  const _ControlBar({required this.cart, required this.onRemoveSelected});

  @override
  Widget build(BuildContext context) {
    final allSelected =
        cart.items.isNotEmpty && cart.selectedCount == cart.items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (_) => cart.toggleAll(!allSelected),
          ),
          const Text(
            'Semua',
            style: TextStyle(fontSize: 14, color: AppColors.dark),
          ),
          const Spacer(),
          InkWell(
            borderRadius: AppRadius.border,
            onTap: onRemoveSelected,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.navy),
                  SizedBox(width: 4),
                  Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<Book> books;
  final CartProvider cart;

  const _ItemList({required this.books, required this.cart});

  @override
  Widget build(BuildContext context) {
    final byId = <int, Book>{for (final b in books) b.id: b};
    final ids = cart.items.keys.where(byId.containsKey).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final book = byId[ids[index]]!;
        return _CartItem(book: book, cart: cart);
      },
    );
  }
}

class _CartItem extends StatelessWidget {
  final Book book;
  final CartProvider cart;

  const _CartItem({required this.book, required this.cart});

  int _discountPercent() {
    final old = book.oldPrice;
    if (old == null || old <= 0) return 0;
    return ((old - book.price) / old * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final discount = _discountPercent();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: cart.isSelected(book.id),
              onChanged: (_) => cart.toggleSelected(book.id),
            ),
            Expanded(
              child: BookListTile(
                book: book,
                discountPercent: discount > 0 ? discount : null,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: AppColors.navy),
                onPressed: () => cart.remove(book.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              _Stepper(bookId: book.id, cart: cart, stock: book.stock),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.grey),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int bookId;
  final CartProvider cart;
  final int stock;

  const _Stepper({
    required this.bookId,
    required this.cart,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final qty = cart.quantityOf(bookId);
    final canDecrement = qty > 1;
    final canIncrement = qty < stock;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onPressed: canDecrement
              ? () => cart.setQuantity(bookId, qty - 1)
              : null,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          alignment: Alignment.center,
          child: Text(
            '$qty',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onPressed: canIncrement
              ? () => cart.setQuantity(bookId, qty + 1)
              : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;

  const _StepButton({this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.background
            : AppColors.grey.withValues(alpha: 0.35),
        border: Border.all(color: AppColors.grey),
        borderRadius: AppRadius.border,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.navy
              : AppColors.dark.withValues(alpha: 0.3),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<Book> books;
  final CartProvider cart;

  const _BottomBar({required this.books, required this.cart});

  @override
  Widget build(BuildContext context) {
    final total = cart.selectedTotal(books);
    final hasSelected = cart.selectedCount > 0;

    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, color: AppColors.grey),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        formatRupiah(total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.40,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: hasSelected
                          ? () => context.push('/checkout')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        shape: AppRadius.shape,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: screenWidth * 0.5,
              height: 140,
              child: Image.asset(
                'assets/images/nochart.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keranjang kamu masih kosong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  shape: AppRadius.shape,
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Jelajahi buku'),
              ),
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, size: 56, color: AppColors.lightBlue),
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
            AppBackButton(onPressed: onBack),
          ],
        ),
      ),
    );
  }
}

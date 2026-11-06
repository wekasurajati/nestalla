import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import '../../widgets/book_cover.dart';
import '../orders/order.dart';
import '../orders/order_repository.dart';
import 'review.dart';
import 'review_repository.dart';

class ReviewPage extends StatefulWidget {
  final int? orderId;

  const ReviewPage({super.key, required this.orderId});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  static const _minChars = 10;
  static const _maxChars = 2000;

  final _controller = TextEditingController();
  late final Future<(Order, Book)?> _targetFuture;
  late final ReviewRepository _reviewRepository;

  int _rating = 0;
  bool _anonymous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final orderRepository = context.read<OrderRepository>();
    final bookRepository = context.read<BookRepository>();
    _reviewRepository = context.read<ReviewRepository>();
    _targetFuture = () async {
      final id = widget.orderId;
      if (id == null) return null;
      final order = await orderRepository.getOrderById(id);
      if (order == null || order.status != OrderStatus.completed) return null;
      final books = await bookRepository.getBooks();
      for (final book in books) {
        if (book.id == order.bookId) return (order, book);
      }
      return null;
    }();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _rating > 0 && _controller.text.trim().length >= _minChars && !_submitting;

  Future<void> _submit(Order order, Book book) async {
    setState(() => _submitting = true);
    try {
      await _reviewRepository.submitReview(
        Review(
          orderId: order.id,
          bookId: book.id,
          rating: _rating,
          comment: _controller.text.trim(),
          anonymous: _anonymous,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ulasan berhasil dikirim')));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/orders');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim ulasan. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Order, Book)?>(
      future: _targetFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final target = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Ulasan Produk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : target == null
              ? const Center(child: Text('Pesanan tidak dapat diulas.'))
              : _buildForm(target.$1, target.$2),
          bottomNavigationBar: target == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: ElevatedButton(
                      onPressed: _canSubmit
                          ? () => _submit(target.$1, target.$2)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.background,
                        disabledBackgroundColor: AppColors.grey,
                        disabledForegroundColor: AppColors.backCircle,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : const Text(
                              'Kirim',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildForm(Order order, Book book) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.border,
            border: Border.all(color: AppColors.grey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(
                    image: book.image,
                    width: 56,
                    height: 84,
                    showShadow: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.author,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.backCircle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StarRating(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 20),
              const Text(
                'Apa pendapatmu tentang produk ini?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 7,
                maxLines: 7,
                maxLength: _maxChars,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Ceritakan pengalamanmu terkait produk. Minimal 10 karakter.',
                  hintStyle: const TextStyle(color: AppColors.backCircle),
                  filled: true,
                  fillColor: AppColors.background,
                  border: _border(AppColors.backCircle),
                  enabledBorder: _border(AppColors.backCircle),
                  focusedBorder: _border(AppColors.blue),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Samarkan foto dan nama saya',
                      style: TextStyle(fontSize: 14, color: AppColors.dark),
                    ),
                  ),
                  Switch(
                    value: _anonymous,
                    activeTrackColor: AppColors.blue,
                    onChanged: (value) => setState(() => _anonymous = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: AppRadius.border,
    borderSide: BorderSide(color: color),
  );
}

class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarRating({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(i),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            icon: Icon(
              Icons.star_rounded,
              size: 44,
              color: i <= rating ? AppColors.star : AppColors.grey,
            ),
          ),
      ],
    );
  }
}
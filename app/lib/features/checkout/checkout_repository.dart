import '../../repositories/book_repository.dart';
import 'checkout_models.dart';

abstract class CheckoutRepository {
  /// Item yang akan dibeli + ongkos kirim.
  Future<CheckoutData> getCheckoutData();

  /// Membuat order baru.
  Future<void> placeOrder(ShippingInfo info, List<CheckoutItem> items);
}

/// Data dummy. Nanti diganti ApiCheckoutRepository yang memanggil REST API.
/// Item checkout nantinya berasal dari Cart (halaman milik teman satu tim).
class DummyCheckoutRepository implements CheckoutRepository {
  final BookRepository _bookRepository;

  DummyCheckoutRepository(this._bookRepository);

  @override
  Future<CheckoutData> getCheckoutData() async {
    final book = await _bookRepository.getBookById(1);
    return CheckoutData(
      items: [if (book != null) CheckoutItem(book: book, quantity: 1)],
      shippingCost: 4680,
    );
  }

  @override
  Future<void> placeOrder(ShippingInfo info, List<CheckoutItem> items) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}
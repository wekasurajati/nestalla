import '../models/book.dart';

abstract class BookRepository {
  Future<List<Book>> getBooks();
  Future<Book?> getBookById(int id);
}

/// Data dummy. Nanti diganti ApiBookRepository yang memanggil REST API.
class DummyBookRepository implements BookRepository {
  static const _books = [
    Book(
      id: 1,
      title: 'Atomic Habits',
      author: 'James Clear',
      description: 'Panduan membangun kebiasaan baik dan meninggalkan yang buruk.',
      price: 108000,
      category: 'Self-improvement',
      isFeatured: true,
      rating: 4.8,
    ),
    Book(
      id: 2,
      title: 'Let Them',
      author: 'Mel Robbins',
      description: 'Buku tentang melepaskan kendali atas hal di luar diri kita.',
      price: 95000,
      category: 'Self-improvement',
      isFeatured: true,
    ),
    Book(
      id: 3,
      title: 'Laut Bercerita',
      author: 'Leila S. Chudori',
      description: 'Novel tentang aktivis dan masa kelam Indonesia.',
      price: 120000,
      oldPrice: 140000,
      category: 'Fiction',
      isDiscount: true,
    ),
  ];

  @override
  Future<List<Book>> getBooks() async => _books;

  @override
  Future<Book?> getBookById(int id) async {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }
}
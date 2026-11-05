import '../models/book.dart';
import '../models/book_review.dart';

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
      publisher: 'Gramedia Pustaka Utama',
      description:
          'Panduan membangun kebiasaan baik dan meninggalkan yang buruk. '
          'James Clear menjelaskan bagaimana perubahan kecil yang konsisten '
          'dapat menghasilkan hasil luar biasa dalam jangka panjang.',
      price: 108000,
      oldPrice: 125000,
      image: 'assets/images/books/book_1.jpg',
      category: 'Self-improvement',
      isFeatured: true,
      isDiscount: true,
      rating: 4.8,
      publishedYear: 2018,
      ageRating: '13+',
      reviews: [
        BookReview(
          name: 'Rina',
          comment:
              'Buku yang sangat praktis. Setiap bab memberi langkah konkret '
              'yang mudah diterapkan.',
          rating: 5,
        ),
        BookReview(
          name: 'Dimas',
          comment:
              'Banyak insight baru soal kebiasaan. Cocok untuk dibaca ulang.',
          rating: 4,
        ),
        BookReview(
          name: 'Sarah',
          comment: 'Bahasa sederhana dan contohnya relate dengan kehidupan sehari-hari.',
          rating: 5,
        ),
      ],
    ),
    Book(
      id: 2,
      title: 'Let Them',
      author: 'Mel Robbins',
      publisher: 'Gramedia Pustaka Utama',
      description:
          'Buku tentang melepaskan kendali atas hal di luar diri kita. '
          'Mel Robbins membahas cara berhenti mengambil beban emosional '
          'orang lain dan mulai fokus pada hal yang bisa kita kendalikan.',
      price: 95000,
      oldPrice: 110000,
      image: 'assets/images/books/book_2.jpg',
      category: 'Self-improvement',
      isFeatured: true,
      isDiscount: true,
      rating: 4.6,
      publishedYear: 2024,
      ageRating: '13+',
      reviews: [
        BookReview(
          name: 'Aditya',
          comment:
              'Ringan dibaca tapi pesannya dalam. Banyak bagian yang bikin '
              'berhenti dan merenung.',
          rating: 5,
        ),
        BookReview(
          name: 'Nadia',
          comment: 'Cocok untuk siapa pun yang sering overthinking soal pendapat orang.',
          rating: 4,
        ),
      ],
    ),
    Book(
      id: 3,
      title: 'Laut Bercerita',
      author: 'Leila S. Chudori',
      publisher: 'Kepustakaan Populer Gramedia',
      description:
          'Novel tentang aktivis dan masa kelam Indonesia. Kisah ini '
          'mengikuti perjalanan sekelompok mahasiswa yang hilang pada '
          '1998 dan keluarga yang terus mencari jawaban.',
      price: 120000,
      oldPrice: 140000,
      image: 'assets/images/books/book_3.jpg',
      category: 'Fiction',
      isFeatured: true,
      isDiscount: true,
      rating: 4.7,
      publishedYear: 2017,
      ageRating: '17+',
      reviews: [
        BookReview(
          name: 'Bagas',
          comment:
              'Novel yang emosional dan penting. Penulisannya membuat '
              'sejarah terasa dekat.',
          rating: 5,
        ),
        BookReview(
          name: 'Maya',
          comment: 'Sulit berhenti membaca. Karakternya kuat dan menyentuh.',
          rating: 5,
        ),
        BookReview(
          name: 'Fajar',
          comment: 'Tema berat tapi disampaikan dengan sangat manusiawi.',
          rating: 4,
        ),
      ],
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

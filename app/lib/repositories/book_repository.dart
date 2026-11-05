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
    Book(
      id: 4,
      title: 'Bumi Manusia',
      author: 'Pramoedya Ananta Toer',
      publisher: 'Lentera Dipantara',
      description:
          'Kisah Minke di awal abad ke-20 yang berjuang di tengah kolonialisme. '
          'Novel pertama dari Tetralogi Buru ini menyoroti pendidikan, cinta, '
          'dan ketidakadilan sosial.',
      price: 135000,
      image: 'assets/images/books/book_3.jpg',
      category: 'Fiction',
      isFeatured: true,
      rating: 4.9,
      publishedYear: 1980,
      ageRating: '17+',
    ),
    Book(
      id: 5,
      title: 'Filosofi Teras',
      author: 'Henry Manampiring',
      publisher: 'Kompas',
      description:
          'Pengantar filsafat Stoa untuk kehidupan modern. Buku ini membantu '
          'pembaca mengelola emosi dan fokus pada hal yang bisa dikendalikan.',
      price: 98000,
      oldPrice: 115000,
      image: 'assets/images/books/book_1.jpg',
      category: 'Self-improvement',
      isDiscount: true,
      rating: 4.8,
      publishedYear: 2018,
    ),
    Book(
      id: 6,
      title: 'The Psychology of Money',
      author: 'Morgan Housel',
      publisher: 'Baca',
      description:
          'Bagaimana perilaku dan kebiasaan memengaruhi keputusan finansial. '
          'Buku ini menekankan bahwa uang lebih soal psikologi daripada rumus.',
      price: 105000,
      oldPrice: 130000,
      image: 'assets/images/books/book_2.jpg',
      category: 'Business',
      isFeatured: true,
      isDiscount: true,
      rating: 4.8,
      publishedYear: 2020,
    ),
    Book(
      id: 7,
      title: 'Sapiens',
      author: 'Yuval Noah Harari',
      publisher: 'Kepustakaan Populer Gramedia',
      description:
          'Sejarah singkat umat manusia, dari revolusi kognitif hingga '
          'revolusi sains. Buku ini menjelaskan bagaimana Homo sapiens '
          'mendominasi bumi.',
      price: 150000,
      image: 'assets/images/books/book_3.jpg',
      category: 'History',
      isFeatured: true,
      rating: 4.7,
      publishedYear: 2011,
    ),
    Book(
      id: 8,
      title: 'Clean Code',
      author: 'Robert C. Martin',
      publisher: 'Prentice Hall',
      description:
          'Panduan menulis kode yang mudah dibaca dan dirawat. Berisi prinsip, '
          'contoh, dan studi kasus untuk menghasilkan perangkat lunak berkualitas.',
      price: 180000,
      image: 'assets/images/books/book_1.jpg',
      category: 'Technology',
      rating: 4.6,
      publishedYear: 2008,
    ),
    Book(
      id: 9,
      title: 'Dune',
      author: 'Frank Herbert',
      publisher: 'Ace Books',
      description:
          'Epik fiksi ilmiah tentang planet gurun Arrakis. Perjuangan Paul '
          'Atreides menyentuh tema kekuasaan, ekologi, dan takdir.',
      price: 145000,
      oldPrice: 165000,
      image: 'assets/images/books/book_3.jpg',
      category: 'Fiction',
      isDiscount: true,
      rating: 4.8,
      publishedYear: 1965,
    ),
    Book(
      id: 10,
      title: 'The Midnight Library',
      author: 'Matt Haig',
      publisher: 'Gramedia Pustaka Utama',
      description:
          'Perpustakaan di antara hidup dan mati menyimpan buku-buku tentang '
          'kemungkinan hidup yang tidak pernah dijalani. Kisah tentang penyesalan '
          'dan harapan.',
      price: 115000,
      image: 'assets/images/books/book_2.jpg',
      category: 'Fiction',
      isFeatured: true,
      rating: 4.6,
      publishedYear: 2020,
    ),
    Book(
      id: 11,
      title: 'Manajemen Keuangan Pribadi',
      author: 'Prita Hapsari',
      publisher: 'Elex Media Komputindo',
      description:
          'Panduan praktis mengatur pemasukan, tabungan, dan investasi untuk '
          'pemula. Dilengkapi contoh anggaran dan perencanaan tujuan keuangan.',
      price: 88000,
      oldPrice: 99000,
      image: 'assets/images/books/book_1.jpg',
      category: 'Business',
      isDiscount: true,
      rating: 4.5,
      publishedYear: 2024,
    ),
    Book(
      id: 12,
      title: 'Algoritma dan Struktur Data',
      author: 'Rinaldi Munir',
      publisher: 'Informatika',
      description:
          'Buku pegangan mahasiswa informatika tentang algoritma, struktur data, '
          'dan analisis kompleksitas dengan contoh implementasi.',
      price: 125000,
      image: 'assets/images/books/book_1.jpg',
      category: 'Technology',
      rating: 4.4,
      publishedYear: 2023,
    ),
    Book(
      id: 13,
      title: 'Rindu',
      author: 'Tere Liye',
      publisher: 'Republika',
      description:
          'Kisah perjalanan panjang seorang perempuan mencari makna cinta dan '
          'kehilangan dalam pelayaran penuh kenangan.',
      price: 92000,
      image: 'assets/images/books/book_3.jpg',
      category: 'Romance',
      rating: 4.5,
      publishedYear: 2014,
    ),
    Book(
      id: 14,
      title: 'Petualangan ke Negeri Awan',
      author: 'Dwi Lestari',
      publisher: 'Erlangga for Kids',
      description:
          'Cerita anak tentang persahabatan dan keberanian saat menjelajahi '
          'negeri di atas awan. Cocok untuk pembaca awal.',
      price: 75000,
      image: 'assets/images/books/book_2.jpg',
      category: 'Children',
      rating: 4.6,
      publishedYear: 2022,
      ageRating: '7+',
    ),
    Book(
      id: 15,
      title: 'Sejarah Indonesia Modern',
      author: 'M.C. Ricklefs',
      publisher: 'Serambi',
      description:
          'Rekonstruksi sejarah Indonesia dari abad ke-13 hingga era reformasi, '
          'membahas politik, ekonomi, dan perubahan sosial.',
      price: 165000,
      image: 'assets/images/books/book_3.jpg',
      category: 'History',
      rating: 4.6,
      publishedYear: 2008,
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

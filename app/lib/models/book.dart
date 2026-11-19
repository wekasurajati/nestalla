import 'book_review.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final String publisher;
  final String description;
  final int price;
  final int? oldPrice;
  final String image;
  final String category;
  final int stock;
  final double rating;
  final bool isFeatured;
  final bool isDiscount;
  final int? publishedYear;
  final String? ageRating;
  final List<BookReview> reviews;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher = '',
    required this.description,
    required this.price,
    this.oldPrice,
    this.image = '',
    required this.category,
    this.stock = 10,
    this.rating = 4.5,
    this.isFeatured = false,
    this.isDiscount = false,
    this.publishedYear,
    this.ageRating,
    this.reviews = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: int.tryParse((json['book_id'] ?? json['id'] ?? '0').toString()) ?? 0,
        title: json['title'] as String,
        author: json['author'] as String,
        publisher: json['publisher'] as String? ?? '',
        description: json['description'] as String,
        price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
        oldPrice: json['old_price'] != null
            ? int.tryParse(json['old_price']?.toString() ?? '')
            : null,
        image: json['image'] as String? ?? '',
        category: json['category'] as String,
        stock: int.tryParse(json['stock']?.toString() ?? '10') ?? 10,
        rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
        isFeatured: int.tryParse(json['is_featured']?.toString() ?? '') == 1,
        isDiscount: int.tryParse(json['is_discount']?.toString() ?? '') == 1,
        publishedYear: int.tryParse(json['published_year']?.toString() ?? ''),
        ageRating: json['age_rating'] as String?,
        reviews: (json['reviews'] as List<dynamic>?)
            ?.map((e) => BookReview.fromJson(e as Map<String, dynamic>))
            .toList() ?? const [],
      );
}

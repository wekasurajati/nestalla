class Book {
  final int id;
  final String title;
  final String author;
  final String description;
  final int price;
  final int? oldPrice;
  final String image;
  final String category;
  final int stock;
  final double rating;
  final bool isFeatured;
  final bool isDiscount;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.price,
    this.oldPrice,
    this.image = '',
    required this.category,
    this.stock = 10,
    this.rating = 4.5,
    this.isFeatured = false,
    this.isDiscount = false,
  });
}
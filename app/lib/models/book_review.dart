class BookReview {
  final String name;
  final String comment;
  final double rating;
  final String avatarUrl;

  const BookReview({
    required this.name,
    required this.comment,
    this.rating = 5,
    this.avatarUrl = '',
  });
}

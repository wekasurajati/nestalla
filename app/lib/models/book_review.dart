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

  factory BookReview.fromJson(Map<String, dynamic> json) => BookReview(
        name: json['name'] as String,
        comment: json['comment'] as String,
        rating: (json['rating'] as num?)?.toDouble() ?? 5,
        avatarUrl: json['avatar_url'] as String? ?? '',
      );
}

class Review {
  final int orderId;
  final int bookId;
  final int rating; // 1-5
  final String comment;
  final bool anonymous;

  const Review({
    required this.orderId,
    required this.bookId,
    required this.rating,
    required this.comment,
    required this.anonymous,
  });
}
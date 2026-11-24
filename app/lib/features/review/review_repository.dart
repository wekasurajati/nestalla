import 'review.dart';

abstract class ReviewRepository {
  Future<void> submitReview(Review review);
}
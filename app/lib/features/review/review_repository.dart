import 'review.dart';

abstract class ReviewRepository {
  Future<void> submitReview(Review review);
}

/// Data dummy. Nanti diganti ApiReviewRepository yang memanggil REST API.
class DummyReviewRepository implements ReviewRepository {
  const DummyReviewRepository();

  @override
  Future<void> submitReview(Review review) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}
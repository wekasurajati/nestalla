import '../../providers/auth_provider.dart';
import '../../repositories/api_client.dart';
import 'review.dart';
import 'review_repository.dart';

/// Ulasan ke backend (backend/api/reviews.php). Wajib login (token).
class ApiReviewRepository implements ReviewRepository {
  final AuthProvider _auth;

  ApiReviewRepository(this._auth);

  @override
  Future<void> submitReview(Review review) async {
    final token = _auth.token;
    if (token == null) {
      throw const ApiException('Silakan login terlebih dahulu', 401);
    }
    await apiRequest(
      'POST',
      'reviews.php',
      token: token,
      body: {
        'order_id': review.orderId,
        'book_id': review.bookId,
        'rating': review.rating,
        'message': review.comment,
      },
    );
  }
}

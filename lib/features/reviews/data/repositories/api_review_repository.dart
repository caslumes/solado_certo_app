import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/reviews/data/models/review_model.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/domain/repositories/review_repository.dart';

class ApiReviewRepository implements ReviewRepositoryInterface {
  static const pageSize = 5;

  final ClientInterface client;

  ApiReviewRepository(this.client);

  @override
  Future<CreatedReview> createReview(
    String orderId,
    String itemId,
    NewReview review,
  ) async {
    final response = await client.post(
      '/orders/$orderId/items/$itemId/review',
      data: newReviewToJson(review),
    );
    return createdReviewFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ReviewsPageEntity> getProductReviews(
    String advertisementId,
    int page,
  ) async {
    final response = await client.get(
      '/catalog/items/$advertisementId/reviews?page=$page&limit=$pageSize',
    );
    return reviewsPageFromJson(response as Map<String, dynamic>);
  }
}

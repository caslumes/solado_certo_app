import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';

abstract class ReviewRepositoryInterface {
  Future<CreatedReview> createReview(
    String orderId,
    String itemId,
    NewReview review,
  );

  Future<ReviewsPageEntity> getProductReviews(String advertisementId, int page);
}

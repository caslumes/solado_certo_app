import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';

abstract class ReviewRepositoryInterface {
  /// Reviews one item of a delivered order; each item once.
  Future<CreatedReview> createReview(
    String orderId,
    String itemId,
    NewReview review,
  );

  /// A product's reviews, newest first; [page] starts at 1.
  Future<ReviewsPageEntity> getProductReviews(String advertisementId, int page);
}

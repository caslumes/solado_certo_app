import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/domain/repositories/review_repository.dart';

class CreateReviewUseCase {
  final ReviewRepositoryInterface reviewRepository;

  CreateReviewUseCase(this.reviewRepository);

  Future<CreatedReview> execute(
    String orderId,
    String itemId,
    NewReview review,
  ) => reviewRepository.createReview(orderId, itemId, review);
}

class GetProductReviewsUseCase {
  final ReviewRepositoryInterface reviewRepository;

  GetProductReviewsUseCase(this.reviewRepository);

  Future<ReviewsPageEntity> execute(String advertisementId, int page) =>
      reviewRepository.getProductReviews(advertisementId, page);
}

import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';

ReviewEntity reviewFromJson(Map<String, dynamic> json) => ReviewEntity(
  productRating: json['product_rating'] as int,
  sellerRating: json['seller_rating'] as int,
  comfortRating: json['comfort_rating'] as int?,
  comment: json['comment'] as String?,
  adaptationFeedback: json['adaptation_feedback'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

CreatedReview createdReviewFromJson(Map<String, dynamic> json) => (
  review: reviewFromJson(json),
  suggestSupport: json['suggest_support'] as bool? ?? false,
);

PublicReviewEntity publicReviewFromJson(Map<String, dynamic> json) =>
    PublicReviewEntity(
      id: json['id'] as String,
      reviewerName: json['reviewer_name'] as String,
      productRating: json['product_rating'] as int,
      comfortRating: json['comfort_rating'] as int?,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

ReviewsPageEntity reviewsPageFromJson(Map<String, dynamic> json) =>
    ReviewsPageEntity(
      items: [
        for (final review in json['items'] as List? ?? const [])
          publicReviewFromJson(review),
      ],
      currentPage: json['current_page'] as int,
      totalItems: json['total_items'] as int,
      hasNext: json['has_next'] as bool,
    );

/// Empty texts are left out.
Map<String, dynamic> newReviewToJson(NewReview review) => {
  'product_rating': review.productRating,
  'seller_rating': review.sellerRating,
  if (review.comfortRating case final comfort?) 'comfort_rating': comfort,
  if (_text(review.comment) case final comment?) 'comment': comment,
  if (_text(review.adaptationFeedback) case final feedback?)
    'adaptation_feedback': feedback,
};

String? _text(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

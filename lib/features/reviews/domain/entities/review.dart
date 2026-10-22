/// The buyer's review of one order item (RF-024, RF-040), as the buyer and
/// the seller see it.
class ReviewEntity {
  final int productRating;
  final int sellerRating;

  /// 1 (very uncomfortable) to 5 (very comfortable).
  final int? comfortRating;
  final String? comment;

  /// How the first days of use went; never shown on the product page.
  final String? adaptationFeedback;
  final DateTime createdAt;

  const ReviewEntity({
    required this.productRating,
    required this.sellerRating,
    this.comfortRating,
    this.comment,
    this.adaptationFeedback,
    required this.createdAt,
  });
}

/// A review on the product page: the reviewer's first name and no
/// adaptation feedback.
class PublicReviewEntity {
  final String id;
  final String reviewerName;
  final int productRating;
  final int? comfortRating;
  final String? comment;
  final DateTime createdAt;

  const PublicReviewEntity({
    required this.id,
    required this.reviewerName,
    required this.productRating,
    this.comfortRating,
    this.comment,
    required this.createdAt,
  });
}

/// One page of a product's reviews, newest first.
class ReviewsPageEntity {
  final List<PublicReviewEntity> items;
  final int currentPage;
  final int totalItems;
  final bool hasNext;

  const ReviewsPageEntity({
    required this.items,
    required this.currentPage,
    required this.totalItems,
    required this.hasNext,
  });
}

class NewReview {
  final int productRating;
  final int sellerRating;
  final int? comfortRating;
  final String? comment;
  final String? adaptationFeedback;

  const NewReview({
    required this.productRating,
    required this.sellerRating,
    this.comfortRating,
    this.comment,
    this.adaptationFeedback,
  });
}

/// A review just sent. [suggestSupport] is set when the comfort was low
/// (UC-010).
typedef CreatedReview = ({ReviewEntity review, bool suggestSupport});

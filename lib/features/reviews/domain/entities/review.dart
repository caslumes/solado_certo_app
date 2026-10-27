class ReviewEntity {
  final int productRating;
  final int sellerRating;

  final int? comfortRating;
  final String? comment;

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

typedef CreatedReview = ({ReviewEntity review, bool suggestSupport});

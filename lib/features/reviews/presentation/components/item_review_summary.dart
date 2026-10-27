import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/comfort_labels.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/rating_stars.dart';

class ItemReviewSummary extends StatelessWidget {
  const ItemReviewSummary({super.key, required this.review, this.title});

  final ReviewEntity review;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2.0,
        children: [
          if (title case final title?) Text(title, style: textTheme.bodySmall),
          Row(
            spacing: 8.0,
            children: [
              Text('Produto', style: textTheme.bodySmall),
              RatingStars(rating: review.productRating, size: 14),
            ],
          ),
          Row(
            spacing: 8.0,
            children: [
              Text('Vendedor', style: textTheme.bodySmall),
              RatingStars(rating: review.sellerRating, size: 14),
            ],
          ),
          if (comfortLabels[review.comfortRating] case final comfort?)
            Text('Conforto: $comfort', style: textTheme.bodySmall),
          if (review.adaptationFeedback case final feedback?)
            Text('Adaptação: $feedback', style: textTheme.bodySmall),
          if (review.comment case final comment?)
            Text('"$comment"', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

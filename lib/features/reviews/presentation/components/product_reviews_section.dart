import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/presentation/bloc/product_reviews_cubit.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/comfort_labels.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/rating_stars.dart';

/// The product's reviews (RF-024), newest first, from the
/// [ProductReviewsCubit] above.
class ProductReviewsSection extends StatelessWidget {
  const ProductReviewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<ProductReviewsCubit, ProductReviewsState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8.0,
        children: [
          Text(
            state.total == 0 ? 'Avaliações' : 'Avaliações (${state.total})',
            style: textTheme.bodyMedium,
          ),
          ...switch (state.status) {
            ProductReviewsStatus.loading => [
              const Center(child: CircularProgressIndicator()),
            ],
            ProductReviewsStatus.failure => [
              Text(
                'Não foi possível carregar as avaliações.',
                style: textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: context.read<ProductReviewsCubit>().load,
                  child: const Text('Tentar novamente'),
                ),
              ),
            ],
            ProductReviewsStatus.loaded when state.reviews.isEmpty => [
              Text(
                'Ainda não há avaliações deste produto.',
                style: textTheme.bodyLarge,
              ),
            ],
            ProductReviewsStatus.loaded => [
              for (final review in state.reviews)
                _ReviewTile(key: ValueKey(review.id), review: review),
              if (state.loadingMore)
                const Center(child: CircularProgressIndicator())
              else if (state.hasNext)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: context.read<ProductReviewsCubit>().loadMore,
                    child: const Text('Ver mais avaliações'),
                  ),
                ),
            ],
          },
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({super.key, required this.review});

  final PublicReviewEntity review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2.0,
        children: [
          Row(
            spacing: 8.0,
            children: [
              RatingStars(rating: review.productRating),
              Expanded(
                child: Text(
                  '${review.reviewerName} · ${formatDate(review.createdAt)}',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (comfortLabels[review.comfortRating] case final comfort?)
            Text('Conforto: $comfort', style: textTheme.bodySmall),
          if (review.comment case final comment?)
            Text(comment, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

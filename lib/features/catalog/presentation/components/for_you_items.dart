import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/recommendations_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_card.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/product_detail_page.dart';

class ForYouItems extends StatelessWidget {
  const ForYouItems({super.key});

  static const _cardWidth = 160.0;
  static const _cardHeight = 270.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendationsCubit, RecommendationsState>(
      builder: (context, state) {
        if (state is! RecommendationsLoaded) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Para você',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.black),
              ),
            ),
            SizedBox(
              height: _cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return SizedBox(
                    width: _cardWidth,
                    child: ProductCard(
                      item: item,
                      onTap: () => Navigator.of(
                        context,
                      ).push(ProductDetailPage.route(item.id)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

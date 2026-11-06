import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_card.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/product_detail_page.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.state});

  final CatalogState state;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 330,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ProductCard(
                item: item,
                onTap: () => Navigator.of(
                  context,
                ).push(ProductDetailPage.route(item.id)),
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: _Footer(state: state)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final CatalogState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == CatalogStatus.loadingNextPage) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.failure != null && state.hasNext) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: TextButton(
            onPressed: () =>
                context.read<CatalogBloc>().add(CatalogRetryRequested()),
            child: const Text('Tentar novamente'),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

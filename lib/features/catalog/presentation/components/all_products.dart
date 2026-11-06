import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_grid.dart';

class AllProducts extends StatelessWidget {
  const AllProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) => switch (state.status) {
        CatalogStatus.initial ||
        CatalogStatus.loading => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        CatalogStatus.failure => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 8.0,
              children: [
                Text(
                  state.failure?.message ?? 'Não foi possível carregar.',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () =>
                      context.read<CatalogBloc>().add(CatalogRetryRequested()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        CatalogStatus.empty => const SliverToBoxAdapter(
          child: SizedBox.shrink(),
        ),
        CatalogStatus.loaded ||
        CatalogStatus.refreshing ||
        CatalogStatus.loadingNextPage => SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Todos os produtos',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.black),
                ),
              ),
            ),
            ProductGrid(state: state),
          ],
        ),
      },
    );
  }
}

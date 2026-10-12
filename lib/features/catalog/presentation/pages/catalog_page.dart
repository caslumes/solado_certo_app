import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_items_use_case.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_options_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/catalog_filter_sheet.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_card.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/search_bar.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/product_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  /// Opens the list with [filters], sharing the caller's options cubit.
  static Route<void> route(
    BuildContext context, {
    CatalogFilters filters = const CatalogFilters(),
  }) {
    final optionsCubit = context.read<CatalogOptionsCubit>();
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: optionsCubit),
          BlocProvider(
            create: (_) => CatalogBloc(
              getCatalogItemsUseCase: getIt<GetCatalogItemsUseCase>(),
              filters: filters,
            )..add(CatalogStarted()),
          ),
        ],
        child: const CatalogPage(),
      ),
    );
  }

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  /// Distance from the end of the list at which the next page is requested.
  static const _loadMoreExtent = 600.0;

  late final _searchController = TextEditingController(
    text: context.read<CatalogBloc>().state.filters.query,
  );

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < _loadMoreExtent) {
      context.read<CatalogBloc>().add(CatalogNextPageRequested());
    }
  }

  /// A short first page can leave nothing to scroll, so no scroll event
  /// would ever ask for the next one.
  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) _onScroll();
    });
  }

  Future<void> _refresh() async {
    final bloc = context.read<CatalogBloc>()..add(CatalogRefreshRequested());
    await bloc.stream.firstWhere(
      (state) =>
          state.status != CatalogStatus.refreshing &&
          state.status != CatalogStatus.loading,
    );
  }

  /// Clears the search field and every filter.
  ///
  /// Also sends an empty [CatalogQueryChanged], so a search still waiting
  /// for the debounce can't bring the old text back.
  void _clearFilters() {
    _searchController.clear();
    context.read<CatalogBloc>()
      ..add(CatalogQueryChanged(''))
      ..add(CatalogFiltersCleared());
  }

  Future<void> _openFilters() async {
    final bloc = context.read<CatalogBloc>();
    final filters = await showCatalogFilterSheet(
      context,
      filters: bloc.state.filters,
    );
    if (filters != null) bloc.add(CatalogFiltersApplied(filters));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<CatalogBloc, CatalogState>(
          listenWhen: (previous, current) =>
              current.items.isNotEmpty &&
              (current.failure != previous.failure ||
                  current.page != previous.page),
          listener: (context, state) {
            final failure = state.failure;
            if (failure != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(failure.message)));
            } else {
              _fillViewport();
            }
          },
          builder: (context, state) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    const BackButton(color: AppColors.primaryColor),
                    Expanded(
                      child: ShoeSearchBar(
                        controller: _searchController,
                        onChanged: (query) => context.read<CatalogBloc>().add(
                          CatalogQueryChanged(query),
                        ),
                        onSubmitted: (query) => context.read<CatalogBloc>().add(
                          CatalogQueryChanged(query),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Toolbar(state: state, onOpenFilters: _openFilters),
              Container(color: AppColors.primaryColor, height: 5),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _Results(
                    state: state,
                    scrollController: _scrollController,
                    onClearFilters: _clearFilters,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.state, required this.onOpenFilters});

  final CatalogState state;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeFilters = state.filters.activeCount;
    final hasCount =
        state.status == CatalogStatus.loaded ||
        state.status == CatalogStatus.loadingNextPage ||
        state.status == CatalogStatus.refreshing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: hasCount
                ? Text(
                    state.totalItems == 1
                        ? '1 produto'
                        : '${state.totalItems} produtos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.tertiaryColor,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Flexible(
            flex: 2,
            child: PopupMenuButton<CatalogSort>(
              tooltip: 'Ordenar',
              initialValue: state.sort,
              onSelected: (sort) =>
                  context.read<CatalogBloc>().add(CatalogSortChanged(sort)),
              itemBuilder: (_) => [
                for (final sort in CatalogSort.values)
                  PopupMenuItem(value: sort, child: Text(sort.label)),
              ],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4.0,
                  children: [
                    const Icon(Icons.sort),
                    Flexible(
                      child: Text(
                        state.sort.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onOpenFilters,
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text('$activeFilters'),
              child: const Icon(Icons.tune),
            ),
            label: const Text('Filtros'),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.state,
    required this.scrollController,
    required this.onClearFilters,
  });

  final CatalogState state;
  final ScrollController scrollController;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      CatalogStatus.initial ||
      CatalogStatus.loading => const Center(child: CircularProgressIndicator()),
      CatalogStatus.failure => _Message(
        title: state.failure?.message ?? 'Não foi possível carregar.',
        actionText: 'Tentar novamente',
        onAction: () =>
            context.read<CatalogBloc>().add(CatalogRetryRequested()),
      ),
      CatalogStatus.empty => _Message(
        title: 'Nenhum produto encontrado',
        description: state.filters.isEmpty
            ? 'Ainda não há produtos no catálogo.'
            : 'Tente outra busca ou ajuste os filtros.',
        actionText: state.filters.isEmpty ? null : 'Limpar filtros',
        onAction: onClearFilters,
      ),
      CatalogStatus.loaded ||
      CatalogStatus.refreshing ||
      CatalogStatus.loadingNextPage => _Grid(
        state: state,
        scrollController: scrollController,
      ),
    };
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.state, required this.scrollController});

  final CatalogState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
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

/// A centered message with an optional action, shown in place of the grid
/// for the empty and error states.
///
/// It scrolls even when it fits on screen, so pull-to-refresh still works.
class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16.0,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  if (description != null)
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                  if (actionText != null)
                    ShoeTextButton(onPressed: onAction, text: actionText!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

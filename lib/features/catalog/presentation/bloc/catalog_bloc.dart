import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/bloc/debounce.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_items_use_case.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  static const searchDebounce = Duration(milliseconds: 400);

  final GetCatalogItemsUseCase _getCatalogItemsUseCase;

  int _generation = 0;

  CatalogBloc({
    required GetCatalogItemsUseCase getCatalogItemsUseCase,
    CatalogFilters filters = const CatalogFilters(),
  }) : _getCatalogItemsUseCase = getCatalogItemsUseCase,
       super(CatalogState(filters: filters)) {
    on<CatalogStarted>((event, emit) => _loadFirstPage(emit));
    on<CatalogQueryChanged>(
      _onQueryChanged,
      transformer: debounce(searchDebounce),
    );
    on<_CatalogSearchRequested>(
      (event, emit) => _loadFirstPage(emit, filters: event.filters),
    );
    on<CatalogFiltersApplied>(
      (event, emit) => _loadFirstPage(
        emit,
        filters: state.filters.withSheetFilters(event.filters),
      ),
    );
    on<CatalogFiltersCleared>(
      (event, emit) => _loadFirstPage(emit, filters: const CatalogFilters()),
    );
    on<CatalogSortChanged>(
      (event, emit) => _loadFirstPage(emit, sort: event.sort),
    );
    on<CatalogRefreshRequested>(_onRefresh);
    on<CatalogNextPageRequested>((event, emit) => _loadNextPage(emit));
    on<CatalogRetryRequested>(_onRetry);
  }

  void _onQueryChanged(CatalogQueryChanged event, Emitter<CatalogState> emit) {
    if (event.query.trim() == state.filters.query.trim()) return;
    add(_CatalogSearchRequested(state.filters.withQuery(event.query)));
  }

  Future<void> _loadFirstPage(
    Emitter<CatalogState> emit, {
    CatalogFilters? filters,
    CatalogSort? sort,
  }) async {
    final generation = ++_generation;
    final next = state.copyWith(
      status: CatalogStatus.loading,
      filters: filters,
      sort: sort,
      items: const [],
      page: 0,
      totalItems: 0,
      hasNext: false,
      failure: null,
    );
    emit(next);
    try {
      final page = await _getCatalogItemsUseCase.execute(
        filters: next.filters,
        sort: next.sort,
        page: 1,
      );
      if (generation != _generation) return;
      emit(
        next.copyWith(
          status: page.items.isEmpty
              ? CatalogStatus.empty
              : CatalogStatus.loaded,
          items: page.items,
          page: page.currentPage,
          totalItems: page.totalItems,
          hasNext: page.hasNext,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        next.copyWith(status: CatalogStatus.failure, failure: Failure.from(e)),
      );
    }
  }

  Future<void> _onRefresh(
    CatalogRefreshRequested event,
    Emitter<CatalogState> emit,
  ) async {
    switch (state.status) {
      case CatalogStatus.failure:
        return _loadFirstPage(emit);
      case CatalogStatus.initial ||
          CatalogStatus.loading ||
          CatalogStatus.refreshing:
        return;
      case CatalogStatus.loaded ||
          CatalogStatus.empty ||
          CatalogStatus.loadingNextPage:
        break;
    }

    final generation = ++_generation;
    final previous = state;
    emit(previous.copyWith(status: CatalogStatus.refreshing, failure: null));
    try {
      final page = await _getCatalogItemsUseCase.execute(
        filters: previous.filters,
        sort: previous.sort,
        page: 1,
      );
      if (generation != _generation) return;
      emit(
        previous.copyWith(
          status: page.items.isEmpty
              ? CatalogStatus.empty
              : CatalogStatus.loaded,
          items: page.items,
          page: page.currentPage,
          totalItems: page.totalItems,
          hasNext: page.hasNext,
          failure: null,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(previous.copyWith(failure: Failure.from(e)));
    }
  }

  Future<void> _loadNextPage(Emitter<CatalogState> emit) async {
    if (state.status != CatalogStatus.loaded || !state.hasNext) return;

    final generation = _generation;
    final previous = state;
    emit(
      previous.copyWith(status: CatalogStatus.loadingNextPage, failure: null),
    );
    try {
      final page = await _getCatalogItemsUseCase.execute(
        filters: previous.filters,
        sort: previous.sort,
        page: previous.page + 1,
      );
      if (generation != _generation) return;
      emit(
        previous.copyWith(
          items: [...previous.items, ...page.items],
          page: page.currentPage,
          totalItems: page.totalItems,
          hasNext: page.hasNext,
          failure: null,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(previous.copyWith(failure: Failure.from(e)));
    }
  }

  Future<void> _onRetry(
    CatalogRetryRequested event,
    Emitter<CatalogState> emit,
  ) {
    if (state.items.isEmpty) return _loadFirstPage(emit);
    return _loadNextPage(emit);
  }
}

enum CatalogStatus {
  initial,
  loading,
  refreshing,
  loadingNextPage,
  loaded,
  empty,
  failure,
}

class CatalogState {
  final CatalogStatus status;
  final CatalogFilters filters;
  final CatalogSort sort;
  final List<CatalogItemEntity> items;
  final int page;
  final int totalItems;
  final bool hasNext;

  final Failure? failure;

  const CatalogState({
    this.status = CatalogStatus.initial,
    this.filters = const CatalogFilters(),
    this.sort = CatalogSort.relevance,
    this.items = const [],
    this.page = 0,
    this.totalItems = 0,
    this.hasNext = false,
    this.failure,
  });

  static const _keep = Object();

  CatalogState copyWith({
    CatalogStatus? status,
    CatalogFilters? filters,
    CatalogSort? sort,
    List<CatalogItemEntity>? items,
    int? page,
    int? totalItems,
    bool? hasNext,
    Object? failure = _keep,
  }) => CatalogState(
    status: status ?? this.status,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
    items: items ?? this.items,
    page: page ?? this.page,
    totalItems: totalItems ?? this.totalItems,
    hasNext: hasNext ?? this.hasNext,
    failure: identical(failure, _keep) ? this.failure : failure as Failure?,
  );
}

sealed class CatalogEvent {}

class CatalogStarted extends CatalogEvent {}

class CatalogQueryChanged extends CatalogEvent {
  CatalogQueryChanged(this.query);

  final String query;
}

class _CatalogSearchRequested extends CatalogEvent {
  _CatalogSearchRequested(this.filters);

  final CatalogFilters filters;
}

class CatalogFiltersApplied extends CatalogEvent {
  CatalogFiltersApplied(this.filters);

  final CatalogFilters filters;
}

class CatalogFiltersCleared extends CatalogEvent {}

class CatalogSortChanged extends CatalogEvent {
  CatalogSortChanged(this.sort);

  final CatalogSort sort;
}

class CatalogRefreshRequested extends CatalogEvent {}

class CatalogNextPageRequested extends CatalogEvent {}

class CatalogRetryRequested extends CatalogEvent {}

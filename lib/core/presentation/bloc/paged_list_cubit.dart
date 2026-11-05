import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';

typedef PageResult<T> = ({List<T> items, int page, bool hasNext});

typedef PageLoader<T, F> = Future<PageResult<T>> Function(F filter, int page);

class PagedListCubit<T, F> extends Cubit<PagedListState<T, F>> {
  final PageLoader<T, F> _loader;

  int _generation = 0;

  PagedListCubit({required PageLoader<T, F> loader, required F filter})
    : _loader = loader,
      super(PagedListState(filter: filter));

  Future<void> load() =>
      _load(state.filter, refreshing: state.status == PagedListStatus.loaded);

  Future<void> applyFilter(F filter) => _load(filter, refreshing: false);

  Future<void> _load(F filter, {required bool refreshing}) async {
    final generation = ++_generation;
    if (!refreshing) {
      emit(PagedListState(status: PagedListStatus.loading, filter: filter));
    }
    try {
      final result = await _loader(filter, 1);
      if (isClosed || generation != _generation) return;
      emit(
        PagedListState(
          status: PagedListStatus.loaded,
          filter: filter,
          items: result.items,
          page: result.page,
          hasNext: result.hasNext,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      final failure = Failure.from(e);
      emit(
        refreshing
            ? state.copyWith(failure: failure)
            : PagedListState(
                status: PagedListStatus.failure,
                filter: filter,
                failure: failure,
              ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != PagedListStatus.loaded ||
        !state.hasNext ||
        state.loadingMore) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _loader(state.filter, state.page + 1);
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          items: [...state.items, ...result.items],
          page: result.page,
          hasNext: result.hasNext,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(loadingMore: false, failure: Failure.from(e)));
    }
  }

  Future<bool> change(
    Future<T> Function() action,
    bool Function(T item) matches,
  ) async {
    if (state.status != PagedListStatus.loaded || state.busy) return false;

    emit(state.copyWith(busy: true));
    try {
      final updated = await action();
      if (isClosed) return true;
      emit(
        state.copyWith(
          busy: false,
          items: [
            for (final item in state.items) matches(item) ? updated : item,
          ],
        ),
      );
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(busy: false, failure: Failure.from(e)));
      }
      return false;
    }
  }
}

enum PagedListStatus { initial, loading, loaded, failure }

class PagedListState<T, F> {
  final PagedListStatus status;
  final F filter;
  final List<T> items;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final bool busy;
  final Failure? failure;

  const PagedListState({
    this.status = PagedListStatus.initial,
    required this.filter,
    this.items = const [],
    this.page = 0,
    this.hasNext = false,
    this.loadingMore = false,
    this.busy = false,
    this.failure,
  });

  PagedListState<T, F> copyWith({
    List<T>? items,
    int? page,
    bool? hasNext,
    bool? loadingMore,
    bool? busy,
    Failure? failure,
  }) => PagedListState(
    status: status,
    filter: filter,
    items: items ?? this.items,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
    busy: busy ?? this.busy,
    failure: failure,
  );
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';

class CustomOrdersCubit extends Cubit<CustomOrdersState> {
  final Future<CustomOrdersPageEntity> Function(int page) _loadPage;

  int _generation = 0;

  CustomOrdersCubit({required GetCustomOrdersUseCase getCustomOrdersUseCase})
    : _loadPage = getCustomOrdersUseCase.execute,
      super(const CustomOrdersState());

  Future<void> load() async {
    final generation = ++_generation;
    final refreshing = state.status == CustomOrdersStatus.loaded;
    if (!refreshing) {
      emit(const CustomOrdersState(status: CustomOrdersStatus.loading));
    }
    try {
      final page = await _loadPage(1);
      if (isClosed || generation != _generation) return;
      emit(
        CustomOrdersState(
          status: CustomOrdersStatus.loaded,
          requests: page.items,
          page: page.currentPage,
          hasNext: page.hasNext,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      final failure = Failure.from(e);
      emit(
        refreshing
            ? state.copyWith(failure: failure)
            : CustomOrdersState(
                status: CustomOrdersStatus.failure,
                failure: failure,
              ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != CustomOrdersStatus.loaded ||
        !state.hasNext ||
        state.loadingMore) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _loadPage(state.page + 1);
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          requests: [...state.requests, ...page.items],
          page: page.currentPage,
          hasNext: page.hasNext,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(loadingMore: false, failure: Failure.from(e)));
    }
  }

  void changed(CustomOrderEntity request) {
    if (state.status != CustomOrdersStatus.loaded) return;
    emit(
      state.copyWith(
        requests: [
          for (final current in state.requests)
            current.id == request.id ? request : current,
        ],
      ),
    );
  }
}

enum CustomOrdersStatus { initial, loading, loaded, failure }

class CustomOrdersState {
  final CustomOrdersStatus status;
  final List<CustomOrderEntity> requests;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final Failure? failure;

  const CustomOrdersState({
    this.status = CustomOrdersStatus.initial,
    this.requests = const [],
    this.page = 0,
    this.hasNext = false,
    this.loadingMore = false,
    this.failure,
  });

  CustomOrdersState copyWith({
    List<CustomOrderEntity>? requests,
    int? page,
    bool? hasNext,
    bool? loadingMore,
    Failure? failure,
  }) => CustomOrdersState(
    status: status,
    requests: requests ?? this.requests,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure,
  );
}

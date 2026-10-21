import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';

/// A list of orders a page at a time: the buyer's (the Pedidos tab) or the
/// seller's with one status (a tab of Minhas vendas).
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final Future<OrdersPageEntity> Function(int page) _loadPage;

  /// Bumped by every first-page load, so a next page that arrives after a
  /// refresh is dropped.
  int _generation = 0;

  OrdersBloc({required GetOrdersUseCase getOrdersUseCase})
    : this._(getOrdersUseCase.execute);

  OrdersBloc.sales({
    required GetSellerOrdersUseCase getSellerOrdersUseCase,
    required OrderStatus status,
  }) : this._((page) => getSellerOrdersUseCase.execute(page, status: status));

  OrdersBloc._(this._loadPage) : super(const OrdersState()) {
    on<LoadOrdersEvent>(_onLoad);
    on<LoadMoreOrdersEvent>(_onLoadMore);
    on<OrderChangedEvent>(_onOrderChanged);
    on<ClearOrdersEvent>((_, emit) {
      _generation++;
      emit(const OrdersState());
    });
  }

  /// Loads the first page. A refresh keeps the orders on screen.
  Future<void> _onLoad(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
    final generation = ++_generation;
    final refreshing = state.status == OrdersStatus.loaded;
    if (!refreshing) emit(const OrdersState(status: OrdersStatus.loading));
    try {
      final page = await _loadPage(1);
      if (generation != _generation) return;
      emit(
        OrdersState(
          status: OrdersStatus.loaded,
          orders: page.items,
          page: page.currentPage,
          hasNext: page.hasNext,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      final failure = Failure.from(e);
      emit(
        refreshing
            ? state.copyWith(failure: failure)
            : OrdersState(status: OrdersStatus.failure, failure: failure),
      );
    }
  }

  Future<void> _onLoadMore(
    LoadMoreOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    if (state.status != OrdersStatus.loaded ||
        !state.hasNext ||
        state.loadingMore) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _loadPage(state.page + 1);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          orders: [...state.orders, ...page.items],
          page: page.currentPage,
          hasNext: page.hasNext,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(loadingMore: false, failure: Failure.from(e)));
    }
  }

  /// An order changed on its detail page, e.g. it was cancelled.
  void _onOrderChanged(OrderChangedEvent event, Emitter<OrdersState> emit) {
    if (state.status != OrdersStatus.loaded) return;
    emit(
      state.copyWith(
        orders: [
          for (final order in state.orders)
            order.id == event.order.id ? event.order : order,
        ],
      ),
    );
  }
}

class OrdersEvent {}

class LoadOrdersEvent extends OrdersEvent {}

class LoadMoreOrdersEvent extends OrdersEvent {}

class OrderChangedEvent extends OrdersEvent {
  final OrderEntity order;

  OrderChangedEvent({required this.order});
}

/// Forgets the orders when the user signs out.
class ClearOrdersEvent extends OrdersEvent {}

enum OrdersStatus { initial, loading, loaded, failure }

class OrdersState {
  final OrdersStatus status;
  final List<OrderEntity> orders;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final Failure? failure;

  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.page = 0,
    this.hasNext = false,
    this.loadingMore = false,
    this.failure,
  });

  /// [failure] is one-shot: it is cleared unless passed.
  OrdersState copyWith({
    List<OrderEntity>? orders,
    int? page,
    bool? hasNext,
    bool? loadingMore,
    Failure? failure,
  }) => OrdersState(
    status: status,
    orders: orders ?? this.orders,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure,
  );
}

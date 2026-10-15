import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final GetOrderUseCase _getOrderUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final String orderId;

  OrderDetailCubit({
    required GetOrderUseCase getOrderUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required this.orderId,
  }) : _getOrderUseCase = getOrderUseCase,
       _cancelOrderUseCase = cancelOrderUseCase,
       super(OrderDetailLoading());

  /// A refresh keeps the order on screen, even when it fails.
  Future<void> load() async {
    final current = state;
    if (current is! OrderDetailLoaded) emit(OrderDetailLoading());
    try {
      final detail = await _getOrderUseCase.execute(orderId);
      if (!isClosed) emit(OrderDetailLoaded(detail: detail));
    } catch (e) {
      if (isClosed) return;
      final failure = Failure.from(e);
      emit(
        current is OrderDetailLoaded
            ? OrderDetailLoaded(detail: current.detail, failure: failure)
            : OrderDetailLoadFailure(failure: failure),
      );
    }
  }

  /// When the status changed elsewhere (409), the order is reloaded so the
  /// page shows where it is now.
  Future<void> cancel() async {
    final current = state;
    if (current is! OrderDetailLoaded || current.cancelling) return;

    emit(OrderDetailLoaded(detail: current.detail, cancelling: true));
    try {
      final detail = await _cancelOrderUseCase.execute(orderId);
      if (isClosed) return;
      emit(OrderDetailLoaded(detail: detail, notice: 'Pedido cancelado.'));
    } catch (e) {
      final failure = Failure.from(e);
      var detail = current.detail;
      if (failure is OrderStatusChangedFailure) {
        try {
          detail = await _getOrderUseCase.execute(orderId);
        } catch (_) {}
      }
      if (!isClosed) emit(OrderDetailLoaded(detail: detail, failure: failure));
    }
  }
}

sealed class OrderDetailState {}

class OrderDetailLoading extends OrderDetailState {}

class OrderDetailLoadFailure extends OrderDetailState {
  final Failure failure;

  OrderDetailLoadFailure({required this.failure});
}

class OrderDetailLoaded extends OrderDetailState {
  final OrderDetailEntity detail;
  final bool cancelling;
  final Failure? failure;
  final String? notice;

  OrderDetailLoaded({
    required this.detail,
    this.cancelling = false,
    this.failure,
    this.notice,
  });
}

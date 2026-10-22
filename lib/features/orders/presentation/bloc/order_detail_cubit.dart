import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final GetOrderUseCase _getOrderUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final ConfirmDeliveryUseCase _confirmDeliveryUseCase;
  final GetPaymentsUseCase _getPaymentsUseCase;
  final String orderId;

  OrderDetailCubit({
    required GetOrderUseCase getOrderUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required ConfirmDeliveryUseCase confirmDeliveryUseCase,
    required GetPaymentsUseCase getPaymentsUseCase,
    required this.orderId,
  }) : _getOrderUseCase = getOrderUseCase,
       _cancelOrderUseCase = cancelOrderUseCase,
       _confirmDeliveryUseCase = confirmDeliveryUseCase,
       _getPaymentsUseCase = getPaymentsUseCase,
       super(OrderDetailLoading());

  /// A refresh keeps the order on screen, even when it fails. The payments
  /// are loaded first: checking a pending one may mark the order paid.
  /// Without them the order is still shown.
  Future<void> load() async {
    final current = state;
    if (current is! OrderDetailLoaded) emit(OrderDetailLoading());
    List<PaymentEntity>? payments;
    try {
      payments = await _getPaymentsUseCase.execute(orderId);
    } catch (_) {}
    try {
      final detail = await _getOrderUseCase.execute(orderId);
      if (isClosed) return;
      emit(
        OrderDetailLoaded(
          detail: detail,
          payments:
              payments ??
              (current is OrderDetailLoaded ? current.payments : const []),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final failure = Failure.from(e);
      emit(
        current is OrderDetailLoaded
            ? OrderDetailLoaded(
                detail: current.detail,
                payments: current.payments,
                failure: failure,
              )
            : OrderDetailLoadFailure(failure: failure),
      );
    }
  }

  /// A paid order is refunded: its payments are loaded again to show the
  /// refund.
  Future<void> cancel() {
    final wasPaid = switch (state) {
      OrderDetailLoaded(:final detail) =>
        detail.order.status == OrderStatus.paid,
      _ => false,
    };
    return _change(
      () => _cancelOrderUseCase.execute(orderId),
      notice: wasPaid
          ? 'Pedido cancelado. O valor pago será estornado.'
          : 'Pedido cancelado.',
      reloadPayments: wasPaid,
    );
  }

  /// "Recebi meu pedido" (RF-023): the items can then be reviewed.
  Future<void> confirmDelivery() => _change(
    () => _confirmDeliveryUseCase.execute(orderId),
    notice: 'Recebimento confirmado. Conte o que achou dos produtos.',
  );

  /// When the status changed elsewhere (409), the order is reloaded so the
  /// page shows where it is now.
  Future<void> _change(
    Future<OrderDetailEntity> Function() action, {
    required String notice,
    bool reloadPayments = false,
  }) async {
    final current = state;
    if (current is! OrderDetailLoaded || current.working) return;

    emit(
      OrderDetailLoaded(
        detail: current.detail,
        payments: current.payments,
        working: true,
      ),
    );
    try {
      final detail = await action();
      var payments = current.payments;
      if (reloadPayments) {
        try {
          payments = await _getPaymentsUseCase.execute(orderId);
        } catch (_) {}
      }
      if (isClosed) return;
      emit(
        OrderDetailLoaded(detail: detail, payments: payments, notice: notice),
      );
    } catch (e) {
      final failure = Failure.from(e);
      var detail = current.detail;
      if (failure is OrderStatusChangedFailure) {
        try {
          detail = await _getOrderUseCase.execute(orderId);
        } catch (_) {}
      }
      if (isClosed) return;
      emit(
        OrderDetailLoaded(
          detail: detail,
          payments: current.payments,
          failure: failure,
        ),
      );
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

  /// The order's payment attempts, newest first.
  final List<PaymentEntity> payments;

  /// Cancelling or confirming the delivery.
  final bool working;
  final Failure? failure;
  final String? notice;

  OrderDetailLoaded({
    required this.detail,
    this.payments = const [],
    this.working = false,
    this.failure,
    this.notice,
  });
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_prescription_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_prescription_consent_use_case.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final GetOrderUseCase _getOrderUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final ConfirmDeliveryUseCase _confirmDeliveryUseCase;
  final GetPaymentsUseCase _getPaymentsUseCase;
  final UploadPrescriptionUseCase _uploadPrescriptionUseCase;
  final HasPrescriptionConsentUseCase _hasPrescriptionConsentUseCase;
  final GrantPrescriptionConsentUseCase _grantPrescriptionConsentUseCase;
  final String orderId;

  bool _hasPrescriptionConsent = false;

  OrderDetailCubit({
    required GetOrderUseCase getOrderUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required ConfirmDeliveryUseCase confirmDeliveryUseCase,
    required GetPaymentsUseCase getPaymentsUseCase,
    required UploadPrescriptionUseCase uploadPrescriptionUseCase,
    required HasPrescriptionConsentUseCase hasPrescriptionConsentUseCase,
    required GrantPrescriptionConsentUseCase grantPrescriptionConsentUseCase,
    required this.orderId,
  }) : _getOrderUseCase = getOrderUseCase,
       _cancelOrderUseCase = cancelOrderUseCase,
       _confirmDeliveryUseCase = confirmDeliveryUseCase,
       _getPaymentsUseCase = getPaymentsUseCase,
       _uploadPrescriptionUseCase = uploadPrescriptionUseCase,
       _hasPrescriptionConsentUseCase = hasPrescriptionConsentUseCase,
       _grantPrescriptionConsentUseCase = grantPrescriptionConsentUseCase,
       super(OrderDetailLoading());

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

  Future<void> confirmDelivery() => _change(
    () => _confirmDeliveryUseCase.execute(orderId),
    notice: 'Recebimento confirmado. Conte o que achou dos produtos.',
  );

  Future<bool?> hasPrescriptionConsent() async {
    if (_hasPrescriptionConsent) return true;
    try {
      return _hasPrescriptionConsent = await _hasPrescriptionConsentUseCase
          .execute();
    } catch (e) {
      _report(Failure.from(e));
      return null;
    }
  }

  Future<bool> grantPrescriptionConsent() async {
    try {
      await _grantPrescriptionConsentUseCase.execute();
      return _hasPrescriptionConsent = true;
    } catch (e) {
      _report(Failure.from(e));
      return false;
    }
  }

  Future<void> uploadPrescription(String itemId, UploadFile file) => _change(
    () async {
      await _uploadPrescriptionUseCase.execute(orderId, itemId, file);
      return _getOrderUseCase.execute(orderId);
    },
    notice: 'Receita enviada.',
    noticeFor: (detail) =>
        detail.order.status == OrderStatus.awaitingPayment &&
            detail.order.itemsAwaitingPrescription.isEmpty
        ? 'Receita aprovada. Você já pode pagar.'
        : null,
  );

  void _report(Failure failure) {
    final current = state;
    if (isClosed || current is! OrderDetailLoaded) return;
    emit(
      OrderDetailLoaded(
        detail: current.detail,
        payments: current.payments,
        failure: failure,
      ),
    );
  }

  Future<void> _change(
    Future<OrderDetailEntity> Function() action, {
    required String notice,
    String? Function(OrderDetailEntity detail)? noticeFor,
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
        OrderDetailLoaded(
          detail: detail,
          payments: payments,
          notice: noticeFor?.call(detail) ?? notice,
        ),
      );
    } catch (e) {
      final failure = Failure.from(e);
      if (failure is PrescriptionConsentRequiredFailure) {
        _hasPrescriptionConsent = false;
      }
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

  final List<PaymentEntity> payments;

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

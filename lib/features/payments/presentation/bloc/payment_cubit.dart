import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/network/idempotency_key.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final GetProfileUseCase _getProfileUseCase;
  final GetPaymentsUseCase _getPaymentsUseCase;
  final CreatePaymentUseCase _createPaymentUseCase;
  final String Function() _newKey;
  final Duration pollInterval;
  final OrderEntity order;

  late String _idempotencyKey = _newKey();
  Timer? _poll;
  bool _checking = false;

  PaymentCubit({
    required this.order,
    required GetProfileUseCase getProfileUseCase,
    required GetPaymentsUseCase getPaymentsUseCase,
    required CreatePaymentUseCase createPaymentUseCase,
    String Function() newKey = newIdempotencyKey,
    this.pollInterval = const Duration(seconds: 5),
  }) : _getProfileUseCase = getProfileUseCase,
       _getPaymentsUseCase = getPaymentsUseCase,
       _createPaymentUseCase = createPaymentUseCase,
       _newKey = newKey,
       super(const PaymentState());

  String get idempotencyKey => _idempotencyKey;

  Future<void> load() async {
    emit(state.copyWith(stage: PaymentStage.loading));
    try {
      final profile = await _getProfileUseCase.execute();
      final payments = await _getPaymentsUseCase.execute(order.id);
      if (isClosed) return;
      final next = _settle(payments);
      emit(
        (next ?? state.copyWith(stage: PaymentStage.choosing)).copyWith(
          needsTaxId: !profile.hasTaxId,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          stage: PaymentStage.loadFailure,
          failure: Failure.from(e),
        ),
      );
    }
  }

  void selectMethod(PaymentMethod method) {
    if (state.stage != PaymentStage.choosing || state.submitting) return;
    if (method != state.method) _idempotencyKey = _newKey();
    emit(state.copyWith(method: method));
  }

  Future<void> pay({String? taxId, CardDetails? card}) async {
    if (state.stage != PaymentStage.choosing || state.submitting) return;

    emit(state.copyWith(submitting: true));
    final request = PaymentRequest(
      method: state.method,
      taxId: state.needsTaxId ? taxId : null,
      card: state.method == PaymentMethod.creditCard ? card : null,
    );
    try {
      final payment = await _createPaymentUseCase.execute(
        order.id,
        request,
        _idempotencyKey,
      );
      _idempotencyKey = _newKey();
      if (isClosed) return;
      emit(_charged(payment));
    } catch (e) {
      final failure = Failure.from(e);
      if (failure is! NetworkFailure) _idempotencyKey = _newKey();
      if (isClosed) return;
      emit(await _payFailed(failure));
    }
  }

  PaymentState _charged(PaymentEntity payment) {
    final charged = state.copyWith(needsTaxId: false, payment: payment);
    return switch (payment.status) {
      PaymentStatus.captured => charged.copyWith(
        stage: PaymentStage.approved,
        payment: payment,
      ),
      PaymentStatus.pending => charged.copyWith(
        stage: PaymentStage.waiting,
        payment: payment,
      ),
      _ => charged.copyWith(stage: PaymentStage.choosing, payment: payment),
    };
  }

  Future<PaymentState> _payFailed(Failure failure) async {
    final choosing = state.copyWith(
      stage: PaymentStage.choosing,
      clearPayment: true,
      failure: failure,
    );
    switch (failure) {
      case TaxIdRequiredFailure():
        return choosing.copyWith(needsTaxId: true, failure: failure);
      case PaymentExpiredFailure():
        return state.copyWith(stage: PaymentStage.closed, failure: failure);
      case OrderStatusChangedFailure() || PaymentInProgressFailure():
        try {
          final payments = await _getPaymentsUseCase.execute(order.id);
          if (_settle(payments) case final settled?) return settled;
        } catch (_) {}
        return failure is OrderStatusChangedFailure
            ? state.copyWith(stage: PaymentStage.closed, failure: failure)
            : choosing;
      default:
        return choosing;
    }
  }

  Future<void> refresh({bool manual = false}) async {
    if (state.stage != PaymentStage.waiting || _checking) return;
    _checking = true;
    if (manual) emit(state.copyWith(refreshing: true));
    try {
      final payments = await _getPaymentsUseCase.execute(order.id);
      if (isClosed || state.stage != PaymentStage.waiting) return;
      final next =
          _settle(payments) ??
          state.copyWith(
            stage: PaymentStage.closed,
            failure: PaymentExpiredFailure(),
          );
      emit(
        manual && next.stage == PaymentStage.waiting
            ? next.copyWith(
                notice: 'Ainda não recebemos a confirmação do pagamento.',
              )
            : next,
      );
    } catch (e) {
      if (isClosed || !manual) return;
      emit(state.copyWith(failure: Failure.from(e)));
    } finally {
      _checking = false;
    }
  }

  void chooseAnotherMethod() {
    if (state.stage != PaymentStage.waiting) return;
    _idempotencyKey = _newKey();
    emit(state.copyWith(stage: PaymentStage.choosing, clearPayment: true));
  }

  PaymentState? _settle(List<PaymentEntity> payments) {
    final captured = payments
        .where((payment) => payment.status == PaymentStatus.captured)
        .firstOrNull;
    if (captured != null) {
      return state.copyWith(stage: PaymentStage.approved, payment: captured);
    }
    final latest = payments.firstOrNull;
    if (latest != null &&
        latest.status == PaymentStatus.pending &&
        latest.method != PaymentMethod.creditCard) {
      return state.copyWith(
        stage: PaymentStage.waiting,
        method: latest.method,
        payment: latest,
      );
    }
    return null;
  }

  @override
  void onChange(Change<PaymentState> change) {
    super.onChange(change);
    final next = change.nextState;
    final polls =
        next.stage == PaymentStage.waiting &&
        next.payment?.method == PaymentMethod.pix;
    if (!polls) {
      _poll?.cancel();
      _poll = null;
    } else {
      _poll ??= Timer.periodic(pollInterval, (_) => refresh());
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}

enum PaymentStage { loading, loadFailure, choosing, waiting, approved, closed }

class PaymentState {
  final PaymentStage stage;
  final PaymentMethod method;
  final bool needsTaxId;

  final PaymentEntity? payment;
  final bool submitting;
  final bool refreshing;

  final Failure? failure;
  final String? notice;

  const PaymentState({
    this.stage = PaymentStage.loading,
    this.method = PaymentMethod.pix,
    this.needsTaxId = false,
    this.payment,
    this.submitting = false,
    this.refreshing = false,
    this.failure,
    this.notice,
  });

  PaymentState copyWith({
    PaymentStage? stage,
    PaymentMethod? method,
    bool? needsTaxId,
    PaymentEntity? payment,
    bool clearPayment = false,
    bool submitting = false,
    bool refreshing = false,
    Failure? failure,
    String? notice,
  }) => PaymentState(
    stage: stage ?? this.stage,
    method: method ?? this.method,
    needsTaxId: needsTaxId ?? this.needsTaxId,
    payment: clearPayment ? null : payment ?? this.payment,
    submitting: submitting,
    refreshing: refreshing,
    failure: failure,
    notice: notice,
  );
}

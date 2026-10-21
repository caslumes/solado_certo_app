import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';

/// One of the seller's orders, with the actions that move it forward
/// (RF-021): start preparing it, then ship it.
class SellerOrderDetailCubit extends Cubit<SellerOrderDetailState> {
  final GetSellerOrderUseCase _getSellerOrderUseCase;
  final StartProcessingUseCase _startProcessingUseCase;
  final ShipOrderUseCase _shipOrderUseCase;
  final String orderId;

  SellerOrderDetailCubit({
    required GetSellerOrderUseCase getSellerOrderUseCase,
    required StartProcessingUseCase startProcessingUseCase,
    required ShipOrderUseCase shipOrderUseCase,
    required this.orderId,
  }) : _getSellerOrderUseCase = getSellerOrderUseCase,
       _startProcessingUseCase = startProcessingUseCase,
       _shipOrderUseCase = shipOrderUseCase,
       super(SellerOrderDetailLoading());

  /// A refresh keeps the order on screen, even when it fails.
  Future<void> load() async {
    final current = state;
    if (current is! SellerOrderDetailLoaded) emit(SellerOrderDetailLoading());
    try {
      final detail = await _getSellerOrderUseCase.execute(orderId);
      if (isClosed) return;
      emit(SellerOrderDetailLoaded(detail: detail));
    } catch (e) {
      if (isClosed) return;
      final failure = Failure.from(e);
      emit(
        current is SellerOrderDetailLoaded
            ? SellerOrderDetailLoaded(detail: current.detail, failure: failure)
            : SellerOrderDetailLoadFailure(failure: failure),
      );
    }
  }

  Future<void> startProcessing() async {
    final current = state;
    if (current is! SellerOrderDetailLoaded || current.working) return;

    emit(SellerOrderDetailLoaded(detail: current.detail, working: true));
    try {
      final detail = await _startProcessingUseCase.execute(orderId);
      if (isClosed) return;
      emit(
        SellerOrderDetailLoaded(
          detail: detail,
          notice: 'Preparação iniciada. Informe o envio quando postar.',
        ),
      );
    } catch (e) {
      await _fail(current, Failure.from(e));
    }
  }

  /// Returns the failure for the shipping form to show (an invalid or
  /// repeated code), or null once the order is shipped. Other failures are
  /// also shown on the page.
  Future<Failure?> ship({
    required String carrier,
    required String trackingCode,
  }) async {
    final current = state;
    if (current is! SellerOrderDetailLoaded || current.working) return null;

    emit(SellerOrderDetailLoaded(detail: current.detail, working: true));
    try {
      final detail = await _shipOrderUseCase.execute(
        orderId,
        carrier: carrier,
        trackingCode: trackingCode,
      );
      if (isClosed) return null;
      emit(
        SellerOrderDetailLoaded(
          detail: detail,
          notice: 'Envio informado. O comprador foi avisado.',
        ),
      );
      return null;
    } catch (e) {
      final failure = Failure.from(e);
      if (failure is InvalidTrackingCodeFailure ||
          failure is TrackingCodeInUseFailure) {
        if (!isClosed) emit(SellerOrderDetailLoaded(detail: current.detail));
      } else {
        await _fail(current, failure);
      }
      return failure;
    }
  }

  /// When the status changed elsewhere (409), e.g. the buyer cancelled, the
  /// order is reloaded so the page shows where it is now.
  Future<void> _fail(SellerOrderDetailLoaded current, Failure failure) async {
    var detail = current.detail;
    if (failure is OrderStatusChangedFailure) {
      try {
        detail = await _getSellerOrderUseCase.execute(orderId);
      } catch (_) {}
    }
    if (isClosed) return;
    emit(SellerOrderDetailLoaded(detail: detail, failure: failure));
  }
}

sealed class SellerOrderDetailState {}

class SellerOrderDetailLoading extends SellerOrderDetailState {}

class SellerOrderDetailLoadFailure extends SellerOrderDetailState {
  final Failure failure;

  SellerOrderDetailLoadFailure({required this.failure});
}

class SellerOrderDetailLoaded extends SellerOrderDetailState {
  final OrderDetailEntity detail;

  /// An action is being sent.
  final bool working;
  final Failure? failure;
  final String? notice;

  SellerOrderDetailLoaded({
    required this.detail,
    this.working = false,
    this.failure,
    this.notice,
  });
}

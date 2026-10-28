import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_custom_order_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_custom_order_consent_use_case.dart';

class CustomOrderDetailCubit extends Cubit<CustomOrderDetailState> {
  final GetCustomOrderUseCase _getCustomOrderUseCase;
  final ComplementCustomOrderUseCase _complementUseCase;
  final CancelCustomOrderUseCase _cancelUseCase;
  final SendFootPhotoUseCase _sendFootPhotoUseCase;
  final HasCustomOrderConsentUseCase _hasConsentUseCase;
  final GrantCustomOrderConsentUseCase _grantConsentUseCase;
  final String requestId;

  bool _hasConsent = false;

  CustomOrderDetailCubit({
    required GetCustomOrderUseCase getCustomOrderUseCase,
    required ComplementCustomOrderUseCase complementUseCase,
    required CancelCustomOrderUseCase cancelUseCase,
    required SendFootPhotoUseCase sendFootPhotoUseCase,
    required HasCustomOrderConsentUseCase hasConsentUseCase,
    required GrantCustomOrderConsentUseCase grantConsentUseCase,
    required this.requestId,
  }) : _getCustomOrderUseCase = getCustomOrderUseCase,
       _complementUseCase = complementUseCase,
       _cancelUseCase = cancelUseCase,
       _sendFootPhotoUseCase = sendFootPhotoUseCase,
       _hasConsentUseCase = hasConsentUseCase,
       _grantConsentUseCase = grantConsentUseCase,
       super(CustomOrderDetailLoading());

  Future<void> load() async {
    final current = state;
    if (current is! CustomOrderDetailLoaded) emit(CustomOrderDetailLoading());
    try {
      final detail = await _getCustomOrderUseCase.execute(requestId);
      if (isClosed) return;
      emit(CustomOrderDetailLoaded(detail: detail));
    } catch (e) {
      if (isClosed) return;
      final failure = Failure.from(e);
      emit(
        current is CustomOrderDetailLoaded
            ? CustomOrderDetailLoaded(detail: current.detail, failure: failure)
            : CustomOrderDetailLoadFailure(failure: failure),
      );
    }
  }

  Future<bool?> hasConsent() async {
    if (_hasConsent) return true;
    try {
      return _hasConsent = await _hasConsentUseCase.execute();
    } catch (e) {
      _report(Failure.from(e));
      return null;
    }
  }

  Future<bool> grantConsent() async {
    try {
      await _grantConsentUseCase.execute();
      return _hasConsent = true;
    } catch (e) {
      _report(Failure.from(e));
      return false;
    }
  }

  Future<Failure?> complement(CustomOrderComplement complement) => _change(
    () => _complementUseCase.execute(requestId, complement),
    notice: 'Resposta enviada ao vendedor.',
  );

  Future<Failure?> cancel({String? reason}) => _change(
    () => _cancelUseCase.execute(requestId, reason: reason),
    notice: 'Solicitação cancelada.',
  );

  Future<Failure?> sendPhoto(UploadFile file) => _change(
    () => _sendFootPhotoUseCase.execute(requestId, file),
    notice: 'Foto enviada.',
  );

  void _report(Failure failure) {
    final current = state;
    if (isClosed || current is! CustomOrderDetailLoaded) return;
    emit(CustomOrderDetailLoaded(detail: current.detail, failure: failure));
  }

  Future<Failure?> _change(
    Future<CustomOrderDetailEntity> Function() action, {
    required String notice,
  }) async {
    final current = state;
    if (current is! CustomOrderDetailLoaded || current.working) return null;

    emit(CustomOrderDetailLoaded(detail: current.detail, working: true));
    try {
      final detail = await action();
      if (!isClosed) {
        emit(CustomOrderDetailLoaded(detail: detail, notice: notice));
      }
      return null;
    } catch (e) {
      final failure = Failure.from(e);
      if (failure is CustomOrderConsentRequiredFailure) _hasConsent = false;
      var detail = current.detail;
      if (failure is OrderStatusChangedFailure) {
        try {
          detail = await _getCustomOrderUseCase.execute(requestId);
        } catch (_) {}
      }
      if (!isClosed) {
        emit(CustomOrderDetailLoaded(detail: detail, failure: failure));
      }
      return failure;
    }
  }
}

sealed class CustomOrderDetailState {}

class CustomOrderDetailLoading extends CustomOrderDetailState {}

class CustomOrderDetailLoadFailure extends CustomOrderDetailState {
  final Failure failure;

  CustomOrderDetailLoadFailure({required this.failure});
}

class CustomOrderDetailLoaded extends CustomOrderDetailState {
  final CustomOrderDetailEntity detail;

  final bool working;
  final Failure? failure;
  final String? notice;

  CustomOrderDetailLoaded({
    required this.detail,
    this.working = false,
    this.failure,
    this.notice,
  });
}

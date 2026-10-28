import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_custom_order_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_custom_order_consent_use_case.dart';

class CustomOrderFormCubit extends Cubit<CustomOrderFormState> {
  final CreateCustomOrderUseCase _createCustomOrderUseCase;
  final SendFootPhotoUseCase _sendFootPhotoUseCase;
  final HasCustomOrderConsentUseCase _hasConsentUseCase;
  final GrantCustomOrderConsentUseCase _grantConsentUseCase;

  bool _hasConsent = false;

  CustomOrderFormCubit({
    required CreateCustomOrderUseCase createCustomOrderUseCase,
    required SendFootPhotoUseCase sendFootPhotoUseCase,
    required HasCustomOrderConsentUseCase hasConsentUseCase,
    required GrantCustomOrderConsentUseCase grantConsentUseCase,
  }) : _createCustomOrderUseCase = createCustomOrderUseCase,
       _sendFootPhotoUseCase = sendFootPhotoUseCase,
       _hasConsentUseCase = hasConsentUseCase,
       _grantConsentUseCase = grantConsentUseCase,
       super(const CustomOrderFormState());

  Future<bool?> hasConsent() async {
    if (_hasConsent) return true;
    try {
      return _hasConsent = await _hasConsentUseCase.execute();
    } catch (e) {
      emit(CustomOrderFormState(failure: Failure.from(e)));
      return null;
    }
  }

  Future<bool> grantConsent() async {
    try {
      await _grantConsentUseCase.execute();
      return _hasConsent = true;
    } catch (e) {
      emit(CustomOrderFormState(failure: Failure.from(e)));
      return false;
    }
  }

  Future<void> submit(NewCustomOrder request, {UploadFile? photo}) async {
    if (state.submitting || state.created != null) return;
    emit(const CustomOrderFormState(submitting: true));

    CustomOrderDetailEntity created;
    try {
      created = await _createCustomOrderUseCase.execute(request);
    } catch (e) {
      final failure = Failure.from(e);
      if (failure is CustomOrderConsentRequiredFailure) _hasConsent = false;
      if (!isClosed) emit(CustomOrderFormState(failure: failure));
      return;
    }

    if (photo == null) {
      if (!isClosed) emit(CustomOrderFormState(created: created));
      return;
    }
    try {
      created = await _sendFootPhotoUseCase.execute(created.request.id, photo);
      if (!isClosed) emit(CustomOrderFormState(created: created));
    } catch (e) {
      if (isClosed) return;
      emit(
        CustomOrderFormState(created: created, photoFailure: Failure.from(e)),
      );
    }
  }
}

class CustomOrderFormState {
  final bool submitting;
  final Failure? failure;

  final CustomOrderDetailEntity? created;
  final Failure? photoFailure;

  const CustomOrderFormState({
    this.submitting = false,
    this.failure,
    this.created,
    this.photoFailure,
  });
}

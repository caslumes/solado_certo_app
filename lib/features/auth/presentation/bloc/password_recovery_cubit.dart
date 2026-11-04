import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/request_password_reset_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/reset_password_use_case.dart';

class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  PasswordRecoveryCubit({
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  }) : _requestPasswordResetUseCase = requestPasswordResetUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       super(const PasswordRecoveryState());

  Future<void> requestCode(String email) async {
    if (state.sending) return;
    final previousEmail = state.email;
    emit(PasswordRecoveryState(email: previousEmail, sending: true));
    try {
      await _requestPasswordResetUseCase.execute(email);
      emit(PasswordRecoveryState(email: email, resent: previousEmail != null));
    } catch (e) {
      emit(
        PasswordRecoveryState(email: previousEmail, failure: Failure.from(e)),
      );
    }
  }

  Future<void> resetPassword(String code, String newPassword) async {
    final email = state.email;
    if (state.sending || state.done || email == null) return;
    emit(PasswordRecoveryState(email: email, sending: true));
    try {
      await _resetPasswordUseCase.execute(email, code, newPassword);
      emit(PasswordRecoveryState(email: email, done: true));
    } catch (e) {
      emit(PasswordRecoveryState(email: email, failure: Failure.from(e)));
    }
  }
}

class PasswordRecoveryState {
  final String? email;
  final bool sending;
  final bool resent;
  final bool done;
  final Failure? failure;

  const PasswordRecoveryState({
    this.email,
    this.sending = false,
    this.resent = false,
    this.done = false,
    this.failure,
  });
}

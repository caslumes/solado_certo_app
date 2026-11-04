import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/password_recovery_cubit.dart';

import '../../../../support/mocks.dart';

void main() {
  const email = 'maria@example.com';

  late MockRequestPasswordResetUseCase requestReset;
  late MockResetPasswordUseCase resetPassword;

  PasswordRecoveryCubit buildCubit() => PasswordRecoveryCubit(
    requestPasswordResetUseCase: requestReset,
    resetPasswordUseCase: resetPassword,
  );

  setUp(() {
    requestReset = MockRequestPasswordResetUseCase();
    resetPassword = MockResetPasswordUseCase();
  });

  blocTest<PasswordRecoveryCubit, PasswordRecoveryState>(
    'moves to the code step after requesting a code',
    setUp: () =>
        when(() => requestReset.execute(email)).thenAnswer((_) async {}),
    build: buildCubit,
    act: (cubit) => cubit.requestCode(email),
    expect: () => [
      isA<PasswordRecoveryState>()
          .having((s) => s.sending, 'sending', true)
          .having((s) => s.email, 'email', isNull),
      isA<PasswordRecoveryState>()
          .having((s) => s.sending, 'sending', false)
          .having((s) => s.email, 'email', email)
          .having((s) => s.resent, 'resent', false),
    ],
  );

  blocTest<PasswordRecoveryCubit, PasswordRecoveryState>(
    'stays on the e-mail step when the request fails',
    setUp: () => when(
      () => requestReset.execute(email),
    ).thenThrow(TooManyRequestsFailure()),
    build: buildCubit,
    act: (cubit) => cubit.requestCode(email),
    skip: 1,
    expect: () => [
      isA<PasswordRecoveryState>()
          .having((s) => s.email, 'email', isNull)
          .having((s) => s.failure, 'failure', isA<TooManyRequestsFailure>()),
    ],
  );

  blocTest<PasswordRecoveryCubit, PasswordRecoveryState>(
    'marks a second request as resent',
    setUp: () =>
        when(() => requestReset.execute(email)).thenAnswer((_) async {}),
    build: buildCubit,
    seed: () => const PasswordRecoveryState(email: email),
    act: (cubit) => cubit.requestCode(email),
    skip: 1,
    expect: () => [
      isA<PasswordRecoveryState>()
          .having((s) => s.email, 'email', email)
          .having((s) => s.resent, 'resent', true),
    ],
  );

  blocTest<PasswordRecoveryCubit, PasswordRecoveryState>(
    'resets the password with the requested e-mail',
    setUp: () => when(
      () => resetPassword.execute(email, '123456', 'new-secret'),
    ).thenAnswer((_) async {}),
    build: buildCubit,
    seed: () => const PasswordRecoveryState(email: email),
    act: (cubit) => cubit.resetPassword('123456', 'new-secret'),
    expect: () => [
      isA<PasswordRecoveryState>().having((s) => s.sending, 'sending', true),
      isA<PasswordRecoveryState>().having((s) => s.done, 'done', true),
    ],
  );

  blocTest<PasswordRecoveryCubit, PasswordRecoveryState>(
    'keeps the code step when the code is refused',
    setUp: () => when(
      () => resetPassword.execute(email, '000000', 'new-secret'),
    ).thenThrow(InvalidResetCodeFailure()),
    build: buildCubit,
    seed: () => const PasswordRecoveryState(email: email),
    act: (cubit) => cubit.resetPassword('000000', 'new-secret'),
    skip: 1,
    expect: () => [
      isA<PasswordRecoveryState>()
          .having((s) => s.email, 'email', email)
          .having((s) => s.done, 'done', false)
          .having((s) => s.failure, 'failure', isA<InvalidResetCodeFailure>()),
    ],
  );

  blocTest<PasswordRecoveryCubit, PasswordRecoveryState>(
    'does not reset before a code was requested',
    build: buildCubit,
    act: (cubit) => cubit.resetPassword('123456', 'new-secret'),
    expect: () => <PasswordRecoveryState>[],
    verify: (_) =>
        verifyNever(() => resetPassword.execute(any(), any(), any())),
  );
}

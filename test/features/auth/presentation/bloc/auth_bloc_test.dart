import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockSignInUseCase signIn;
  late MockSignUpUseCase signUp;
  late MockSignOutUseCase signOut;
  late MockGetProfileUseCase getProfile;

  AuthBloc buildBloc() => AuthBloc(
    signInUseCase: signIn,
    signUpUseCase: signUp,
    signOutUseCase: signOut,
    getProfileUseCase: getProfile,
  );

  Matcher unauthenticatedWith<T extends Failure>() =>
      isA<AuthUnauthenticated>().having((s) => s.failure, 'failure', isA<T>());

  setUp(() {
    signIn = MockSignInUseCase();
    signUp = MockSignUpUseCase();
    signOut = MockSignOutUseCase();
    getProfile = MockGetProfileUseCase();
  });

  group('CheckAuthEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits authenticated when the profile loads',
      setUp: () => when(
        () => getProfile.execute(),
      ).thenAnswer((_) async => buildProfile()),
      build: buildBloc,
      act: (bloc) => bloc.add(CheckAuthEvent()),
      expect: () => [isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated without a failure when the profile fails',
      setUp: () => when(
        () => getProfile.execute(),
      ).thenThrow(buildDioException(statusCode: 401)),
      build: buildBloc,
      act: (bloc) => bloc.add(CheckAuthEvent()),
      expect: () => [
        isA<AuthUnauthenticated>().having((s) => s.failure, 'failure', isNull),
      ],
    );
  });

  group('SignInEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then authenticated on success',
      setUp: () {
        when(() => signIn.execute(any(), any())).thenAnswer((_) async {});
        when(
          () => getProfile.execute(),
        ).thenAnswer((_) async => buildProfile());
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(SignInEvent(email: 'maria@example.com', password: 'x')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'reports invalid credentials on 401',
      setUp: () => when(
        () => signIn.execute(any(), any()),
      ).thenThrow(buildDioException(statusCode: 401)),
      build: buildBloc,
      act: (bloc) =>
          bloc.add(SignInEvent(email: 'maria@example.com', password: 'x')),
      expect: () => [
        isA<AuthLoading>(),
        unauthenticatedWith<InvalidCredentialsFailure>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'reports a network failure distinctly from bad credentials',
      setUp: () => when(
        () => signIn.execute(any(), any()),
      ).thenThrow(buildDioException(type: DioExceptionType.connectionError)),
      build: buildBloc,
      act: (bloc) =>
          bloc.add(SignInEvent(email: 'maria@example.com', password: 'x')),
      expect: () => [isA<AuthLoading>(), unauthenticatedWith<NetworkFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'ignores a second submission while the first is loading',
      setUp: () {
        when(() => signIn.execute(any(), any())).thenAnswer((_) async {});
        when(
          () => getProfile.execute(),
        ).thenAnswer((_) async => buildProfile());
      },
      build: buildBloc,
      act: (bloc) => bloc
        ..add(SignInEvent(email: 'maria@example.com', password: 'x'))
        ..add(SignInEvent(email: 'maria@example.com', password: 'x')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
      verify: (_) => verify(() => signIn.execute(any(), any())).called(1),
    );
  });

  group('SignUpEvent', () {
    SignUpEvent event() => SignUpEvent(
      name: 'Maria Souza',
      email: 'maria@example.com',
      phone: '19999999999',
      password: 'secret123',
    );

    blocTest<AuthBloc, AuthState>(
      'emits success then unauthenticated so the user can sign in',
      setUp: () => when(
        () => signUp.execute(any(), any(), any(), any()),
      ).thenAnswer((_) async {}),
      build: buildBloc,
      act: (bloc) => bloc.add(event()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSignUpSuccess>(),
        isA<AuthUnauthenticated>().having((s) => s.failure, 'failure', isNull),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'reports invalid input on 400',
      setUp: () => when(
        () => signUp.execute(any(), any(), any(), any()),
      ).thenThrow(buildDioException(statusCode: 400)),
      build: buildBloc,
      act: (bloc) => bloc.add(event()),
      expect: () => [
        isA<AuthLoading>(),
        unauthenticatedWith<InvalidInputFailure>(),
      ],
    );
  });

  group('SignOutEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated after signing out',
      setUp: () => when(() => signOut.execute()).thenAnswer((_) async {}),
      build: buildBloc,
      act: (bloc) => bloc.add(SignOutEvent()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'still emits unauthenticated when revocation fails',
      setUp: () => when(
        () => signOut.execute(),
      ).thenAnswer((_) => Future.error(Exception('offline'))),
      build: buildBloc,
      act: (bloc) => bloc.add(SignOutEvent()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
      errors: () => isEmpty,
    );
  });
}

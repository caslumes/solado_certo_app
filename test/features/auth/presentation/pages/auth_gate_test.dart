import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/auth_gate.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:solado_certo_app/features/splash/presentation/pages/splash_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;
  late StreamController<AuthState> states;

  Future<void> pumpGate(WidgetTester tester) => tester.pumpWidget(
    BlocProvider<AuthBloc>.value(
      value: bloc,
      child: MaterialApp(home: const AuthGate(), routes: AuthRoutes.routes),
    ),
  );

  Future<void> emit(WidgetTester tester, AuthState state) async {
    when(() => bloc.state).thenReturn(state);
    states.add(state);
    await tester.pump();
  }

  setUp(() {
    bloc = MockAuthBloc();
    states = StreamController<AuthState>();
    whenListen(bloc, states.stream, initialState: AuthInitial());
  });

  tearDown(() => states.close());

  testWidgets('shows the splash page while the session is being checked', (
    tester,
  ) async {
    await pumpGate(tester);

    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('shows the home page with a sign-in link when signed out', (
    tester,
  ) async {
    await pumpGate(tester);
    await emit(tester, AuthUnauthenticated());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(find.byTooltip('Meu perfil'), findsNothing);
  });

  Future<void> openSignIn(WidgetTester tester) async {
    await pumpGate(tester);
    await emit(tester, AuthUnauthenticated());
    await tester.tap(find.text('Entre na sua conta'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'swipes back from sign-in to the home page on iOS',
    (tester) async {
      await openSignIn(tester);

      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsNothing);
      expect(find.text('Entre na sua conta'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('keeps the sign-in form and its input through a failed sign-in', (
    tester,
  ) async {
    await openSignIn(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'maria@example.com',
    );

    await emit(tester, AuthLoading());
    expect(find.byType(SignInPage), findsOneWidget);

    await emit(tester, AuthUnauthenticated(failure: NetworkFailure()));
    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.text('maria@example.com'), findsOneWidget);
  });

  testWidgets('closes the sign-in page once signed in', (tester) async {
    final onboarding = Completer<OnboardingEntity>();
    final getOnboarding = MockGetOnboardingUseCase();
    when(getOnboarding.execute).thenAnswer((_) => onboarding.future);
    getIt
      ..registerSingleton<GetOnboardingUseCase>(getOnboarding)
      ..registerSingleton<GetProfileUseCase>(MockGetProfileUseCase())
      ..registerSingleton<UpdateProfileUseCase>(MockUpdateProfileUseCase())
      ..registerSingleton<GetAddressesUseCase>(MockGetAddressesUseCase())
      ..registerSingleton<GetPodologicalProfileUseCase>(
        MockGetPodologicalProfileUseCase(),
      )
      ..registerSingleton<SavePodologicalProfileUseCase>(
        MockSavePodologicalProfileUseCase(),
      )
      ..registerSingleton<GetPainPointsUseCase>(MockGetPainPointsUseCase())
      ..registerSingleton<HasPodologicalConsentUseCase>(
        MockHasPodologicalConsentUseCase(),
      )
      ..registerSingleton<ChangeOnboardingStepUseCase>(
        MockChangeOnboardingStepUseCase(),
      );
    addTearDown(getIt.reset);

    await openSignIn(tester);
    await emit(tester, AuthAuthenticated(user: buildProfile()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(SignInPage), findsNothing);
    expect(find.byType(HomePage), findsNothing);
  });
}

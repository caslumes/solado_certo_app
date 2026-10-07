import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/auth_gate.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:solado_certo_app/features/splash/presentation/pages/splash_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;
  late StreamController<AuthState> states;

  Future<void> pumpGate(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(value: bloc, child: const AuthGate()),
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

  testWidgets('keeps the sign-in form and its input through a failed sign-in', (
    tester,
  ) async {
    await pumpGate(tester);
    await emit(tester, AuthUnauthenticated());
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
}

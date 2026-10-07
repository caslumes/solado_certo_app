import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  final emailField = find.byType(TextFormField).at(0);
  final passwordField = find.byType(TextFormField).at(1);
  final submitButton = find.widgetWithText(FilledButton, 'ENTRAR');

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const SignInPage(),
      ),
    ),
  );

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
  }

  setUpAll(() {
    registerFallbackValue(SignInEvent(email: '', password: ''));
  });

  setUp(() {
    bloc = MockAuthBloc();
    when(() => bloc.state).thenReturn(AuthUnauthenticated());
  });

  testWidgets('shows field errors and does not submit an empty form', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapSubmit(tester);

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Campo obrigatório'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('submits a normalized e-mail and the raw password', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(emailField, '  Maria@Example.com ');
    await tester.enterText(passwordField, ' secret123');
    await tapSubmit(tester);

    final event =
        verify(() => bloc.add(captureAny())).captured.single as SignInEvent;
    expect(event.email, 'maria@example.com');
    expect(event.password, ' secret123');
  });

  testWidgets('disables the button and shows progress while loading', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(AuthLoading());
    await pumpPage(tester);

    expect(submitButton, findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('shows the failure message in a SnackBar', (tester) async {
    whenListen(
      bloc,
      Stream<AuthState>.fromIterable([
        AuthLoading(),
        AuthUnauthenticated(failure: InvalidCredentialsFailure()),
      ]),
      initialState: AuthUnauthenticated(),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
  });
}

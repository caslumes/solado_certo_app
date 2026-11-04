import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/password_recovery_cubit.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/forgot_password_page.dart';

class MockPasswordRecoveryCubit extends MockCubit<PasswordRecoveryState>
    implements PasswordRecoveryCubit {}

void main() {
  const email = 'maria@example.com';
  const codeStep = PasswordRecoveryState(email: email);

  late MockPasswordRecoveryCubit cubit;

  final emailField = find.descendant(
    of: find.byKey(const ValueKey('recovery-email')),
    matching: find.byType(TextFormField),
  );
  final codeField = find.descendant(
    of: find.byKey(const ValueKey('recovery-code')),
    matching: find.byType(TextFormField),
  );
  final passwordField = find.descendant(
    of: find.byKey(const ValueKey('recovery-password')),
    matching: find.byType(TextFormField),
  );

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider<PasswordRecoveryCubit>.value(
                  value: cubit,
                  child: const ForgotPasswordPage(),
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );

  Future<void> openPage(WidgetTester tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
  }

  setUp(() {
    cubit = MockPasswordRecoveryCubit();
    when(() => cubit.state).thenReturn(const PasswordRecoveryState());
    when(() => cubit.requestCode(any())).thenAnswer((_) async {});
    when(() => cubit.resetPassword(any(), any())).thenAnswer((_) async {});
  });

  testWidgets('does not request a code without a valid e-mail', (tester) async {
    await openPage(tester);

    await tapSubmit(tester);

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    verifyNever(() => cubit.requestCode(any()));
  });

  testWidgets('requests the code with a normalized e-mail', (tester) async {
    await openPage(tester);

    await tester.enterText(emailField, '  Maria@Example.com ');
    await tapSubmit(tester);

    verify(() => cubit.requestCode(email)).called(1);
  });

  testWidgets('validates the code and the new password', (tester) async {
    when(() => cubit.state).thenReturn(codeStep);
    await openPage(tester);

    await tester.enterText(codeField, '123');
    await tester.enterText(passwordField, 'short');
    await tapSubmit(tester);

    expect(find.text('O código tem 6 dígitos'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 8 caracteres'),
      findsOneWidget,
    );
    verifyNever(() => cubit.resetPassword(any(), any()));
  });

  testWidgets('submits the code and the raw new password', (tester) async {
    when(() => cubit.state).thenReturn(codeStep);
    await openPage(tester);

    await tester.enterText(codeField, ' 123456 ');
    await tester.enterText(passwordField, ' new-secret');
    await tapSubmit(tester);

    verify(() => cubit.resetPassword('123456', ' new-secret')).called(1);
  });

  testWidgets('resends the code to the same e-mail', (tester) async {
    when(() => cubit.state).thenReturn(codeStep);
    await openPage(tester);

    await tester.ensureVisible(find.text('Reenviar código'));
    await tester.tap(find.text('Reenviar código'));
    await tester.pump();

    verify(() => cubit.requestCode(email)).called(1);
  });

  testWidgets('shows the failure message in a SnackBar', (tester) async {
    whenListen(
      cubit,
      Stream<PasswordRecoveryState>.fromIterable([
        PasswordRecoveryState(email: email, failure: InvalidResetCodeFailure()),
      ]),
      initialState: codeStep,
    );
    await openPage(tester);

    expect(find.text('Código inválido ou expirado.'), findsOneWidget);
  });

  testWidgets('goes back with a confirmation when the password changes', (
    tester,
  ) async {
    whenListen(
      cubit,
      Stream<PasswordRecoveryState>.fromIterable([
        const PasswordRecoveryState(email: email, done: true),
      ]),
      initialState: codeStep,
    );
    await openPage(tester);

    expect(find.byType(ForgotPasswordPage), findsNothing);
    expect(
      find.text('Senha alterada! Entre com a nova senha.'),
      findsOneWidget,
    );
  });
}

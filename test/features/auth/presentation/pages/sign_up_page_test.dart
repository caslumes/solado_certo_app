import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_up_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  const accountExistsMessage =
      'E-mail ou telefone já cadastrado. Faça login ou recupere sua senha.';

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const SignUpPage(),
      ),
    ),
  );

  setUp(() {
    bloc = MockAuthBloc();
    when(() => bloc.state).thenReturn(AuthUnauthenticated());
  });

  testWidgets('shows an existing account under the form, not in a SnackBar', (
    tester,
  ) async {
    whenListen(
      bloc,
      Stream<AuthState>.fromIterable([
        AuthLoading(),
        AuthUnauthenticated(failure: AccountAlreadyExistsFailure()),
      ]),
      initialState: AuthUnauthenticated(),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(find.text(accountExistsMessage), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows other failures in a SnackBar', (tester) async {
    whenListen(
      bloc,
      Stream<AuthState>.fromIterable([
        AuthLoading(),
        AuthUnauthenticated(failure: NetworkFailure()),
      ]),
      initialState: AuthUnauthenticated(),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(accountExistsMessage), findsNothing);
  });

  testWidgets('clears the message while a new submission is loading', (
    tester,
  ) async {
    whenListen(
      bloc,
      Stream<AuthState>.fromIterable([
        AuthUnauthenticated(failure: AccountAlreadyExistsFailure()),
        AuthLoading(),
      ]),
      initialState: AuthUnauthenticated(),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(find.text(accountExistsMessage), findsNothing);
  });
}

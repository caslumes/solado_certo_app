import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';

import '../../../../support/builders.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  Future<void> pumpHome(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const HomePage(isSignedIn: true),
      ),
    ),
  );

  setUpAll(() => registerFallbackValue(SignOutEvent()));

  setUp(() {
    bloc = MockAuthBloc();
    when(() => bloc.state).thenReturn(AuthAuthenticated(user: buildProfile()));
  });

  testWidgets('shows the profile shortcut instead of the sign-in link', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byTooltip('Meu perfil'), findsOneWidget);
    expect(find.text('Entre na sua conta'), findsNothing);
  });

  testWidgets('signs out', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('SAIR'));

    verify(() => bloc.add(any(that: isA<SignOutEvent>()))).called(1);
  });
}

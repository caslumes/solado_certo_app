import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_shell.dart';

import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  Future<void> pumpShell(WidgetTester tester, {required bool isSignedIn}) =>
      tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp(
            home: HomeShell(isSignedIn: isSignedIn),
            routes: AuthRoutes.routes,
          ),
        ),
      );

  Future<void> selectTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    bloc = MockAuthBloc();
    when(() => bloc.state).thenReturn(AuthUnauthenticated());
    registerCatalogFilterOptions();
  });

  testWidgets('starts on the catalog tab', (tester) async {
    await pumpShell(tester, isSignedIn: false);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Carrinho'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
  });

  testWidgets('switches tabs when signed in', (tester) async {
    await pumpShell(tester, isSignedIn: true);

    await selectTab(tester, 'Carrinho');

    expect(find.text('Em breve'), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);

    await selectTab(tester, 'Catálogo');

    expect(find.text('Em breve'), findsNothing);
  });

  testWidgets('asks to sign in before opening the orders when signed out', (
    tester,
  ) async {
    await pumpShell(tester, isSignedIn: false);

    await selectTab(tester, 'Pedidos');

    expect(find.byType(SignInPage), findsOneWidget);
  });
}

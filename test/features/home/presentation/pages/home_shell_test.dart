import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/cart/presentation/pages/cart_page.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_shell.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;
  late MockGetRecommendedItemsUseCase recommendations;
  late MockCartBloc cartBloc;

  Future<void> pumpShell(WidgetTester tester, {required bool isSignedIn}) =>
      tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: bloc),
            BlocProvider<CartBloc>.value(value: cartBloc),
          ],
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
    recommendations = registerRecommendedItems();
    cartBloc = buildCartBloc();
    registerFallbackValue(LoadCartEvent());
  });

  testWidgets('shows "Para você" when signed in with matching items', (
    tester,
  ) async {
    when(
      recommendations.execute,
    ).thenAnswer((_) async => [buildCatalogItem(id: '603')]);
    await pumpShell(tester, isSignedIn: true);
    await tester.pump();

    expect(find.text('Para você'), findsOneWidget);
    expect(find.text('Palmilha 603'), findsOneWidget);
  });

  testWidgets('hides "Para você" when there are no matches', (tester) async {
    await pumpShell(tester, isSignedIn: true);
    await tester.pump();

    verify(recommendations.execute).called(1);
    expect(find.text('Para você'), findsNothing);
  });

  testWidgets('does not ask for "Para você" when signed out', (tester) async {
    when(recommendations.execute).thenAnswer((_) async => [buildCatalogItem()]);
    await pumpShell(tester, isSignedIn: false);
    await tester.pump();

    verifyNever(recommendations.execute);
    expect(find.text('Para você'), findsNothing);
  });

  testWidgets('starts on the catalog tab', (tester) async {
    await pumpShell(tester, isSignedIn: false);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Carrinho'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
  });

  testWidgets('switches tabs when signed in', (tester) async {
    when(() => cartBloc.state).thenReturn(CartLoaded(cart: buildCart({})));
    await pumpShell(tester, isSignedIn: true);

    await selectTab(tester, 'Carrinho');

    expect(find.byType(CartPage), findsOneWidget);
    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);

    await selectTab(tester, 'Pedidos');

    expect(find.text('Em breve'), findsOneWidget);
  });

  testWidgets('loads the cart when signed in and again on its tab', (
    tester,
  ) async {
    await pumpShell(tester, isSignedIn: true);

    verify(() => cartBloc.add(any(that: isA<LoadCartEvent>()))).called(1);

    await selectTab(tester, 'Carrinho');

    verify(() => cartBloc.add(any(that: isA<LoadCartEvent>()))).called(1);
  });

  testWidgets('clears the cart when the user signs out', (tester) async {
    await pumpShell(tester, isSignedIn: true);
    await pumpShell(tester, isSignedIn: false);

    verify(() => cartBloc.add(any(that: isA<ClearCartEvent>()))).called(1);
  });

  testWidgets('does not load the cart when signed out', (tester) async {
    await pumpShell(tester, isSignedIn: false);

    verifyNever(() => cartBloc.add(any()));
  });

  testWidgets('shows the units in the cart on its tab', (tester) async {
    when(() => cartBloc.state).thenReturn(
      CartLoaded(
        cart: buildCart({
          's1': [buildCartItem(quantity: 2)],
          's2': [buildCartItem(id: '602', quantity: 1)],
        }),
      ),
    );
    await pumpShell(tester, isSignedIn: true);

    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('3')),
      findsOneWidget,
    );
  });

  testWidgets('hides the badge with an empty cart', (tester) async {
    when(() => cartBloc.state).thenReturn(CartLoaded(cart: buildCart({})));
    await pumpShell(tester, isSignedIn: true);

    final badge = tester.widget<Badge>(find.byType(Badge).first);
    expect(badge.isLabelVisible, isFalse);
  });

  testWidgets('asks to sign in before opening the orders when signed out', (
    tester,
  ) async {
    await pumpShell(tester, isSignedIn: false);

    await selectTab(tester, 'Pedidos');

    expect(find.byType(SignInPage), findsOneWidget);
  });
}

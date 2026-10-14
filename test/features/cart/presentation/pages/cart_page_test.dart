import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/cart/domain/enum/cart_item_problem.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/cart/presentation/pages/cart_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockCartBloc bloc;
  late MockAuthBloc authBloc;
  late StreamController<CartState> states;

  final cart = buildCart({
    'João': [buildCartItem(quantity: 2), buildCartItem(id: '602', price: 10)],
    'Ana': [buildCartItem(id: '603', price: 50, stock: 1)],
  });

  Future<void> pumpPage(
    WidgetTester tester,
    CartState state, {
    VoidCallback? onCheckout,
  }) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(state);
    return tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartBloc>.value(value: bloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(home: CartPage(onCheckout: onCheckout)),
      ),
    );
  }

  Finder itemTile(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'CartItemTile',
    ),
  );

  setUpAll(() {
    initializeFormatting();
    registerFallbackValue(LoadCartEvent());
    registerFallbackValue(SignOutEvent());
  });

  setUp(() {
    bloc = MockCartBloc();
    authBloc = MockAuthBloc();
    states = StreamController<CartState>.broadcast();
    addTearDown(states.close);
    when(() => bloc.stream).thenAnswer((_) => states.stream);
  });

  testWidgets('groups the items by seller with subtotals', (tester) async {
    await pumpPage(tester, CartLoaded(cart: cart));

    expect(find.text('Vendido por Loja João'), findsOneWidget);
    expect(find.text('Vendido por Loja Ana'), findsOneWidget);
    expect(find.text('Palmilha 601'), findsOneWidget);
    expect(find.text('Palmilha 602'), findsOneWidget);
    expect(find.text('Palmilha 603'), findsOneWidget);
    expect(find.text(formatCurrency(189.8)), findsOneWidget);
    expect(find.text(formatCurrency(50)), findsWidgets);
    expect(find.text('Subtotal (4 itens)'), findsOneWidget);
    expect(find.text(formatCurrency(239.8)), findsOneWidget);
    expect(find.text('O frete é escolhido no checkout.'), findsOneWidget);
  });

  testWidgets('changes the quantity and removes an item', (tester) async {
    await pumpPage(tester, CartLoaded(cart: cart));

    await tester.tap(
      find.descendant(
        of: itemTile('Palmilha 601'),
        matching: find.byTooltip('Aumentar quantidade'),
      ),
    );
    verify(
      () => bloc.add(
        any(
          that: isA<ChangeCartItemQuantityEvent>()
              .having((e) => e.advertisementId, 'id', '601')
              .having((e) => e.quantity, 'quantity', 3),
        ),
      ),
    ).called(1);

    await tester.tap(
      find.descendant(
        of: itemTile('Palmilha 601'),
        matching: find.byTooltip('Diminuir quantidade'),
      ),
    );
    verify(
      () => bloc.add(
        any(
          that: isA<ChangeCartItemQuantityEvent>().having(
            (e) => e.quantity,
            'quantity',
            1,
          ),
        ),
      ),
    ).called(1);

    await tester.tap(
      find.descendant(
        of: itemTile('Palmilha 602'),
        matching: find.byTooltip('Remover do carrinho'),
      ),
    );
    verify(
      () => bloc.add(
        any(
          that: isA<RemoveCartItemEvent>().having(
            (e) => e.advertisementId,
            'id',
            '602',
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('cannot go over the stock or under one unit', (tester) async {
    await pumpPage(tester, CartLoaded(cart: cart));

    final tile = itemTile('Palmilha 603');
    final plus = tester.widget<IconButton>(
      find.descendant(
        of: tile,
        matching: find.widgetWithIcon(IconButton, Icons.add),
      ),
    );
    final minus = tester.widget<IconButton>(
      find.descendant(
        of: tile,
        matching: find.widgetWithIcon(IconButton, Icons.remove),
      ),
    );
    expect(plus.onPressed, isNull);
    expect(minus.onPressed, isNull);
  });

  testWidgets('flags items with problems and blocks continuing', (
    tester,
  ) async {
    final withProblems = buildCart({
      'João': [
        buildCartItem(
          quantity: 3,
          stock: 2,
          problem: CartItemProblem.insufficientStock,
        ),
        buildCartItem(id: '602', problem: CartItemProblem.unavailable),
        buildCartItem(id: '603', price: 50, addedPrice: 40),
      ],
    });
    await pumpPage(tester, CartLoaded(cart: withProblems), onCheckout: () {});

    expect(find.text('Só há 2 unidades disponíveis'), findsOneWidget);
    expect(find.text('Indisponível no momento'), findsOneWidget);
    expect(
      find.textContaining('Alguns itens estão indisponíveis'),
      findsOneWidget,
    );
    expect(find.textContaining('Alguns preços mudaram'), findsOneWidget);
    expect(
      find.text('O preço mudou desde que você adicionou.'),
      findsOneWidget,
    );
    expect(find.text(formatCurrency(40)), findsOneWidget);

    final continueButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('CONTINUAR'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(continueButton.onPressed, isNull);

    final plus = tester.widget<IconButton>(
      find.descendant(
        of: itemTile('Palmilha 601'),
        matching: find.widgetWithIcon(IconButton, Icons.add),
      ),
    );
    final minus = tester.widget<IconButton>(
      find.descendant(
        of: itemTile('Palmilha 601'),
        matching: find.widgetWithIcon(IconButton, Icons.remove),
      ),
    );
    expect(plus.onPressed, isNull, reason: 'a short item cannot be raised');
    expect(minus.onPressed, isNotNull, reason: 'but can be lowered');
  });

  testWidgets('continues when every item can be bought', (tester) async {
    var started = false;
    await pumpPage(
      tester,
      CartLoaded(cart: cart),
      onCheckout: () => started = true,
    );

    await tester.tap(find.text('CONTINUAR'));

    expect(started, isTrue);
  });

  testWidgets('disables the items while one is changing', (tester) async {
    await pumpPage(tester, CartLoaded(cart: cart, busyItemId: '601'));

    expect(
      find.descendant(
        of: itemTile('Palmilha 601'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    final remove = tester.widget<IconButton>(
      find.descendant(
        of: itemTile('Palmilha 602'),
        matching: find.widgetWithIcon(IconButton, Icons.delete_outline),
      ),
    );
    expect(remove.onPressed, isNull);
  });

  testWidgets('shows the empty cart', (tester) async {
    await pumpPage(tester, CartLoaded(cart: buildCart({})));

    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsNothing);
  });

  testWidgets('retries after a load failure', (tester) async {
    await pumpPage(tester, CartLoadFailure(failure: NetworkFailure()));

    expect(find.text(NetworkFailure().message), findsOneWidget);
    await tester.tap(find.text('TENTAR NOVAMENTE'));

    verify(() => bloc.add(any(that: isA<LoadCartEvent>()))).called(1);
  });

  testWidgets('shows notices and failures of the cart actions', (tester) async {
    await pumpPage(tester, CartLoaded(cart: cart));

    states.add(CartLoaded(cart: cart, notice: 'Produto removido do carrinho.'));
    await tester.pump();
    expect(find.text('Produto removido do carrinho.'), findsOneWidget);

    states.add(
      CartLoaded(
        cart: cart,
        failure: const OutOfStockFailure([
          StockShortage(advertisementId: '601', requested: 3, available: 2),
        ]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Só há 2 unidades disponíveis.'), findsOneWidget);
  });

  testWidgets('signs out when the session expired', (tester) async {
    await pumpPage(tester, CartLoaded(cart: cart));

    states.add(CartLoaded(cart: cart, failure: UnauthorizedFailure()));
    await tester.pump();

    verify(() => authBloc.add(any(that: isA<SignOutEvent>()))).called(1);
  });
}

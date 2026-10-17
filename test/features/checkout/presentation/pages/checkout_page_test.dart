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
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:solado_certo_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:solado_certo_app/features/checkout/presentation/pages/order_confirmation_page.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetAddressesUseCase getAddresses;
  late MockPreviewCheckoutUseCase preview;
  late MockCheckoutUseCase checkout;
  late MockCartBloc cartBloc;
  late MockAuthBloc authBloc;

  final cart = buildCart({
    's1': [buildCartItem(quantity: 2)],
    's2': [buildCartItem(id: '602')],
  });

  /// Opens checkout over a page standing in for the cart, like the app does.
  Future<void> pumpCheckout(
    WidgetTester tester, {
    Future<AddressEntity> Function(NewAddress)? addAddress,
    VoidCallback? onViewOrders,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartBloc>.value(value: cartBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider(
                      create: (_) => CheckoutBloc(
                        cart: cart,
                        getAddressesUseCase: getAddresses,
                        previewCheckoutUseCase: preview,
                        checkoutUseCase: checkout,
                        newKey: () => 'key-1',
                      )..add(LoadCheckoutEvent()),
                      child: CheckoutPage(
                        addAddress:
                            addAddress ?? (_) async => buildAddress(id: 'new'),
                        onViewOrders: onViewOrders,
                      ),
                    ),
                  ),
                ),
                child: const Text('Carrinho de teste'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Carrinho de teste'));
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(find.text(text.toUpperCase()));
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    initializeFormatting();
    registerFallbackValue(const CheckoutSelection(addressId: '', shipping: {}));
    registerFallbackValue(LoadCartEvent());
  });

  setUp(() {
    getAddresses = MockGetAddressesUseCase();
    preview = MockPreviewCheckoutUseCase();
    checkout = MockCheckoutUseCase();
    cartBloc = buildCartBloc(CartLoaded(cart: cart));
    authBloc = MockAuthBloc();
    when(getAddresses.execute).thenAnswer(
      (_) async => [
        buildAddress(id: 'a1'),
        buildAddress(id: 'a2', label: 'Trabalho', isDefault: true),
      ],
    );
    when(
      () => preview.execute(any()),
    ).thenAnswer((_) async => buildCheckoutPlan(sellers: ['s1', 's2']));
  });

  testWidgets('goes through address, shipping and summary to the orders', (
    tester,
  ) async {
    final result = buildCheckoutResult(
      orders: [
        buildOrder(number: 'SC-20261014-AAAAAA'),
        buildOrder(id: 'o2', number: 'SC-20261014-BBBBBB', seller: 's2'),
      ],
    );
    when(() => checkout.execute(any(), any())).thenAnswer((_) async => result);
    var viewedOrders = false;
    await pumpCheckout(tester, onViewOrders: () => viewedOrders = true);

    expect(find.text('Onde você quer receber?'), findsOneWidget);
    final chosen = find.ancestor(
      of: find.text('Trabalho'),
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(chosen).selected, isTrue);
    await tester.tap(find.text('Casa'));
    await tester.pump();

    await tapButton(tester, 'Próximo');
    expect(find.text('Vendido por Loja s1'), findsOneWidget);
    expect(find.text('Vendido por Loja s2'), findsOneWidget);
    expect(find.text('2 × Palmilha 601'), findsOneWidget);
    expect(find.text('PAC (Correios)'), findsNWidgets(2));
    expect(find.text('Até 7 dias úteis'), findsNWidgets(2));
    expect(find.text('Frete deste vendedor'), findsNWidgets(2));

    await tapButton(tester, 'Próximo');
    expect(find.text('Pedido de Loja s1'), findsOneWidget);
    expect(find.text('Pedido de Loja s2'), findsOneWidget);
    expect(
      find.text('Serão criados 2 pedidos, um para cada vendedor.'),
      findsOneWidget,
    );
    expect(find.text(formatCurrency(219.6)), findsOneWidget);
    final selection =
        verify(() => preview.execute(captureAny())).captured.single
            as CheckoutSelection;
    expect(selection.addressId, 'a1');
    expect(selection.shipping, {'601': 'pac', '602': 'pac'});

    await tapButton(tester, 'Confirmar pedido');
    verify(() => checkout.execute(any(), 'key-1')).called(1);
    verify(() => cartBloc.add(any(that: isA<LoadCartEvent>()))).called(1);
    expect(find.byType(OrderConfirmationPage), findsOneWidget);
    expect(find.text('Seus pedidos foram criados!'), findsOneWidget);
    expect(find.text('Pedido SC-20261014-AAAAAA'), findsOneWidget);
    expect(find.text('Pedido SC-20261014-BBBBBB'), findsOneWidget);
    expect(find.text('Loja s1 · Aguardando pagamento'), findsOneWidget);

    expect(find.text('PAGAR PEDIDO 1 DE 2'), findsOneWidget);
    await tester.tap(find.text('Ver meus pedidos'));
    await tester.pumpAndSettle();
    expect(viewedOrders, isTrue);
    expect(find.text('Carrinho de teste'), findsOneWidget);
  });

  testWidgets('"Voltar" sits above "Próximo" and goes back a step', (
    tester,
  ) async {
    await pumpCheckout(tester);
    expect(find.text('VOLTAR'), findsNothing);

    await tapButton(tester, 'Próximo');
    expect(
      tester.getTopLeft(find.text('VOLTAR')).dy,
      lessThan(tester.getTopLeft(find.text('PRÓXIMO')).dy),
    );

    await tapButton(tester, 'Voltar');
    expect(find.text('Onde você quer receber?'), findsOneWidget);
  });

  testWidgets('without addresses, adds one and continues with it', (
    tester,
  ) async {
    when(getAddresses.execute).thenAnswer((_) async => []);
    NewAddress? sent;
    await pumpCheckout(
      tester,
      addAddress: (address) async {
        sent = address;
        return buildAddress(id: 'new', label: 'Nova casa');
      },
    );

    expect(
      find.text('Cadastre um endereço para receber seus pedidos.'),
      findsOneWidget,
    );
    final next = find.ancestor(
      of: find.text('PRÓXIMO'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(next).onPressed, isNull);

    await tester.tap(find.text('ADICIONAR ENDEREÇO'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Maria Souza');
    await tester.enterText(fields.at(2), '13010-111');
    await tester.enterText(fields.at(3), 'Rua das Flores');
    await tester.enterText(fields.at(4), '10');
    await tester.enterText(fields.at(6), 'Centro');
    await tester.enterText(fields.at(7), 'Campinas');
    await tester.enterText(fields.at(8), 'SP');
    final save = find.text('SALVAR ENDEREÇO');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(sent?.isDefault, isTrue);
    expect(find.text('Nova casa'), findsOneWidget);
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
  });

  testWidgets('a stock conflict says what changed and returns to the cart', (
    tester,
  ) async {
    final current = buildCart({
      's1': [
        buildCartItem(
          quantity: 2,
          stock: 1,
          problem: CartItemProblem.insufficientStock,
        ),
      ],
      's2': [buildCartItem(id: '602')],
    });
    when(() => preview.execute(any())).thenThrow(
      CheckoutConflict(failure: const OutOfStockFailure([]), cart: current),
    );
    await pumpCheckout(tester);

    await tapButton(tester, 'Próximo');
    await tapButton(tester, 'Próximo');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Alguns produtos não têm estoque suficiente.'),
      findsOneWidget,
    );
    expect(
      find.text('• Palmilha 601: Só há 1 unidade disponível'),
      findsOneWidget,
    );
    final updated =
        verify(
              () => cartBloc.add(captureAny(that: isA<CartUpdatedEvent>())),
            ).captured.single
            as CartUpdatedEvent;
    expect(updated.cart, same(current));

    await tester.tap(find.text('Ver carrinho'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutPage), findsNothing);
    expect(find.text('Carrinho de teste'), findsOneWidget);
    verifyNever(() => checkout.execute(any(), any()));
  });

  testWidgets('a failed confirmation stays on the summary to retry', (
    tester,
  ) async {
    when(() => checkout.execute(any(), any())).thenThrow(ServerFailure(500));
    await pumpCheckout(tester);

    await tapButton(tester, 'Próximo');
    await tapButton(tester, 'Próximo');
    await tapButton(tester, 'Confirmar pedido');

    expect(
      find.text('Erro no servidor. Tente novamente mais tarde.'),
      findsOneWidget,
    );
    expect(find.text('Pedido de Loja s1'), findsOneWidget);
    expect(find.byType(OrderConfirmationPage), findsNothing);
  });

  testWidgets('shows a load error with retry', (tester) async {
    when(getAddresses.execute).thenThrow(NetworkFailure());
    await pumpCheckout(tester);

    expect(
      find.text(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      ),
      findsOneWidget,
    );

    when(getAddresses.execute).thenAnswer((_) async => [buildAddress()]);
    await tapButton(tester, 'Tentar novamente');
    expect(find.text('Onde você quer receber?'), findsOneWidget);
  });

  testWidgets('a single order says so on the confirmation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OrderConfirmationPage(result: buildCheckoutResult())),
    );

    expect(find.text('Seu pedido foi criado!'), findsOneWidget);
    expect(find.text('PAGAR AGORA'), findsOneWidget);
    expect(find.text('VER MEUS PEDIDOS'), findsNothing);
    expect(find.text('Continuar comprando'), findsOneWidget);
  });

  testWidgets("the confirmation pays each seller's order in turn", (
    tester,
  ) async {
    final paying = <(String, String?)>[];
    var paid = true;
    await tester.pumpWidget(
      MaterialApp(
        home: OrderConfirmationPage(
          result: buildCheckoutResult(
            orders: [
              buildOrder(id: 'o1', number: 'SC-20261014-AAAAAA'),
              buildOrder(id: 'o2', number: 'SC-20261014-BBBBBB', seller: 's2'),
            ],
          ),
          onViewOrders: () {},
          pay: (_, order, position) async {
            paying.add((order.id, position));
            return paid;
          },
        ),
      ),
    );
    expect(
      find.text(
        'Cada vendedor recebe um pagamento separado. Os produtos ficam '
        'reservados até o pagamento, que você pode fazer agora ou depois, '
        'pela tela de cada pedido.',
      ),
      findsOneWidget,
    );

    await tapButton(tester, 'Pagar pedido 1 de 2');
    expect(find.text('Loja s1 · Pago'), findsOneWidget);
    expect(find.text('Loja s2 · Aguardando pagamento'), findsOneWidget);

    paid = false;
    await tapButton(tester, 'Pagar pedido 2 de 2');
    expect(find.text('Loja s2 · Aguardando pagamento'), findsOneWidget);

    paid = true;
    await tapButton(tester, 'Pagar pedido 2 de 2');
    expect(find.text('Loja s2 · Pago'), findsOneWidget);
    expect(find.textContaining('PAGAR PEDIDO'), findsNothing);
    expect(find.text('VER MEUS PEDIDOS'), findsOneWidget);
    expect(paying, [('o1', '1 de 2'), ('o2', '2 de 2'), ('o2', '2 de 2')]);
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_checkout_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_checkout_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetAddressesUseCase getAddresses;
  late MockGetProductDetailUseCase getProduct;
  late MockCheckoutCustomOrderUseCase checkout;
  late MockAddAddressUseCase addAddress;
  late List<String> openedOrders;

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: MockAuthBloc(),
        child: MaterialApp(
          home: BlocProvider(
            create: (_) => CustomOrderCheckoutCubit(
              getAddressesUseCase: getAddresses,
              getProductDetailUseCase: getProduct,
              checkoutUseCase: checkout,
              request: buildCustomOrder(
                status: CustomOrderStatus.approved,
                quotedPrice: 320,
              ),
              newKey: () => 'k1',
            )..load(),
            child: CustomOrderCheckoutPage(
              addAddress: addAddress.execute,
              openOrder: (_, orderId) => openedOrders.add(orderId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(initializeFormatting);

  setUp(() {
    getAddresses = MockGetAddressesUseCase();
    getProduct = MockGetProductDetailUseCase();
    checkout = MockCheckoutCustomOrderUseCase();
    addAddress = MockAddAddressUseCase();
    openedOrders = [];
    when(getAddresses.execute).thenAnswer(
      (_) async => [
        buildAddress(isDefault: true),
        buildAddress(id: 'a2', label: 'Trabalho'),
      ],
    );
    when(
      () => getProduct.execute('603'),
    ).thenAnswer((_) async => buildProductDetail());
  });

  testWidgets('shows the quoted price with the shipping and confirms', (
    tester,
  ) async {
    when(
      () => checkout.execute(
        'c1',
        addressId: 'a2',
        shippingOptionId: '701',
        idempotencyKey: 'k1',
      ),
    ).thenAnswer(
      (_) async => buildCustomOrderDetail(
        status: CustomOrderStatus.approved,
        orderId: 'o1',
        actions: const {},
      ),
    );
    await pumpPage(tester);

    expect(find.text('Palmilha sob medida'), findsOneWidget);
    expect(find.text(formatCurrency(320)), findsOneWidget);
    expect(find.text(formatCurrency(19.9)), findsNWidgets(2));
    expect(find.text(formatCurrency(339.9)), findsOneWidget);
    await tester.tap(find.text('Trabalho'));
    await tester.pump();
    await tester.tap(find.text('CONFIRMAR PEDIDO'));
    await tester.pumpAndSettle();

    expect(openedOrders, ['o1']);
    expect(find.text('Pedido criado. Agora é só pagar.'), findsOneWidget);
  });

  testWidgets('without an address the order cannot be confirmed', (
    tester,
  ) async {
    when(getAddresses.execute).thenAnswer((_) async => []);
    await pumpPage(tester);

    expect(
      find.text('Cadastre um endereço para receber o pedido.'),
      findsOneWidget,
    );
    await tester.tap(find.text('CONFIRMAR PEDIDO'));
    await tester.pumpAndSettle();

    verifyNever(
      () => checkout.execute(
        any(),
        addressId: any(named: 'addressId'),
        shippingOptionId: any(named: 'shippingOptionId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    );
  });

  testWidgets('explains when the ad is gone', (tester) async {
    when(
      () => getProduct.execute('603'),
    ).thenThrow(buildDioException(statusCode: 404));
    await pumpPage(tester);

    expect(
      find.text('O anúncio deste item não está mais disponível.'),
      findsOneWidget,
    );
  });
}

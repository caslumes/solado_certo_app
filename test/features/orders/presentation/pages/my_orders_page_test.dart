import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/my_orders_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetOrdersUseCase getOrders;
  late MockAuthBloc authBloc;
  late OrdersBloc bloc;

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(800, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bloc = OrdersBloc(getOrdersUseCase: getOrders);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<OrdersBloc>.value(value: bloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MaterialApp(home: MyOrdersPage()),
      ),
    );
    // The home shell loads the orders when the tab is opened, after the
    // page was built.
    bloc.add(LoadOrdersEvent());
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    initializeFormatting();
    registerFallbackValue(SignOutEvent());
  });

  setUp(() {
    getOrders = MockGetOrdersUseCase();
    authBloc = MockAuthBloc();
  });

  testWidgets('lists the orders with number, items, seller, date and status', (
    tester,
  ) async {
    when(() => getOrders.execute(1, filter: const OrderFilter())).thenAnswer(
      (_) async => OrdersPageEntity(
        items: [
          buildOrder(
            number: 'SC-20261014-AAAAAA',
            items: [
              buildOrderItem(),
              buildOrderItem(id: '602'),
            ],
          ),
          buildOrder(
            id: 'o2',
            number: 'SC-20261013-BBBBBB',
            seller: 's2',
            status: OrderStatus.cancelled,
          ),
        ],
        currentPage: 1,
        hasNext: false,
      ),
    );
    await pumpPage(tester);

    expect(find.text('Pedido SC-20261014-AAAAAA'), findsOneWidget);
    expect(find.text('Palmilha 601 e mais 1 item'), findsOneWidget);
    expect(find.text('Loja s1 · 14/10/2026'), findsOneWidget);
    expect(find.text('Aguardando pagamento'), findsOneWidget);
    expect(find.text('Pedido SC-20261013-BBBBBB'), findsOneWidget);
    expect(find.text('Palmilha 601'), findsOneWidget);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.text(formatCurrency(109.8)), findsNWidgets(2));
  });

  testWidgets('loads the next page when scrolled to the end', (tester) async {
    when(() => getOrders.execute(1, filter: const OrderFilter())).thenAnswer(
      (_) async => OrdersPageEntity(
        items: [
          for (var i = 0; i < 10; i++) buildOrder(id: 'o$i', number: 'N$i'),
        ],
        currentPage: 1,
        hasNext: true,
      ),
    );
    when(() => getOrders.execute(2, filter: const OrderFilter())).thenAnswer(
      (_) async => OrdersPageEntity(
        items: [buildOrder(id: 'o10', number: 'N10')],
        currentPage: 2,
        hasNext: false,
      ),
    );
    await pumpPage(tester, size: const Size(800, 600));
    verifyNever(() => getOrders.execute(2, filter: const OrderFilter()));

    await tester.scrollUntilVisible(find.text('Pedido N9'), 300);
    await tester.pumpAndSettle();

    verify(() => getOrders.execute(2, filter: const OrderFilter())).called(1);
    await tester.scrollUntilVisible(find.text('Pedido N10'), 300);
    expect(find.text('Pedido N10'), findsOneWidget);
  });

  testWidgets('says when there are no orders', (tester) async {
    when(() => getOrders.execute(1, filter: const OrderFilter())).thenAnswer(
      (_) async =>
          const OrdersPageEntity(items: [], currentPage: 1, hasNext: false),
    );
    await pumpPage(tester);

    expect(find.text('Você ainda não fez pedidos'), findsOneWidget);
  });

  testWidgets('shows a load error with retry', (tester) async {
    when(
      () => getOrders.execute(1, filter: const OrderFilter()),
    ).thenThrow(NetworkFailure());
    await pumpPage(tester);

    expect(
      find.text(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      ),
      findsOneWidget,
    );

    when(() => getOrders.execute(1, filter: const OrderFilter())).thenAnswer(
      (_) async => OrdersPageEntity(
        items: [buildOrder()],
        currentPage: 1,
        hasNext: false,
      ),
    );
    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pumpAndSettle();
    expect(find.text('Pedido SC-20261014-ABC123'), findsOneWidget);
  });

  testWidgets('signs out when the session expired', (tester) async {
    when(
      () => getOrders.execute(1, filter: const OrderFilter()),
    ).thenAnswer((_) async => throw UnauthorizedFailure());
    await pumpPage(tester);

    verify(() => authBloc.add(any(that: isA<SignOutEvent>()))).called(1);
  });

  testWidgets('a cancel on the detail page updates the list', (tester) async {
    final getOrder = MockGetOrderUseCase();
    final cancelOrder = MockCancelOrderUseCase();
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail());
    when(
      () => cancelOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail(cancelled: true));
    final getPayments = MockGetPaymentsUseCase();
    when(() => getPayments.execute('o1')).thenAnswer((_) async => []);
    getIt
      ..registerSingleton<GetOrderUseCase>(getOrder)
      ..registerSingleton<CancelOrderUseCase>(cancelOrder)
      ..registerSingleton<ConfirmDeliveryUseCase>(MockConfirmDeliveryUseCase())
      ..registerSingleton<GetPaymentsUseCase>(getPayments);
    addTearDown(getIt.reset);
    when(() => getOrders.execute(1, filter: const OrderFilter())).thenAnswer(
      (_) async => OrdersPageEntity(
        items: [buildOrder()],
        currentPage: 1,
        hasNext: false,
      ),
    );
    await pumpPage(tester);

    await tester.tap(find.text('Pedido SC-20261014-ABC123'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailPage), findsOneWidget);

    await tester.tap(find.text('Cancelar pedido'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar pedido'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailPage), findsNothing);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.text('Aguardando pagamento'), findsNothing);
  });

  testWidgets('filters by status and period, and clears (RF-025)', (
    tester,
  ) async {
    const filter = OrderFilter(
      status: OrderStatus.delivered,
      period: OrderPeriod.last30Days,
    );
    when(() => getOrders.execute(1, filter: const OrderFilter())).thenAnswer(
      (_) async => OrdersPageEntity(
        items: [buildOrder()],
        currentPage: 1,
        hasNext: false,
      ),
    );
    when(() => getOrders.execute(1, filter: filter)).thenAnswer(
      (_) async =>
          const OrdersPageEntity(items: [], currentPage: 1, hasNext: false),
    );
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Filtrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entregue'));
    await tester.tap(find.text('Últimos 30 dias'));
    await tester.tap(find.text('APLICAR'));
    await tester.pumpAndSettle();

    verify(() => getOrders.execute(1, filter: filter)).called(1);
    expect(find.text('Entregue · Últimos 30 dias'), findsOneWidget);
    expect(find.text('Nenhum pedido encontrado'), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(find.text('Entregue · Últimos 30 dias'), findsNothing);
    expect(find.text('Pedido SC-20261014-ABC123'), findsOneWidget);
  });
}

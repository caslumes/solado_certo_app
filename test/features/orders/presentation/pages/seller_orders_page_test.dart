import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/seller_order_detail_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/seller_orders_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetSellerOrdersUseCase getOrders;
  late MockGetSellerOrderUseCase getOrder;

  void answer(OrderStatus status, List<OrderEntity> orders) {
    when(
      () => getOrders.execute(any(), filter: OrderFilter(status: status)),
    ).thenAnswer(
      (_) async =>
          OrdersPageEntity(items: orders, currentPage: 1, hasNext: false),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: MockAuthBloc(),
        child: const MaterialApp(home: SellerOrdersPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(initializeFormatting);

  setUp(() {
    getOrders = MockGetSellerOrdersUseCase();
    getOrder = MockGetSellerOrderUseCase();
    for (final status in OrderStatus.values) {
      answer(status, const []);
    }
    getIt.registerSingleton<GetSellerOrdersUseCase>(getOrders);
    getIt.registerSingleton<GetSellerOrderUseCase>(getOrder);
    getIt.registerSingleton<StartProcessingUseCase>(
      MockStartProcessingUseCase(),
    );
    getIt.registerSingleton<ShipOrderUseCase>(MockShipOrderUseCase());
    getIt.registerSingleton<RejectPrescriptionUseCase>(
      MockRejectPrescriptionUseCase(),
    );
    addTearDown(getIt.reset);
  });

  testWidgets('opens on the new orders, with the buyer and the paid date', (
    tester,
  ) async {
    answer(OrderStatus.paid, [
      buildOrder(
        status: OrderStatus.paid,
        buyerName: 'Maria Souza',
        paidAt: DateTime(2026, 10, 15, 10),
      ),
    ]);
    await pumpPage(tester);

    for (final tab in [
      'Novos',
      'Em preparação',
      'Enviados',
      'Entregues',
      'Cancelados',
    ]) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.text('Pedido SC-20261014-ABC123'), findsOneWidget);
    expect(find.text('Maria Souza · 15/10/2026'), findsOneWidget);
    verify(
      () => getOrders.execute(1, filter: OrderFilter(status: OrderStatus.paid)),
    ).called(1);
  });

  testWidgets('each tab loads its status when shown', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Enviados'));
    await tester.pumpAndSettle();

    verify(
      () => getOrders.execute(
        1,
        filter: OrderFilter(status: OrderStatus.shipped),
      ),
    ).called(1);
    expect(find.text('Nenhum pedido enviado'), findsOneWidget);
  });

  testWidgets('opens a sale and reloads its tab on return', (tester) async {
    answer(OrderStatus.paid, [
      buildOrder(status: OrderStatus.paid, buyerName: 'Maria Souza'),
    ]);
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildSellerOrderDetail());
    await pumpPage(tester);

    await tester.tap(find.text('Pedido SC-20261014-ABC123'));
    await tester.pumpAndSettle();

    expect(find.byType(SellerOrderDetailPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    verify(
      () => getOrders.execute(1, filter: OrderFilter(status: OrderStatus.paid)),
    ).called(2);
  });

  testWidgets('a period applies to the tab shown (RF-025)', (tester) async {
    registerFallbackValue(const OrderFilter());
    when(
      () => getOrders.execute(any(), filter: any(named: 'filter')),
    ).thenAnswer(
      (_) async =>
          const OrdersPageEntity(items: [], currentPage: 1, hasNext: false),
    );
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Filtrar'));
    await tester.pumpAndSettle();
    expect(find.text('Situação'), findsNothing);
    await tester.tap(find.text('Últimos 3 meses'));
    await tester.tap(find.text('APLICAR'));
    await tester.pumpAndSettle();

    verify(
      () => getOrders.execute(
        1,
        filter: const OrderFilter(
          status: OrderStatus.paid,
          period: OrderPeriod.last3Months,
        ),
      ),
    ).called(1);
    expect(find.text('Últimos 3 meses'), findsOneWidget);
    expect(find.text('Nenhuma venda neste período.'), findsOneWidget);

    await tester.tap(find.text('Entregues'));
    await tester.pumpAndSettle();

    verify(
      () => getOrders.execute(
        1,
        filter: const OrderFilter(
          status: OrderStatus.delivered,
          period: OrderPeriod.last3Months,
        ),
      ),
    ).called(1);
  });
}

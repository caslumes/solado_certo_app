import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetOrderUseCase getOrder;
  late MockCancelOrderUseCase cancelOrder;
  late MockAuthBloc authBloc;
  late List<OrderEntity> changes;

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          home: BlocProvider(
            create: (_) => OrderDetailCubit(
              getOrderUseCase: getOrder,
              cancelOrderUseCase: cancelOrder,
              orderId: 'o1',
            )..load(),
            child: OrderDetailPage(onChanged: changes.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> cancelFromDialog(WidgetTester tester) async {
    await tester.tap(find.text('CANCELAR PEDIDO'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar pedido'),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    initializeFormatting();
    registerFallbackValue(SignOutEvent());
  });

  setUp(() {
    getOrder = MockGetOrderUseCase();
    cancelOrder = MockCancelOrderUseCase();
    authBloc = MockAuthBloc();
    changes = [];
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail());
  });

  testWidgets('shows the order, its items, address, totals and history', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Pedido SC-20261014-ABC123'), findsOneWidget);
    expect(find.text('Feito em 14/10/2026 às 09:05'), findsOneWidget);
    expect(find.text('Aguardando pagamento'), findsNWidgets(2));
    expect(
      find.text('Os produtos ficam reservados para você até o pagamento.'),
      findsOneWidget,
    );
    expect(find.text('Vendido por Loja s1'), findsOneWidget);
    expect(find.text('Palmilha 601'), findsOneWidget);
    expect(find.text('1 × ${formatCurrency(89.9)}'), findsOneWidget);
    expect(find.text('PAC (Correios) · Até 7 dias úteis'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(
      find.text('Rua das Flores, 10\nCentro, Campinas - SP\nCEP 13010-111'),
      findsOneWidget,
    );
    expect(find.text(formatCurrency(109.8)), findsOneWidget);
    expect(find.text('14/10/2026 às 09:05 · Pedido criado'), findsOneWidget);
    expect(find.text('CANCELAR PEDIDO'), findsOneWidget);
    expect(changes.single.status, OrderStatus.awaitingPayment);
  });

  testWidgets('cancels after confirming', (tester) async {
    when(
      () => cancelOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail(cancelled: true));
    await pumpPage(tester);

    await cancelFromDialog(tester);

    verify(() => cancelOrder.execute('o1')).called(1);
    expect(find.text('Pedido cancelado.'), findsOneWidget);
    expect(find.text('Cancelado'), findsNWidgets(2));
    expect(
      find.text('14/10/2026 às 10:30 · Cancelado por você'),
      findsOneWidget,
    );
    expect(find.text('CANCELAR PEDIDO'), findsNothing);
    expect(changes.last.status, OrderStatus.cancelled);
  });

  testWidgets('keeps the order when the buyer gives up', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('CANCELAR PEDIDO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    verifyNever(() => cancelOrder.execute(any()));
    expect(find.text('CANCELAR PEDIDO'), findsOneWidget);
  });

  testWidgets('explains when the order can no longer be cancelled', (
    tester,
  ) async {
    when(
      () => cancelOrder.execute('o1'),
    ).thenThrow(OrderStatusChangedFailure());
    await pumpPage(tester);
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail(cancelled: true));

    await cancelFromDialog(tester);

    expect(
      find.text('A situação deste pedido mudou. Confira e tente de novo.'),
      findsOneWidget,
    );
    expect(find.text('CANCELAR PEDIDO'), findsNothing);
  });

  testWidgets('shows a load error with retry', (tester) async {
    when(() => getOrder.execute('o1')).thenThrow(NotFoundFailure());
    await pumpPage(tester);

    expect(
      find.text('O conteúdo procurado não foi encontrado.'),
      findsOneWidget,
    );

    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail());
    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pumpAndSettle();
    expect(find.text('Pedido SC-20261014-ABC123'), findsOneWidget);
  });

  testWidgets('signs out when the session expired', (tester) async {
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => throw UnauthorizedFailure());
    await pumpPage(tester);

    verify(() => authBloc.add(any(that: isA<SignOutEvent>()))).called(1);
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/seller_order_detail_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/ship_order_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetSellerOrderUseCase getOrder;
  late MockStartProcessingUseCase startProcessing;
  late MockShipOrderUseCase shipOrder;

  Future<void> pumpPage(WidgetTester tester, OrderStatus status) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildSellerOrderDetail(status: status));
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: MockAuthBloc(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context).push(SellerOrderDetailPage.route('o1')),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  When<Future<OrderDetailEntity>> whenShipping() => when(
    () => shipOrder.execute(
      any(),
      carrier: any(named: 'carrier'),
      trackingCode: any(named: 'trackingCode'),
    ),
  );

  Future<void> openShipping(WidgetTester tester) async {
    await tester.tap(find.text('INFORMAR ENVIO'));
    await tester.pumpAndSettle();
  }

  Future<void> fillCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextFormField).at(1), code);
    await tester.tap(find.text('CONFIRMAR ENVIO'));
    await tester.pumpAndSettle();
  }

  setUpAll(initializeFormatting);

  setUp(() {
    getOrder = MockGetSellerOrderUseCase();
    startProcessing = MockStartProcessingUseCase();
    shipOrder = MockShipOrderUseCase();
    getIt.registerSingleton<GetSellerOrderUseCase>(getOrder);
    getIt.registerSingleton<StartProcessingUseCase>(startProcessing);
    getIt.registerSingleton<ShipOrderUseCase>(shipOrder);
    addTearDown(getIt.reset);
  });

  testWidgets('shows the buyer, the address, the items and the next step', (
    tester,
  ) async {
    await pumpPage(tester, OrderStatus.paid);

    expect(find.text('Pedido SC-20261014-ABC123'), findsOneWidget);
    expect(find.text('Comprado por Maria Souza'), findsOneWidget);
    expect(find.text('Enviar para'), findsOneWidget);
    expect(find.text('Palmilha 601'), findsOneWidget);
    expect(find.textContaining('Inicie a preparação'), findsOneWidget);
    expect(find.text('INICIAR PREPARAÇÃO'), findsOneWidget);
    expect(find.text('INFORMAR ENVIO'), findsNothing);
  });

  testWidgets('starts preparing after confirming', (tester) async {
    when(() => startProcessing.execute('o1')).thenAnswer(
      (_) async => buildSellerOrderDetail(status: OrderStatus.processing),
    );
    await pumpPage(tester, OrderStatus.paid);

    await tester.tap(find.text('INICIAR PREPARAÇÃO'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não pode mais cancelar'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Iniciar preparação'));
    await tester.pumpAndSettle();

    verify(() => startProcessing.execute('o1')).called(1);
    expect(find.text('INFORMAR ENVIO'), findsOneWidget);
    expect(find.textContaining('Preparação iniciada'), findsOneWidget);
  });

  testWidgets('going back from the confirmation changes nothing', (
    tester,
  ) async {
    await pumpPage(tester, OrderStatus.paid);

    await tester.tap(find.text('INICIAR PREPARAÇÃO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    verifyNever(() => startProcessing.execute(any()));
  });

  testWidgets('ships with the suggested carrier and a valid code', (
    tester,
  ) async {
    whenShipping().thenAnswer(
      (_) async => buildSellerOrderDetail(status: OrderStatus.shipped),
    );
    await pumpPage(tester, OrderStatus.processing);
    await openShipping(tester);

    expect(find.byType(ShipOrderPage), findsOneWidget);
    expect(find.text('Correios'), findsOneWidget);

    await fillCode(tester, 'aa 123456789 br');

    verify(
      () => shipOrder.execute(
        'o1',
        carrier: 'Correios',
        trackingCode: 'AA123456789BR',
      ),
    ).called(1);
    expect(find.byType(ShipOrderPage), findsNothing);
    expect(find.text('Envio'), findsOneWidget);
    expect(find.text('Código AA123456789BR'), findsOneWidget);
    expect(find.textContaining('Envio informado'), findsOneWidget);
  });

  testWidgets('a code in the wrong format is not sent (UC-009)', (
    tester,
  ) async {
    await pumpPage(tester, OrderStatus.processing);
    await openShipping(tester);

    await fillCode(tester, '123456');

    expect(find.textContaining('formato dos Correios'), findsOneWidget);
    verifyNever(
      () => shipOrder.execute(
        any(),
        carrier: any(named: 'carrier'),
        trackingCode: any(named: 'trackingCode'),
      ),
    );
  });

  testWidgets('a code the backend refuses keeps the form with the error', (
    tester,
  ) async {
    whenShipping().thenThrow(
      buildDioException(
        statusCode: 409,
        data: {'error': 'tracking code already registered'},
      ),
    );
    await pumpPage(tester, OrderStatus.processing);
    await openShipping(tester);

    await fillCode(tester, 'AA123456789BR');

    expect(find.byType(ShipOrderPage), findsOneWidget);
    expect(find.textContaining('já foi usado'), findsOneWidget);
  });

  testWidgets('a shipped order shows its tracking and no action', (
    tester,
  ) async {
    await pumpPage(tester, OrderStatus.shipped);

    expect(find.text('Código AA123456789BR'), findsOneWidget);
    expect(find.textContaining('confirmar o recebimento'), findsOneWidget);
    expect(find.text('INFORMAR ENVIO'), findsNothing);
    expect(find.text('INICIAR PREPARAÇÃO'), findsNothing);
  });

  testWidgets('a cancelled order says not to ship it', (tester) async {
    await pumpPage(tester, OrderStatus.cancelled);

    expect(find.textContaining('Não o envie'), findsOneWidget);
    expect(find.text('INFORMAR ENVIO'), findsNothing);
    expect(find.text('INICIAR PREPARAÇÃO'), findsNothing);
  });
}

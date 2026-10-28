import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/seller_custom_order_detail_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/seller_custom_order_detail_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetSellerCustomOrderUseCase getRequest;
  late MockReviewCustomOrderUseCase review;
  late MockAcceptCustomOrderUseCase accept;
  late MockRejectCustomOrderUseCase reject;
  late MockRequestCustomOrderInfoUseCase requestInfo;
  late MockSendFittingReportUseCase sendReport;
  late List<CustomOrderEntity> changes;
  late List<String> openedDocuments;
  late List<String> openedOrders;
  late int reportsOpened;

  final requested = buildCustomOrderDetail(
    actions: const {
      CustomOrderAction.review,
      CustomOrderAction.accept,
      CustomOrderAction.reject,
      CustomOrderAction.requestInfo,
    },
    footPhotoUrl: '/seller/custom-orders/c1/photo',
  );
  final approved = buildCustomOrderDetail(
    status: CustomOrderStatus.approved,
    quotedPrice: 189.9,
    actions: const {},
  );

  void stubLoad(CustomOrderDetailEntity detail) =>
      when(() => getRequest.execute('c1')).thenAnswer((_) async => detail);

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: MockAuthBloc(),
        child: MaterialApp(
          home: BlocProvider(
            create: (_) => SellerCustomOrderDetailCubit(
              getCustomOrderUseCase: getRequest,
              reviewUseCase: review,
              acceptUseCase: accept,
              rejectUseCase: reject,
              requestInfoUseCase: requestInfo,
              sendReportUseCase: sendReport,
              requestId: 'c1',
            )..load(),
            child: SellerCustomOrderDetailPage(
              onChanged: changes.add,
              openDocument: (_, url, _) => openedDocuments.add(url),
              openOrder: (_, orderId) async => openedOrders.add(orderId),
              openReport: (_, _) async => reportsOpened++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(initializeFormatting);

  setUp(() {
    getRequest = MockGetSellerCustomOrderUseCase();
    review = MockReviewCustomOrderUseCase();
    accept = MockAcceptCustomOrderUseCase();
    reject = MockRejectCustomOrderUseCase();
    requestInfo = MockRequestCustomOrderInfoUseCase();
    sendReport = MockSendFittingReportUseCase();
    changes = [];
    openedDocuments = [];
    openedOrders = [];
    reportsOpened = 0;
    stubLoad(requested);
  });

  testWidgets('shows the buyer request with every decision (RF-038)', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Pedido por Maria Souza'), findsOneWidget);
    expect(find.textContaining('Confira as medidas'), findsOneWidget);
    expect(find.text('25,5 cm × 9,5 cm'), findsOneWidget);
    expect(find.text('Dor no calcanhar'), findsOneWidget);
    expect(find.text('26/10/2026 às 09:00 · Comprador'), findsOneWidget);
    expect(find.text('ACEITAR COM PREÇO'), findsOneWidget);
    expect(find.text('Iniciar análise'), findsOneWidget);
    expect(find.text('Pedir informações'), findsOneWidget);
    expect(find.text('Recusar solicitação'), findsOneWidget);
    expect(find.text('ENVIAR LAUDO'), findsNothing);

    await tester.tap(find.text('Ver foto'));
    expect(openedDocuments, ['/seller/custom-orders/c1/photo']);
  });

  testWidgets('starts the review', (tester) async {
    when(() => review.execute('c1')).thenAnswer(
      (_) async => buildCustomOrderDetail(
        status: CustomOrderStatus.underReview,
        actions: const {CustomOrderAction.accept},
      ),
    );
    await pumpPage(tester);
    await tester.tap(find.text('Iniciar análise'));
    await tester.pumpAndSettle();

    expect(
      find.text('Análise iniciada. O comprador foi avisado.'),
      findsOneWidget,
    );
    expect(find.text('Iniciar análise'), findsNothing);
    expect(changes.last.status, CustomOrderStatus.underReview);
  });

  testWidgets('accepts only with a valid price', (tester) async {
    when(
      () => accept.execute('c1', '189.90'),
    ).thenAnswer((_) async => approved);
    await pumpPage(tester);
    await tester.tap(find.text('ACEITAR COM PREÇO'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar'));
    await tester.pump();
    expect(find.text('Informe o preço do item.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Aceitar'));
    await tester.pump();
    expect(find.text('Valor inválido (ex.: 189,90)'), findsOneWidget);
    verifyNever(() => accept.execute(any(), any()));

    await tester.enterText(find.byType(TextField), '189,90');
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();

    verify(() => accept.execute('c1', '189.90')).called(1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Você aceitou por'), findsOneWidget);
    expect(find.text(formatCurrency(189.9)), findsOneWidget);
  });

  testWidgets('asks the buyer for more information (UC-008)', (tester) async {
    when(() => requestInfo.execute('c1', 'Qual o arco?')).thenAnswer(
      (_) async => buildCustomOrderDetail(
        status: CustomOrderStatus.needsInfo,
        actions: const {CustomOrderAction.reject},
        history: [
          CustomOrderChangeEntity(
            from: CustomOrderStatus.requested,
            to: CustomOrderStatus.needsInfo,
            changedBy: CustomOrderActor.seller,
            reason: 'Qual o arco?',
            createdAt: DateTime(2026, 10, 26, 11, 0),
          ),
        ],
      ),
    );
    await pumpPage(tester);
    await tester.tap(find.text('Pedir informações'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar pergunta'));
    await tester.pump();
    expect(find.text('Escreva o que você precisa saber.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), ' Qual o arco? ');
    await tester.tap(find.text('Enviar pergunta'));
    await tester.pumpAndSettle();

    verify(() => requestInfo.execute('c1', 'Qual o arco?')).called(1);
    expect(
      find.text('Aguardando a resposta do comprador: Qual o arco?'),
      findsOneWidget,
    );
    expect(find.text('Pergunta: Qual o arco?'), findsOneWidget);
    expect(find.text('26/10/2026 às 11:00 · Você'), findsOneWidget);
  });

  testWidgets('rejects with the reason', (tester) async {
    when(() => reject.execute('c1', 'Sem material')).thenAnswer(
      (_) async => buildCustomOrderDetail(
        status: CustomOrderStatus.rejected,
        rejectionReason: 'Sem material',
        actions: const {},
      ),
    );
    await pumpPage(tester);
    await tester.tap(find.text('Recusar solicitação'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sem material');
    await tester.tap(find.text('Recusar'));
    await tester.pumpAndSettle();

    verify(() => reject.execute('c1', 'Sem material')).called(1);
    expect(
      find.text('Você recusou a solicitação: Sem material'),
      findsOneWidget,
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
      isNull,
    );
  });

  testWidgets('going back from a dialog sends nothing', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Recusar solicitação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => reject.execute(any(), any()));
  });

  testWidgets('once paid it asks for the report (RF-039)', (tester) async {
    stubLoad(
      buildCustomOrderDetail(
        status: CustomOrderStatus.inProduction,
        quotedPrice: 189.9,
        orderId: 'o1',
        actions: const {CustomOrderAction.report},
      ),
    );
    await pumpPage(tester);

    expect(
      find.textContaining('Pagamento aprovado. Produza o item'),
      findsOneWidget,
    );
    await tester.tap(find.text('ENVIAR LAUDO'));
    await tester.pumpAndSettle();
    expect(reportsOpened, 1);

    await tester.tap(find.text('Ver pedido'));
    await tester.pumpAndSettle();
    expect(openedOrders, ['o1']);
  });

  testWidgets('shows the report it sent', (tester) async {
    stubLoad(
      buildCustomOrderDetail(
        status: CustomOrderStatus.completed,
        actions: const {},
        adaptationInstructions: 'Use 1 hora no primeiro dia.',
        fittingReport: FittingReportEntity(
          id: 'd9',
          url: '/documents/d9',
          createdAt: DateTime(2026, 10, 30, 12, 0),
        ),
      ),
    );
    await pumpPage(tester);

    expect(find.text('Use 1 hora no primeiro dia.'), findsOneWidget);
    await tester.tap(find.text('Ver laudo'));
    expect(openedDocuments, ['/documents/d9']);
  });

  testWidgets('says when the request is not the seller own', (tester) async {
    when(
      () => getRequest.execute('c1'),
    ).thenThrow(buildDioException(statusCode: 404));
    await pumpPage(tester);

    expect(find.text('Solicitação não encontrada.'), findsOneWidget);
  });
}

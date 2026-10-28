import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_detail_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_detail_page.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGetCustomOrderUseCase getRequest;
  late MockComplementCustomOrderUseCase complement;
  late MockCancelCustomOrderUseCase cancel;
  late MockSendFootPhotoUseCase sendPhoto;
  late MockHasCustomOrderConsentUseCase hasConsent;
  late MockGrantCustomOrderConsentUseCase grantConsent;
  late List<CustomOrderEntity> changes;
  late List<String> openedDocuments;
  late List<String> openedOrders;
  late List<String> checkouts;
  late int consentAsked;

  const photo = UploadFile(bytes: [1, 2, 3], filename: 'pe.jpg');

  final needsInfo = buildCustomOrderDetail(
    status: CustomOrderStatus.needsInfo,
    actions: const {
      CustomOrderAction.complement,
      CustomOrderAction.cancel,
      CustomOrderAction.sendPhoto,
    },
    history: [
      CustomOrderChangeEntity(
        to: CustomOrderStatus.requested,
        changedBy: CustomOrderActor.buyer,
        createdAt: DateTime(2026, 10, 26, 9, 0),
      ),
      CustomOrderChangeEntity(
        from: CustomOrderStatus.requested,
        to: CustomOrderStatus.needsInfo,
        changedBy: CustomOrderActor.seller,
        reason: 'Qual a altura do arco?',
        createdAt: DateTime(2026, 10, 26, 11, 0),
      ),
    ],
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
            create: (_) => CustomOrderDetailCubit(
              getCustomOrderUseCase: getRequest,
              complementUseCase: complement,
              cancelUseCase: cancel,
              sendFootPhotoUseCase: sendPhoto,
              hasConsentUseCase: hasConsent,
              grantConsentUseCase: grantConsent,
              requestId: 'c1',
            )..load(),
            child: CustomOrderDetailPage(
              onChanged: changes.add,
              askConsent: (_) async {
                consentAsked++;
                return true;
              },
              pickPhoto: (_) async => photo,
              openDocument: (_, url, _) => openedDocuments.add(url),
              openOrder: (_, orderId) async => openedOrders.add(orderId),
              openCheckout: (_, request) async => checkouts.add(request.id),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    initializeFormatting();
    registerFallbackValue(const CustomOrderComplement(message: ''));
    registerFallbackValue(photo);
  });

  setUp(() {
    getRequest = MockGetCustomOrderUseCase();
    complement = MockComplementCustomOrderUseCase();
    cancel = MockCancelCustomOrderUseCase();
    sendPhoto = MockSendFootPhotoUseCase();
    hasConsent = MockHasCustomOrderConsentUseCase();
    grantConsent = MockGrantCustomOrderConsentUseCase();
    changes = [];
    openedDocuments = [];
    openedOrders = [];
    checkouts = [];
    consentAsked = 0;
    when(hasConsent.execute).thenAnswer((_) async => true);
    stubLoad(buildCustomOrderDetail());
  });

  testWidgets('shows the request, its measurements and history', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Palmilha sob medida'), findsOneWidget);
    expect(find.text('Vendido por Loja Pé Bem'), findsOneWidget);
    expect(find.text('Enviada'), findsNWidgets(2));
    expect(
      find.textContaining('O vendedor vai analisar suas medidas'),
      findsOneWidget,
    );
    expect(find.text('25,5 cm × 9,5 cm'), findsOneWidget);
    expect(find.text('25,8 cm × 9,6 cm'), findsOneWidget);
    expect(find.text('39'), findsOneWidget);
    expect(find.text('Plano'), findsOneWidget);
    expect(find.text('Dor no calcanhar'), findsOneWidget);
    expect(find.text('26/10/2026 às 09:00 · Você'), findsOneWidget);
    expect(find.text('Enviar foto'), findsOneWidget);
    expect(find.text('Cancelar solicitação'), findsOneWidget);
    expect(find.text('RESPONDER AO VENDEDOR'), findsNothing);
    expect(changes.single.id, 'c1');
  });

  testWidgets('answers the question of the seller (UC-008)', (tester) async {
    stubLoad(needsInfo);
    when(() => complement.execute('c1', any())).thenAnswer(
      (_) async =>
          buildCustomOrderDetail(status: CustomOrderStatus.underReview),
    );
    await pumpPage(tester);

    expect(
      find.text(
        'O vendedor precisa de mais informações: Qual a altura do arco?',
      ),
      findsOneWidget,
    );
    expect(find.text('Pergunta: Qual a altura do arco?'), findsOneWidget);
    await tester.tap(find.text('RESPONDER AO VENDEDOR'));
    await tester.pumpAndSettle();

    expect(find.text('O vendedor perguntou'), findsOneWidget);
    await tester.tap(find.text('ENVIAR RESPOSTA'));
    await tester.pumpAndSettle();
    expect(find.text('Campo obrigatório'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(ShoeTextFormField, 'Sua resposta'),
        matching: find.byType(TextFormField),
      ),
      'É bem alto',
    );
    await tester.tap(find.text('ENVIAR RESPOSTA'));
    await tester.pumpAndSettle();

    final sent =
        verify(() => complement.execute('c1', captureAny())).captured.single
            as CustomOrderComplement;
    expect(sent.message, 'É bem alto');
    expect(sent.measurements, isNull);
    expect(sent.technicalNotes, isNull);
    expect(find.text('O vendedor perguntou'), findsNothing);
    expect(find.text('Resposta enviada ao vendedor.'), findsOneWidget);
    expect(find.text('Em análise'), findsWidgets);
  });

  testWidgets('asks for consent again before answering when it was revoked', (
    tester,
  ) async {
    stubLoad(needsInfo);
    when(hasConsent.execute).thenAnswer((_) async => false);
    when(grantConsent.execute).thenAnswer(
      (_) async => ConsentEntity(
        purpose: ConsentPurposes.customOrder,
        termsVersion: ConsentTermsVersions.customOrder,
        grantedAt: DateTime(2026),
      ),
    );
    await pumpPage(tester);

    await tester.tap(find.text('RESPONDER AO VENDEDOR'));
    await tester.pumpAndSettle();

    expect(consentAsked, 1);
    verify(grantConsent.execute).called(1);
    expect(find.text('O vendedor perguntou'), findsOneWidget);
  });

  testWidgets('sends the foot photo', (tester) async {
    when(() => sendPhoto.execute('c1', photo)).thenAnswer(
      (_) async =>
          buildCustomOrderDetail(footPhotoUrl: '/custom-orders/c1/photo'),
    );
    await pumpPage(tester);

    await tester.tap(find.text('Enviar foto'));
    await tester.pumpAndSettle();

    expect(find.text('Foto enviada.'), findsOneWidget);
    await tester.tap(find.text('Ver foto'));
    expect(openedDocuments, ['/custom-orders/c1/photo']);
    expect(find.text('Trocar foto'), findsOneWidget);
  });

  testWidgets('cancels with the optional reason', (tester) async {
    when(() => cancel.execute('c1', reason: 'Comprei pronto')).thenAnswer(
      (_) async => buildCustomOrderDetail(
        status: CustomOrderStatus.cancelled,
        actions: const {},
      ),
    );
    await pumpPage(tester);

    await tester.tap(find.text('Cancelar solicitação'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Comprei pronto');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar solicitação'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => cancel.execute('c1', reason: 'Comprei pronto')).called(1);
    expect(find.text('Solicitação cancelada.'), findsOneWidget);
    expect(find.text('Cancelar solicitação'), findsNothing);
  });

  testWidgets('going back from the cancel dialog keeps the request', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('Cancelar solicitação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    verifyNever(() => cancel.execute(any(), reason: any(named: 'reason')));
  });

  testWidgets('shows the accepted price and opens the checkout', (
    tester,
  ) async {
    stubLoad(
      buildCustomOrderDetail(
        status: CustomOrderStatus.approved,
        quotedPrice: 320,
        actions: const {CustomOrderAction.checkout, CustomOrderAction.cancel},
      ),
    );
    await pumpPage(tester);

    expect(
      find.text(
        'O vendedor aceitou fazer o item por ${formatCurrency(320)}. '
        'Confirme e pague para a produção começar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Preço combinado'), findsOneWidget);
    await tester.tap(find.text('CONFIRMAR E PAGAR'));
    await tester.pumpAndSettle();

    expect(checkouts, ['c1']);
    verify(() => getRequest.execute('c1')).called(2);
  });

  testWidgets('an accepted request with an order goes to its payment', (
    tester,
  ) async {
    stubLoad(
      buildCustomOrderDetail(
        status: CustomOrderStatus.approved,
        quotedPrice: 320,
        orderId: 'o1',
        actions: const {},
      ),
    );
    await pumpPage(tester);

    expect(
      find.text('Pedido criado. Pague para a produção começar.'),
      findsOneWidget,
    );
    await tester.tap(find.text('PAGAR PEDIDO'));
    await tester.pumpAndSettle();

    expect(openedOrders, ['o1']);
  });

  testWidgets('shows why the seller rejected it (UC-008)', (tester) async {
    stubLoad(
      buildCustomOrderDetail(
        status: CustomOrderStatus.rejected,
        rejectionReason: 'Não faço esse tamanho',
        actions: const {},
      ),
    );
    await pumpPage(tester);

    expect(
      find.text('O vendedor recusou a solicitação: Não faço esse tamanho'),
      findsOneWidget,
    );
    expect(find.text('Cancelar solicitação'), findsNothing);
    final page = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(page.bottomNavigationBar, isNull);
  });

  testWidgets('shows the adaptation instructions and the report (RF-039)', (
    tester,
  ) async {
    stubLoad(
      buildCustomOrderDetail(
        status: CustomOrderStatus.completed,
        quotedPrice: 320,
        orderId: 'o1',
        adaptationInstructions: 'Use 1 hora no primeiro dia.',
        fittingReport: FittingReportEntity(
          id: 'd9',
          url: '/documents/d9',
          createdAt: DateTime(2026, 10, 30, 12, 0),
        ),
        actions: const {},
      ),
    );
    await pumpPage(tester);

    expect(find.text('Laudo e adaptação'), findsOneWidget);
    expect(find.text('Use 1 hora no primeiro dia.'), findsOneWidget);
    await tester.tap(find.text('Ver laudo'));
    expect(openedDocuments, ['/documents/d9']);
    await tester.tap(find.text('Ver pedido'));
    expect(openedOrders, ['o1']);
  });

  testWidgets('says when the request does not exist', (tester) async {
    when(
      () => getRequest.execute('c1'),
    ).thenThrow(buildDioException(statusCode: 404));
    await pumpPage(tester);

    expect(find.text('Solicitação não encontrada.'), findsOneWidget);
  });
}

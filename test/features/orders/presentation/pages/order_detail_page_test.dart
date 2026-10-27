import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/enum/document_status.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';
import 'package:solado_certo_app/features/payments/presentation/pages/payment_page.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/reviews/domain/usecases/review_use_cases.dart';
import 'package:solado_certo_app/features/reviews/presentation/pages/review_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

final cancelButton = find.widgetWithText(TextButton, 'Cancelar pedido');

void main() {
  late MockGetOrderUseCase getOrder;
  late MockCancelOrderUseCase cancelOrder;
  late MockConfirmDeliveryUseCase confirmDelivery;
  late MockGetPaymentsUseCase getPayments;
  late MockUploadPrescriptionUseCase uploadPrescription;
  late MockHasPrescriptionConsentUseCase hasConsent;
  late MockGrantPrescriptionConsentUseCase grantConsent;
  late MockAuthBloc authBloc;
  late List<OrderEntity> changes;
  late List<String> openedDocuments;
  late int consentAsked;
  late bool consentAnswer;

  const file = UploadFile(bytes: [1, 2, 3], filename: 'receita.pdf');

  Future<void> pumpPage(
    WidgetTester tester, {
    Future<bool> Function(Uri url)? openUrl,
  }) async {
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
              confirmDeliveryUseCase: confirmDelivery,
              getPaymentsUseCase: getPayments,
              uploadPrescriptionUseCase: uploadPrescription,
              hasPrescriptionConsentUseCase: hasConsent,
              grantPrescriptionConsentUseCase: grantConsent,
              orderId: 'o1',
            )..load(),
            child: OrderDetailPage(
              onChanged: changes.add,
              openUrl: openUrl ?? (_) async => true,
              askConsent: (_) async {
                consentAsked++;
                return consentAnswer;
              },
              pickFile: (_) async => file,
              openDocument: (_, url) => openedDocuments.add(url),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> cancelFromDialog(WidgetTester tester) async {
    await tester.tap(cancelButton);
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
    registerFallbackValue(file);
  });

  setUp(() {
    getOrder = MockGetOrderUseCase();
    cancelOrder = MockCancelOrderUseCase();
    confirmDelivery = MockConfirmDeliveryUseCase();
    getPayments = MockGetPaymentsUseCase();
    uploadPrescription = MockUploadPrescriptionUseCase();
    hasConsent = MockHasPrescriptionConsentUseCase();
    grantConsent = MockGrantPrescriptionConsentUseCase();
    when(() => getPayments.execute('o1')).thenAnswer((_) async => []);
    authBloc = MockAuthBloc();
    changes = [];
    openedDocuments = [];
    consentAsked = 0;
    consentAnswer = true;
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
    expect(cancelButton, findsOneWidget);
    expect(changes.single.status, OrderStatus.awaitingPayment);
  });

  testWidgets('shows the payments and pays the order', (tester) async {
    when(() => getPayments.execute('o1')).thenAnswer(
      (_) async => [
        buildPayment(
          method: PaymentMethod.creditCard,
          status: PaymentStatus.failed,
          failureReason: 'card_refused',
        ),
      ],
    );
    final getProfile = MockGetProfileUseCase();
    when(getProfile.execute).thenAnswer((_) async => buildProfile());
    getIt
      ..registerSingleton<GetProfileUseCase>(getProfile)
      ..registerSingleton<GetPaymentsUseCase>(getPayments)
      ..registerSingleton<CreatePaymentUseCase>(MockCreatePaymentUseCase());
    addTearDown(getIt.reset);
    await pumpPage(tester);

    expect(find.text('Pagamento'), findsOneWidget);
    expect(find.text('Cartão de crédito final 4444'), findsOneWidget);
    expect(find.text('Cartão recusado · 15/10/2026 às 09:30'), findsOneWidget);

    await tester.tap(find.text('PAGAR'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentPage), findsOneWidget);

    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail(paid: true));
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Pago'), findsNWidgets(2));
    expect(
      find.text('15/10/2026 às 10:00 · Pagamento aprovado'),
      findsOneWidget,
    );
    expect(find.text('PAGAR'), findsNothing);
    expect(cancelButton, findsOneWidget);
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
    expect(cancelButton, findsNothing);
    expect(changes.last.status, OrderStatus.cancelled);
  });

  testWidgets('cancels a paid order and shows its refund', (tester) async {
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail(paid: true));
    when(
      () => getPayments.execute('o1'),
    ).thenAnswer((_) async => [buildPayment(status: PaymentStatus.captured)]);
    when(
      () => cancelOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail(cancelled: true));
    await pumpPage(tester);
    expect(find.text('Aprovado · 15/10/2026 às 10:00'), findsOneWidget);

    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('O valor pago será estornado na mesma forma'),
      findsOneWidget,
    );
    when(() => getPayments.execute('o1')).thenAnswer(
      (_) async => [
        buildPayment(
          status: PaymentStatus.captured,
          refundRequestedAt: DateTime(2026, 10, 16, 8, 0),
        ),
      ],
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar pedido'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Pedido cancelado. O valor pago será estornado.'),
      findsOneWidget,
    );
    expect(
      find.text('Estorno solicitado · 15/10/2026 às 10:00'),
      findsOneWidget,
    );
    expect(find.text('Informar conta para estorno'), findsNothing);
  });

  testWidgets('asks for the bank account of a boleto refund', (tester) async {
    final opened = <Uri>[];
    var canOpen = true;
    when(
      () => getOrder.execute('o1'),
    ).thenAnswer((_) async => buildOrderDetail(cancelled: true));
    when(() => getPayments.execute('o1')).thenAnswer(
      (_) async => [
        buildPayment(
          method: PaymentMethod.boleto,
          status: PaymentStatus.captured,
          refundRequestedAt: DateTime(2026, 10, 16, 8, 0),
          refundUrl: 'https://sandbox.asaas.com/r/1',
        ),
      ],
    );
    await pumpPage(
      tester,
      openUrl: (url) async {
        opened.add(url);
        return canOpen;
      },
    );

    expect(
      find.text('Estorno solicitado · 15/10/2026 às 10:00'),
      findsOneWidget,
    );
    await tester.tap(find.text('Informar conta para estorno'));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://sandbox.asaas.com/r/1')]);

    canOpen = false;
    await tester.tap(find.text('Informar conta para estorno'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível abrir a página.'), findsOneWidget);
  });

  testWidgets('keeps the order when the buyer gives up', (tester) async {
    await pumpPage(tester);

    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    verifyNever(() => cancelOrder.execute(any()));
    expect(cancelButton, findsOneWidget);
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
    expect(cancelButton, findsNothing);
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

  group('shipped (RF-022, RF-023)', () {
    testWidgets('shows the tracking and opens the carrier page', (
      tester,
    ) async {
      final opened = <Uri>[];
      when(
        () => getOrder.execute('o1'),
      ).thenAnswer((_) async => buildShippedOrderDetail());
      await pumpPage(
        tester,
        openUrl: (url) async {
          opened.add(url);
          return true;
        },
      );

      expect(find.text('Envio'), findsOneWidget);
      expect(find.text('Código AA123456789BR'), findsOneWidget);
      expect(find.text('Enviado em 15/10/2026 às 08:00'), findsOneWidget);
      expect(find.textContaining('confirme o recebimento'), findsOneWidget);
      expect(find.text('CANCELAR PEDIDO'), findsNothing);

      await tester.tap(find.text('Acompanhar entrega'));
      await tester.pumpAndSettle();
      expect(opened.single.host, 'rastreamento.correios.com.br');
      expect(opened.single.queryParameters['objetos'], 'AA123456789BR');
    });

    testWidgets('confirms the delivery after asking', (tester) async {
      when(
        () => getOrder.execute('o1'),
      ).thenAnswer((_) async => buildShippedOrderDetail());
      when(
        () => confirmDelivery.execute('o1'),
      ).thenAnswer((_) async => buildShippedOrderDetail(delivered: true));
      await pumpPage(tester);

      await tester.tap(find.text('RECEBI MEU PEDIDO'));
      await tester.pumpAndSettle();
      expect(find.text('Recebeu o pedido?'), findsOneWidget);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      verify(() => confirmDelivery.execute('o1')).called(1);
      expect(find.text('RECEBI MEU PEDIDO'), findsNothing);
      expect(find.textContaining('Recebimento confirmado'), findsOneWidget);
      expect(find.text('Entregue em 20/10/2026 às 18:00'), findsOneWidget);
      expect(changes.last.status, OrderStatus.delivered);
    });

    testWidgets('going back from the confirmation changes nothing', (
      tester,
    ) async {
      when(
        () => getOrder.execute('o1'),
      ).thenAnswer((_) async => buildShippedOrderDetail());
      await pumpPage(tester);

      await tester.tap(find.text('RECEBI MEU PEDIDO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      verifyNever(() => confirmDelivery.execute(any()));
    });
  });

  group('delivered (RF-024)', () {
    testWidgets('opens the review of an item and reloads after it', (
      tester,
    ) async {
      final createReview = MockCreateReviewUseCase();
      getIt.registerSingleton<CreateReviewUseCase>(createReview);
      addTearDown(getIt.reset);
      when(
        () => getOrder.execute('o1'),
      ).thenAnswer((_) async => buildShippedOrderDetail(delivered: true));
      await pumpPage(tester);

      expect(find.textContaining('avalie cada produto'), findsOneWidget);
      await tester.tap(find.text('Avaliar'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);

      when(() => getOrder.execute('o1')).thenAnswer(
        (_) async =>
            buildShippedOrderDetail(delivered: true, review: buildReview()),
      );
      Navigator.of(tester.element(find.byType(ReviewPage))).pop(true);
      await tester.pumpAndSettle();

      verify(() => getOrder.execute('o1')).called(2);
      expect(find.text('Sua avaliação'), findsOneWidget);
      expect(find.text('Avaliar'), findsNothing);
      expect(find.text('Conforto: Confortável'), findsOneWidget);
      expect(
        find.text('Adaptação: Duas semanas para acostumar'),
        findsOneWidget,
      );
    });
  });

  group('prescriptions', () {
    final pending = buildOrderDetail(
      items: [
        buildOrderItem(
          itemId: 'i1',
          prescriptionRequired: true,
          canUploadPrescription: true,
        ),
      ],
    );
    final approved = buildOrderDetail(
      items: [
        buildOrderItem(
          itemId: 'i1',
          prescriptionRequired: true,
          prescription: buildPrescription(),
          canUploadPrescription: true,
        ),
      ],
    );

    Finder payButton() => find.widgetWithText(ShoeTextButton, 'PAGAR');

    void uploadAnswers() {
      when(
        () => uploadPrescription.execute('o1', 'i1', file),
      ).thenAnswer((_) async => buildPrescription());
    }

    testWidgets('holds the payment until the prescription is sent (UC-007)', (
      tester,
    ) async {
      when(() => getOrder.execute('o1')).thenAnswer((_) async => pending);
      await pumpPage(tester);

      expect(find.text('Receita pendente'), findsOneWidget);
      expect(
        find.text(
          'Envie a receita dos itens que exigem prescrição para liberar o '
          'pagamento.',
        ),
        findsOneWidget,
      );
      final pay = tester.widget<ShoeTextButton>(payButton());
      expect(pay.onPressed, isNull);
      expect(find.text('Ver receita'), findsNothing);
    });

    testWidgets('asks for consent the first time, then uploads', (
      tester,
    ) async {
      when(() => getOrder.execute('o1')).thenAnswer((_) async => pending);
      when(() => hasConsent.execute()).thenAnswer((_) async => false);
      when(() => grantConsent.execute()).thenAnswer(
        (_) async => ConsentEntity(
          purpose: ConsentPurposes.prescription,
          termsVersion: ConsentTermsVersions.prescription,
          grantedAt: DateTime(2026, 10, 27),
        ),
      );
      uploadAnswers();
      await pumpPage(tester);

      when(() => getOrder.execute('o1')).thenAnswer((_) async => approved);
      await tester.tap(find.text('Enviar receita'));
      await tester.pumpAndSettle();

      expect(consentAsked, 1);
      verify(() => grantConsent.execute()).called(1);
      verify(() => uploadPrescription.execute('o1', 'i1', file)).called(1);
      expect(find.text('Receita aprovada'), findsOneWidget);
      expect(
        find.text('Receita aprovada. Você já pode pagar.'),
        findsOneWidget,
      );
      final pay = tester.widget<ShoeTextButton>(payButton());
      expect(pay.onPressed, isNotNull);

      await tester.tap(find.text('Enviar outra receita'));
      await tester.pumpAndSettle();
      expect(consentAsked, 1);
      verify(() => uploadPrescription.execute('o1', 'i1', file)).called(1);
    });

    testWidgets('sends nothing when the buyer declines the consent', (
      tester,
    ) async {
      when(() => getOrder.execute('o1')).thenAnswer((_) async => pending);
      when(() => hasConsent.execute()).thenAnswer((_) async => false);
      consentAnswer = false;
      await pumpPage(tester);

      await tester.tap(find.text('Enviar receita'));
      await tester.pumpAndSettle();

      expect(consentAsked, 1);
      verifyNever(() => grantConsent.execute());
      verifyNever(() => uploadPrescription.execute(any(), any(), any()));
    });

    testWidgets('explains a refused file and keeps the payment held', (
      tester,
    ) async {
      when(() => getOrder.execute('o1')).thenAnswer((_) async => pending);
      when(() => hasConsent.execute()).thenAnswer((_) async => true);
      when(() => uploadPrescription.execute('o1', 'i1', file)).thenThrow(
        buildDioException(
          statusCode: 415,
          data: {'error': 'the prescription must be a PDF, JPEG or PNG file'},
        ),
      );
      await pumpPage(tester);

      await tester.tap(find.text('Enviar receita'));
      await tester.pumpAndSettle();

      expect(consentAsked, 0);
      expect(find.text('Envie a receita em PDF, JPEG ou PNG.'), findsOneWidget);
      expect(find.text('Receita pendente'), findsOneWidget);
    });

    testWidgets('shows why the seller rejected it and opens the file', (
      tester,
    ) async {
      when(() => getOrder.execute('o1')).thenAnswer(
        (_) async => buildOrderDetail(
          paid: true,
          items: [
            buildOrderItem(
              itemId: 'i1',
              prescriptionRequired: true,
              prescription: buildPrescription(
                status: DocumentStatus.rejected,
                rejectionReason: 'Receita vencida',
              ),
              canUploadPrescription: true,
            ),
          ],
        ),
      );
      await pumpPage(tester);

      expect(find.text('Receita recusada'), findsOneWidget);
      expect(find.text('Motivo: Receita vencida'), findsOneWidget);
      expect(
        find.text(
          'O vendedor recusou a receita de um item. Envie outra para que o '
          'pedido possa ser enviado.',
        ),
        findsOneWidget,
      );
      expect(find.text('Enviar outra receita'), findsOneWidget);

      await tester.tap(find.text('Ver receita'));
      expect(openedDocuments, ['/documents/d1']);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/payments/presentation/bloc/payment_cubit.dart';
import 'package:solado_certo_app/features/payments/presentation/pages/payment_page.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';
import '../bloc/payment_cubit_test.dart' show profileWithTaxId;

void main() {
  late MockGetProfileUseCase getProfile;
  late MockGetPaymentsUseCase getPayments;
  late MockCreatePaymentUseCase createPayment;
  late List<Uri> opened;
  late List<bool?> results;
  late String? copied;

  /// Opens the page from a host page, so what it answers when closed is kept
  /// in [results].
  Future<void> pumpPage(WidgetTester tester, {String? position}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => PaymentCubit(
                      order: buildOrder(),
                      getProfileUseCase: getProfile,
                      getPaymentsUseCase: getPayments,
                      createPaymentUseCase: createPayment,
                      newKey: () => 'key',
                      pollInterval: const Duration(seconds: 5),
                    )..load(),
                    child: PaymentPage(
                      order: buildOrder(),
                      position: position,
                      openUrl: (url) async {
                        opened.add(url);
                        return true;
                      },
                    ),
                  ),
                ),
              );
              results.add(result);
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  void answerPayment(Object answer) {
    final stub = when(() => createPayment.execute('o1', any(), any()));
    if (answer is Failure) {
      stub.thenThrow(answer);
    } else {
      stub.thenAnswer((_) async => answer as dynamic);
    }
  }

  PaymentRequest sentRequest() =>
      verify(
            () => createPayment.execute('o1', captureAny(), any()),
          ).captured.single
          as PaymentRequest;

  setUpAll(() {
    initializeFormatting();
    registerFallbackValue(const PaymentRequest(method: PaymentMethod.pix));
  });

  setUp(() {
    getProfile = MockGetProfileUseCase();
    getPayments = MockGetPaymentsUseCase();
    createPayment = MockCreatePaymentUseCase();
    opened = [];
    results = [];
    copied = null;
    when(getProfile.execute).thenAnswer((_) async => profileWithTaxId());
    when(() => getPayments.execute('o1')).thenAnswer((_) async => []);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  testWidgets('pays with Pix, waits for the confirmation and shows the '
      'summary', (tester) async {
    answerPayment(buildPayment());
    await pumpPage(tester, position: '1 de 2');

    expect(find.text('Pedido SC-20261014-ABC123 (1 de 2)'), findsOneWidget);
    expect(find.text('Como você quer pagar?'), findsOneWidget);
    expect(find.text(formatCurrency(105.3)), findsOneWidget);
    expect(find.text(formatCurrency(109.8)), findsNWidgets(2));
    expect(find.text('CPF'), findsNothing);

    await tester.tap(find.text('PAGAR ${formatCurrency(105.3)}'.toUpperCase()));
    await tester.pump();
    await tester.pump();

    expect(sentRequest().method, PaymentMethod.pix);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Pague até 17/10/2026 às 23:59.'), findsOneWidget);
    expect(find.text('Aguardando a confirmação do pagamento'), findsOneWidget);

    await tester.tap(find.text('COPIAR CÓDIGO PIX'));
    await tester.pump();
    expect(copied, '00020101021226820014br.gov.bcb.pix');
    expect(find.text('Código Pix copiado.'), findsOneWidget);

    when(
      () => getPayments.execute('o1'),
    ).thenAnswer((_) async => [buildPayment(status: PaymentStatus.captured)]);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento aprovado!'), findsOneWidget);
    expect(find.text('Pago com Pix em 15/10/2026 às 10:00.'), findsOneWidget);
    expect(find.text('Desconto'), findsOneWidget);
    expect(find.text('- ${formatCurrency(4.5)}'), findsOneWidget);
    expect(find.text('1 × Palmilha 601'), findsOneWidget);

    await tester.tap(find.text('CONCLUIR'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('asks the CPF before the first payment', (tester) async {
    when(getProfile.execute).thenAnswer((_) async => buildProfile());
    answerPayment(buildPayment(method: PaymentMethod.boleto));
    await pumpPage(tester);

    await tester.tap(find.text('Boleto'));
    await tester.pump();
    await tester.tap(find.text('PAGAR ${formatCurrency(109.8)}'.toUpperCase()));
    await tester.pump();
    expect(find.text('Informe seu CPF'), findsOneWidget);
    verifyNever(() => createPayment.execute(any(), any(), any()));

    await tester.enterText(find.byType(TextFormField), '529.982.247-25');
    await tester.tap(find.text('PAGAR ${formatCurrency(109.8)}'.toUpperCase()));
    await tester.pump();
    await tester.pump();

    final request = sentRequest();
    expect(request.method, PaymentMethod.boleto);
    expect(request.taxId, '52998224725');
    expect(find.text('Boleto gerado'), findsOneWidget);
    expect(find.text('Vencimento: 17/10/2026'), findsOneWidget);

    await tester.tap(find.text('ABRIR BOLETO'));
    await tester.pump();
    expect(opened, [Uri.parse('https://sandbox.asaas.com/b/pdf/1')]);

    await tester.tap(find.text('Escolher outra forma de pagamento'));
    await tester.pumpAndSettle();
    expect(find.text('Como você quer pagar?'), findsOneWidget);
    expect(find.text('CPF'), findsNothing);
  });

  testWidgets('a refused card shows why and lets the buyer try again', (
    tester,
  ) async {
    answerPayment(
      buildPayment(
        method: PaymentMethod.creditCard,
        status: PaymentStatus.failed,
        failureReason: 'card_refused',
        failureMessage: 'Transação não autorizada.',
      ),
    );
    await pumpPage(tester);

    await tester.tap(find.text('Cartão de crédito'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Os dados do cartão são enviados à operadora e não ficam '
        'salvos.',
      ),
      findsOneWidget,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '5184 0197 4037 3151');
    await tester.enterText(fields.at(1), 'MARIA SOUZA');
    await tester.enterText(fields.at(2), '05/30');
    await tester.enterText(fields.at(3), '123');
    await tester.tap(find.text('PAGAR ${formatCurrency(109.8)}'.toUpperCase()));
    await tester.pumpAndSettle();

    final card = sentRequest().card!;
    expect(card.number, '5184019740373151');
    expect(card.holderName, 'MARIA SOUZA');
    expect(card.expiryMonth, '05');
    expect(card.expiryYear, '2030');
    expect(card.cvv, '123');
    expect(
      find.text(
        'Transação não autorizada. Tente outro cartão ou escolha outra forma '
        'de pagamento.',
      ),
      findsOneWidget,
    );
    expect(find.text('Como você quer pagar?'), findsOneWidget);
  });

  testWidgets('offers to try again when the gateway is down', (tester) async {
    answerPayment(GatewayUnavailableFailure());
    await pumpPage(tester);

    await tester.tap(find.text('PAGAR ${formatCurrency(105.3)}'.toUpperCase()));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'O serviço de pagamento está indisponível no momento. Tente '
        'novamente.',
      ),
      findsOneWidget,
    );

    answerPayment(buildPayment());
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('says when the order can no longer be paid', (tester) async {
    answerPayment(PaymentExpiredFailure());
    await pumpPage(tester);

    await tester.tap(find.text('PAGAR ${formatCurrency(105.3)}'.toUpperCase()));
    await tester.pumpAndSettle();
    expect(
      find.text('O prazo para pagar este pedido terminou.'),
      findsOneWidget,
    );

    await tester.tap(find.text('VOLTAR'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('going back before paying answers false', (tester) async {
    await pumpPage(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(results, [false]);
  });
}

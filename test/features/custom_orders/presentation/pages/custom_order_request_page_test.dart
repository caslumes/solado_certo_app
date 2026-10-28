import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/measurements.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/arch_type.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_form_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_request_page.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Finder field(String label, {int index = 0}) => find
    .descendant(
      of: find.widgetWithText(ShoeTextFormField, label),
      matching: find.byType(TextFormField),
    )
    .at(index);

void main() {
  late MockCreateCustomOrderUseCase create;
  late MockSendFootPhotoUseCase sendPhoto;
  late MockHasCustomOrderConsentUseCase hasConsent;
  late MockGrantCustomOrderConsentUseCase grantConsent;
  late List<CustomOrderDetailEntity> opened;
  late int consentAsked;
  late bool consentAnswer;

  const photo = UploadFile(bytes: [1, 2, 3], filename: 'pe.jpg');
  const expected = NewCustomOrder(
    advertisementId: '603',
    measurements: Measurements(
      left: FootMeasurement(lengthCm: 25.5, widthCm: 9.5),
      right: FootMeasurement(lengthCm: 25.8, widthCm: 9.6),
      archType: ArchType.flat,
      shoeSize: 39,
    ),
    technicalNotes: 'Dor no calcanhar',
  );

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: MockAuthBloc(),
        child: MaterialApp(
          home: BlocProvider(
            create: (_) => CustomOrderFormCubit(
              createCustomOrderUseCase: create,
              sendFootPhotoUseCase: sendPhoto,
              hasConsentUseCase: hasConsent,
              grantConsentUseCase: grantConsent,
            ),
            child: CustomOrderRequestPage(
              product: buildProductDetail(customMadeAllowed: true),
              askConsent: (_) async {
                consentAsked++;
                return consentAnswer;
              },
              pickPhoto: (_) async => photo,
              openDetail: (_, detail) => opened.add(detail),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> fillForm(WidgetTester tester) async {
    await tester.enterText(field('Comprimento (cm)'), '25,5');
    await tester.enterText(field('Largura (cm)'), '9,5');
    await tester.enterText(field('Comprimento (cm)', index: 1), '25.8');
    await tester.enterText(field('Largura (cm)', index: 1), '9,6');
    await tester.enterText(field('Numeração do calçado'), '39');
    await tester.enterText(
      field('Observações técnicas (opcional)'),
      ' Dor no calcanhar ',
    );
    await tester.tap(find.byType(DropdownButtonFormField<ArchType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plano').last);
    await tester.pumpAndSettle();
  }

  void expectSent(List<dynamic> captured) {
    final sent = captured.single as NewCustomOrder;
    expect(sent.advertisementId, expected.advertisementId);
    expect(sent.measurements, expected.measurements);
    expect(sent.technicalNotes, expected.technicalNotes);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('ENVIAR SOLICITAÇÃO'));
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    registerFallbackValue(expected);
    registerFallbackValue(photo);
  });

  setUp(() {
    create = MockCreateCustomOrderUseCase();
    sendPhoto = MockSendFootPhotoUseCase();
    hasConsent = MockHasCustomOrderConsentUseCase();
    grantConsent = MockGrantCustomOrderConsentUseCase();
    opened = [];
    consentAsked = 0;
    consentAnswer = true;
    when(hasConsent.execute).thenAnswer((_) async => true);
    when(
      () => create.execute(any()),
    ).thenAnswer((_) async => buildCustomOrderDetail());
  });

  testWidgets('shows how to measure and validates every measurement', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Órtese corretora para joanete'), findsOneWidget);
    expect(find.text('Como medir'), findsOneWidget);
    await tester.enterText(field('Comprimento (cm)'), '40');
    await tester.enterText(field('Largura (cm)'), 'abc');
    await tester.enterText(field('Numeração do calçado'), '60');
    await submit(tester);

    expect(find.text('Informe entre 10 e 35 cm'), findsOneWidget);
    expect(find.text('Valor inválido (ex.: 26,5)'), findsOneWidget);
    expect(find.text('Campo obrigatório'), findsNWidgets(3));
    expect(find.text('Informe um número entre 15 e 50'), findsOneWidget);
    verifyNever(() => create.execute(any()));
  });

  testWidgets('sends the measurements and opens the request', (tester) async {
    await pumpPage(tester);
    await fillForm(tester);
    await submit(tester);

    expectSent(verify(() => create.execute(captureAny())).captured);
    verifyNever(() => sendPhoto.execute(any(), any()));
    expect(opened.single.request.id, 'c1');
    expect(find.text('Solicitação enviada ao vendedor.'), findsOneWidget);
    expect(consentAsked, 0);
  });

  testWidgets('sends the chosen photo after the request', (tester) async {
    when(
      () => sendPhoto.execute('c1', photo),
    ).thenAnswer((_) async => buildCustomOrderDetail());
    await pumpPage(tester);
    await fillForm(tester);
    await tester.tap(find.text('Adicionar foto'));
    await tester.pumpAndSettle();

    expect(find.text('pe.jpg'), findsOneWidget);
    await submit(tester);

    verify(() => sendPhoto.execute('c1', photo)).called(1);
    expect(opened, hasLength(1));
  });

  testWidgets('asks for consent first and sends nothing when declined', (
    tester,
  ) async {
    when(hasConsent.execute).thenAnswer((_) async => false);
    consentAnswer = false;
    await pumpPage(tester);
    await fillForm(tester);
    await submit(tester);

    expect(consentAsked, 1);
    verifyNever(grantConsent.execute);
    verifyNever(() => create.execute(any()));
  });

  testWidgets('records the consent and then sends', (tester) async {
    when(hasConsent.execute).thenAnswer((_) async => false);
    when(grantConsent.execute).thenAnswer(
      (_) async => ConsentEntity(
        purpose: ConsentPurposes.customOrder,
        termsVersion: ConsentTermsVersions.customOrder,
        grantedAt: DateTime(2026),
      ),
    );
    await pumpPage(tester);
    await fillForm(tester);
    await submit(tester);

    verify(grantConsent.execute).called(1);
    expectSent(verify(() => create.execute(captureAny())).captured);
  });

  testWidgets('stays on the form when the ad no longer takes requests', (
    tester,
  ) async {
    when(() => create.execute(any())).thenThrow(
      buildDioException(
        statusCode: 409,
        data: {'error': 'this advertisement does not take custom orders'},
      ),
    );
    await pumpPage(tester);
    await fillForm(tester);
    await submit(tester);

    expect(
      find.text('Este anúncio não aceita pedidos sob medida.'),
      findsOneWidget,
    );
    expect(opened, isEmpty);
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_form_step.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/presentation/bloc/ad_form_bloc.dart';
import 'package:solado_certo_app/features/seller/presentation/pages/ad_form_page.dart';

class MockAdFormBloc extends MockBloc<AdFormEvent, AdFormState>
    implements AdFormBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAdFormBloc bloc;
  late MockAuthBloc authBloc;
  late UploadFile? pickedPhoto;

  const photo = UploadFile(bytes: [1, 2, 3], filename: 'foto.jpg');
  const options = CatalogFilterOptions(
    categories: [
      CategoryEntity(
        id: '301',
        name: 'Palmilhas',
        requiredAttributes: [
          'side',
          'size',
          'material',
          'rigidity',
          'usage_indication',
        ],
      ),
      CategoryEntity(
        id: '303',
        name: 'Meias terapêuticas',
        requiredAttributes: ['size', 'material'],
      ),
    ],
    purposes: [PurposeEntity(code: 'prevention', name: 'Prevenção')],
    conditions: [ConditionEntity(id: '501', name: 'Fascite plantar')],
  );

  SellerAdEntity ad({
    AdStatus status = AdStatus.draft,
    String categoryId = '301',
    List<SellerAdImage> images = const [],
  }) => SellerAdEntity(
    id: '601',
    title: 'Palmilha esportiva',
    price: 89.9,
    stock: 10,
    status: status,
    categoryId: categoryId,
    images: images,
  );

  AdFormState ready({
    SellerAdEntity? ad,
    AdFormStep step = AdFormStep.general,
    Set<String> highlightedFields = const {},
  }) => AdFormState(
    status: AdFormStatus.ready,
    options: options,
    ad: ad,
    step: step,
    highlightedFields: highlightedFields,
  );

  Future<void> pumpPage(WidgetTester tester, AdFormState state) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<AdFormBloc>.value(value: bloc),
          ],
          child: AdFormPage(pickPhoto: () async => pickedPhoto),
        ),
      ),
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  T capturedEvent<T>() =>
      verify(() => bloc.add(captureAny())).captured.single as T;

  setUpAll(() {
    registerFallbackValue(LoadAdFormEvent());
  });

  setUp(() {
    bloc = MockAdFormBloc();
    authBloc = MockAuthBloc();
    pickedPhoto = photo;
    when(() => authBloc.state).thenReturn(AuthUnauthenticated());
  });

  group('new ad', () {
    testWidgets('needs a title and a category to move on', (tester) async {
      await pumpPage(tester, ready());

      await tap(tester, find.text('PRÓXIMO'));

      expect(find.text('Campo obrigatório'), findsOneWidget);
      expect(find.text('Escolha a categoria'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('sends the typed values when moving on', (tester) async {
      await pumpPage(tester, ready());

      await tester.enterText(find.byType(TextFormField).at(0), ' Palmilha ');
      await tap(tester, find.byType(DropdownButtonFormField<String>));
      await tap(tester, find.text('Palmilhas').last);
      await tester.enterText(find.byType(TextFormField).at(2), '89,9');
      await tap(tester, find.text('PRÓXIMO'));

      final event = capturedEvent<GoToStepEvent>();
      expect(event.step, AdFormStep.attributes);
      expect(event.draft.title, 'Palmilha');
      expect(event.draft.categoryId, '301');
      expect(event.draft.price, '89.9');
      expect(event.draft.stock, 1);
    });

    testWidgets('offers publishing and saving a draft', (tester) async {
      await pumpPage(tester, ready(step: AdFormStep.review));

      expect(find.text('NOVO ANÚNCIO'), findsOneWidget);
      expect(find.text('Salvar rascunho'), findsOneWidget);
      expect(find.text('PUBLICAR'), findsOneWidget);
      expect(
        find.text('Salve o rascunho para conferir o que falta.'),
        findsOneWidget,
      );
    });
  });

  group('required attributes (RF-031)', () {
    testWidgets('marks the attributes the category requires', (tester) async {
      await pumpPage(tester, ready(ad: ad(), step: AdFormStep.attributes));

      expect(find.text('Lado *'), findsOneWidget);
      expect(find.text('Rigidez *'), findsOneWidget);
      expect(find.text('Tamanho *'), findsOneWidget);
    });

    testWidgets('marks only size and material for socks', (tester) async {
      await pumpPage(
        tester,
        ready(
          ad: ad(categoryId: '303'),
          step: AdFormStep.attributes,
        ),
      );

      expect(find.text('Lado'), findsOneWidget);
      expect(find.text('Rigidez'), findsOneWidget);
      expect(find.text('Tamanho *'), findsOneWidget);
      expect(find.text('Material *'), findsOneWidget);
    });
  });

  testWidgets('highlights a missing field and flags its step', (tester) async {
    await pumpPage(
      tester,
      ready(
        ad: ad(),
        step: AdFormStep.purposes,
        highlightedFields: const {'contraindications'},
      ),
    );

    expect(find.text('Obrigatório para publicar'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ChoiceChip, '3. Finalidades e segurança'),
        matching: find.byIcon(Icons.error_outline),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).last,
      'Feridas abertas nos pés.',
    );
    await tester.pump();
    expect(find.text('Obrigatório para publicar'), findsNothing);
  });

  testWidgets('publishes the draft from the review step', (tester) async {
    await pumpPage(tester, ready(ad: ad(), step: AdFormStep.review));

    await tap(tester, find.text('PUBLICAR'));

    final event = capturedEvent<PublishAdEvent>();
    expect(event.draft.title, 'Palmilha esportiva');
    expect(event.draft.price, '89.90');
  });

  testWidgets('saves a published ad instead of publishing it', (tester) async {
    await pumpPage(
      tester,
      ready(
        ad: ad(status: AdStatus.published),
        step: AdFormStep.review,
      ),
    );

    expect(find.text('EDITAR ANÚNCIO'), findsOneWidget);
    expect(find.text('PUBLICAR'), findsNothing);
    await tap(tester, find.text('SALVAR ALTERAÇÕES'));

    expect(capturedEvent<AdFormEvent>(), isA<SaveAdEvent>());
  });

  group('photos', () {
    const images = [
      SellerAdImage(id: 'i1', url: '/files/public/ads/a.png', isCover: true),
      SellerAdImage(id: 'i2', url: '/files/public/ads/b.png'),
    ];

    testWidgets('uploads the picked photo', (tester) async {
      await pumpPage(tester, ready(ad: ad(), step: AdFormStep.photos));

      expect(find.text('0 de 6 fotos'), findsOneWidget);
      await tap(tester, find.text('Adicionar foto'));

      expect(capturedEvent<AddImageEvent>().photo, same(photo));
    });

    testWidgets('does nothing when the picker is cancelled', (tester) async {
      pickedPhoto = null;
      await pumpPage(tester, ready(ad: ad(), step: AdFormStep.photos));

      await tap(tester, find.text('Adicionar foto'));

      verifyNever(() => bloc.add(any()));
    });

    testWidgets('chooses another cover and moves a photo', (tester) async {
      await pumpPage(
        tester,
        ready(
          ad: ad(images: images),
          step: AdFormStep.photos,
        ),
      );

      expect(find.text('Capa'), findsOneWidget);
      await tap(tester, find.byTooltip('Usar como capa').last);
      expect(capturedEvent<SetCoverImageEvent>().imageId, 'i2');

      await tap(tester, find.byTooltip('Mover para a esquerda').last);
      final move = capturedEvent<MoveImageEvent>();
      expect((move.imageId, move.offset), ('i2', -1));
    });

    testWidgets('stops at six photos', (tester) async {
      await pumpPage(
        tester,
        ready(
          ad: ad(
            images: [
              for (var i = 0; i < 6; i++)
                SellerAdImage(id: 'i$i', url: '/files/public/ads/$i.png'),
            ],
          ),
          step: AdFormStep.photos,
        ),
      );

      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Adicionar foto'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('adds and removes shipping options', (tester) async {
    await pumpPage(tester, ready(ad: ad(), step: AdFormStep.shipping));

    await tap(tester, find.text('Adicionar opção de envio'));
    await tap(tester, find.text('Adicionar opção de envio'));
    expect(find.text('Opção 2'), findsOneWidget);

    await tap(tester, find.byTooltip('Remover opção 1'));
    expect(find.text('Opção 2'), findsNothing);
    expect(find.text('Opção 1'), findsOneWidget);
  });

  testWidgets('blocks saving an incomplete shipping option', (tester) async {
    await pumpPage(tester, ready(ad: ad(), step: AdFormStep.shipping));

    await tap(tester, find.text('Adicionar opção de envio'));
    await tap(tester, find.text('Salvar rascunho'));

    verifyNever(() => bloc.add(any()));
    expect(find.text('Campo obrigatório'), findsWidgets);
  });

  testWidgets('sends the shipping options when saving', (tester) async {
    await pumpPage(tester, ready(ad: ad(), step: AdFormStep.shipping));

    await tap(tester, find.text('Adicionar opção de envio'));
    final card = find.ancestor(
      of: find.text('Opção 1'),
      matching: find.byType(DecoratedBox),
    );
    final inputs = find.descendant(
      of: card.first,
      matching: find.byType(TextFormField),
    );
    await tester.enterText(inputs.at(0), 'PAC');
    await tester.enterText(inputs.at(2), '19,90');
    await tester.enterText(inputs.at(3), '7');
    await tap(tester, find.text('Salvar rascunho'));

    final draft = capturedEvent<SaveAdEvent>().draft;
    expect(draft.shippingOptions.single.asRecord(), (null, 'PAC', '19.90', 7));
  });
}

extension on ShippingOptionDraft {
  (String?, String, String, int) asRecord() => (id, name, price, deliveryDays);
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/presentation/bloc/my_ads_bloc.dart';
import 'package:solado_certo_app/features/seller/presentation/pages/my_ads_page.dart';

import '../../../../support/builders.dart';

class MockMyAdsBloc extends MockBloc<MyAdsEvent, MyAdsState>
    implements MyAdsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockMyAdsBloc bloc;
  late MockAuthBloc authBloc;
  late List<String?> openedForms;

  final ads = [
    buildSellerAd(id: '601', title: 'Palmilha esportiva'),
    buildSellerAd(id: '602', title: 'Tênis diabético', stock: 0),
    buildSellerAd(
      id: '603',
      title: 'Rascunho incompleto',
      status: AdStatus.draft,
      missingFields: ['price', 'images'],
    ),
    buildSellerAd(id: '604', title: 'Rascunho pronto', status: AdStatus.draft),
  ];

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<MyAdsBloc>.value(value: bloc),
        ],
        child: MyAdsPage(openForm: (_, adId) async => openedForms.add(adId)),
      ),
    ),
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String title) => tap(
    tester,
    find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(Row)),
      matching: find.byTooltip('Ações do anúncio'),
    ),
  );

  setUpAll(() {
    registerFallbackValue(LoadMyAdsEvent());
    registerFallbackValue(SignOutEvent());
  });

  setUp(() {
    openedForms = [];
    bloc = MockMyAdsBloc();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthUnauthenticated());
    when(() => bloc.state).thenReturn(MyAdsLoaded(ads: ads));
    when(() => bloc.isClosed).thenReturn(false);
  });

  testWidgets('counts the ads per tab and lists the published ones', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Publicados (2)'), findsOneWidget);
    expect(find.text('Rascunhos (2)'), findsOneWidget);
    expect(find.text('Pausados (0)'), findsOneWidget);
    expect(find.text('Palmilha esportiva'), findsOneWidget);
    expect(find.text('Rascunho pronto'), findsNothing);
  });

  testWidgets('shows "Esgotado" for a published ad without stock', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Esgotado'), findsOneWidget);
  });

  testWidgets('pauses a published ad', (tester) async {
    await pumpPage(tester);

    await openMenu(tester, 'Palmilha esportiva');
    await tap(tester, find.text('Pausar'));

    final event =
        verify(() => bloc.add(captureAny())).captured.single
            as ChangeAdStatusEvent;
    expect(event.adId, '601');
    expect(event.action, AdStatusAction.pause);
  });

  testWidgets('offers publishing only for a complete draft', (tester) async {
    await pumpPage(tester);
    await tap(tester, find.text('Rascunhos (2)'));

    expect(find.text('Incompleto'), findsOneWidget);
    expect(find.text('Falta preencher: Preço, Fotos.'), findsOneWidget);

    await openMenu(tester, 'Rascunho incompleto');
    expect(find.text('Publicar'), findsNothing);
    expect(find.text('Remover'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await openMenu(tester, 'Rascunho pronto');
    await tap(tester, find.text('Publicar'));
    verify(
      () => bloc.add(
        any(
          that: isA<ChangeAdStatusEvent>().having(
            (e) => e.action,
            'action',
            AdStatusAction.publish,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('asks for confirmation before removing', (tester) async {
    await pumpPage(tester);

    await openMenu(tester, 'Palmilha esportiva');
    await tap(tester, find.text('Remover'));
    expect(find.text('Remover anúncio?'), findsOneWidget);
    await tap(tester, find.text('Cancelar'));
    verifyNever(() => bloc.add(any()));

    await openMenu(tester, 'Palmilha esportiva');
    await tap(tester, find.text('Remover'));
    await tap(tester, find.widgetWithText(TextButton, 'Remover'));
    verify(
      () => bloc.add(
        any(that: isA<RemoveAdEvent>().having((e) => e.adId, 'id', '601')),
      ),
    ).called(1);
  });

  testWidgets('shows a spinner instead of the menu while an ad is busy', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(MyAdsLoaded(ads: ads, busyAdId: '601'));
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Ações do anúncio'), findsOneWidget);
  });

  testWidgets('shows an empty tab message', (tester) async {
    await pumpPage(tester);

    await tap(tester, find.text('Pausados (0)'));

    expect(find.text('Nenhum anúncio pausado.'), findsOneWidget);
  });

  testWidgets('lists the missing fields when publishing is refused', (
    tester,
  ) async {
    whenListen(
      bloc,
      Stream<MyAdsState>.fromIterable([
        MyAdsLoaded(
          ads: ads,
          failure: const MissingFieldsFailure(['contraindications']),
        ),
      ]),
      initialState: MyAdsLoaded(ads: ads),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(
      find.text(
        'Preencha os campos obrigatórios antes de publicar. '
        'Falta: Contraindicações.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('signs out when the session expired', (tester) async {
    whenListen(
      bloc,
      Stream<MyAdsState>.fromIterable([
        MyAdsLoaded(ads: ads, failure: UnauthorizedFailure()),
      ]),
      initialState: MyAdsLoaded(ads: ads),
    );
    await pumpPage(tester);
    await tester.pump();

    verify(() => authBloc.add(any(that: isA<SignOutEvent>()))).called(1);
  });

  testWidgets('offers a retry when loading fails', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(MyAdsLoadFailure(failure: NetworkFailure()));
    await pumpPage(tester);

    await tap(tester, find.text('TENTAR NOVAMENTE'));

    verify(() => bloc.add(any(that: isA<LoadMyAdsEvent>()))).called(1);
  });

  testWidgets('opens the form for a new ad and reloads on return', (
    tester,
  ) async {
    await pumpPage(tester);

    await tap(tester, find.text('Novo anúncio'));

    expect(openedForms, [null]);
    verify(() => bloc.add(any(that: isA<LoadMyAdsEvent>()))).called(1);
  });

  testWidgets('opens the form to edit an ad', (tester) async {
    await pumpPage(tester);

    await openMenu(tester, 'Palmilha esportiva');
    await tap(tester, find.text('Editar'));

    expect(openedForms, ['601']);
    verify(() => bloc.add(any(that: isA<LoadMyAdsEvent>()))).called(1);
  });
}

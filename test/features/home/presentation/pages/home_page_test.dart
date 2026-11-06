import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_items_use_case.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_options_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/home_sections_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/catalog_page.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/notifications/presentation/bloc/notifications_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;
  late MockGetCatalogItemsUseCase getItems;
  late MockGetCatalogItemsUseCase homeItems;

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: bloc),
            BlocProvider(
              create: (_) => CatalogOptionsCubit(
                getCatalogFilterOptionsUseCase:
                    getIt<GetCatalogFilterOptionsUseCase>(),
              )..load(),
            ),
            BlocProvider(
              create: (_) => HomeSectionsCubit(
                getHomeSectionsUseCase: MockGetHomeSectionsUseCase(),
              ),
            ),
            BlocProvider(
              create: (_) =>
                  CatalogBloc(getCatalogItemsUseCase: homeItems)
                    ..add(CatalogStarted()),
            ),
            BlocProvider(
              create: (_) => NotificationsBloc(
                getNotificationsUseCase: MockGetNotificationsUseCase(),
                markNotificationReadUseCase: MockMarkNotificationReadUseCase(),
                markAllNotificationsReadUseCase:
                    MockMarkAllNotificationsReadUseCase(),
              ),
            ),
          ],
          child: const HomePage(isSignedIn: true),
        ),
      ),
    );
    await tester.pump();
  }

  void stubHomeItems(Future<CatalogPageEntity> Function(int page) answer) {
    when(
      () => homeItems.execute(
        filters: any(named: 'filters'),
        sort: any(named: 'sort'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (invocation) => answer(invocation.namedArguments[#page] as int),
    );
  }

  List<CatalogItemEntity> buildItems(int count, {int first = 0}) => [
    for (var i = 0; i < count; i++) buildCatalogItem(id: '${first + i}'),
  ];

  void verifyHomePageRequested(int page) => verify(
    () => homeItems.execute(
      filters: any(named: 'filters'),
      sort: any(named: 'sort'),
      page: page,
    ),
  ).called(1);

  void verifyHomePageNotRequested(int page) => verifyNever(
    () => homeItems.execute(
      filters: any(named: 'filters'),
      sort: any(named: 'sort'),
      page: page,
    ),
  );

  CatalogFilters requestedFilters() =>
      verify(
            () => getItems.execute(
              filters: captureAny(named: 'filters'),
              sort: any(named: 'sort'),
              page: 1,
            ),
          ).captured.single
          as CatalogFilters;

  setUpAll(() {
    registerFallbackValue(const CatalogFilters());
    registerFallbackValue(CatalogSort.relevance);
  });

  setUp(() {
    bloc = MockAuthBloc();
    when(() => bloc.state).thenReturn(AuthAuthenticated(user: buildProfile()));
    registerCatalogFilterOptions();
    getItems = MockGetCatalogItemsUseCase();
    when(
      () => getItems.execute(
        filters: any(named: 'filters'),
        sort: any(named: 'sort'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => buildCatalogPage());
    getIt.registerSingleton<GetCatalogItemsUseCase>(getItems);
    homeItems = MockGetCatalogItemsUseCase();
    stubHomeItems((_) async => buildCatalogPage());
  });

  testWidgets('shows the profile shortcut instead of the sign-in link', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byTooltip('Meu perfil'), findsOneWidget);
    expect(find.text('Entre na sua conta'), findsNothing);
  });

  testWidgets('opens the catalog filtered by a top-level category', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('PALMILHAS SOB MEDIDA'), findsNothing);
    await tester.tap(find.text('CALÇADOS ORTOPÉDICOS'));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogPage), findsOneWidget);
    expect(requestedFilters().categoryId, '302');
  });

  testWidgets('opens the catalog with the searched text', (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextFormField), 'palmilha');
    await tester.tap(find.bySemanticsLabel('Pesquisar'));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogPage), findsOneWidget);
    expect(requestedFilters().query, 'palmilha');
    expect(find.text('palmilha'), findsOneWidget);
  });

  group('all products', () {
    testWidgets('shows the products in a grid', (tester) async {
      stubHomeItems(
        (_) async => buildCatalogPage(items: buildItems(2), totalItems: 2),
      );
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('Todos os produtos'), findsOneWidget);
      expect(find.text('Palmilha 0'), findsOneWidget);
      expect(find.text('Palmilha 1'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Palmilha 0')).dy,
        tester.getTopLeft(find.text('Palmilha 1')).dy,
      );
    });

    testWidgets('loads the next page only when scrolling near the end', (
      tester,
    ) async {
      stubHomeItems(
        (page) async => buildCatalogPage(
          items: buildItems(20, first: (page - 1) * 20),
          page: page,
          totalItems: 40,
          hasNext: page == 1,
        ),
      );
      await pumpHome(tester);
      await tester.pumpAndSettle();
      verifyHomePageNotRequested(2);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      verifyHomePageRequested(2);
    });

    testWidgets('loads more when the first page does not fill the screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      stubHomeItems(
        (page) async => buildCatalogPage(
          items: buildItems(2, first: (page - 1) * 2),
          page: page,
          totalItems: 4,
          hasNext: page == 1,
        ),
      );
      await pumpHome(tester);
      await tester.pumpAndSettle();

      verifyHomePageRequested(2);
    });

    testWidgets('hides the section when there are no products', (tester) async {
      stubHomeItems(
        (_) async => buildCatalogPage(items: const [], totalItems: 0),
      );
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('Todos os produtos'), findsNothing);
    });

    testWidgets('offers a retry when the products fail to load', (
      tester,
    ) async {
      stubHomeItems((_) async => throw buildDioException(statusCode: 500));
      await pumpHome(tester);
      await tester.pumpAndSettle();

      stubHomeItems((_) async => buildCatalogPage());
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Todos os produtos'), findsOneWidget);
      expect(find.text('Palmilha 601'), findsOneWidget);
    });
  });
}

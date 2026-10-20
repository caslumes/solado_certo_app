import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_items_use_case.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_options_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/recommendations_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/catalog_page.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/notifications/presentation/bloc/notifications_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;
  late MockGetCatalogItemsUseCase getItems;

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
              create: (_) => RecommendationsCubit(
                getRecommendedItemsUseCase: MockGetRecommendedItemsUseCase(),
              ),
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
}

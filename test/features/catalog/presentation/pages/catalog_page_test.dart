import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_options_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/catalog_page.dart';

import '../../../../support/builders.dart';

class MockCatalogBloc extends MockBloc<CatalogEvent, CatalogState>
    implements CatalogBloc {}

class MockCatalogOptionsCubit extends MockCubit<CatalogOptionsState>
    implements CatalogOptionsCubit {}

void main() {
  late MockCatalogBloc bloc;
  late MockCatalogOptionsCubit options;

  Future<void> pumpPage(WidgetTester tester, CatalogState state) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CatalogBloc>.value(value: bloc),
            BlocProvider<CatalogOptionsCubit>.value(value: options),
          ],
          child: const CatalogPage(),
        ),
      ),
    );
  }

  setUpAll(() => registerFallbackValue(CatalogRetryRequested()));

  setUp(() {
    bloc = MockCatalogBloc();
    options = MockCatalogOptionsCubit();
    when(
      () => options.state,
    ).thenReturn(CatalogOptionsLoaded(options: catalogFilterOptions));
  });

  testWidgets('suggests clearing the filters when nothing matches', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const CatalogState(
        status: CatalogStatus.empty,
        filters: CatalogFilters(query: 'xyz', state: 'AC'),
      ),
    );

    expect(find.text('Nenhum produto encontrado'), findsOneWidget);
    expect(find.text('xyz'), findsOneWidget);

    await tester.tap(find.text('LIMPAR FILTROS'));
    await tester.pump();

    expect(find.text('xyz'), findsNothing);
    verify(() => bloc.add(any(that: isA<CatalogFiltersCleared>()))).called(1);
  });

  testWidgets('offers no clearing for an empty catalog without filters', (
    tester,
  ) async {
    await pumpPage(tester, const CatalogState(status: CatalogStatus.empty));

    expect(find.text('Ainda não há produtos no catálogo.'), findsOneWidget);
    expect(find.text('LIMPAR FILTROS'), findsNothing);
  });

  testWidgets('retries after a failure', (tester) async {
    await pumpPage(
      tester,
      CatalogState(status: CatalogStatus.failure, failure: NetworkFailure()),
    );

    expect(find.text(NetworkFailure().message), findsOneWidget);

    await tester.tap(find.text('TENTAR NOVAMENTE'));

    verify(() => bloc.add(any(that: isA<CatalogRetryRequested>()))).called(1);
  });

  testWidgets('shows the total, the prices and the active filter count', (
    tester,
  ) async {
    await pumpPage(
      tester,
      CatalogState(
        status: CatalogStatus.loaded,
        filters: const CatalogFilters(state: 'SP', ratingMin: 4),
        items: [
          buildCatalogItem(id: '601'),
          buildCatalogItem(id: '602'),
        ],
        page: 1,
        totalItems: 2,
      ),
    );

    expect(find.text('2 produtos'), findsOneWidget);
    expect(find.text('Palmilha 601'), findsOneWidget);
    expect(find.text('R\$\u00A089,90'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('applies the filters chosen in the sheet', (tester) async {
    await pumpPage(
      tester,
      CatalogState(
        status: CatalogStatus.loaded,
        items: [buildCatalogItem()],
        page: 1,
        totalItems: 1,
      ),
    );

    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prevenção'));
    await tester.pump();
    await tester.tap(find.text('APLICAR'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        any(
          that: isA<CatalogFiltersApplied>().having(
            (event) => event.filters.purposes,
            'purposes',
            {'prevention'},
          ),
        ),
      ),
    ).called(1);
  });
}

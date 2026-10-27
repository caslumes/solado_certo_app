import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetCatalogItemsUseCase getItems;
  late Completer<CatalogPageEntity> slowResponse;

  CatalogBloc buildBloc({CatalogFilters filters = const CatalogFilters()}) =>
      CatalogBloc(getCatalogItemsUseCase: getItems, filters: filters);

  void answerPage(int page, Future<CatalogPageEntity> Function() answer) {
    when(
      () => getItems.execute(
        filters: any(named: 'filters'),
        sort: any(named: 'sort'),
        page: page,
      ),
    ).thenAnswer((_) => answer());
  }

  void verifyPageRequested(int page, {int times = 1}) => verify(
    () => getItems.execute(
      filters: any(named: 'filters'),
      sort: any(named: 'sort'),
      page: page,
    ),
  ).called(times);

  final firstPage = buildCatalogPage(
    items: [
      buildCatalogItem(id: '601'),
      buildCatalogItem(id: '602'),
    ],
    totalItems: 3,
    hasNext: true,
  );
  final secondPage = buildCatalogPage(
    items: [buildCatalogItem(id: '603')],
    page: 2,
    totalItems: 3,
  );

  CatalogState loadedState() => CatalogState(
    status: CatalogStatus.loaded,
    items: firstPage.items,
    page: 1,
    totalItems: 3,
    hasNext: true,
  );

  setUpAll(() {
    registerFallbackValue(const CatalogFilters());
    registerFallbackValue(CatalogSort.relevance);
  });

  setUp(() {
    getItems = MockGetCatalogItemsUseCase();
    answerPage(1, () async => firstPage);
    answerPage(2, () async => secondPage);
  });

  group('CatalogStarted', () {
    blocTest<CatalogBloc, CatalogState>(
      'loads the first page with the given filters',
      build: () => buildBloc(filters: const CatalogFilters(query: 'palm')),
      act: (bloc) => bloc.add(CatalogStarted()),
      expect: () => [
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loading)
            .having((s) => s.filters.query, 'query', 'palm'),
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loaded)
            .having((s) => s.items.map((i) => i.id), 'items', ['601', '602'])
            .having((s) => s.totalItems, 'totalItems', 3)
            .having((s) => s.hasNext, 'hasNext', true),
      ],
      verify: (_) => verify(
        () => getItems.execute(
          filters: any(
            named: 'filters',
            that: isA<CatalogFilters>().having((f) => f.query, 'query', 'palm'),
          ),
          sort: CatalogSort.relevance,
          page: 1,
        ),
      ).called(1),
    );

    blocTest<CatalogBloc, CatalogState>(
      'is empty when nothing matches',
      setUp: () => answerPage(
        1,
        () async => buildCatalogPage(items: const [], totalItems: 0),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(CatalogStarted()),
      expect: () => [
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.loading,
        ),
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.empty,
        ),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'fails with the mapped failure',
      setUp: () => answerPage(
        1,
        () async =>
            throw buildDioException(type: DioExceptionType.connectionError),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(CatalogStarted()),
      expect: () => [
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.loading,
        ),
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.failure)
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'retries the first page after a failure',
      build: buildBloc,
      seed: () => CatalogState(
        status: CatalogStatus.failure,
        failure: NetworkFailure(),
      ),
      act: (bloc) => bloc.add(CatalogRetryRequested()),
      expect: () => [
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loading)
            .having((s) => s.failure, 'failure', isNull),
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.loaded,
        ),
      ],
    );
  });

  group('CatalogNextPageRequested', () {
    blocTest<CatalogBloc, CatalogState>(
      'appends the next page',
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(CatalogNextPageRequested()),
      expect: () => [
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.loadingNextPage,
        ),
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loaded)
            .having((s) => s.items.map((i) => i.id), 'items', [
              '601',
              '602',
              '603',
            ])
            .having((s) => s.page, 'page', 2)
            .having((s) => s.hasNext, 'hasNext', false),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'never requests a page that is loading or past the last one',
      setUp: () {
        slowResponse = Completer<CatalogPageEntity>();
        answerPage(2, () => slowResponse.future);
      },
      build: buildBloc,
      seed: loadedState,
      act: (bloc) async {
        bloc.add(CatalogNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(CatalogNextPageRequested())
          ..add(CatalogNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        slowResponse.complete(secondPage);
        await Future<void>.delayed(Duration.zero);
        bloc.add(CatalogNextPageRequested());
      },
      verify: (_) {
        verifyPageRequested(2);
        verifyNoMoreInteractions(getItems);
      },
    );

    blocTest<CatalogBloc, CatalogState>(
      'keeps the loaded items when the next page fails',
      setUp: () => answerPage(
        2,
        () async =>
            throw buildDioException(type: DioExceptionType.connectionError),
      ),
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(CatalogNextPageRequested()),
      expect: () => [
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.loadingNextPage,
        ),
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loaded)
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
      ],
    );
  });

  group('CatalogRefreshRequested', () {
    blocTest<CatalogBloc, CatalogState>(
      'reloads the first page while keeping the items on screen',
      setUp: () => answerPage(
        1,
        () async => buildCatalogPage(items: [buildCatalogItem(id: '609')]),
      ),
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(CatalogRefreshRequested()),
      expect: () => [
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.refreshing)
            .having((s) => s.items.length, 'items', 2),
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loaded)
            .having((s) => s.items.map((i) => i.id), 'items', ['609'])
            .having((s) => s.page, 'page', 1),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'drops a next page that answers after a refresh',
      setUp: () {
        slowResponse = Completer<CatalogPageEntity>();
        answerPage(2, () => slowResponse.future);
      },
      build: buildBloc,
      seed: loadedState,
      act: (bloc) async {
        bloc.add(CatalogNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(CatalogRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        slowResponse.complete(secondPage);
      },
      expect: () => [
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.loadingNextPage,
        ),
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.refreshing,
        ),
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loaded)
            .having((s) => s.page, 'page', 1),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'keeps the items and reports the failure when refreshing fails',
      setUp: () => answerPage(
        1,
        () async =>
            throw buildDioException(type: DioExceptionType.connectionError),
      ),
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(CatalogRefreshRequested()),
      expect: () => [
        isA<CatalogState>().having(
          (s) => s.status,
          'status',
          CatalogStatus.refreshing,
        ),
        isA<CatalogState>()
            .having((s) => s.status, 'status', CatalogStatus.loaded)
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
      ],
    );
  });

  group('CatalogQueryChanged', () {
    blocTest<CatalogBloc, CatalogState>(
      'searches once, 400 ms after the last keystroke',
      build: buildBloc,
      seed: loadedState,
      act: (bloc) async {
        bloc
          ..add(CatalogQueryChanged('p'))
          ..add(CatalogQueryChanged('pa'))
          ..add(CatalogQueryChanged('palm'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        verifyNever(
          () => getItems.execute(
            filters: any(named: 'filters'),
            sort: any(named: 'sort'),
            page: any(named: 'page'),
          ),
        );
      },
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        verify(
          () => getItems.execute(
            filters: any(
              named: 'filters',
              that: isA<CatalogFilters>().having(
                (f) => f.query,
                'query',
                'palm',
              ),
            ),
            sort: any(named: 'sort'),
            page: 1,
          ),
        ).called(1);
        verifyNoMoreInteractions(getItems);
        expect(bloc.state.filters.query, 'palm');
      },
    );

    blocTest<CatalogBloc, CatalogState>(
      'does not search again for the same text',
      build: buildBloc,
      seed: () => CatalogState(
        status: CatalogStatus.loaded,
        filters: const CatalogFilters(query: 'palm'),
        items: firstPage.items,
      ),
      act: (bloc) => bloc.add(CatalogQueryChanged('palm ')),
      wait: const Duration(milliseconds: 500),
      verify: (_) => verifyZeroInteractions(getItems),
    );

    blocTest<CatalogBloc, CatalogState>(
      'shows only the latest search when an older one answers last',
      setUp: () {
        slowResponse = Completer<CatalogPageEntity>();
        when(
          () => getItems.execute(
            filters: any(
              named: 'filters',
              that: isA<CatalogFilters>().having((f) => f.query, 'query', 'a'),
            ),
            sort: any(named: 'sort'),
            page: 1,
          ),
        ).thenAnswer((_) => slowResponse.future);
      },
      build: () => buildBloc(filters: const CatalogFilters(query: 'a')),
      act: (bloc) async {
        bloc.add(CatalogStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(CatalogQueryChanged('b'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        slowResponse.complete(
          buildCatalogPage(items: [buildCatalogItem(id: 'stale')]),
        );
      },
      verify: (bloc) {
        expect(bloc.state.status, CatalogStatus.loaded);
        expect(bloc.state.filters.query, 'b');
        expect(bloc.state.items.map((i) => i.id), ['601', '602']);
      },
    );
  });

  group('filters and sort', () {
    blocTest<CatalogBloc, CatalogState>(
      'applies the sheet filters and keeps the search text',
      build: buildBloc,
      seed: () => CatalogState(
        status: CatalogStatus.loaded,
        filters: const CatalogFilters(query: 'palm', state: 'RJ'),
        items: firstPage.items,
      ),
      act: (bloc) => bloc.add(
        CatalogFiltersApplied(
          const CatalogFilters(categoryId: '301', ratingMin: 4),
        ),
      ),
      verify: (bloc) {
        final filters = bloc.state.filters;
        expect(filters.query, 'palm');
        expect(filters.categoryId, '301');
        expect(filters.ratingMin, 4);
        expect(filters.state, isNull);
        verifyPageRequested(1);
      },
    );

    blocTest<CatalogBloc, CatalogState>(
      'clears the search text and every filter',
      build: buildBloc,
      seed: () => CatalogState(
        status: CatalogStatus.empty,
        filters: const CatalogFilters(query: 'xyz', purposes: {'prevention'}),
      ),
      act: (bloc) => bloc.add(CatalogFiltersCleared()),
      verify: (bloc) => expect(bloc.state.filters.isEmpty, isTrue),
    );

    blocTest<CatalogBloc, CatalogState>(
      'reloads the first page with the new sort',
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(CatalogSortChanged(CatalogSort.priceAsc)),
      verify: (bloc) {
        expect(bloc.state.sort, CatalogSort.priceAsc);
        expect(bloc.state.page, 1);
        verify(
          () => getItems.execute(
            filters: any(named: 'filters'),
            sort: CatalogSort.priceAsc,
            page: 1,
          ),
        ).called(1);
      },
    );
  });
}

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/recommendations_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetRecommendedItemsUseCase getRecommendedItems;

  RecommendationsCubit buildCubit() =>
      RecommendationsCubit(getRecommendedItemsUseCase: getRecommendedItems);

  setUp(() => getRecommendedItems = MockGetRecommendedItemsUseCase());

  test('starts hidden', () {
    expect(buildCubit().state, isA<RecommendationsHidden>());
  });

  blocTest<RecommendationsCubit, RecommendationsState>(
    'shows the matching items',
    setUp: () => when(
      getRecommendedItems.execute,
    ).thenAnswer((_) async => [buildCatalogItem(id: '603')]),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<RecommendationsLoaded>().having(
        (state) => state.items.single.id,
        'item id',
        '603',
      ),
    ],
  );

  blocTest<RecommendationsCubit, RecommendationsState>(
    'stays hidden without matches',
    setUp: () =>
        when(getRecommendedItems.execute).thenAnswer((_) async => const []),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [isA<RecommendationsHidden>()],
  );

  blocTest<RecommendationsCubit, RecommendationsState>(
    'hides the section without the podological profile consent',
    setUp: () => when(
      getRecommendedItems.execute,
    ).thenThrow(buildDioException(statusCode: 403)),
    build: buildCubit,
    seed: () => RecommendationsLoaded(items: [buildCatalogItem()]),
    act: (cubit) => cubit.load(),
    expect: () => [isA<RecommendationsHidden>()],
  );

  blocTest<RecommendationsCubit, RecommendationsState>(
    'ignores a response that arrives after signing out',
    build: buildCubit,
    act: (cubit) async {
      final response = Completer<List<CatalogItemEntity>>();
      when(getRecommendedItems.execute).thenAnswer((_) => response.future);
      final load = cubit.load();
      cubit.hide();
      response.complete([buildCatalogItem()]);
      await load;
    },
    expect: () => [isA<RecommendationsHidden>()],
  );
}

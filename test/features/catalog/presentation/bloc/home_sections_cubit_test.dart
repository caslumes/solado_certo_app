import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/home_section.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/home_sections_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetHomeSectionsUseCase getHomeSections;

  HomeSectionsCubit buildCubit() =>
      HomeSectionsCubit(getHomeSectionsUseCase: getHomeSections);

  setUp(() => getHomeSections = MockGetHomeSectionsUseCase());

  test('starts with no sections', () {
    expect(buildCubit().state, isEmpty);
  });

  blocTest<HomeSectionsCubit, List<HomeSectionEntity>>(
    'shows the sections in the order the server sent them',
    setUp: () => when(getHomeSections.execute).thenAnswer(
      (_) async => [
        buildHomeSection(code: 'FOR_ME', title: 'Para você'),
        buildHomeSection(code: 'TRENDING', title: 'Em alta'),
      ],
    ),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<List<HomeSectionEntity>>().having(
        (sections) => sections.map((section) => section.code),
        'codes',
        ['FOR_ME', 'TRENDING'],
      ),
    ],
  );

  blocTest<HomeSectionsCubit, List<HomeSectionEntity>>(
    'hides the sections when the request fails',
    setUp: () => when(
      getHomeSections.execute,
    ).thenThrow(buildDioException(statusCode: 500)),
    build: buildCubit,
    seed: () => [buildHomeSection()],
    act: (cubit) => cubit.load(),
    expect: () => [isEmpty],
  );

  blocTest<HomeSectionsCubit, List<HomeSectionEntity>>(
    'ignores a response that arrives after signing out',
    build: buildCubit,
    seed: () => [buildHomeSection()],
    act: (cubit) async {
      final response = Completer<List<HomeSectionEntity>>();
      when(getHomeSections.execute).thenAnswer((_) => response.future);
      final load = cubit.load();
      cubit.hide();
      response.complete([buildHomeSection()]);
      await load;
    },
    expect: () => [isEmpty],
  );

  blocTest<HomeSectionsCubit, List<HomeSectionEntity>>(
    'keeps only the response of the latest load',
    build: buildCubit,
    act: (cubit) async {
      final older = Completer<List<HomeSectionEntity>>();
      final newer = Completer<List<HomeSectionEntity>>();
      final responses = [older, newer];
      when(
        getHomeSections.execute,
      ).thenAnswer((_) => responses.removeAt(0).future);
      final first = cubit.load();
      final second = cubit.load();
      newer.complete([buildHomeSection(code: 'TRENDING')]);
      await second;
      older.complete([buildHomeSection(code: 'FOR_ME')]);
      await first;
    },
    expect: () => [
      isA<List<HomeSectionEntity>>().having(
        (sections) => sections.single.code,
        'code',
        'TRENDING',
      ),
    ],
  );
}

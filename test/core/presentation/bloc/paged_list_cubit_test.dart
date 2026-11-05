import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';

typedef ListCubit = PagedListCubit<String, String>;
typedef ListState = PagedListState<String, String>;

void main() {
  late List<(String, int)> calls;
  late Map<(String, int), Object> answers;

  Future<PageResult<String>> loader(String filter, int page) async {
    calls.add((filter, page));
    final answer = answers[(filter, page)];
    if (answer is PageResult<String>) return answer;
    throw answer ?? NotFoundFailure();
  }

  ListCubit buildCubit() => ListCubit(loader: loader, filter: 'all');

  setUp(() {
    calls = [];
    answers = {
      ('all', 1): (items: ['a', 'b'], page: 1, hasNext: true),
      ('all', 2): (items: ['c'], page: 2, hasNext: false),
      ('blocked', 1): (items: ['x'], page: 1, hasNext: false),
    };
  });

  blocTest<ListCubit, ListState>(
    'loads the first page with the initial filter',
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ListState>().having(
        (s) => s.status,
        'status',
        PagedListStatus.loading,
      ),
      isA<ListState>()
          .having((s) => s.status, 'status', PagedListStatus.loaded)
          .having((s) => s.items, 'items', ['a', 'b'])
          .having((s) => s.hasNext, 'hasNext', true),
    ],
  );

  blocTest<ListCubit, ListState>(
    'appends the next page and stops at the last one',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.items, ['a', 'b', 'c']);
      expect(cubit.state.hasNext, isFalse);
      expect(calls, [('all', 1), ('all', 2)]);
    },
  );

  blocTest<ListCubit, ListState>(
    'starts over from the first page when the filter changes',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.applyFilter('blocked');
    },
    skip: 2,
    expect: () => [
      isA<ListState>()
          .having((s) => s.status, 'status', PagedListStatus.loading)
          .having((s) => s.filter, 'filter', 'blocked')
          .having((s) => s.items, 'items', isEmpty),
      isA<ListState>().having((s) => s.items, 'items', ['x']),
    ],
  );

  blocTest<ListCubit, ListState>(
    'keeps the items when a refresh fails',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      answers[('all', 1)] = NetworkFailure();
      await cubit.load();
    },
    skip: 2,
    expect: () => [
      isA<ListState>()
          .having((s) => s.status, 'status', PagedListStatus.loaded)
          .having((s) => s.items, 'items', ['a', 'b'])
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<ListCubit, ListState>(
    'reports a first load failure',
    build: () => ListCubit(loader: loader, filter: 'missing'),
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<ListState>()
          .having((s) => s.status, 'status', PagedListStatus.failure)
          .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
    ],
  );

  blocTest<ListCubit, ListState>(
    'replaces the changed item',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      expect(
        await cubit.change(() async => 'B', (item) => item == 'b'),
        isTrue,
      );
    },
    skip: 2,
    expect: () => [
      isA<ListState>().having((s) => s.busy, 'busy', true),
      isA<ListState>().having((s) => s.busy, 'busy', false).having(
        (s) => s.items,
        'items',
        ['a', 'B'],
      ),
    ],
  );

  blocTest<ListCubit, ListState>(
    'keeps the items and reports the failure when a change is refused',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      final changed = await cubit.change(
        () async => throw ForbiddenFailure(),
        (item) => item == 'b',
      );
      expect(changed, isFalse);
    },
    skip: 3,
    expect: () => [
      isA<ListState>()
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.items, 'items', ['a', 'b'])
          .having((s) => s.failure, 'failure', isA<ForbiddenFailure>()),
    ],
  );
}

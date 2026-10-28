import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_orders_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetCustomOrdersUseCase getRequests;

  CustomOrdersPageEntity page(int number, List<String> ids, bool hasNext) =>
      CustomOrdersPageEntity(
        items: [for (final id in ids) buildCustomOrder(id: id)],
        currentPage: number,
        hasNext: hasNext,
      );

  setUp(() => getRequests = MockGetCustomOrdersUseCase());

  blocTest<CustomOrdersCubit, CustomOrdersState>(
    'loads the first page and then the next',
    setUp: () {
      when(
        () => getRequests.execute(1),
      ).thenAnswer((_) async => page(1, ['c1'], true));
      when(
        () => getRequests.execute(2),
      ).thenAnswer((_) async => page(2, ['c2'], false));
    },
    build: () => CustomOrdersCubit(getCustomOrdersUseCase: getRequests),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore();
    },
    expect: () => [
      isA<CustomOrdersState>().having(
        (s) => s.status,
        'status',
        CustomOrdersStatus.loading,
      ),
      isA<CustomOrdersState>().having((s) => s.requests.length, 'count', 1),
      isA<CustomOrdersState>().having(
        (s) => s.loadingMore,
        'loadingMore',
        true,
      ),
      isA<CustomOrdersState>()
          .having((s) => s.requests.map((r) => r.id), 'ids', ['c1', 'c2'])
          .having((s) => s.hasNext, 'hasNext', false),
    ],
  );

  blocTest<CustomOrdersCubit, CustomOrdersState>(
    'shows the error of the first page',
    setUp: () => when(
      () => getRequests.execute(1),
    ).thenThrow(buildDioException(statusCode: 500)),
    build: () => CustomOrdersCubit(getCustomOrdersUseCase: getRequests),
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<CustomOrdersState>()
          .having((s) => s.status, 'status', CustomOrdersStatus.failure)
          .having((s) => s.failure, 'failure', isA<ServerFailure>()),
    ],
  );

  blocTest<CustomOrdersCubit, CustomOrdersState>(
    'replaces a request changed in its detail',
    build: () => CustomOrdersCubit(getCustomOrdersUseCase: getRequests),
    seed: () => CustomOrdersState(
      status: CustomOrdersStatus.loaded,
      requests: [
        buildCustomOrder(id: 'c1'),
        buildCustomOrder(id: 'c2'),
      ],
    ),
    act: (cubit) => cubit.changed(
      buildCustomOrder(id: 'c2', status: CustomOrderStatus.cancelled),
    ),
    expect: () => [
      isA<CustomOrdersState>().having(
        (s) => s.requests.map((r) => r.status),
        'statuses',
        [CustomOrderStatus.requested, CustomOrderStatus.cancelled],
      ),
    ],
  );
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/presentation/bloc/indicators_cubit.dart';

import '../../../../support/mocks.dart';

IndicatorsEntity buildIndicators({int orders = 5}) => IndicatorsEntity(
  from: DateTime(2026, 10, 6),
  to: DateTime(2026, 11, 4),
  newUsers: 4,
  blockedUsers: 1,
  suspendedUsers: 0,
  newAds: 2,
  publishedAds: 9,
  orders: orders,
  ordersByStatus: const {},
  paidOrders: 5,
  paidAmount: 640.5,
  paymentsByStatus: const {},
  refundsGivenUp: 1,
  ticketsOpened: 3,
  ticketsResolved: 2,
  openTickets: 1,
);

void main() {
  late MockGetIndicatorsUseCase getIndicators;

  IndicatorsCubit buildCubit() => IndicatorsCubit(
    getIndicatorsUseCase: getIndicators,
    now: () => DateTime(2026, 11, 4, 15, 30),
  );

  setUp(() {
    getIndicators = MockGetIndicatorsUseCase();
    when(
      () => getIndicators.execute(any(), any()),
    ).thenAnswer((_) async => buildIndicators());
  });

  blocTest<IndicatorsCubit, IndicatorsState>(
    'loads the last 30 days including today',
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<IndicatorsState>().having((s) => s.loading, 'loading', true),
      isA<IndicatorsState>()
          .having((s) => s.period, 'period', IndicatorPeriod.month)
          .having((s) => s.indicators?.orders, 'orders', 5),
    ],
    verify: (_) => verify(
      () => getIndicators.execute(DateTime(2026, 10, 6), DateTime(2026, 11, 4)),
    ).called(1),
  );

  blocTest<IndicatorsCubit, IndicatorsState>(
    'reloads with another period',
    build: buildCubit,
    act: (cubit) => cubit.load(IndicatorPeriod.week),
    verify: (cubit) {
      expect(cubit.state.period, IndicatorPeriod.week);
      verify(
        () => getIndicators.execute(
          DateTime(2026, 10, 29),
          DateTime(2026, 11, 4),
        ),
      ).called(1);
    },
  );

  blocTest<IndicatorsCubit, IndicatorsState>(
    'keeps the numbers when a refresh fails',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      when(
        () => getIndicators.execute(any(), any()),
      ).thenThrow(NetworkFailure());
      await cubit.load();
    },
    skip: 2,
    expect: () => [
      isA<IndicatorsState>()
          .having((s) => s.indicators?.orders, 'orders', 5)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<IndicatorsCubit, IndicatorsState>(
    'reports a first load failure',
    setUp: () => when(
      () => getIndicators.execute(any(), any()),
    ).thenThrow(ForbiddenFailure()),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<IndicatorsState>()
          .having((s) => s.indicators, 'indicators', isNull)
          .having((s) => s.failure, 'failure', isA<ForbiddenFailure>()),
    ],
  );
}

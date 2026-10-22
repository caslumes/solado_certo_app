import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetOrdersUseCase getOrders;

  final first = buildOrder(id: 'o1');
  final second = buildOrder(id: 'o2');
  final third = buildOrder(id: 'o3');

  OrdersPageEntity page(
    List<OrderEntity> orders, {
    int at = 1,
    bool next = false,
  }) => OrdersPageEntity(items: orders, currentPage: at, hasNext: next);

  OrdersState loaded(
    List<OrderEntity> orders, {
    int at = 1,
    bool next = false,
  }) => OrdersState(
    status: OrdersStatus.loaded,
    orders: orders,
    page: at,
    hasNext: next,
  );

  TypeMatcher<OrdersState> matches({
    OrdersStatus status = OrdersStatus.loaded,
    List<String>? ids,
    bool loadingMore = false,
    TypeMatcher<Failure>? failure,
  }) {
    var matcher = isA<OrdersState>()
        .having((s) => s.status, 'status', status)
        .having((s) => s.loadingMore, 'loadingMore', loadingMore)
        .having((s) => s.failure, 'failure', failure ?? isNull);
    if (ids != null) {
      matcher = matcher.having((s) => s.orders.map((o) => o.id), 'ids', ids);
    }
    return matcher;
  }

  OrdersBloc buildBloc() => OrdersBloc(getOrdersUseCase: getOrders);

  setUp(() => getOrders = MockGetOrdersUseCase());

  group('LoadOrdersEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'loads the first page',
      setUp: () => when(
        () => getOrders.execute(1, filter: const OrderFilter()),
      ).thenAnswer((_) async => page([first, second], next: true)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadOrdersEvent()),
      expect: () => [
        matches(status: OrdersStatus.loading),
        matches(ids: ['o1', 'o2']).having((s) => s.hasNext, 'hasNext', true),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'a first load that fails shows the error',
      setUp: () => when(
        () => getOrders.execute(1, filter: const OrderFilter()),
      ).thenThrow(buildDioException(type: DioExceptionType.connectionError)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadOrdersEvent()),
      expect: () => [
        matches(status: OrdersStatus.loading),
        matches(status: OrdersStatus.failure, failure: isA<NetworkFailure>()),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'a refresh keeps the orders on screen, even when it fails',
      setUp: () => when(
        () => getOrders.execute(1, filter: const OrderFilter()),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => loaded([first]),
      act: (bloc) => bloc.add(LoadOrdersEvent()),
      expect: () => [
        matches(ids: ['o1'], failure: isA<ServerFailure>()),
      ],
    );
  });

  group('LoadMoreOrdersEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'appends the next page',
      setUp: () => when(
        () => getOrders.execute(2, filter: const OrderFilter()),
      ).thenAnswer((_) async => page([third], at: 2)),
      build: buildBloc,
      seed: () => loaded([first, second], next: true),
      act: (bloc) => bloc.add(LoadMoreOrdersEvent()),
      expect: () => [
        matches(ids: ['o1', 'o2'], loadingMore: true),
        matches(
          ids: ['o1', 'o2', 'o3'],
        ).having((s) => s.hasNext, 'hasNext', false),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'does nothing on the last page',
      build: buildBloc,
      seed: () => loaded([first]),
      act: (bloc) => bloc.add(LoadMoreOrdersEvent()),
      expect: () => <OrdersState>[],
      verify: (_) => verifyNever(
        () => getOrders.execute(any(), filter: const OrderFilter()),
      ),
    );

    blocTest<OrdersBloc, OrdersState>(
      'a failure keeps the orders and allows another try',
      setUp: () => when(
        () => getOrders.execute(2, filter: const OrderFilter()),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => loaded([first], next: true),
      act: (bloc) => bloc.add(LoadMoreOrdersEvent()),
      expect: () => [
        matches(ids: ['o1'], loadingMore: true),
        matches(
          ids: ['o1'],
          failure: isA<ServerFailure>(),
        ).having((s) => s.hasNext, 'hasNext', true),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'drops a next page that arrives after a refresh',
      setUp: () {
        final nextPage = Completer<OrdersPageEntity>();
        when(
          () => getOrders.execute(2, filter: const OrderFilter()),
        ).thenAnswer((_) => nextPage.future);
        when(
          () => getOrders.execute(1, filter: const OrderFilter()),
        ).thenAnswer((_) async {
          nextPage.complete(page([third], at: 2));
          return page([second]);
        });
      },
      build: buildBloc,
      seed: () => loaded([first], next: true),
      act: (bloc) async {
        bloc.add(LoadMoreOrdersEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(LoadOrdersEvent());
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [
        matches(ids: ['o1'], loadingMore: true),
        matches(ids: ['o2']),
      ],
    );
  });

  blocTest<OrdersBloc, OrdersState>(
    'replaces an order changed on its detail page',
    build: buildBloc,
    seed: () => loaded([first, second]),
    act: (bloc) => bloc.add(
      OrderChangedEvent(
        order: buildOrder(id: 'o2', status: OrderStatus.cancelled),
      ),
    ),
    expect: () => [
      matches(ids: ['o1', 'o2']).having(
        (s) => s.orders.map((o) => o.status),
        'statuses',
        [OrderStatus.awaitingPayment, OrderStatus.cancelled],
      ),
    ],
  );

  blocTest<OrdersBloc, OrdersState>(
    'forgets the orders on sign-out',
    build: buildBloc,
    seed: () => loaded([first]),
    act: (bloc) => bloc.add(ClearOrdersEvent()),
    expect: () => [matches(status: OrdersStatus.initial, ids: [])],
  );

  group('filter (RF-025)', () {
    const delivered = OrderFilter(
      status: OrderStatus.delivered,
      period: OrderPeriod.last30Days,
    );

    blocTest<OrdersBloc, OrdersState>(
      'starts over with the new filter and keeps it for the next pages',
      setUp: () {
        when(
          () => getOrders.execute(1, filter: delivered),
        ).thenAnswer((_) async => page([second], next: true));
        when(
          () => getOrders.execute(2, filter: delivered),
        ).thenAnswer((_) async => page([third], at: 2));
      },
      build: buildBloc,
      seed: () => loaded([first]),
      act: (bloc) async {
        bloc.add(FilterOrdersEvent(filter: delivered));
        await bloc.stream.firstWhere((s) => s.status == OrdersStatus.loaded);
        bloc.add(LoadMoreOrdersEvent());
      },
      expect: () => [
        matches(status: OrdersStatus.loading, ids: []),
        matches(ids: ['o2']).having((s) => s.filter, 'filter', delivered),
        matches(ids: ['o2'], loadingMore: true),
        matches(ids: ['o2', 'o3']).having((s) => s.filter, 'filter', delivered),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'a refresh keeps the filter',
      setUp: () => when(
        () => getOrders.execute(1, filter: delivered),
      ).thenAnswer((_) async => page([second])),
      build: buildBloc,
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        filter: delivered,
        orders: [second],
        page: 1,
      ),
      act: (bloc) => bloc.add(LoadOrdersEvent()),
      expect: () => [
        matches(ids: ['o2']),
      ],
      verify: (_) =>
          verify(() => getOrders.execute(1, filter: delivered)).called(1),
    );

    blocTest<OrdersBloc, OrdersState>(
      'the same filter again changes nothing',
      build: buildBloc,
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        filter: delivered,
        orders: [second],
        page: 1,
      ),
      act: (bloc) => bloc.add(FilterOrdersEvent(filter: delivered)),
      expect: () => const <OrdersState>[],
    );

    blocTest<OrdersBloc, OrdersState>(
      "a sales tab keeps its status and takes the filter's period",
      build: () {
        final useCase = MockGetSellerOrdersUseCase();
        when(
          () => useCase.execute(
            1,
            filter: const OrderFilter(
              status: OrderStatus.shipped,
              period: OrderPeriod.last3Months,
            ),
          ),
        ).thenAnswer((_) async => page([first]));
        return OrdersBloc.sales(
          getSellerOrdersUseCase: useCase,
          status: OrderStatus.shipped,
        );
      },
      act: (bloc) => bloc.add(
        FilterOrdersEvent(
          filter: const OrderFilter(period: OrderPeriod.last3Months),
        ),
      ),
      expect: () => [
        matches(status: OrdersStatus.loading, ids: []),
        matches(ids: ['o1']),
      ],
    );
  });
}

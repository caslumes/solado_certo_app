import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/seller_order_detail_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetSellerOrderUseCase getOrder;
  late MockStartProcessingUseCase startProcessing;
  late MockShipOrderUseCase shipOrder;

  final paid = buildSellerOrderDetail();
  final processing = buildSellerOrderDetail(status: OrderStatus.processing);
  final shipped = buildSellerOrderDetail(status: OrderStatus.shipped);

  SellerOrderDetailCubit buildCubit() => SellerOrderDetailCubit(
    getSellerOrderUseCase: getOrder,
    startProcessingUseCase: startProcessing,
    shipOrderUseCase: shipOrder,
    orderId: 'o1',
  );

  TypeMatcher<SellerOrderDetailLoaded> loaded(
    OrderStatus status, {
    bool working = false,
    TypeMatcher<Failure>? failure,
    bool notice = false,
  }) => isA<SellerOrderDetailLoaded>()
      .having((s) => s.detail.order.status, 'status', status)
      .having((s) => s.working, 'working', working)
      .having((s) => s.failure, 'failure', failure ?? isNull)
      .having((s) => s.notice, 'notice', notice ? isNotNull : isNull);

  void shipAnswers(Object answer) {
    final call = when(
      () => shipOrder.execute(
        any(),
        carrier: any(named: 'carrier'),
        trackingCode: any(named: 'trackingCode'),
      ),
    );
    if (answer is OrderDetailEntity) {
      call.thenAnswer((_) async => answer);
    } else {
      call.thenThrow(answer);
    }
  }

  setUp(() {
    getOrder = MockGetSellerOrderUseCase();
    startProcessing = MockStartProcessingUseCase();
    shipOrder = MockShipOrderUseCase();
  });

  group('load', () {
    blocTest<SellerOrderDetailCubit, SellerOrderDetailState>(
      'shows the order',
      setUp: () =>
          when(() => getOrder.execute('o1')).thenAnswer((_) async => paid),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [isA<SellerOrderDetailLoading>(), loaded(OrderStatus.paid)],
    );

    blocTest<SellerOrderDetailCubit, SellerOrderDetailState>(
      'a first load that fails shows the error',
      setUp: () => when(
        () => getOrder.execute('o1'),
      ).thenThrow(buildDioException(statusCode: 404)),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SellerOrderDetailLoading>(),
        isA<SellerOrderDetailLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NotFoundFailure>(),
        ),
      ],
    );
  });

  group('startProcessing', () {
    blocTest<SellerOrderDetailCubit, SellerOrderDetailState>(
      'moves the order to processing',
      setUp: () => when(
        () => startProcessing.execute('o1'),
      ).thenAnswer((_) async => processing),
      build: buildCubit,
      seed: () => SellerOrderDetailLoaded(detail: paid),
      act: (cubit) => cubit.startProcessing(),
      expect: () => [
        loaded(OrderStatus.paid, working: true),
        loaded(OrderStatus.processing, notice: true),
      ],
    );

    blocTest<SellerOrderDetailCubit, SellerOrderDetailState>(
      'reloads when the buyer cancelled meanwhile',
      setUp: () {
        when(() => startProcessing.execute('o1')).thenThrow(
          buildDioException(
            statusCode: 409,
            data: {'error': 'invalid status transition: an order cannot go'},
          ),
        );
        when(() => getOrder.execute('o1')).thenAnswer(
          (_) async => buildSellerOrderDetail(status: OrderStatus.cancelled),
        );
      },
      build: buildCubit,
      seed: () => SellerOrderDetailLoaded(detail: paid),
      act: (cubit) => cubit.startProcessing(),
      expect: () => [
        loaded(OrderStatus.paid, working: true),
        loaded(
          OrderStatus.cancelled,
          failure: isA<OrderStatusChangedFailure>(),
        ),
      ],
    );
  });

  group('ship', () {
    blocTest<SellerOrderDetailCubit, SellerOrderDetailState>(
      'ships the order and returns no failure',
      setUp: () => shipAnswers(shipped),
      build: buildCubit,
      seed: () => SellerOrderDetailLoaded(detail: processing),
      act: (cubit) async {
        final failure = await cubit.ship(
          carrier: 'Correios',
          trackingCode: 'AA123456789BR',
        );
        expect(failure, isNull);
      },
      expect: () => [
        loaded(OrderStatus.processing, working: true),
        loaded(OrderStatus.shipped, notice: true),
      ],
      verify: (_) => verify(
        () => shipOrder.execute(
          'o1',
          carrier: 'Correios',
          trackingCode: 'AA123456789BR',
        ),
      ).called(1),
    );

    blocTest<SellerOrderDetailCubit, SellerOrderDetailState>(
      'returns an invalid code to the form, not to the page',
      setUp: () => shipAnswers(
        buildDioException(
          statusCode: 422,
          data: {'error': 'invalid tracking code: format'},
        ),
      ),
      build: buildCubit,
      seed: () => SellerOrderDetailLoaded(detail: processing),
      act: (cubit) async {
        final failure = await cubit.ship(
          carrier: 'Correios',
          trackingCode: 'X',
        );
        expect(failure, isA<InvalidTrackingCodeFailure>());
      },
      expect: () => [
        loaded(OrderStatus.processing, working: true),
        loaded(OrderStatus.processing),
      ],
    );

    blocTest<SellerOrderDetailCubit, SellerOrderDetailState>(
      'shows other failures on the page',
      setUp: () => shipAnswers(
        buildDioException(type: DioExceptionType.connectionError),
      ),
      build: buildCubit,
      seed: () => SellerOrderDetailLoaded(detail: processing),
      act: (cubit) async {
        final failure = await cubit.ship(
          carrier: 'Correios',
          trackingCode: 'AA123456789BR',
        );
        expect(failure, isA<NetworkFailure>());
      },
      expect: () => [
        loaded(OrderStatus.processing, working: true),
        loaded(OrderStatus.processing, failure: isA<NetworkFailure>()),
      ],
    );
  });

  group('OrdersBloc.sales', () {
    blocTest<OrdersBloc, OrdersState>(
      'loads the sales with one status',
      build: () {
        final useCase = MockGetSellerOrdersUseCase();
        when(
          () => useCase.execute(
            1,
            filter: const OrderFilter(status: OrderStatus.shipped),
          ),
        ).thenAnswer(
          (_) async => OrdersPageEntity(
            items: [shipped.order],
            currentPage: 1,
            hasNext: false,
          ),
        );
        return OrdersBloc.sales(
          getSellerOrdersUseCase: useCase,
          status: OrderStatus.shipped,
        );
      },
      act: (bloc) => bloc.add(LoadOrdersEvent()),
      skip: 1,
      expect: () => [
        isA<OrdersState>().having(
          (s) => s.orders.map((o) => o.status),
          'statuses',
          [OrderStatus.shipped],
        ),
      ],
    );
  });
}

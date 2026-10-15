import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/order_detail_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetOrderUseCase getOrder;
  late MockCancelOrderUseCase cancelOrder;

  final open = buildOrderDetail();
  final cancelled = buildOrderDetail(cancelled: true);

  OrderDetailCubit buildCubit() => OrderDetailCubit(
    getOrderUseCase: getOrder,
    cancelOrderUseCase: cancelOrder,
    orderId: 'o1',
  );

  setUp(() {
    getOrder = MockGetOrderUseCase();
    cancelOrder = MockCancelOrderUseCase();
  });

  group('load', () {
    blocTest<OrderDetailCubit, OrderDetailState>(
      'loads the order',
      setUp: () =>
          when(() => getOrder.execute('o1')).thenAnswer((_) async => open),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<OrderDetailLoading>(),
        isA<OrderDetailLoaded>().having((s) => s.detail, 'detail', open),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'an unknown or foreign order shows the error',
      setUp: () => when(
        () => getOrder.execute('o1'),
      ).thenThrow(buildDioException(statusCode: 404)),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<OrderDetailLoading>(),
        isA<OrderDetailLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NotFoundFailure>(),
        ),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'a refresh that fails keeps the order on screen',
      setUp: () => when(
        () => getOrder.execute('o1'),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: open),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<OrderDetailLoaded>()
            .having((s) => s.detail, 'detail', open)
            .having((s) => s.failure, 'failure', isA<ServerFailure>()),
      ],
    );
  });

  group('cancel', () {
    blocTest<OrderDetailCubit, OrderDetailState>(
      'cancels and shows the new status',
      setUp: () => when(
        () => cancelOrder.execute('o1'),
      ).thenAnswer((_) async => cancelled),
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: open),
      act: (cubit) => cubit.cancel(),
      expect: () => [
        isA<OrderDetailLoaded>().having(
          (s) => s.cancelling,
          'cancelling',
          true,
        ),
        isA<OrderDetailLoaded>()
            .having((s) => s.cancelling, 'cancelling', false)
            .having((s) => s.detail, 'detail', cancelled)
            .having((s) => s.notice, 'notice', 'Pedido cancelado.'),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'when the status changed elsewhere, reloads the order',
      setUp: () {
        when(() => cancelOrder.execute('o1')).thenThrow(
          buildDioException(
            statusCode: 409,
            data: {'error': 'invalid status transition'},
          ),
        );
        when(
          () => getOrder.execute('o1'),
        ).thenAnswer((_) async => buildOrderDetail(cancelled: true));
      },
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: open),
      act: (cubit) => cubit.cancel(),
      skip: 1,
      expect: () => [
        isA<OrderDetailLoaded>()
            .having(
              (s) => s.detail.order.status,
              'status',
              OrderStatus.cancelled,
            )
            .having(
              (s) => s.failure,
              'failure',
              isA<OrderStatusChangedFailure>(),
            ),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'any other failure keeps the order as it was',
      setUp: () => when(
        () => cancelOrder.execute('o1'),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: open),
      act: (cubit) => cubit.cancel(),
      skip: 1,
      expect: () => [
        isA<OrderDetailLoaded>()
            .having((s) => s.detail, 'detail', open)
            .having((s) => s.failure, 'failure', isA<ServerFailure>()),
      ],
      verify: (_) => verifyNever(() => getOrder.execute(any())),
    );
  });
}

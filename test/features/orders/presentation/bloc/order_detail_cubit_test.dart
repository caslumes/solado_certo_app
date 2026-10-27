import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/orders/domain/enum/document_status.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetOrderUseCase getOrder;
  late MockCancelOrderUseCase cancelOrder;
  late MockConfirmDeliveryUseCase confirmDelivery;
  late MockGetPaymentsUseCase getPayments;
  late MockUploadPrescriptionUseCase uploadPrescription;
  late MockHasPrescriptionConsentUseCase hasConsent;
  late MockGrantPrescriptionConsentUseCase grantConsent;

  const file = UploadFile(bytes: [1, 2, 3], filename: 'receita.pdf');
  final open = buildOrderDetail();
  final awaitingPrescription = buildOrderDetail(
    items: [
      buildOrderItem(
        itemId: 'i1',
        prescriptionRequired: true,
        canUploadPrescription: true,
      ),
    ],
  );
  final withPrescription = buildOrderDetail(
    items: [
      buildOrderItem(
        itemId: 'i1',
        prescriptionRequired: true,
        prescription: buildPrescription(),
        canUploadPrescription: true,
      ),
    ],
  );
  final cancelled = buildOrderDetail(cancelled: true);

  OrderDetailCubit buildCubit() => OrderDetailCubit(
    getOrderUseCase: getOrder,
    cancelOrderUseCase: cancelOrder,
    confirmDeliveryUseCase: confirmDelivery,
    getPaymentsUseCase: getPayments,
    uploadPrescriptionUseCase: uploadPrescription,
    hasPrescriptionConsentUseCase: hasConsent,
    grantPrescriptionConsentUseCase: grantConsent,
    orderId: 'o1',
  );

  setUp(() {
    getOrder = MockGetOrderUseCase();
    cancelOrder = MockCancelOrderUseCase();
    confirmDelivery = MockConfirmDeliveryUseCase();
    getPayments = MockGetPaymentsUseCase();
    uploadPrescription = MockUploadPrescriptionUseCase();
    hasConsent = MockHasPrescriptionConsentUseCase();
    grantConsent = MockGrantPrescriptionConsentUseCase();
    when(() => getPayments.execute('o1')).thenAnswer((_) async => []);
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
      'loads the payments before the order, which they may have paid',
      setUp: () {
        when(
          () => getPayments.execute('o1'),
        ).thenAnswer((_) async => [buildPayment()]);
        when(() => getOrder.execute('o1')).thenAnswer((_) async => open);
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<OrderDetailLoading>(),
        isA<OrderDetailLoaded>().having(
          (s) => s.payments.single.id,
          'payment',
          'p1',
        ),
      ],
      verify: (_) => verifyInOrder([
        () => getPayments.execute('o1'),
        () => getOrder.execute('o1'),
      ]),
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'shows the order when its payments fail to load, keeping the last ones',
      setUp: () {
        when(
          () => getPayments.execute('o1'),
        ).thenThrow(buildDioException(statusCode: 500));
        when(() => getOrder.execute('o1')).thenAnswer((_) async => open);
      },
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: open, payments: [buildPayment()]),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<OrderDetailLoaded>()
            .having((s) => s.payments.single.id, 'payment', 'p1')
            .having((s) => s.failure, 'failure', isNull),
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
        isA<OrderDetailLoaded>().having((s) => s.working, 'working', true),
        isA<OrderDetailLoaded>()
            .having((s) => s.working, 'working', false)
            .having((s) => s.detail, 'detail', cancelled)
            .having((s) => s.notice, 'notice', 'Pedido cancelado.'),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'cancels a paid order and shows its refund',
      setUp: () {
        when(
          () => cancelOrder.execute('o1'),
        ).thenAnswer((_) async => cancelled);
        when(() => getPayments.execute('o1')).thenAnswer(
          (_) async => [
            buildPayment(
              status: PaymentStatus.captured,
              refundRequestedAt: DateTime(2026, 10, 16),
            ),
          ],
        );
      },
      build: buildCubit,
      seed: () => OrderDetailLoaded(
        detail: buildOrderDetail(paid: true),
        payments: [buildPayment(status: PaymentStatus.captured)],
      ),
      act: (cubit) => cubit.cancel(),
      skip: 1,
      expect: () => [
        isA<OrderDetailLoaded>()
            .having((s) => s.detail, 'detail', cancelled)
            .having(
              (s) => s.payments.single.refundRequestedAt,
              'refund requested',
              isNotNull,
            )
            .having(
              (s) => s.notice,
              'notice',
              'Pedido cancelado. O valor pago será estornado.',
            ),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'keeps the payments shown when they fail to reload after cancelling',
      setUp: () {
        when(
          () => cancelOrder.execute('o1'),
        ).thenAnswer((_) async => cancelled);
        when(
          () => getPayments.execute('o1'),
        ).thenThrow(buildDioException(statusCode: 500));
      },
      build: buildCubit,
      seed: () => OrderDetailLoaded(
        detail: buildOrderDetail(paid: true),
        payments: [buildPayment(status: PaymentStatus.captured)],
      ),
      act: (cubit) => cubit.cancel(),
      skip: 1,
      expect: () => [
        isA<OrderDetailLoaded>()
            .having(
              (s) => s.payments.single.status,
              'payment',
              PaymentStatus.captured,
            )
            .having((s) => s.failure, 'failure', isNull),
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

  group('confirmDelivery (RF-023)', () {
    final shipped = buildShippedOrderDetail();
    final delivered = buildShippedOrderDetail(delivered: true);

    blocTest<OrderDetailCubit, OrderDetailState>(
      'marks the order delivered',
      setUp: () => when(
        () => confirmDelivery.execute('o1'),
      ).thenAnswer((_) async => delivered),
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: shipped),
      act: (cubit) => cubit.confirmDelivery(),
      expect: () => [
        isA<OrderDetailLoaded>().having((s) => s.working, 'working', true),
        isA<OrderDetailLoaded>()
            .having((s) => s.working, 'working', false)
            .having((s) => s.detail, 'detail', delivered)
            .having((s) => s.notice, 'notice', contains('Recebimento')),
      ],
      verify: (_) => verifyNever(() => getPayments.execute(any())),
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'shows why it could not confirm',
      setUp: () => when(
        () => confirmDelivery.execute('o1'),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: shipped),
      act: (cubit) => cubit.confirmDelivery(),
      skip: 1,
      expect: () => [
        isA<OrderDetailLoaded>()
            .having((s) => s.detail, 'detail', shipped)
            .having((s) => s.failure, 'failure', isA<ServerFailure>()),
      ],
    );
  });

  group('prescriptions', () {
    blocTest<OrderDetailCubit, OrderDetailState>(
      'uploads the prescription and reloads the order, now payable',
      setUp: () {
        when(
          () => uploadPrescription.execute('o1', 'i1', file),
        ).thenAnswer((_) async => buildPrescription());
        when(
          () => getOrder.execute('o1'),
        ).thenAnswer((_) async => withPrescription);
      },
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: awaitingPrescription),
      act: (cubit) => cubit.uploadPrescription('i1', file),
      expect: () => [
        isA<OrderDetailLoaded>().having((s) => s.working, 'working', true),
        isA<OrderDetailLoaded>()
            .having((s) => s.detail, 'detail', withPrescription)
            .having(
              (s) => s.notice,
              'notice',
              'Receita aprovada. Você já pode pagar.',
            ),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'keeps the order and explains why the file was refused',
      setUp: () =>
          when(() => uploadPrescription.execute('o1', 'i1', file)).thenThrow(
            buildDioException(
              statusCode: 422,
              data: {'error': 'unreadable document: the PDF is incomplete'},
            ),
          ),
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: awaitingPrescription),
      act: (cubit) => cubit.uploadPrescription('i1', file),
      skip: 1,
      expect: () => [
        isA<OrderDetailLoaded>()
            .having((s) => s.detail, 'detail', awaitingPrescription)
            .having(
              (s) => s.failure?.message,
              'failure',
              'Não foi possível ler o arquivo: o PDF está incompleto.',
            ),
      ],
      verify: (_) => verifyNever(() => getOrder.execute(any())),
    );

    test('asks for the consent only until it is known to be given', () async {
      when(() => hasConsent.execute()).thenAnswer((_) async => true);
      final cubit = buildCubit();

      expect(await cubit.hasPrescriptionConsent(), isTrue);
      expect(await cubit.hasPrescriptionConsent(), isTrue);
      verify(() => hasConsent.execute()).called(1);
    });

    test('remembers a consent just given', () async {
      when(() => hasConsent.execute()).thenAnswer((_) async => false);
      when(() => grantConsent.execute()).thenAnswer(
        (_) async => ConsentEntity(
          purpose: ConsentPurposes.prescription,
          termsVersion: ConsentTermsVersions.prescription,
          grantedAt: DateTime(2026, 10, 27),
        ),
      );
      final cubit = buildCubit();

      expect(await cubit.hasPrescriptionConsent(), isFalse);
      expect(await cubit.grantPrescriptionConsent(), isTrue);
      expect(await cubit.hasPrescriptionConsent(), isTrue);
      verify(() => hasConsent.execute()).called(1);
    });

    blocTest<OrderDetailCubit, OrderDetailState>(
      'reports a consent check that failed',
      setUp: () => when(
        () => hasConsent.execute(),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildCubit,
      seed: () => OrderDetailLoaded(detail: awaitingPrescription),
      act: (cubit) async =>
          expect(await cubit.hasPrescriptionConsent(), isNull),
      expect: () => [
        isA<OrderDetailLoaded>().having(
          (s) => s.failure,
          'failure',
          isA<ServerFailure>(),
        ),
      ],
    );

    test('checks the consent again after the server asked for it', () async {
      when(() => hasConsent.execute()).thenAnswer((_) async => true);
      when(() => uploadPrescription.execute('o1', 'i1', file)).thenThrow(
        buildDioException(
          statusCode: 403,
          data: {
            'error':
                'sending a prescription requires consent to the prescription terms',
          },
        ),
      );
      final cubit = buildCubit()
        ..emit(OrderDetailLoaded(detail: awaitingPrescription));

      await cubit.hasPrescriptionConsent();
      await cubit.uploadPrescription('i1', file);

      expect(
        (cubit.state as OrderDetailLoaded).failure,
        isA<PrescriptionConsentRequiredFailure>(),
      );
      await cubit.hasPrescriptionConsent();
      verify(() => hasConsent.execute()).called(2);
    });

    test('an item without an approved prescription holds the payment', () {
      expect(
        awaitingPrescription.order.itemsAwaitingPrescription,
        hasLength(1),
      );
      expect(withPrescription.order.itemsAwaitingPrescription, isEmpty);
      expect(
        buildOrderDetail(
          items: [
            buildOrderItem(
              prescriptionRequired: true,
              prescription: buildPrescription(status: DocumentStatus.rejected),
            ),
          ],
        ).order.itemsAwaitingPrescription,
        hasLength(1),
      );
      expect(open.order.itemsAwaitingPrescription, isEmpty);
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/payments/presentation/bloc/payment_cubit.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

const card = CardDetails(
  holderName: 'MARIA SOUZA',
  number: '4444444444444444',
  expiryMonth: '05',
  expiryYear: '2030',
  cvv: '123',
);

ProfileEntity profileWithTaxId() => ProfileEntity(
  name: 'Maria Souza',
  email: 'maria@example.com',
  phone: '19999999999',
  avatarUrl: '',
  hasTaxId: true,
);

void main() {
  late MockGetProfileUseCase getProfile;
  late MockGetPaymentsUseCase getPayments;
  late MockCreatePaymentUseCase createPayment;
  late int keys;

  final pendingPix = buildPayment();
  final paidPix = buildPayment(status: PaymentStatus.captured);
  final refused = buildPayment(
    id: 'p2',
    method: PaymentMethod.creditCard,
    status: PaymentStatus.failed,
    failureReason: 'card_refused',
    failureMessage: 'Transação não autorizada.',
  );
  final approvedCard = buildPayment(
    id: 'p3',
    method: PaymentMethod.creditCard,
    status: PaymentStatus.captured,
  );

  PaymentCubit buildCubit() => PaymentCubit(
    order: buildOrder(),
    getProfileUseCase: getProfile,
    getPaymentsUseCase: getPayments,
    createPaymentUseCase: createPayment,
    newKey: () => 'key-${++keys}',
    pollInterval: const Duration(milliseconds: 10),
  );

  PaymentState choosing({
    PaymentMethod method = PaymentMethod.pix,
    bool needsTaxId = false,
  }) => PaymentState(
    stage: PaymentStage.choosing,
    method: method,
    needsTaxId: needsTaxId,
  );

  List<(PaymentRequest, String)> sent() {
    final captured = verify(
      () => createPayment.execute('o1', captureAny(), captureAny()),
    ).captured;
    return [
      for (var i = 0; i < captured.length; i += 2)
        (captured[i] as PaymentRequest, captured[i + 1] as String),
    ];
  }

  setUpAll(() {
    registerFallbackValue(const PaymentRequest(method: PaymentMethod.pix));
  });

  setUp(() {
    getProfile = MockGetProfileUseCase();
    getPayments = MockGetPaymentsUseCase();
    createPayment = MockCreatePaymentUseCase();
    keys = 0;
    when(getProfile.execute).thenAnswer((_) async => profileWithTaxId());
    when(() => getPayments.execute('o1')).thenAnswer((_) async => []);
  });

  group('load', () {
    blocTest<PaymentCubit, PaymentState>(
      'chooses a method, asking the CPF when the profile has none',
      setUp: () =>
          when(getProfile.execute).thenAnswer((_) async => buildProfile()),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<PaymentState>().having(
          (s) => s.stage,
          'stage',
          PaymentStage.loading,
        ),
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.choosing)
            .having((s) => s.method, 'method', PaymentMethod.pix)
            .having((s) => s.needsTaxId, 'needsTaxId', isTrue),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'goes back to a pending Pix',
      setUp: () => when(
        () => getPayments.execute('o1'),
      ).thenAnswer((_) async => [pendingPix, refused]),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.waiting)
            .having((s) => s.payment, 'payment', pendingPix)
            .having((s) => s.needsTaxId, 'needsTaxId', isFalse),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'shows the result when a payment was already captured',
      setUp: () => when(
        () => getPayments.execute('o1'),
      ).thenAnswer((_) async => [refused, approvedCard]),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.approved)
            .having((s) => s.payment, 'payment', approvedCard),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'a refused card from before is not shown again',
      setUp: () => when(
        () => getPayments.execute('o1'),
      ).thenAnswer((_) async => [refused]),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.choosing)
            .having((s) => s.payment, 'payment', isNull),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'reports a load failure',
      setUp: () =>
          when(() => getPayments.execute('o1')).thenThrow(NetworkFailure()),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.loadFailure)
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
      ],
    );
  });

  group('pay', () {
    blocTest<PaymentCubit, PaymentState>(
      'a Pix waits for the confirmation, sending the CPF once',
      setUp: () => when(
        () => createPayment.execute('o1', any(), any()),
      ).thenAnswer((_) async => pendingPix),
      build: buildCubit,
      seed: () => choosing(needsTaxId: true),
      act: (cubit) async {
        await cubit.pay(taxId: '52998224725');
        cubit.chooseAnotherMethod();
      },
      expect: () => [
        isA<PaymentState>().having((s) => s.submitting, 'submitting', isTrue),
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.waiting)
            .having((s) => s.payment, 'payment', pendingPix)
            .having((s) => s.needsTaxId, 'needsTaxId', isFalse),
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.choosing)
            .having((s) => s.payment, 'payment', isNull),
      ],
      verify: (_) {
        final (request, key) = sent().single;
        expect(request.method, PaymentMethod.pix);
        expect(request.taxId, '52998224725');
        expect(request.card, isNull);
        expect(key, 'key-1');
      },
    );

    blocTest<PaymentCubit, PaymentState>(
      'an approved card shows the result; the CPF is not sent again',
      setUp: () => when(
        () => createPayment.execute('o1', any(), any()),
      ).thenAnswer((_) async => approvedCard),
      build: buildCubit,
      seed: choosing,
      act: (cubit) {
        cubit.selectMethod(PaymentMethod.creditCard);
        return cubit.pay(taxId: '52998224725', card: card);
      },
      skip: 2,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.approved)
            .having((s) => s.payment, 'payment', approvedCard),
      ],
      verify: (_) {
        final (request, _) = sent().single;
        expect(request.method, PaymentMethod.creditCard);
        expect(request.taxId, isNull);
        expect(request.card, card);
      },
    );

    blocTest<PaymentCubit, PaymentState>(
      'a refused card goes back to the choice with the reason; another '
      'method is a new attempt',
      setUp: () {
        when(
          () => createPayment.execute('o1', any(), any()),
        ).thenAnswer((_) async => refused);
      },
      build: buildCubit,
      seed: () => choosing(method: PaymentMethod.creditCard),
      act: (cubit) async {
        await cubit.pay(card: card);
        cubit.selectMethod(PaymentMethod.pix);
        when(
          () => createPayment.execute('o1', any(), any()),
        ).thenAnswer((_) async => pendingPix);
        await cubit.pay();
      },
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.choosing)
            .having((s) => s.method, 'method', PaymentMethod.creditCard)
            .having((s) => s.payment, 'payment', refused),
        isA<PaymentState>().having(
          (s) => s.method,
          'method',
          PaymentMethod.pix,
        ),
        isA<PaymentState>().having((s) => s.submitting, 'submitting', isTrue),
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.waiting)
            .having((s) => s.payment, 'payment', pendingPix),
      ],
      verify: (_) => expect(sent().map((call) => call.$2), ['key-1', 'key-3']),
    );

    blocTest<PaymentCubit, PaymentState>(
      'keeps the key after a network failure, so trying again is safe',
      setUp: () => when(
        () => createPayment.execute('o1', any(), any()),
      ).thenThrow(NetworkFailure()),
      build: buildCubit,
      seed: choosing,
      act: (cubit) async {
        await cubit.pay();
        await cubit.pay();
        when(
          () => createPayment.execute('o1', any(), any()),
        ).thenThrow(GatewayUnavailableFailure());
        await cubit.pay();
        await cubit.pay();
      },
      verify: (cubit) {
        expect(sent().map((call) => call.$2), [
          'key-1',
          'key-1',
          'key-1',
          'key-2',
        ]);
        expect(cubit.state.stage, PaymentStage.choosing);
        expect(cubit.state.failure, isA<GatewayUnavailableFailure>());
      },
    );

    blocTest<PaymentCubit, PaymentState>(
      'asks the CPF when the server needs it',
      setUp: () => when(
        () => createPayment.execute('o1', any(), any()),
      ).thenThrow(TaxIdRequiredFailure()),
      build: buildCubit,
      seed: choosing,
      act: (cubit) => cubit.pay(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.choosing)
            .having((s) => s.needsTaxId, 'needsTaxId', isTrue)
            .having((s) => s.failure, 'failure', isA<TaxIdRequiredFailure>()),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'closes when the payment window is over',
      setUp: () => when(
        () => createPayment.execute('o1', any(), any()),
      ).thenThrow(PaymentExpiredFailure()),
      build: buildCubit,
      seed: choosing,
      act: (cubit) => cubit.pay(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.closed)
            .having((s) => s.failure, 'failure', isA<PaymentExpiredFailure>()),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'shows the payment made elsewhere when the order was already paid',
      setUp: () {
        when(
          () => createPayment.execute('o1', any(), any()),
        ).thenThrow(OrderStatusChangedFailure());
        when(
          () => getPayments.execute('o1'),
        ).thenAnswer((_) async => [paidPix]);
      },
      build: buildCubit,
      seed: choosing,
      act: (cubit) => cubit.pay(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.approved)
            .having((s) => s.payment, 'payment', paidPix),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'closes when the order changed and nothing was paid',
      setUp: () => when(
        () => createPayment.execute('o1', any(), any()),
      ).thenThrow(OrderStatusChangedFailure()),
      build: buildCubit,
      seed: choosing,
      act: (cubit) => cubit.pay(),
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.closed)
            .having(
              (s) => s.failure,
              'failure',
              isA<OrderStatusChangedFailure>(),
            ),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'waits for the attempt already in progress',
      setUp: () {
        when(
          () => createPayment.execute('o1', any(), any()),
        ).thenThrow(PaymentInProgressFailure());
        when(
          () => getPayments.execute('o1'),
        ).thenAnswer((_) async => [pendingPix]);
      },
      build: buildCubit,
      seed: choosing,
      act: (cubit) async {
        await cubit.pay();
        cubit.chooseAnotherMethod();
      },
      skip: 1,
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.waiting)
            .having((s) => s.payment, 'payment', pendingPix),
        isA<PaymentState>().having(
          (s) => s.stage,
          'stage',
          PaymentStage.choosing,
        ),
      ],
    );
  });

  group('waiting', () {
    PaymentState waiting([PaymentMethod method = PaymentMethod.pix]) =>
        PaymentState(
          stage: PaymentStage.waiting,
          method: method,
          payment: method == PaymentMethod.pix
              ? pendingPix
              : buildPayment(method: method),
        );

    blocTest<PaymentCubit, PaymentState>(
      'polls a Pix until it is captured, then stops',
      setUp: () {
        var calls = 0;
        when(
          () => getPayments.execute('o1'),
        ).thenAnswer((_) async => ++calls < 2 ? [pendingPix] : [paidPix]);
      },
      build: buildCubit,
      act: (cubit) => cubit.emit(waiting()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PaymentState>().having(
          (s) => s.stage,
          'stage',
          PaymentStage.waiting,
        ),
        isA<PaymentState>().having(
          (s) => s.stage,
          'stage',
          PaymentStage.waiting,
        ),
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.approved)
            .having((s) => s.payment, 'payment', paidPix),
      ],
      verify: (_) => verify(() => getPayments.execute('o1')).called(2),
    );

    blocTest<PaymentCubit, PaymentState>(
      'does not poll a boleto; "Já paguei" says when nothing arrived',
      setUp: () => when(
        () => getPayments.execute('o1'),
      ).thenAnswer((_) async => [buildPayment(method: PaymentMethod.boleto)]),
      build: buildCubit,
      seed: () => waiting(PaymentMethod.boleto),
      act: (cubit) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await cubit.refresh(manual: true);
      },
      expect: () => [
        isA<PaymentState>().having((s) => s.refreshing, 'refreshing', isTrue),
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.waiting)
            .having((s) => s.refreshing, 'refreshing', isFalse)
            .having(
              (s) => s.notice,
              'notice',
              'Ainda não recebemos a confirmação do pagamento.',
            ),
      ],
      verify: (_) => verify(() => getPayments.execute('o1')).called(1),
    );

    blocTest<PaymentCubit, PaymentState>(
      'closes when the charge was cancelled with the order',
      setUp: () => when(() => getPayments.execute('o1')).thenAnswer(
        (_) async => [buildPayment(status: PaymentStatus.cancelled)],
      ),
      build: buildCubit,
      seed: waiting,
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.closed)
            .having((s) => s.failure, 'failure', isA<PaymentExpiredFailure>()),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'a failed poll is quiet; a failed "Já paguei" is reported',
      setUp: () =>
          when(() => getPayments.execute('o1')).thenThrow(NetworkFailure()),
      build: buildCubit,
      seed: () => waiting(PaymentMethod.boleto),
      act: (cubit) async {
        await cubit.refresh();
        await cubit.refresh(manual: true);
      },
      expect: () => [
        isA<PaymentState>().having((s) => s.refreshing, 'refreshing', isTrue),
        isA<PaymentState>()
            .having((s) => s.stage, 'stage', PaymentStage.waiting)
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
      ],
    );
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_detail_cubit.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetCustomOrderUseCase getRequest;
  late MockComplementCustomOrderUseCase complement;
  late MockCancelCustomOrderUseCase cancel;
  late MockSendFootPhotoUseCase sendPhoto;
  late MockHasCustomOrderConsentUseCase hasConsent;
  late MockGrantCustomOrderConsentUseCase grantConsent;

  const file = UploadFile(bytes: [1, 2, 3], filename: 'pe.jpg');
  const answer = CustomOrderComplement(message: 'Arco alto');
  final needsInfo = buildCustomOrderDetail(status: CustomOrderStatus.needsInfo);
  final underReview = buildCustomOrderDetail(
    status: CustomOrderStatus.underReview,
  );
  final cancelled = buildCustomOrderDetail(
    status: CustomOrderStatus.cancelled,
    actions: const {},
  );

  CustomOrderDetailCubit buildCubit() => CustomOrderDetailCubit(
    getCustomOrderUseCase: getRequest,
    complementUseCase: complement,
    cancelUseCase: cancel,
    sendFootPhotoUseCase: sendPhoto,
    hasConsentUseCase: hasConsent,
    grantConsentUseCase: grantConsent,
    requestId: 'c1',
  );

  setUpAll(() => registerFallbackValue(answer));

  setUp(() {
    getRequest = MockGetCustomOrderUseCase();
    complement = MockComplementCustomOrderUseCase();
    cancel = MockCancelCustomOrderUseCase();
    sendPhoto = MockSendFootPhotoUseCase();
    hasConsent = MockHasCustomOrderConsentUseCase();
    grantConsent = MockGrantCustomOrderConsentUseCase();
  });

  blocTest<CustomOrderDetailCubit, CustomOrderDetailState>(
    'loads the request',
    setUp: () =>
        when(() => getRequest.execute('c1')).thenAnswer((_) async => needsInfo),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CustomOrderDetailLoading>(),
      isA<CustomOrderDetailLoaded>().having(
        (s) => s.detail,
        'detail',
        needsInfo,
      ),
    ],
  );

  blocTest<CustomOrderDetailCubit, CustomOrderDetailState>(
    "another buyer's request shows not found",
    setUp: () => when(
      () => getRequest.execute('c1'),
    ).thenThrow(buildDioException(statusCode: 404)),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CustomOrderDetailLoading>(),
      isA<CustomOrderDetailLoadFailure>().having(
        (s) => s.failure,
        'failure',
        isA<NotFoundFailure>(),
      ),
    ],
  );

  blocTest<CustomOrderDetailCubit, CustomOrderDetailState>(
    'answers the seller and shows the request back under review',
    setUp: () => when(
      () => complement.execute('c1', answer),
    ).thenAnswer((_) async => underReview),
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: needsInfo),
    act: (cubit) async => expect(await cubit.complement(answer), isNull),
    expect: () => [
      isA<CustomOrderDetailLoaded>().having((s) => s.working, 'working', true),
      isA<CustomOrderDetailLoaded>()
          .having((s) => s.detail, 'detail', underReview)
          .having((s) => s.notice, 'notice', 'Resposta enviada ao vendedor.'),
    ],
  );

  blocTest<CustomOrderDetailCubit, CustomOrderDetailState>(
    'reloads when the seller decided meanwhile',
    setUp: () {
      when(() => complement.execute('c1', answer)).thenThrow(
        buildDioException(
          statusCode: 409,
          data: {'error': 'invalid status transition: rejected'},
        ),
      );
      when(() => getRequest.execute('c1')).thenAnswer((_) async => cancelled);
    },
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: needsInfo),
    act: (cubit) async => expect(
      await cubit.complement(answer),
      isA<OrderStatusChangedFailure>(),
    ),
    expect: () => [
      isA<CustomOrderDetailLoaded>().having((s) => s.working, 'working', true),
      isA<CustomOrderDetailLoaded>()
          .having((s) => s.detail, 'detail', cancelled)
          .having(
            (s) => s.failure,
            'failure',
            isA<OrderStatusChangedFailure>(),
          ),
    ],
  );

  blocTest<CustomOrderDetailCubit, CustomOrderDetailState>(
    'cancels with the reason',
    setUp: () => when(
      () => cancel.execute('c1', reason: 'Desisti'),
    ).thenAnswer((_) async => cancelled),
    build: buildCubit,
    seed: () => CustomOrderDetailLoaded(detail: needsInfo),
    act: (cubit) => cubit.cancel(reason: 'Desisti'),
    expect: () => [
      isA<CustomOrderDetailLoaded>(),
      isA<CustomOrderDetailLoaded>()
          .having(
            (s) => s.detail.request.status,
            'status',
            CustomOrderStatus.cancelled,
          )
          .having((s) => s.notice, 'notice', 'Solicitação cancelada.'),
    ],
  );

  group('consent', () {
    test('asks the profile once and remembers a granted consent', () async {
      when(hasConsent.execute).thenAnswer((_) async => false);
      when(grantConsent.execute).thenThrow(buildDioException(statusCode: 500));
      final cubit = buildCubit();

      expect(await cubit.hasConsent(), isFalse);
      expect(await cubit.grantConsent(), isFalse);
      when(grantConsent.execute).thenAnswer(
        (_) async => ConsentEntity(
          purpose: ConsentPurposes.customOrder,
          termsVersion: ConsentTermsVersions.customOrder,
          grantedAt: DateTime(2026),
        ),
      );
      expect(await cubit.grantConsent(), isTrue);
      expect(await cubit.hasConsent(), isTrue);
      verify(hasConsent.execute).called(1);
    });

    blocTest<CustomOrderDetailCubit, CustomOrderDetailState>(
      'forgets the consent when the backend says it was revoked',
      setUp: () {
        when(hasConsent.execute).thenAnswer((_) async => true);
        when(() => sendPhoto.execute('c1', file)).thenThrow(
          buildDioException(
            statusCode: 403,
            data: {
              'error':
                  'a custom order request requires consent to the custom order terms',
            },
          ),
        );
      },
      build: buildCubit,
      seed: () => CustomOrderDetailLoaded(detail: needsInfo),
      act: (cubit) async {
        await cubit.hasConsent();
        await cubit.sendPhoto(file);
        await cubit.hasConsent();
      },
      skip: 1,
      expect: () => [
        isA<CustomOrderDetailLoaded>().having(
          (s) => s.failure,
          'failure',
          isA<CustomOrderConsentRequiredFailure>(),
        ),
      ],
      verify: (_) => verify(hasConsent.execute).called(2),
    );
  });
}

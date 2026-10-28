import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_form_cubit.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockCreateCustomOrderUseCase create;
  late MockSendFootPhotoUseCase sendPhoto;
  late MockHasCustomOrderConsentUseCase hasConsent;
  late MockGrantCustomOrderConsentUseCase grantConsent;

  const photo = UploadFile(bytes: [1, 2, 3], filename: 'pe.jpg');
  const request = NewCustomOrder(
    advertisementId: '603',
    measurements: footMeasurements,
  );
  final created = buildCustomOrderDetail();
  final withPhoto = buildCustomOrderDetail(
    footPhotoUrl: '/custom-orders/c1/photo',
  );

  CustomOrderFormCubit buildCubit() => CustomOrderFormCubit(
    createCustomOrderUseCase: create,
    sendFootPhotoUseCase: sendPhoto,
    hasConsentUseCase: hasConsent,
    grantConsentUseCase: grantConsent,
  );

  setUpAll(() => registerFallbackValue(photo));

  setUp(() {
    create = MockCreateCustomOrderUseCase();
    sendPhoto = MockSendFootPhotoUseCase();
    hasConsent = MockHasCustomOrderConsentUseCase();
    grantConsent = MockGrantCustomOrderConsentUseCase();
    when(() => create.execute(request)).thenAnswer((_) async => created);
  });

  blocTest<CustomOrderFormCubit, CustomOrderFormState>(
    'creates the request',
    build: buildCubit,
    act: (cubit) => cubit.submit(request),
    expect: () => [
      isA<CustomOrderFormState>().having(
        (s) => s.submitting,
        'submitting',
        true,
      ),
      isA<CustomOrderFormState>()
          .having((s) => s.created, 'created', created)
          .having((s) => s.photoFailure, 'photoFailure', isNull),
    ],
    verify: (_) => verifyNever(() => sendPhoto.execute(any(), any())),
  );

  blocTest<CustomOrderFormCubit, CustomOrderFormState>(
    'sends the photo after creating the request',
    setUp: () => when(
      () => sendPhoto.execute('c1', photo),
    ).thenAnswer((_) async => withPhoto),
    build: buildCubit,
    act: (cubit) => cubit.submit(request, photo: photo),
    expect: () => [
      isA<CustomOrderFormState>(),
      isA<CustomOrderFormState>().having(
        (s) => s.created,
        'created',
        withPhoto,
      ),
    ],
  );

  blocTest<CustomOrderFormCubit, CustomOrderFormState>(
    'keeps the created request when the photo fails',
    setUp: () => when(() => sendPhoto.execute('c1', photo)).thenThrow(
      buildDioException(
        statusCode: 415,
        data: {'error': 'the photo must be a JPEG or PNG file'},
      ),
    ),
    build: buildCubit,
    act: (cubit) => cubit.submit(request, photo: photo),
    expect: () => [
      isA<CustomOrderFormState>(),
      isA<CustomOrderFormState>()
          .having((s) => s.created, 'created', created)
          .having(
            (s) => s.photoFailure,
            'photoFailure',
            isA<FootPhotoFileTypeFailure>(),
          ),
    ],
  );

  blocTest<CustomOrderFormCubit, CustomOrderFormState>(
    'shows why the request was refused and sends no photo',
    setUp: () => when(() => create.execute(request)).thenThrow(
      buildDioException(
        statusCode: 409,
        data: {'error': 'this advertisement does not take custom orders'},
      ),
    ),
    build: buildCubit,
    act: (cubit) => cubit.submit(request, photo: photo),
    expect: () => [
      isA<CustomOrderFormState>(),
      isA<CustomOrderFormState>()
          .having((s) => s.created, 'created', isNull)
          .having(
            (s) => s.failure,
            'failure',
            isA<CustomMadeNotAllowedFailure>(),
          ),
    ],
    verify: (_) => verifyNever(() => sendPhoto.execute(any(), any())),
  );

  blocTest<CustomOrderFormCubit, CustomOrderFormState>(
    'does not create twice',
    build: buildCubit,
    act: (cubit) async {
      await cubit.submit(request);
      await cubit.submit(request);
    },
    skip: 2,
    expect: () => <CustomOrderFormState>[],
    verify: (_) => verify(() => create.execute(request)).called(1),
  );
}

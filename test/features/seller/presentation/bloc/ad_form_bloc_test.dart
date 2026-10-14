import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_form_step.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/presentation/bloc/ad_form_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetCatalogFilterOptionsUseCase getOptions;
  late MockGetAdUseCase getAd;
  late MockSaveAdUseCase saveAd;
  late MockChangeAdStatusUseCase changeStatus;
  late MockAddAdImageUseCase addImage;
  late MockRemoveAdImageUseCase removeImage;
  late MockReorderAdImagesUseCase reorderImages;

  const draft = AdDraft(title: 'Palmilha', categoryId: '301');
  const photo = UploadFile(bytes: [1, 2, 3], filename: 'foto.jpg');

  SellerAdEntity ad({
    AdStatus status = AdStatus.draft,
    List<String> missingFields = const [],
    List<SellerAdImage> images = const [],
  }) => SellerAdEntity(
    id: '601',
    title: 'Palmilha',
    price: 89.9,
    stock: 10,
    status: status,
    categoryId: '301',
    missingFields: missingFields,
    images: images,
  );

  const images = [
    SellerAdImage(id: 'i1', url: '/a.png', isCover: true),
    SellerAdImage(id: 'i2', url: '/b.png'),
    SellerAdImage(id: 'i3', url: '/c.png'),
  ];

  AdFormBloc buildBloc({String? adId}) => AdFormBloc(
    adId: adId,
    getOptionsUseCase: getOptions,
    getAdUseCase: getAd,
    saveAdUseCase: saveAd,
    changeAdStatusUseCase: changeStatus,
    addImageUseCase: addImage,
    removeImageUseCase: removeImage,
    reorderImagesUseCase: reorderImages,
  );

  AdFormState ready({SellerAdEntity? ad, AdFormStep? step}) => AdFormState(
    status: AdFormStatus.ready,
    options: catalogFilterOptions,
    ad: ad,
    step: step ?? AdFormStep.general,
  );

  setUpAll(() {
    registerFallbackValue(draft);
    registerFallbackValue(photo);
    registerFallbackValue(AdStatusAction.publish);
  });

  setUp(() {
    getOptions = MockGetCatalogFilterOptionsUseCase();
    getAd = MockGetAdUseCase();
    saveAd = MockSaveAdUseCase();
    changeStatus = MockChangeAdStatusUseCase();
    addImage = MockAddAdImageUseCase();
    removeImage = MockRemoveAdImageUseCase();
    reorderImages = MockReorderAdImagesUseCase();
    when(
      () => getOptions.execute(),
    ).thenAnswer((_) async => catalogFilterOptions);
  });

  group('LoadAdFormEvent', () {
    blocTest<AdFormBloc, AdFormState>(
      'loads only the options for a new ad',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadAdFormEvent()),
      expect: () => [
        isA<AdFormState>().having(
          (s) => s.status,
          'status',
          AdFormStatus.loading,
        ),
        isA<AdFormState>()
            .having((s) => s.status, 'status', AdFormStatus.ready)
            .having((s) => s.ad, 'ad', isNull)
            .having((s) => s.canPublish, 'canPublish', isTrue),
      ],
      verify: (_) => verifyNever(() => getAd.execute(any())),
    );

    blocTest<AdFormBloc, AdFormState>(
      'loads the ad to edit',
      setUp: () => when(
        () => getAd.execute('601'),
      ).thenAnswer((_) async => ad(status: AdStatus.published)),
      build: () => buildBloc(adId: '601'),
      act: (bloc) => bloc.add(LoadAdFormEvent()),
      skip: 1,
      expect: () => [
        isA<AdFormState>()
            .having((s) => s.ad?.id, 'ad', '601')
            .having((s) => s.canPublish, 'canPublish', isFalse),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'shows a load failure',
      setUp: () => when(
        () => getAd.execute(any()),
      ).thenThrow(buildDioException(statusCode: 404)),
      build: () => buildBloc(adId: '601'),
      act: (bloc) => bloc.add(LoadAdFormEvent()),
      skip: 1,
      expect: () => [
        isA<AdFormState>()
            .having((s) => s.status, 'status', AdFormStatus.loadFailure)
            .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
      ],
    );
  });

  group('GoToStepEvent', () {
    blocTest<AdFormBloc, AdFormState>(
      'just moves between steps that need no saved ad',
      build: buildBloc,
      seed: ready,
      act: (bloc) =>
          bloc.add(GoToStepEvent(step: AdFormStep.attributes, draft: draft)),
      expect: () => [
        isA<AdFormState>().having((s) => s.step, 'step', AdFormStep.attributes),
      ],
      verify: (_) => verifyNever(() => saveAd.execute(any(), any())),
    );

    blocTest<AdFormBloc, AdFormState>(
      'saves a new ad as a draft before the photos',
      setUp: () =>
          when(() => saveAd.execute(null, draft)).thenAnswer((_) async => ad()),
      build: buildBloc,
      seed: ready,
      act: (bloc) =>
          bloc.add(GoToStepEvent(step: AdFormStep.photos, draft: draft)),
      expect: () => [
        isA<AdFormState>().having(
          (s) => s.activity,
          'activity',
          AdFormActivity.saving,
        ),
        isA<AdFormState>()
            .having((s) => s.ad?.id, 'ad', '601')
            .having((s) => s.step, 'step', AdFormStep.general),
        isA<AdFormState>()
            .having((s) => s.step, 'step', AdFormStep.photos)
            .having((s) => s.notice, 'notice', 'Rascunho salvo.'),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'stays on the step when that save fails',
      setUp: () => when(
        () => saveAd.execute(any(), any()),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: ready,
      act: (bloc) =>
          bloc.add(GoToStepEvent(step: AdFormStep.photos, draft: draft)),
      skip: 1,
      expect: () => [
        isA<AdFormState>()
            .having((s) => s.step, 'step', AdFormStep.general)
            .having((s) => s.isBusy, 'busy', isFalse)
            .having((s) => s.failure, 'failure', isA<ServerFailure>()),
      ],
    );
  });

  group('SaveAdEvent', () {
    blocTest<AdFormBloc, AdFormState>(
      'reports a saved draft',
      setUp: () => when(
        () => saveAd.execute('601', draft),
      ).thenAnswer((_) async => ad()),
      build: buildBloc,
      seed: () => ready(ad: ad()),
      act: (bloc) => bloc.add(SaveAdEvent(draft: draft)),
      skip: 2,
      expect: () => [
        isA<AdFormState>().having((s) => s.notice, 'notice', 'Rascunho salvo.'),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'reports saved changes of a published ad',
      setUp: () => when(
        () => saveAd.execute(any(), any()),
      ).thenAnswer((_) async => ad(status: AdStatus.published)),
      build: buildBloc,
      seed: () => ready(ad: ad(status: AdStatus.published)),
      act: (bloc) => bloc.add(SaveAdEvent(draft: draft)),
      skip: 2,
      expect: () => [
        isA<AdFormState>().having(
          (s) => s.notice,
          'notice',
          'Alterações salvas.',
        ),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'highlights the fields a published ad cannot lose and opens their step',
      setUp: () => when(() => saveAd.execute(any(), any())).thenThrow(
        buildDioException(
          statusCode: 422,
          data: {
            'fields': ['contraindications'],
          },
        ),
      ),
      build: buildBloc,
      seed: () => ready(
        ad: ad(status: AdStatus.published),
        step: AdFormStep.review,
      ),
      act: (bloc) => bloc.add(SaveAdEvent(draft: draft)),
      skip: 1,
      expect: () => [
        isA<AdFormState>()
            .having((s) => s.step, 'step', AdFormStep.purposes)
            .having((s) => s.highlightedFields, 'highlighted', {
              'contraindications',
            })
            .having((s) => s.failure, 'failure', isA<MissingFieldsFailure>())
            .having((s) => s.isBusy, 'busy', isFalse),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'keeps only the highlights still missing after a save',
      setUp: () => when(
        () => saveAd.execute(any(), any()),
      ).thenAnswer((_) async => ad(missingFields: ['images'])),
      build: buildBloc,
      seed: () => AdFormState(
        status: AdFormStatus.ready,
        options: catalogFilterOptions,
        ad: ad(),
        highlightedFields: const {'price', 'images'},
      ),
      act: (bloc) => bloc.add(SaveAdEvent(draft: draft)),
      skip: 1,
      expect: () => [
        isA<AdFormState>().having((s) => s.highlightedFields, 'highlighted', {
          'images',
        }),
        isA<AdFormState>(),
      ],
    );
  });

  group('PublishAdEvent', () {
    blocTest<AdFormBloc, AdFormState>(
      'saves, publishes and finishes',
      setUp: () {
        when(() => saveAd.execute(any(), any())).thenAnswer((_) async => ad());
        when(
          () => changeStatus.execute('601', AdStatusAction.publish),
        ).thenAnswer((_) async => ad(status: AdStatus.published));
      },
      build: buildBloc,
      seed: () => ready(step: AdFormStep.review),
      act: (bloc) => bloc.add(PublishAdEvent(draft: draft)),
      expect: () => [
        isA<AdFormState>().having(
          (s) => s.activity,
          'activity',
          AdFormActivity.publishing,
        ),
        isA<AdFormState>()
            .having((s) => s.ad?.id, 'ad', '601')
            .having((s) => s.activity, 'activity', AdFormActivity.publishing),
        isA<AdFormState>()
            .having((s) => s.isFinished, 'finished', isTrue)
            .having((s) => s.ad?.status, 'status', AdStatus.published)
            .having((s) => s.notice, 'notice', 'Anúncio publicado.'),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'does not try to publish while fields are missing (UC-003)',
      setUp: () => when(
        () => saveAd.execute(any(), any()),
      ).thenAnswer((_) async => ad(missingFields: ['side', 'images'])),
      build: buildBloc,
      seed: () => ready(ad: ad(), step: AdFormStep.review),
      act: (bloc) => bloc.add(PublishAdEvent(draft: draft)),
      skip: 2,
      expect: () => [
        isA<AdFormState>()
            .having((s) => s.step, 'step', AdFormStep.attributes)
            .having((s) => s.highlightedFields, 'highlighted', {
              'side',
              'images',
            })
            .having((s) => s.isFinished, 'finished', isFalse)
            .having(
              (s) => s.failure,
              'failure',
              isA<MissingFieldsFailure>().having((f) => f.fields, 'fields', [
                'side',
                'images',
              ]),
            ),
      ],
      verify: (_) => verifyNever(() => changeStatus.execute(any(), any())),
    );

    blocTest<AdFormBloc, AdFormState>(
      'maps a refused publish (422) to the missing fields',
      setUp: () {
        when(() => saveAd.execute(any(), any())).thenAnswer((_) async => ad());
        when(
          () => changeStatus.execute(any(), any()),
        ).thenThrow(buildDioException(statusCode: 422));
      },
      build: buildBloc,
      seed: () => ready(ad: ad(), step: AdFormStep.review),
      act: (bloc) => bloc.add(PublishAdEvent(draft: draft)),
      skip: 2,
      expect: () => [
        isA<AdFormState>()
            .having((s) => s.failure, 'failure', isA<MissingFieldsFailure>())
            .having((s) => s.isBusy, 'busy', isFalse),
      ],
    );
  });

  group('images', () {
    blocTest<AdFormBloc, AdFormState>(
      'adds a photo and clears the photo highlight',
      setUp: () => when(
        () => addImage.execute('601', photo),
      ).thenAnswer((_) async => ad(images: images.sublist(0, 1))),
      build: buildBloc,
      seed: () => AdFormState(
        status: AdFormStatus.ready,
        options: catalogFilterOptions,
        ad: ad(),
        step: AdFormStep.photos,
        highlightedFields: const {'images', 'price'},
      ),
      act: (bloc) => bloc.add(AddImageEvent(photo: photo)),
      expect: () => [
        isA<AdFormState>().having(
          (s) => s.activity,
          'activity',
          AdFormActivity.uploading,
        ),
        isA<AdFormState>()
            .having((s) => s.ad?.images.length, 'images', 1)
            .having((s) => s.highlightedFields, 'highlighted', {'price'}),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'explains the photo limit on 409',
      setUp: () => when(
        () => addImage.execute(any(), any()),
      ).thenThrow(buildDioException(statusCode: 409)),
      build: buildBloc,
      seed: () => ready(
        ad: ad(images: images),
        step: AdFormStep.photos,
      ),
      act: (bloc) => bloc.add(AddImageEvent(photo: photo)),
      skip: 1,
      expect: () => [
        isA<AdFormState>().having(
          (s) => s.failure,
          'failure',
          isA<TooManyPhotosFailure>(),
        ),
      ],
    );

    blocTest<AdFormBloc, AdFormState>(
      'moves a photo one place and sends the whole order',
      setUp: () => when(
        () => reorderImages.execute(any(), any()),
      ).thenAnswer((_) async => ad(images: images)),
      build: buildBloc,
      seed: () => ready(
        ad: ad(images: images),
        step: AdFormStep.photos,
      ),
      act: (bloc) => bloc.add(MoveImageEvent(imageId: 'i3', offset: -1)),
      verify: (_) => verify(
        () => reorderImages.execute('601', ['i1', 'i3', 'i2']),
      ).called(1),
    );

    blocTest<AdFormBloc, AdFormState>(
      'ignores a move past the ends',
      build: buildBloc,
      seed: () => ready(
        ad: ad(images: images),
        step: AdFormStep.photos,
      ),
      act: (bloc) => bloc.add(MoveImageEvent(imageId: 'i1', offset: -1)),
      expect: () => <AdFormState>[],
    );

    blocTest<AdFormBloc, AdFormState>(
      'sets the cover keeping the order',
      setUp: () => when(
        () => reorderImages.execute(
          any(),
          any(),
          coverImageId: any(named: 'coverImageId'),
        ),
      ).thenAnswer((_) async => ad(images: images)),
      build: buildBloc,
      seed: () => ready(
        ad: ad(images: images),
        step: AdFormStep.photos,
      ),
      act: (bloc) => bloc.add(SetCoverImageEvent(imageId: 'i2')),
      verify: (_) => verify(
        () => reorderImages.execute('601', [
          'i1',
          'i2',
          'i3',
        ], coverImageId: 'i2'),
      ).called(1),
    );

    blocTest<AdFormBloc, AdFormState>(
      'removing the last photo of a published ad is refused (422)',
      setUp: () => when(
        () => removeImage.execute(any(), any()),
      ).thenThrow(buildDioException(statusCode: 422)),
      build: buildBloc,
      seed: () => ready(
        ad: ad(status: AdStatus.published, images: images.sublist(0, 1)),
        step: AdFormStep.photos,
      ),
      act: (bloc) => bloc.add(RemoveImageEvent(imageId: 'i1')),
      skip: 1,
      expect: () => [
        isA<AdFormState>()
            .having((s) => s.ad?.images.length, 'images', 1)
            .having((s) => s.failure, 'failure', isA<MissingFieldsFailure>()),
      ],
    );
  });

  blocTest<AdFormBloc, AdFormState>(
    'ignores actions while busy',
    build: buildBloc,
    seed: () => AdFormState(
      status: AdFormStatus.ready,
      options: catalogFilterOptions,
      ad: ad(),
      activity: AdFormActivity.uploading,
    ),
    act: (bloc) => bloc
      ..add(SaveAdEvent(draft: draft))
      ..add(PublishAdEvent(draft: draft))
      ..add(GoToStepEvent(step: AdFormStep.review, draft: draft)),
    expect: () => <AdFormState>[],
  );
}

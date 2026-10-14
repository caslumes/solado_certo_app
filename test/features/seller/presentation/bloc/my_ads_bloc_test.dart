import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/presentation/bloc/my_ads_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetMyAdsUseCase getMyAds;
  late MockChangeAdStatusUseCase changeStatus;
  late MockRemoveAdUseCase removeAd;

  final published = buildSellerAd(id: '601');
  final draft = buildSellerAd(id: '602', status: AdStatus.draft);

  MyAdsBloc buildBloc() => MyAdsBloc(
    getMyAdsUseCase: getMyAds,
    changeAdStatusUseCase: changeStatus,
    removeAdUseCase: removeAd,
  );

  TypeMatcher<MyAdsLoaded> loaded({
    List<String>? ids,
    String? busyAdId,
    String? notice,
    TypeMatcher<Failure>? failure,
  }) {
    var matcher = isA<MyAdsLoaded>()
        .having((s) => s.busyAdId, 'busyAdId', busyAdId)
        .having((s) => s.notice, 'notice', notice)
        .having((s) => s.failure, 'failure', failure ?? isNull);
    if (ids != null) {
      matcher = matcher.having(
        (s) => s.ads.map((ad) => ad.id).toList(),
        'ids',
        ids,
      );
    }
    return matcher;
  }

  setUpAll(() => registerFallbackValue(AdStatusAction.pause));

  setUp(() {
    getMyAds = MockGetMyAdsUseCase();
    changeStatus = MockChangeAdStatusUseCase();
    removeAd = MockRemoveAdUseCase();
  });

  group('LoadMyAdsEvent', () {
    blocTest<MyAdsBloc, MyAdsState>(
      'loads the ads',
      setUp: () => when(
        () => getMyAds.execute(),
      ).thenAnswer((_) async => [published, draft]),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadMyAdsEvent()),
      expect: () => [
        isA<MyAdsLoading>(),
        loaded(ids: ['601', '602']),
      ],
    );

    blocTest<MyAdsBloc, MyAdsState>(
      'emits a load failure on the first load',
      setUp: () => when(
        () => getMyAds.execute(),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadMyAdsEvent()),
      expect: () => [
        isA<MyAdsLoading>(),
        isA<MyAdsLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<ServerFailure>(),
        ),
      ],
    );

    blocTest<MyAdsBloc, MyAdsState>(
      'keeps the list when a refresh fails',
      setUp: () => when(
        () => getMyAds.execute(),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [published]),
      act: (bloc) => bloc.add(LoadMyAdsEvent()),
      expect: () => [
        loaded(ids: ['601'], failure: isA<ServerFailure>()),
      ],
    );
  });

  group('ChangeAdStatusEvent', () {
    blocTest<MyAdsBloc, MyAdsState>(
      'replaces the ad with the one returned',
      setUp: () => when(
        () => changeStatus.execute('601', AdStatusAction.pause),
      ).thenAnswer((_) async => buildSellerAd(status: AdStatus.paused)),
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [published, draft]),
      act: (bloc) => bloc.add(
        ChangeAdStatusEvent(adId: '601', action: AdStatusAction.pause),
      ),
      expect: () => [
        loaded(busyAdId: '601'),
        loaded(ids: ['601', '602'], notice: 'Anúncio pausado.').having(
          (s) => s.withStatus(AdStatus.paused).single.id,
          'paused',
          '601',
        ),
      ],
    );

    blocTest<MyAdsBloc, MyAdsState>(
      'keeps the list and exposes the missing fields on 422',
      setUp: () => when(
        () => changeStatus.execute(any(), any()),
      ).thenThrow(buildDioException(statusCode: 422)),
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [draft]),
      act: (bloc) => bloc.add(
        ChangeAdStatusEvent(adId: '602', action: AdStatusAction.publish),
      ),
      expect: () => [
        loaded(busyAdId: '602'),
        loaded(ids: ['602'], failure: isA<MissingFieldsFailure>()),
      ],
      verify: (_) => verifyNever(() => getMyAds.execute()),
    );

    blocTest<MyAdsBloc, MyAdsState>(
      'reloads the list when the ad changed elsewhere (409)',
      setUp: () {
        when(
          () => changeStatus.execute(any(), any()),
        ).thenThrow(buildDioException(statusCode: 409));
        when(
          () => getMyAds.execute(),
        ).thenAnswer((_) async => [buildSellerAd(status: AdStatus.paused)]);
      },
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [published]),
      act: (bloc) => bloc.add(
        ChangeAdStatusEvent(adId: '601', action: AdStatusAction.pause),
      ),
      expect: () => [
        loaded(busyAdId: '601'),
        loaded(
          failure: isA<AdOutdatedFailure>(),
        ).having((s) => s.ads.single.status, 'status', AdStatus.paused),
      ],
    );

    blocTest<MyAdsBloc, MyAdsState>(
      'ignores another action while one is running',
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [published, draft], busyAdId: '601'),
      act: (bloc) => bloc.add(RemoveAdEvent(adId: '602')),
      expect: () => <MyAdsState>[],
      verify: (_) => verifyNever(() => removeAd.execute(any())),
    );
  });

  group('RemoveAdEvent', () {
    blocTest<MyAdsBloc, MyAdsState>(
      'drops the ad from the list',
      setUp: () => when(() => removeAd.execute('602')).thenAnswer((_) async {}),
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [published, draft]),
      act: (bloc) => bloc.add(RemoveAdEvent(adId: '602')),
      expect: () => [
        loaded(busyAdId: '602'),
        loaded(ids: ['601'], notice: 'Anúncio removido.'),
      ],
    );

    blocTest<MyAdsBloc, MyAdsState>(
      'reloads the list when the ad no longer exists (404)',
      setUp: () {
        when(
          () => removeAd.execute(any()),
        ).thenThrow(buildDioException(statusCode: 404));
        when(() => getMyAds.execute()).thenAnswer((_) async => [published]);
      },
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [published, draft]),
      act: (bloc) => bloc.add(RemoveAdEvent(adId: '602')),
      expect: () => [
        loaded(busyAdId: '602'),
        loaded(ids: ['601'], failure: isA<AdOutdatedFailure>()),
      ],
    );

    blocTest<MyAdsBloc, MyAdsState>(
      'keeps the ad when removing fails',
      setUp: () => when(
        () => removeAd.execute(any()),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => MyAdsLoaded(ads: [published, draft]),
      act: (bloc) => bloc.add(RemoveAdEvent(adId: '602')),
      expect: () => [
        loaded(busyAdId: '602'),
        loaded(ids: ['601', '602'], failure: isA<ServerFailure>()),
      ],
    );
  });
}

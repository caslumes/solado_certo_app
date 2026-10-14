import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/profile/presentation/bloc/profile_bloc.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetProfileUseCase getProfile;
  late MockUpdateProfileUseCase updateProfile;
  late MockGetAddressesUseCase getAddresses;
  late MockGetPodologicalProfileUseCase getPodologicalProfile;
  late MockSavePodologicalProfileUseCase savePodologicalProfile;
  late MockGetPainPointsUseCase getPainPoints;
  late MockHasPodologicalConsentUseCase hasPodologicalConsent;
  late MockRevokePodologicalConsentUseCase revokeConsent;
  late MockChangeAvatarUseCase changeAvatar;
  late MockRemoveAvatarUseCase removeAvatar;
  late MockGetRolesUseCase getRoles;
  late MockBecomeSellerUseCase becomeSeller;

  const photo = UploadFile(bytes: [1, 2, 3], filename: 'foto.jpg');

  ProfileBloc buildBloc() => ProfileBloc(
    getProfileUseCase: getProfile,
    updateProfileUseCase: updateProfile,
    getAddressesUseCase: getAddresses,
    getPodologicalProfileUseCase: getPodologicalProfile,
    savePodologicalProfileUseCase: savePodologicalProfile,
    getPainPointsUseCase: getPainPoints,
    hasPodologicalConsentUseCase: hasPodologicalConsent,
    revokePodologicalConsentUseCase: revokeConsent,
    changeAvatarUseCase: changeAvatar,
    removeAvatarUseCase: removeAvatar,
    getRolesUseCase: getRoles,
    becomeSellerUseCase: becomeSeller,
  );

  ProfileData buildData({bool hasConsent = true}) => ProfileData(
    profile: buildProfile(),
    addresses: const [],
    podologicalProfile: PodologicalProfileEntity(
      footstrikeType: FootstrikeType.pronated,
      painPoints: const [PainPointEntity(id: 'p1', name: 'Calcanhar')],
    ),
    painPoints: const [PainPointEntity(id: 'p1', name: 'Calcanhar')],
    hasPodologicalConsent: hasConsent,
    roles: const [UserRole.buyer],
  );

  TypeMatcher<ProfileLoaded> loaded({
    bool isSaving = false,
    ProfileNotice? notice,
    TypeMatcher<Failure>? failure,
  }) => isA<ProfileLoaded>()
      .having((s) => s.isSaving, 'isSaving', isSaving)
      .having((s) => s.notice, 'notice', notice)
      .having((s) => s.failure, 'failure', failure ?? isNull);

  setUpAll(() {
    registerFallbackValue(buildProfile());
    registerFallbackValue(photo);
    registerFallbackValue(
      const PodologicalProfileUpdate(footstrikeType: FootstrikeType.neutral),
    );
  });

  setUp(() {
    getProfile = MockGetProfileUseCase();
    updateProfile = MockUpdateProfileUseCase();
    getAddresses = MockGetAddressesUseCase();
    getPodologicalProfile = MockGetPodologicalProfileUseCase();
    savePodologicalProfile = MockSavePodologicalProfileUseCase();
    getPainPoints = MockGetPainPointsUseCase();
    hasPodologicalConsent = MockHasPodologicalConsentUseCase();
    revokeConsent = MockRevokePodologicalConsentUseCase();
    changeAvatar = MockChangeAvatarUseCase();
    removeAvatar = MockRemoveAvatarUseCase();
    getRoles = MockGetRolesUseCase();
    becomeSeller = MockBecomeSellerUseCase();
  });

  group('LoadProfileEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'loads the profile, addresses, podological profile, consent and roles',
      setUp: () {
        when(
          () => getProfile.execute(),
        ).thenAnswer((_) async => buildProfile());
        when(() => getAddresses.execute()).thenAnswer((_) async => []);
        when(
          () => getPodologicalProfile.execute(),
        ).thenAnswer((_) async => PodologicalProfileEntity());
        when(() => getPainPoints.execute()).thenAnswer((_) async => []);
        when(
          () => hasPodologicalConsent.execute(),
        ).thenAnswer((_) async => true);
        when(
          () => getRoles.execute(),
        ).thenAnswer((_) async => [UserRole.buyer, UserRole.seller]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadProfileEvent()),
      expect: () => [
        isA<ProfileLoading>(),
        loaded()
            .having((s) => s.data.hasPodologicalConsent, 'consent', isTrue)
            .having((s) => s.data.isSeller, 'is seller', isTrue),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits a load failure when a request fails',
      setUp: () => when(
        () => getProfile.execute(),
      ).thenThrow(buildDioException(type: DioExceptionType.connectionError)),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadProfileEvent()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ],
    );
  });

  group('SavePersonalDataEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'saves name and phone and reports it',
      setUp: () => when(() => updateProfile.execute(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as ProfileEntity,
      ),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(
        SavePersonalDataEvent(name: 'Maria Lima', phone: '19988887777'),
      ),
      expect: () => [
        loaded(isSaving: true),
        loaded(
          notice: ProfileNotice.personalDataSaved,
        ).having((s) => s.data.profile.name, 'name', 'Maria Lima'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'keeps the old data and exposes the failure when saving fails',
      setUp: () => when(
        () => updateProfile.execute(any()),
      ).thenThrow(buildDioException(statusCode: 400)),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) =>
          bloc.add(SavePersonalDataEvent(name: 'X', phone: '19988887777')),
      expect: () => [
        loaded(isSaving: true),
        loaded(
          failure: isA<InvalidInputFailure>(),
        ).having((s) => s.data.profile.name, 'name', buildProfile().name),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'reports a phone already used by another account on 409',
      setUp: () => when(
        () => updateProfile.execute(any()),
      ).thenThrow(buildDioException(statusCode: 409)),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) =>
          bloc.add(SavePersonalDataEvent(name: 'X', phone: '19988887777')),
      expect: () => [
        loaded(isSaving: true),
        loaded(
          failure: isA<PhoneAlreadyInUseFailure>(),
        ).having((s) => s.data.profile.phone, 'phone', buildProfile().phone),
      ],
    );
  });

  blocTest<ProfileBloc, ProfileState>(
    'AddressesChangedEvent reloads the address list',
    setUp: () => when(() => getAddresses.execute()).thenAnswer((_) async => []),
    build: buildBloc,
    seed: () => ProfileLoaded(data: buildData()),
    act: (bloc) => bloc.add(AddressesChangedEvent()),
    expect: () => [
      loaded(isSaving: true),
      loaded(notice: ProfileNotice.addressSaved),
    ],
    verify: (_) => verify(() => getAddresses.execute()).called(1),
  );

  blocTest<ProfileBloc, ProfileState>(
    'SavePodologicalProfileEvent saves and marks consent as given',
    setUp: () => when(() => savePodologicalProfile.execute(any())).thenAnswer(
      (_) async =>
          PodologicalProfileEntity(footstrikeType: FootstrikeType.neutral),
    ),
    build: buildBloc,
    seed: () => ProfileLoaded(data: buildData(hasConsent: false)),
    act: (bloc) => bloc.add(
      SavePodologicalProfileEvent(
        update: const PodologicalProfileUpdate(
          footstrikeType: FootstrikeType.neutral,
        ),
      ),
    ),
    expect: () => [
      loaded(isSaving: true),
      loaded(notice: ProfileNotice.podologicalProfileSaved)
          .having((s) => s.data.hasPodologicalConsent, 'consent', isTrue)
          .having(
            (s) => s.data.podologicalProfile.footstrikeType,
            'footstrike',
            FootstrikeType.neutral,
          ),
    ],
  );

  group('RevokePodologicalConsentEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'revokes consent and clears the podological profile',
      setUp: () => when(() => revokeConsent.execute()).thenAnswer((_) async {}),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(RevokePodologicalConsentEvent()),
      expect: () => [
        loaded(isSaving: true),
        loaded(notice: ProfileNotice.podologicalConsentRevoked)
            .having((s) => s.data.hasPodologicalConsent, 'consent', isFalse)
            .having(
              (s) => s.data.podologicalProfile.footstrikeType,
              'footstrike',
              isNull,
            )
            .having(
              (s) => s.data.podologicalProfile.painPoints,
              'pain points',
              isEmpty,
            ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'keeps the profile and consent when revocation fails',
      setUp: () => when(
        () => revokeConsent.execute(),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(RevokePodologicalConsentEvent()),
      expect: () => [
        loaded(isSaving: true),
        loaded(failure: isA<ServerFailure>())
            .having((s) => s.data.hasPodologicalConsent, 'consent', isTrue)
            .having(
              (s) => s.data.podologicalProfile.footstrikeType,
              'footstrike',
              FootstrikeType.pronated,
            ),
      ],
    );
  });

  group('ChangeAvatarEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'uploads the photo and shows the new avatar',
      setUp: () => when(() => changeAvatar.execute(any())).thenAnswer(
        (_) async => ProfileEntity(
          name: 'Maria Souza',
          email: 'maria@example.com',
          phone: '19999999999',
          avatarUrl: '/files/public/avatars/a.jpg',
        ),
      ),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(ChangeAvatarEvent(photo: photo)),
      expect: () => [
        loaded(isSaving: true),
        loaded(notice: ProfileNotice.avatarChanged).having(
          (s) => s.data.profile.avatarUrl,
          'avatar',
          '/files/public/avatars/a.jpg',
        ),
      ],
      verify: (_) => verify(() => changeAvatar.execute(photo)).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'explains a rejected file type and keeps the old avatar',
      setUp: () => when(
        () => changeAvatar.execute(any()),
      ).thenThrow(buildDioException(statusCode: 415)),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(ChangeAvatarEvent(photo: photo)),
      expect: () => [
        loaded(isSaving: true),
        loaded(
          failure: isA<UnsupportedFileTypeFailure>(),
        ).having((s) => s.data.profile.avatarUrl, 'avatar', ''),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'explains a file over the size limit',
      setUp: () => when(
        () => changeAvatar.execute(any()),
      ).thenThrow(buildDioException(statusCode: 413)),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(ChangeAvatarEvent(photo: photo)),
      expect: () => [
        loaded(isSaving: true),
        loaded(failure: isA<FileTooLargeFailure>()),
      ],
    );
  });

  blocTest<ProfileBloc, ProfileState>(
    'RemoveAvatarEvent clears the avatar',
    setUp: () => when(
      () => removeAvatar.execute(),
    ).thenAnswer((_) async => buildProfile()),
    build: buildBloc,
    seed: () => ProfileLoaded(data: buildData()),
    act: (bloc) => bloc.add(RemoveAvatarEvent()),
    expect: () => [
      loaded(isSaving: true),
      loaded(
        notice: ProfileNotice.avatarRemoved,
      ).having((s) => s.data.profile.avatarUrl, 'avatar', ''),
    ],
  );

  group('BecomeSellerEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'adds the seller role',
      setUp: () => when(
        () => becomeSeller.execute(),
      ).thenAnswer((_) async => [UserRole.buyer, UserRole.seller]),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(BecomeSellerEvent()),
      expect: () => [
        loaded(isSaving: true),
        loaded(
          notice: ProfileNotice.becameSeller,
        ).having((s) => s.data.isSeller, 'is seller', isTrue),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'stays a buyer when the request fails',
      setUp: () => when(
        () => becomeSeller.execute(),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => ProfileLoaded(data: buildData()),
      act: (bloc) => bloc.add(BecomeSellerEvent()),
      expect: () => [
        loaded(isSaving: true),
        loaded(
          failure: isA<ServerFailure>(),
        ).having((s) => s.data.isSeller, 'is seller', isFalse),
      ],
    );
  });
}

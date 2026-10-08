import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';

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
  late MockGetOnboardingUseCase getOnboarding;
  late MockChangeOnboardingStepUseCase changeStep;

  OnboardingBloc buildBloc() => OnboardingBloc(
    getProfileUseCase: getProfile,
    updateProfileUseCase: updateProfile,
    getAddressesUseCase: getAddresses,
    getPodologicalProfileUseCase: getPodologicalProfile,
    savePodologicalProfileUseCase: savePodologicalProfile,
    getPainPointsUseCase: getPainPoints,
    hasPodologicalConsentUseCase: hasPodologicalConsent,
    getOnboardingUseCase: getOnboarding,
    changeOnboardingStepUseCase: changeStep,
  );

  OnboardingInProgress inProgressAt(OnboardingStep step) =>
      OnboardingInProgress(onboardingDraft: buildDraft(step: step));

  TypeMatcher<OnboardingInProgress> inProgress({
    OnboardingStep? step,
    bool isSaving = false,
    TypeMatcher<Failure>? failure,
  }) => isA<OnboardingInProgress>()
      .having(
        (s) => s.onboardingDraft.onboarding.currentStep,
        'step',
        step ?? anything,
      )
      .having((s) => s.isSaving, 'isSaving', isSaving)
      .having((s) => s.failure, 'failure', failure ?? isNull);

  setUpAll(() {
    registerFallbackValue(OnboardingStep.welcome);
    registerFallbackValue(OnboardingAction.advance);
    registerFallbackValue(buildProfile());
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
    getOnboarding = MockGetOnboardingUseCase();
    changeStep = MockChangeOnboardingStepUseCase();

    when(() => getProfile.execute()).thenAnswer((_) async => buildProfile());
    when(() => getAddresses.execute()).thenAnswer((_) async => []);
    when(
      () => getPodologicalProfile.execute(),
    ).thenAnswer((_) async => PodologicalProfileEntity());
    when(() => getPainPoints.execute()).thenAnswer(
      (_) async => const [PainPointEntity(id: 'p1', name: 'Calcanhar')],
    );
    when(() => hasPodologicalConsent.execute()).thenAnswer((_) async => true);
  });

  group('StartOnboardingEvent', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'loads the draft and resumes at the server-side step',
      setUp: () => when(() => getOnboarding.execute()).thenAnswer(
        (_) async => buildOnboarding(step: OnboardingStep.addressConfig),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(StartOnboardingEvent()),
      expect: () => [
        isA<OnboardingLoading>(),
        inProgress(step: OnboardingStep.addressConfig)
            .having(
              (s) => s.onboardingDraft.painPoints.single.name,
              'pain point',
              'Calcanhar',
            )
            .having(
              (s) => s.onboardingDraft.hasPodologicalConsent,
              'consent',
              isTrue,
            ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'finishes immediately when onboarding is already completed',
      setUp: () => when(() => getOnboarding.execute()).thenAnswer(
        (_) async => buildOnboarding(status: OnboardingStatus.completed),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(StartOnboardingEvent()),
      expect: () => [isA<OnboardingLoading>(), isA<OnboardingFinished>()],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emits a load failure instead of hanging when a request fails',
      setUp: () => when(
        () => getOnboarding.execute(),
      ).thenThrow(buildDioException(type: DioExceptionType.connectionError)),
      build: buildBloc,
      act: (bloc) => bloc.add(StartOnboardingEvent()),
      expect: () => [
        isA<OnboardingLoading>(),
        isA<OnboardingLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ],
    );
  });

  group('AdvanceOnboardingEvent', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'saves, then moves to the step returned by the server',
      setUp: () {
        when(() => changeStep.execute(any(), any())).thenAnswer((_) async {});
        when(() => getOnboarding.execute()).thenAnswer(
          (_) async => buildOnboarding(step: OnboardingStep.profileConfig),
        );
      },
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.welcome),
      act: (bloc) => bloc.add(AdvanceOnboardingEvent()),
      expect: () => [
        inProgress(step: OnboardingStep.welcome, isSaving: true),
        inProgress(step: OnboardingStep.profileConfig),
      ],
      verify: (_) => verify(
        () => changeStep.execute(
          OnboardingStep.welcome,
          OnboardingAction.advance,
        ),
      ).called(1),
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'keeps the current step and exposes the failure when saving fails',
      setUp: () => when(
        () => changeStep.execute(any(), any()),
      ).thenThrow(buildDioException(statusCode: 500)),
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.welcome),
      act: (bloc) => bloc.add(AdvanceOnboardingEvent()),
      expect: () => [
        inProgress(step: OnboardingStep.welcome, isSaving: true),
        inProgress(step: OnboardingStep.welcome, failure: isA<ServerFailure>()),
      ],
    );

    late Completer<void> pendingSave;

    blocTest<OnboardingBloc, OnboardingState>(
      'ignores rapid repeated taps while a step change is saving',
      setUp: () {
        pendingSave = Completer<void>();
        when(
          () => changeStep.execute(any(), any()),
        ).thenAnswer((_) => pendingSave.future);
        when(() => getOnboarding.execute()).thenAnswer(
          (_) async => buildOnboarding(step: OnboardingStep.profileConfig),
        );
      },
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.welcome),
      act: (bloc) async {
        bloc.add(AdvanceOnboardingEvent());
        await pumpEventQueue();
        bloc
          ..add(AdvanceOnboardingEvent())
          ..add(RetreatOnboardingEvent());
        await pumpEventQueue();
        pendingSave.complete();
      },
      expect: () => [
        inProgress(step: OnboardingStep.welcome, isSaving: true),
        inProgress(step: OnboardingStep.profileConfig),
      ],
      verify: (_) => verify(() => changeStep.execute(any(), any())).called(1),
    );
  });

  group('SubmitProfileStepEvent', () {
    SubmitProfileStepEvent event() =>
        SubmitProfileStepEvent(name: 'Maria Lima', phone: '19988887777');

    late ProfileEntity sentProfile;

    blocTest<OnboardingBloc, OnboardingState>(
      'saves the profile before advancing and keeps the saved profile',
      setUp: () {
        when(() => updateProfile.execute(any())).thenAnswer((invocation) async {
          sentProfile = invocation.positionalArguments.single as ProfileEntity;
          return sentProfile;
        });
        when(() => changeStep.execute(any(), any())).thenAnswer((_) async {});
        when(() => getOnboarding.execute()).thenAnswer(
          (_) async => buildOnboarding(step: OnboardingStep.addressConfig),
        );
      },
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.profileConfig),
      act: (bloc) => bloc.add(event()),
      expect: () => [
        inProgress(step: OnboardingStep.profileConfig, isSaving: true),
        inProgress(step: OnboardingStep.addressConfig).having(
          (s) => s.onboardingDraft.profile.name,
          'profile name',
          'Maria Lima',
        ),
      ],
      verify: (_) {
        expect(sentProfile.name, 'Maria Lima');
        expect(sentProfile.phone, '19988887777');
        expect(sentProfile.email, buildProfile().email);
        verifyInOrder([
          () => updateProfile.execute(any()),
          () => changeStep.execute(
            OnboardingStep.profileConfig,
            OnboardingAction.advance,
          ),
        ]);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'stays on the step and does not advance when saving the profile fails',
      setUp: () => when(
        () => updateProfile.execute(any()),
      ).thenThrow(buildDioException(statusCode: 400)),
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.profileConfig),
      act: (bloc) => bloc.add(event()),
      expect: () => [
        inProgress(step: OnboardingStep.profileConfig, isSaving: true),
        inProgress(
          step: OnboardingStep.profileConfig,
          failure: isA<InvalidInputFailure>(),
        ),
      ],
      verify: (_) => verifyNever(() => changeStep.execute(any(), any())),
    );
  });

  group('ReloadAddressesEvent', () {
    final address = AddressEntity(
      id: 'a1',
      receiver: 'Maria Souza',
      zipCode: '13010111',
      street: 'Rua A',
      number: '10',
      district: 'Centro',
      city: 'Campinas',
      state: 'SP',
      country: 'BR',
      isDefault: true,
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'replaces the addresses in the draft',
      setUp: () =>
          when(() => getAddresses.execute()).thenAnswer((_) async => [address]),
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.addressConfig),
      act: (bloc) => bloc.add(ReloadAddressesEvent()),
      expect: () => [
        inProgress(
          step: OnboardingStep.addressConfig,
        ).having((s) => s.onboardingDraft.addresses, 'addresses', [address]),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'exposes the failure when the list cannot be loaded',
      setUp: () => when(
        () => getAddresses.execute(),
      ).thenThrow(buildDioException(type: DioExceptionType.connectionError)),
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.addressConfig),
      act: (bloc) => bloc.add(ReloadAddressesEvent()),
      expect: () => [
        inProgress(
          step: OnboardingStep.addressConfig,
          failure: isA<NetworkFailure>(),
        ),
      ],
    );
  });

  group('SubmitPodologicalProfileStepEvent', () {
    const update = PodologicalProfileUpdate(
      footstrikeType: FootstrikeType.pronated,
      painPointIds: ['p1'],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'saves the profile with consent, then advances',
      setUp: () {
        when(() => savePodologicalProfile.execute(any())).thenAnswer(
          (_) async =>
              PodologicalProfileEntity(footstrikeType: FootstrikeType.pronated),
        );
        when(() => changeStep.execute(any(), any())).thenAnswer((_) async {});
        when(() => getOnboarding.execute()).thenAnswer(
          (_) async => buildOnboarding(step: OnboardingStep.completion),
        );
      },
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.podologicalProfile),
      act: (bloc) =>
          bloc.add(SubmitPodologicalProfileStepEvent(update: update)),
      expect: () => [
        inProgress(step: OnboardingStep.podologicalProfile, isSaving: true),
        inProgress(step: OnboardingStep.completion)
            .having(
              (s) => s.onboardingDraft.podologicalProfile.footstrikeType,
              'footstrike',
              FootstrikeType.pronated,
            )
            .having(
              (s) => s.onboardingDraft.hasPodologicalConsent,
              'consent',
              isTrue,
            ),
      ],
      verify: (_) => verifyInOrder([
        () => savePodologicalProfile.execute(update),
        () => changeStep.execute(
          OnboardingStep.podologicalProfile,
          OnboardingAction.advance,
        ),
      ]),
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'stays on the step when the profile is refused',
      setUp: () => when(
        () => savePodologicalProfile.execute(any()),
      ).thenThrow(buildDioException(statusCode: 403)),
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.podologicalProfile),
      act: (bloc) =>
          bloc.add(SubmitPodologicalProfileStepEvent(update: update)),
      expect: () => [
        inProgress(step: OnboardingStep.podologicalProfile, isSaving: true),
        inProgress(
          step: OnboardingStep.podologicalProfile,
          failure: isA<ServerFailure>(),
        ),
      ],
      verify: (_) => verifyNever(() => changeStep.execute(any(), any())),
    );
  });

  group('SkipOnboardingStepEvent', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'sends the skip action without saving anything',
      setUp: () {
        when(() => changeStep.execute(any(), any())).thenAnswer((_) async {});
        when(() => getOnboarding.execute()).thenAnswer(
          (_) async => buildOnboarding(step: OnboardingStep.completion),
        );
      },
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.podologicalProfile),
      act: (bloc) => bloc.add(SkipOnboardingStepEvent()),
      expect: () => [
        inProgress(step: OnboardingStep.podologicalProfile, isSaving: true),
        inProgress(step: OnboardingStep.completion),
      ],
      verify: (_) {
        verify(
          () => changeStep.execute(
            OnboardingStep.podologicalProfile,
            OnboardingAction.skip,
          ),
        ).called(1);
        verifyNever(() => savePodologicalProfile.execute(any()));
      },
    );
  });

  group('RetreatOnboardingEvent', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'sends the retreat action for the current step',
      setUp: () {
        when(() => changeStep.execute(any(), any())).thenAnswer((_) async {});
        when(() => getOnboarding.execute()).thenAnswer(
          (_) async => buildOnboarding(step: OnboardingStep.welcome),
        );
      },
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.profileConfig),
      act: (bloc) => bloc.add(RetreatOnboardingEvent()),
      expect: () => [
        inProgress(step: OnboardingStep.profileConfig, isSaving: true),
        inProgress(step: OnboardingStep.welcome),
      ],
      verify: (_) => verify(
        () => changeStep.execute(
          OnboardingStep.profileConfig,
          OnboardingAction.retreat,
        ),
      ).called(1),
    );
  });

  group('CompleteOnboardingEvent', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'finishes only after the server accepts completion',
      setUp: () =>
          when(() => changeStep.execute(any(), any())).thenAnswer((_) async {}),
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.completion),
      act: (bloc) => bloc.add(CompleteOnboardingEvent()),
      expect: () => [
        inProgress(step: OnboardingStep.completion, isSaving: true),
        isA<OnboardingFinished>(),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'stays in progress with a failure when completion is rejected',
      setUp: () => when(
        () => changeStep.execute(any(), any()),
      ).thenAnswer((_) => Future.error(buildDioException(statusCode: 500))),
      build: buildBloc,
      seed: () => inProgressAt(OnboardingStep.completion),
      act: (bloc) => bloc.add(CompleteOnboardingEvent()),
      expect: () => [
        inProgress(step: OnboardingStep.completion, isSaving: true),
        inProgress(
          step: OnboardingStep.completion,
          failure: isA<ServerFailure>(),
        ),
      ],
    );
  });
}

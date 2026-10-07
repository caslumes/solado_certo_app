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
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockGetProfileUseCase getProfile;
  late MockGetAddressesUseCase getAddresses;
  late MockGetPodologicalProfileUseCase getPodologicalProfile;
  late MockGetOnboardingUseCase getOnboarding;
  late MockChangeOnboardingStepUseCase changeStep;

  OnboardingBloc buildBloc() => OnboardingBloc(
    getProfileUseCase: getProfile,
    getAddressesUseCase: getAddresses,
    getPodologicalProfileUseCase: getPodologicalProfile,
    getOnboardingUseCase: getOnboarding,
    changeOnboardingStepUseCase: changeStep,
  );

  OnboardingInProgress inProgressAt(OnboardingStep step) =>
      OnboardingInProgress(onboardingDraft: buildDraft(step: step));

  Matcher inProgress({
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
  });

  setUp(() {
    getProfile = MockGetProfileUseCase();
    getAddresses = MockGetAddressesUseCase();
    getPodologicalProfile = MockGetPodologicalProfileUseCase();
    getOnboarding = MockGetOnboardingUseCase();
    changeStep = MockChangeOnboardingStepUseCase();

    when(() => getProfile.execute()).thenAnswer((_) async => buildProfile());
    when(() => getAddresses.execute()).thenAnswer((_) async => []);
    when(
      () => getPodologicalProfile.execute(),
    ).thenAnswer((_) async => PodologicalProfileEntity());
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
        inProgress(step: OnboardingStep.addressConfig),
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

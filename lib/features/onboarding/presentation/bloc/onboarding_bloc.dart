import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final GetAddressesUseCase _getAddressesUseCase;
  final GetPodologicalProfileUseCase _getPodologicalProfileUseCase;
  final SavePodologicalProfileUseCase _savePodologicalProfileUseCase;
  final GetPainPointsUseCase _getPainPointsUseCase;
  final HasPodologicalConsentUseCase _hasPodologicalConsentUseCase;
  final GetOnboardingUseCase _getOnboardingUseCase;
  final ChangeOnboardingStepUseCase _changeOnboardingStepUseCase;

  OnboardingBloc({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required GetAddressesUseCase getAddressesUseCase,
    required GetPodologicalProfileUseCase getPodologicalProfileUseCase,
    required SavePodologicalProfileUseCase savePodologicalProfileUseCase,
    required GetPainPointsUseCase getPainPointsUseCase,
    required HasPodologicalConsentUseCase hasPodologicalConsentUseCase,
    required GetOnboardingUseCase getOnboardingUseCase,
    required ChangeOnboardingStepUseCase changeOnboardingStepUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _getAddressesUseCase = getAddressesUseCase,
       _getPodologicalProfileUseCase = getPodologicalProfileUseCase,
       _savePodologicalProfileUseCase = savePodologicalProfileUseCase,
       _getPainPointsUseCase = getPainPointsUseCase,
       _hasPodologicalConsentUseCase = hasPodologicalConsentUseCase,
       _getOnboardingUseCase = getOnboardingUseCase,
       _changeOnboardingStepUseCase = changeOnboardingStepUseCase,
       super(OnboardingLoading()) {
    on<StartOnboardingEvent>(_onOnboardingStarted);
    on<CompleteOnboardingEvent>(_onOnboardingCompleted);
    on<AdvanceOnboardingEvent>(_onOnboardingAdvanced);
    on<RetreatOnboardingEvent>(_onOnboardingRetreated);
    on<SkipOnboardingStepEvent>(_onOnboardingStepSkipped);
    on<SubmitPodologicalProfileStepEvent>(_onPodologicalProfileStepSubmitted);
    on<SubmitProfileStepEvent>(_onProfileStepSubmitted);
    on<ReloadAddressesEvent>(_onAddressesReloaded);
  }

  Future<OnboardingDraft> fetchOnboardingDraft() async {
    final onboarding = await _getOnboardingUseCase.execute();
    final profile = await _getProfileUseCase.execute();
    final addresses = await _getAddressesUseCase.execute();
    final podologicalProfile = await _getPodologicalProfileUseCase.execute();
    final painPoints = await _getPainPointsUseCase.execute();
    final hasPodologicalConsent = await _hasPodologicalConsentUseCase.execute();
    return OnboardingDraft(
      onboarding: onboarding,
      profile: profile,
      addresses: addresses,
      podologicalProfile: podologicalProfile,
      painPoints: painPoints,
      hasPodologicalConsent: hasPodologicalConsent,
    );
  }

  Future<void> _onOnboardingStarted(
    StartOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final onboardingDraft = await fetchOnboardingDraft();
      if (onboardingDraft.onboarding.status == OnboardingStatus.completed) {
        emit(OnboardingFinished());
        return;
      }
      emit(OnboardingInProgress(onboardingDraft: onboardingDraft));
    } catch (e) {
      emit(OnboardingLoadFailure(failure: Failure.from(e)));
    }
  }

  Future<void> _onOnboardingAdvanced(
    AdvanceOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) => _changeStep(OnboardingAction.advance, emit);

  Future<void> _onOnboardingRetreated(
    RetreatOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) => _changeStep(OnboardingAction.retreat, emit);

  Future<void> _onOnboardingStepSkipped(
    SkipOnboardingStepEvent event,
    Emitter<OnboardingState> emit,
  ) => _changeStep(OnboardingAction.skip, emit);

  Future<void> _onPodologicalProfileStepSubmitted(
    SubmitPodologicalProfileStepEvent event,
    Emitter<OnboardingState> emit,
  ) => _changeStep(
    OnboardingAction.advance,
    emit,
    saveStep: (draft) async {
      final podologicalProfile = await _savePodologicalProfileUseCase.execute(
        event.update,
      );
      return draft.copyWith(
        podologicalProfile: podologicalProfile,
        hasPodologicalConsent: true,
      );
    },
  );

  Future<void> _onProfileStepSubmitted(
    SubmitProfileStepEvent event,
    Emitter<OnboardingState> emit,
  ) => _changeStep(
    OnboardingAction.advance,
    emit,
    saveStep: (draft) async {
      final profile = await _updateProfileUseCase.execute(
        draft.profile.copyWith(name: event.name, phone: event.phone),
      );
      return draft.copyWith(profile: profile);
    },
  );

  Future<void> _onAddressesReloaded(
    ReloadAddressesEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is! OnboardingInProgress) return;
    try {
      final addresses = await _getAddressesUseCase.execute();
      final currentState = state;
      if (currentState is! OnboardingInProgress) return;
      emit(
        OnboardingInProgress(
          onboardingDraft: currentState.onboardingDraft.copyWith(
            addresses: addresses,
          ),
          isSaving: currentState.isSaving,
        ),
      );
    } catch (e) {
      final currentState = state;
      if (currentState is! OnboardingInProgress) return;
      emit(
        OnboardingInProgress(
          onboardingDraft: currentState.onboardingDraft,
          failure: Failure.from(e),
        ),
      );
    }
  }

  Future<void> _changeStep(
    OnboardingAction action,
    Emitter<OnboardingState> emit, {
    Future<OnboardingDraft> Function(OnboardingDraft draft)? saveStep,
  }) async {
    final currentState = state;
    if (currentState is! OnboardingInProgress || currentState.isSaving) return;

    var draft = currentState.onboardingDraft;
    emit(OnboardingInProgress(onboardingDraft: draft, isSaving: true));
    try {
      if (saveStep != null) draft = await saveStep(draft);
      await _changeOnboardingStepUseCase.execute(
        draft.onboarding.currentStep,
        action,
      );
      final updatedOnboarding = await _getOnboardingUseCase.execute();
      emit(
        OnboardingInProgress(
          onboardingDraft: draft.copyWith(onboarding: updatedOnboarding),
        ),
      );
    } catch (e) {
      emit(
        OnboardingInProgress(onboardingDraft: draft, failure: Failure.from(e)),
      );
    }
  }

  Future<void> _onOnboardingCompleted(
    CompleteOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OnboardingInProgress || currentState.isSaving) return;

    final draft = currentState.onboardingDraft;
    emit(OnboardingInProgress(onboardingDraft: draft, isSaving: true));
    try {
      await _changeOnboardingStepUseCase.execute(
        draft.onboarding.currentStep,
        OnboardingAction.complete,
      );
      emit(OnboardingFinished());
    } catch (e) {
      emit(
        OnboardingInProgress(onboardingDraft: draft, failure: Failure.from(e)),
      );
    }
  }
}

class OnboardingEvent {}

class StartOnboardingEvent extends OnboardingEvent {}

class AdvanceOnboardingEvent extends OnboardingEvent {}

class RetreatOnboardingEvent extends OnboardingEvent {}

class CompleteOnboardingEvent extends OnboardingEvent {}

class SubmitProfileStepEvent extends OnboardingEvent {
  final String name;
  final String phone;

  SubmitProfileStepEvent({required this.name, required this.phone});
}

class ReloadAddressesEvent extends OnboardingEvent {}

class SkipOnboardingStepEvent extends OnboardingEvent {}

class SubmitPodologicalProfileStepEvent extends OnboardingEvent {
  final PodologicalProfileUpdate update;

  SubmitPodologicalProfileStepEvent({required this.update});
}

class OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingLoadFailure extends OnboardingState {
  final Failure failure;

  OnboardingLoadFailure({required this.failure});
}

class OnboardingInProgress extends OnboardingState {
  final OnboardingDraft onboardingDraft;
  final bool isSaving;
  final Failure? failure;

  OnboardingInProgress({
    required this.onboardingDraft,
    this.isSaving = false,
    this.failure,
  });
}

class OnboardingFinished extends OnboardingState {}

class OnboardingDraft {
  final OnboardingEntity onboarding;
  final ProfileEntity profile;
  final List<AddressEntity> addresses;
  final PodologicalProfileEntity podologicalProfile;
  final List<PainPointEntity> painPoints;
  final bool hasPodologicalConsent;

  const OnboardingDraft({
    required this.onboarding,
    required this.profile,
    required this.addresses,
    required this.podologicalProfile,
    this.painPoints = const [],
    this.hasPodologicalConsent = false,
  });

  OnboardingDraft copyWith({
    OnboardingEntity? onboarding,
    ProfileEntity? profile,
    List<AddressEntity>? addresses,
    PodologicalProfileEntity? podologicalProfile,
    bool? hasPodologicalConsent,
  }) => OnboardingDraft(
    onboarding: onboarding ?? this.onboarding,
    profile: profile ?? this.profile,
    addresses: addresses ?? this.addresses,
    podologicalProfile: podologicalProfile ?? this.podologicalProfile,
    painPoints: painPoints,
    hasPodologicalConsent: hasPodologicalConsent ?? this.hasPodologicalConsent,
  );
}

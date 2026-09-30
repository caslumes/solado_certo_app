import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetProfileUseCase _getProfileUseCase;
  final GetAddressesUseCase _getAddressesUseCase;
  final GetPodologicalProfileUseCase _getPodologicalProfileUseCase;
  final GetOnboardingUseCase _getOnboardingUseCase;
  final ChangeOnboardingStepUseCase _changeOnboardingStepUseCase;

  OnboardingBloc({
    required GetProfileUseCase getProfileUseCase,
    required GetAddressesUseCase getAddressesUseCase,
    required GetPodologicalProfileUseCase getPodologicalProfileUseCase,
    required GetOnboardingUseCase getOnboardingUseCase,
    required ChangeOnboardingStepUseCase changeOnboardingStepUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _getAddressesUseCase = getAddressesUseCase,
       _getPodologicalProfileUseCase = getPodologicalProfileUseCase,
       _getOnboardingUseCase = getOnboardingUseCase,
       _changeOnboardingStepUseCase = changeOnboardingStepUseCase,
       super(OnboardingInitial()) {
    on<StartOnboardingEvent>(_onOnboardingStarted);
    on<CompleteOnboardingEvent>(_onOnboardingCompleted);
    on<AdvanceOnboardingEvent>(_onOnboardingAdvanced);
    on<RetreatOnboardingEvent>(_onOnboardingRetreated);
  }

  Future<OnboardingDraft> fetchOnboardingDraft() async {
    final onboarding = await _getOnboardingUseCase.execute();
    final profile = await _getProfileUseCase.execute();
    final addresses = await _getAddressesUseCase.execute();
    final podologicalProfile = await _getPodologicalProfileUseCase.execute();
    return OnboardingDraft()
      ..onboarding = onboarding
      ..profile = profile
      ..addresses = addresses
      ..podologicalProfile = podologicalProfile;
  }

  void _onOnboardingStarted(
    StartOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final onboardingDraft = await fetchOnboardingDraft();
    if (onboardingDraft.onboarding!.status == OnboardingStatus.completed) {
      emit(OnboardingFinished());
      return;
    }
    emit(OnboardingInProgress(onboardingDraft: onboardingDraft));
  }

  void _onOnboardingAdvanced(
    AdvanceOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      final currentStep = currentState.onboardingDraft!.onboarding!.currentStep;
      await _changeOnboardingStepUseCase.execute(
        currentStep,
        OnboardingAction.advance,
      );
      final updatedOnboarding = await _getOnboardingUseCase.execute();
      emit(
        OnboardingInProgress(
          onboardingDraft: currentState.onboardingDraft!
            ..onboarding = updatedOnboarding,
        ),
      );
    }
  }

  void _onOnboardingRetreated(
    RetreatOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      final currentStep = currentState.onboardingDraft!.onboarding!.currentStep;
      await _changeOnboardingStepUseCase.execute(
        currentStep,
        OnboardingAction.retreat,
      );
      final updatedOnboardingEntity = await _getOnboardingUseCase.execute();
      emit(
        OnboardingInProgress(
          onboardingDraft: currentState.onboardingDraft!
            ..onboarding = updatedOnboardingEntity,
        ),
      );
    }
  }

  void _onOnboardingCompleted(
    CompleteOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      final currentStep = currentState.onboardingDraft!.onboarding!.currentStep;
      _changeOnboardingStepUseCase.execute(
        currentStep,
        OnboardingAction.complete,
      );
      emit(OnboardingFinished());
    }
  }
}

class OnboardingEvent {}

class StartOnboardingEvent extends OnboardingEvent {}

class AdvanceOnboardingEvent extends OnboardingEvent {}

class RetreatOnboardingEvent extends OnboardingEvent {}

class CompleteOnboardingEvent extends OnboardingEvent {}

class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingInProgress extends OnboardingState {
  final OnboardingDraft? onboardingDraft;

  OnboardingInProgress({this.onboardingDraft});
}

class OnboardingFinished extends OnboardingState {}

class OnboardingDraft {
  OnboardingEntity? onboarding;
  ProfileEntity? profile;
  List<AddressEntity>? addresses;
  PodologicalProfileEntity? podologicalProfile;
}

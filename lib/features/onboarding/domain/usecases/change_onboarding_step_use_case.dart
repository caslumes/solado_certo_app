import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class ChangeOnboardingStepUseCase {
  final OnboardingRepository _onboardingRepository;

  ChangeOnboardingStepUseCase(this._onboardingRepository);

  Future<void> execute(
    OnboardingStep currentStep,
    OnboardingAction action,
  ) async {
    switch (action) {
      case OnboardingAction.advance:
        await _onboardingRepository.changeOnboardingStep(
          currentStep,
          OnboardingAction.advance,
        );
        break;
      case OnboardingAction.retreat:
        await _onboardingRepository.changeOnboardingStep(
          currentStep,
          OnboardingAction.retreat,
        );
        break;
      case OnboardingAction.skip:
        await _onboardingRepository.changeOnboardingStep(
          currentStep,
          OnboardingAction.skip,
        );
        break;
      case OnboardingAction.dismiss:
        await _onboardingRepository.changeOnboardingStep(
          currentStep,
          OnboardingAction.dismiss,
        );
        break;
      case OnboardingAction.complete:
        await _onboardingRepository.changeOnboardingStep(
          currentStep,
          OnboardingAction.complete,
        );
        break;
    }
  }
}

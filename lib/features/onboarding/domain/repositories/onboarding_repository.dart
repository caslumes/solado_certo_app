import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';

abstract class OnboardingRepository {
  Future<OnboardingEntity> getOnboarding();
  Future<void> changeOnboardingStep(
    OnboardingStep currentStep,
    OnboardingAction action,
  );
}

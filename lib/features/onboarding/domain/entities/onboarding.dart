import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';

class OnboardingEntity {
  final OnboardingStep currentStep;
  final OnboardingStatus status;

  OnboardingEntity({required this.currentStep, required this.status});
}

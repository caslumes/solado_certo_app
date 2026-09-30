import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';

class OnboardingEntity {
  final OnboardingStep currentStep;
  final OnboardingStatus status;

  OnboardingEntity({required this.currentStep, required this.status});

  factory OnboardingEntity.fromJson(Map<String, dynamic> json) {
    return OnboardingEntity(
      currentStep: onboardingStepFromString(json['current_step']),
      status: onboardingStatusFromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_step': currentStep.toString().split('.').last,
      'status': status.toString().split('.').last,
    };
  }
}

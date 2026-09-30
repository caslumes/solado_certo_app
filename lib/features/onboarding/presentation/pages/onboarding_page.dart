import 'package:flutter/widgets.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/presentation/components/onboarding_address.dart';
import 'package:solado_certo_app/features/onboarding/presentation/components/onboarding_finish.dart';
import 'package:solado_certo_app/features/onboarding/presentation/components/onboarding_podological_profile.dart';
import 'package:solado_certo_app/features/onboarding/presentation/components/onboarding_profile.dart';
import 'package:solado_certo_app/features/onboarding/presentation/components/onboarding_welcome.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.currentStep});

  final OnboardingStep currentStep;

  @override
  Widget build(BuildContext context) {
    return switch (currentStep) {
      OnboardingStep.welcome => const OnboardingWelcome(),
      OnboardingStep.profileConfig => const OnboardingProfile(),
      OnboardingStep.addressConfig => const OnboardingAddress(),
      OnboardingStep.podologicalProfile => const OnboardingPodologicalProfile(),
      OnboardingStep.completion => const OnboardingFinish(),
    };
  }
}

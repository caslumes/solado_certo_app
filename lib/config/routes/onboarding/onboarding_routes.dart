import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/onboarding/presentation/pages/onboarding_gate.dart';

class OnboardingRoutes {
  static const String onboarding = '/onboarding';

  static Map<String, WidgetBuilder> get routes => {
    onboarding: (context) => const OnboardingGate(),
  };
}

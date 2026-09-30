enum OnboardingStep {
  welcome,
  profileConfig,
  addressConfig,
  podologicalProfile,
  completion,
}

OnboardingStep onboardingStepFromString(String step) {
  switch (step) {
    case 'bem_vindo':
      return OnboardingStep.welcome;
    case 'configuracao_perfil':
      return OnboardingStep.profileConfig;
    case 'configuracao_endereco':
      return OnboardingStep.addressConfig;
    case 'perfil_podologico':
      return OnboardingStep.podologicalProfile;
    case 'finalizacao':
      return OnboardingStep.completion;
    default:
      throw Exception('Invalid onboarding step string: $step');
  }
}

String onboardingStepToString(OnboardingStep step) {
  switch (step) {
    case OnboardingStep.welcome:
      return 'bem_vindo';
    case OnboardingStep.profileConfig:
      return 'configuracao_perfil';
    case OnboardingStep.addressConfig:
      return 'configuracao_endereco';
    case OnboardingStep.podologicalProfile:
      return 'perfil_podologico';
    case OnboardingStep.completion:
      return 'finalizacao';
  }
}

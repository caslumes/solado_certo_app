enum OnboardingStatus {
  notStarted,
  inProgress,
  completed,
  dismissed,
}

OnboardingStatus onboardingStatusFromString(String status) {
  switch (status) {
    case 'nao_iniciado':
      return OnboardingStatus.notStarted;
    case 'em_andamento':
      return OnboardingStatus.inProgress;
    case 'concluido':
      return OnboardingStatus.completed;
    case 'dispensado':
      return OnboardingStatus.dismissed;
    default:
      throw ArgumentError('Invalid onboarding status: $status');
  }
}

String onboardingStatusToString(OnboardingStatus status) {
  switch (status) {
    case OnboardingStatus.notStarted:
      return 'nao_iniciado';
    case OnboardingStatus.inProgress:
      return 'em_andamento';
    case OnboardingStatus.completed:
      return 'concluido';
    case OnboardingStatus.dismissed:
      return 'dispensado';
  }
}
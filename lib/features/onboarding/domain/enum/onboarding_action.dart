enum OnboardingAction { advance, retreat, skip, dismiss, complete }

OnboardingAction onboardingActionFromString(String action) {
  switch (action) {
    case 'advance':
      return OnboardingAction.advance;
    case 'retreat':
      return OnboardingAction.retreat;
    case 'skip':
      return OnboardingAction.skip;
    case 'dismiss':
      return OnboardingAction.dismiss;
    case 'complete':
      return OnboardingAction.complete;
    default:
      throw ArgumentError('Invalid onboarding action: $action');
  }
}

String onboardingActionToString(OnboardingAction action) {
  return action.toString().split('.').last;
}

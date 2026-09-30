import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingUseCase {
  final OnboardingRepository _onboardingRepository;

  GetOnboardingUseCase(this._onboardingRepository);

  Future<OnboardingEntity> execute() async {
    return await _onboardingRepository.getOnboarding();
  }
}
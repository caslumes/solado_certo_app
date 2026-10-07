import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/onboarding/data/models/onboarding_model.dart';
import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class ApiOnboardingRepository implements OnboardingRepository {
  final ClientInterface _client;

  ApiOnboardingRepository(this._client);

  @override
  Future<void> changeOnboardingStep(
    OnboardingStep currentStep,
    OnboardingAction action,
  ) async {
    await _client.put(
      '/me/onboarding',
      data: {
        'step': onboardingStepToApi(currentStep),
        'action': onboardingActionToApi(action),
      },
    );
  }

  @override
  Future<OnboardingEntity> getOnboarding() async {
    final response = await _client.get('/me/onboarding');
    return OnboardingModel.fromJson(response).toEntity();
  }
}

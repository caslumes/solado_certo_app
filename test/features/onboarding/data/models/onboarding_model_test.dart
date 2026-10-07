import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/onboarding/data/models/onboarding_model.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';

void main() {
  test('maps API step and status values to domain enums', () {
    final entity = OnboardingModel.fromJson({
      'current_step': 'configuracao_endereco',
      'status': 'em_andamento',
    }).toEntity();

    expect(entity.currentStep, OnboardingStep.addressConfig);
    expect(entity.status, OnboardingStatus.inProgress);
  });

  test('round-trips every step through its API value', () {
    for (final step in OnboardingStep.values) {
      final model = OnboardingModel.fromJson({
        'current_step': onboardingStepToApi(step),
        'status': 'nao_iniciado',
      });
      expect(model.currentStep, step);
    }
  });

  test('sends actions with the names the backend expects', () {
    expect(onboardingActionToApi(OnboardingAction.advance), 'advance');
    expect(onboardingActionToApi(OnboardingAction.complete), 'complete');
  });

  test('rejects unknown API values', () {
    expect(
      () => OnboardingModel.fromJson({
        'current_step': 'unknown',
        'status': 'em_andamento',
      }),
      throwsFormatException,
    );
    expect(
      () => OnboardingModel.fromJson({
        'current_step': 'bem_vindo',
        'status': 'unknown',
      }),
      throwsFormatException,
    );
  });

  test('rejects a missing step', () {
    expect(
      () => OnboardingModel.fromJson({'status': 'em_andamento'}),
      throwsA(isA<TypeError>()),
    );
  });
}

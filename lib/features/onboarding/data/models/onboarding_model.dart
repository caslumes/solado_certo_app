import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_action.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';

const _stepValues = {
  OnboardingStep.welcome: 'bem_vindo',
  OnboardingStep.profileConfig: 'configuracao_perfil',
  OnboardingStep.addressConfig: 'configuracao_endereco',
  OnboardingStep.podologicalProfile: 'perfil_podologico',
  OnboardingStep.completion: 'finalizacao',
};

const _statusValues = {
  OnboardingStatus.notStarted: 'nao_iniciado',
  OnboardingStatus.inProgress: 'em_andamento',
  OnboardingStatus.completed: 'concluido',
  OnboardingStatus.dismissed: 'dispensado',
};

String onboardingStepToApi(OnboardingStep step) => _stepValues[step]!;

String onboardingActionToApi(OnboardingAction action) => action.name;

T _fromApi<T>(Map<T, String> values, String value, String field) => values
    .entries
    .firstWhere(
      (entry) => entry.value == value,
      orElse: () => throw FormatException('Invalid $field: $value'),
    )
    .key;

class OnboardingModel {
  const OnboardingModel({required this.currentStep, required this.status});

  final OnboardingStep currentStep;
  final OnboardingStatus status;

  factory OnboardingModel.fromJson(Map<String, dynamic> json) =>
      OnboardingModel(
        currentStep: _fromApi(
          _stepValues,
          json['current_step'] as String,
          'onboarding step',
        ),
        status: _fromApi(
          _statusValues,
          json['status'] as String,
          'onboarding status',
        ),
      );

  OnboardingEntity toEntity() =>
      OnboardingEntity(currentStep: currentStep, status: status);
}

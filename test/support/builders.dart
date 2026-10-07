import 'package:dio/dio.dart';
import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

ProfileEntity buildProfile() => ProfileEntity(
  name: 'Maria Souza',
  email: 'maria@example.com',
  phone: '19999999999',
  avatarUrl: '',
);

OnboardingEntity buildOnboarding({
  OnboardingStep step = OnboardingStep.welcome,
  OnboardingStatus status = OnboardingStatus.inProgress,
}) => OnboardingEntity(currentStep: step, status: status);

OnboardingDraft buildDraft({OnboardingStep step = OnboardingStep.welcome}) =>
    OnboardingDraft(
      onboarding: buildOnboarding(step: step),
      profile: buildProfile(),
      addresses: const [],
      podologicalProfile: PodologicalProfileEntity(),
    );

DioException buildDioException({
  int? statusCode,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode == null
        ? null
        : Response(requestOptions: requestOptions, statusCode: statusCode),
  );
}

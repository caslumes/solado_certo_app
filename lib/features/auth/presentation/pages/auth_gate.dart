import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/pages/onboarding_gate.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:solado_certo_app/features/splash/presentation/pages/splash_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          current is! AuthLoading && current is! AuthSignUpSuccess,
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return BlocProvider<OnboardingBloc>(
            create: (context) => OnboardingBloc(
              getProfileUseCase: getIt<GetProfileUseCase>(),
              updateProfileUseCase: getIt<UpdateProfileUseCase>(),
              getAddressesUseCase: getIt<GetAddressesUseCase>(),
              getPodologicalProfileUseCase:
                  getIt<GetPodologicalProfileUseCase>(),
              savePodologicalProfileUseCase:
                  getIt<SavePodologicalProfileUseCase>(),
              getPainPointsUseCase: getIt<GetPainPointsUseCase>(),
              hasPodologicalConsentUseCase:
                  getIt<HasPodologicalConsentUseCase>(),
              getOnboardingUseCase: getIt<GetOnboardingUseCase>(),
              changeOnboardingStepUseCase: getIt<ChangeOnboardingStepUseCase>(),
            )..add(StartOnboardingEvent()),
            child: const OnboardingGate(),
          );
        }

        if (state is AuthUnauthenticated) {
          return const SignInPage();
        }

        return const SplashPage();
      },
    );
  }
}

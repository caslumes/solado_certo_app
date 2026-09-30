import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/config/dependencies.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/pages/onboarding_gate.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/splash/presentation/pages/splash_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingBloc>(
      create: (context) => OnboardingBloc(
        getProfileUseCase: getIt<GetProfileUseCase>(),
        getAddressesUseCase: getIt<GetAddressesUseCase>(),
        getPodologicalProfileUseCase: getIt<GetPodologicalProfileUseCase>(),
        getOnboardingUseCase: getIt<GetOnboardingUseCase>(),
        changeOnboardingStepUseCase: getIt<ChangeOnboardingStepUseCase>(),
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);
          if (state is AuthAuthenticated) {
            onboardingBloc.add(StartOnboardingEvent());
            return const OnboardingGate();
          }

          if (state is AuthUnauthenticated) {
            return const SignInPage();
          }

          return const SplashPage();
        },
      ),
    );
  }
}

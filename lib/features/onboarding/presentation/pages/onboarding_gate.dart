import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/pages/onboarding_page.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is OnboardingInitial) {
          return CircularProgressIndicator();
        }

        if (state is OnboardingInProgress) {
          return OnboardingPage(
            currentStep: state.onboardingDraft!.onboarding!.currentStep,
          );
        }

        if (state is OnboardingFinished) {
          return const HomePage();
        }

        return const HomePage();
      },
    );
  }
}

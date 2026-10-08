import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/home/presentation/pages/home_page.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/pages/onboarding_page.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (previous, current) => _failureOf(current) != null,
      listener: (context, state) {
        final failure = _failureOf(state)!;
        if (failure is UnauthorizedFailure) {
          context.read<AuthBloc>().add(SignOutEvent());
        }
        if (state is OnboardingInProgress) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      builder: (context, state) {
        if (state is OnboardingLoadFailure) {
          return _OnboardingLoadError(failure: state.failure);
        }

        if (state is OnboardingInProgress) {
          return Stack(
            children: [
              OnboardingPage(
                currentStep: state.onboardingDraft.onboarding.currentStep,
              ),
              if (state.isSaving)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(child: LinearProgressIndicator()),
                ),
            ],
          );
        }

        if (state is OnboardingFinished) {
          return const HomePage(isSignedIn: true);
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  static Failure? _failureOf(OnboardingState state) => switch (state) {
    OnboardingLoadFailure(:final failure) => failure,
    OnboardingInProgress(:final failure) => failure,
    _ => null,
  };
}

class _OnboardingLoadError extends StatelessWidget {
  const _OnboardingLoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16.0,
            children: [
              Text(
                failure.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              ShoeTextButton(
                onPressed: () =>
                    context.read<OnboardingBloc>().add(StartOnboardingEvent()),
                text: 'Tentar novamente',
              ),
              ShoeTextButton(
                onPressed: () => context.read<AuthBloc>().add(SignOutEvent()),
                text: 'Sair',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

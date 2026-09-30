import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/common/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingWelcome extends StatelessWidget {
  const OnboardingWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bem-vindo ao Solado Certo!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'O Solado Certo é um aplicativo que ajuda você a encontrar o calçado ideal para o seu estilo e conforto.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ShoeTextButton(
            onPressed: () => onboardingBloc.add(AdvanceOnboardingEvent()),
            text: "Avançar",
          ),
          ShoeTextButton(
            onPressed: () {
              authBloc.add(SignOutEvent());
            },
            text: "Sair",
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingWelcome extends StatelessWidget {
  const OnboardingWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);
    final headlineStyle = Theme.of(context).textTheme.headlineSmall;
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image(image: AssetImage('assets/images/logo.png')),
                      Text(
                        'Bem-vindo ao\nSolado Certo!',
                        style: headlineStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'O Solado Certo é o aplicativo que ajuda você a encontrar o calçado ideal para o seu estilo e conforto.',
                        textAlign: TextAlign.justify,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              ShoeTextButton(
                onPressed: () {
                  authBloc.add(SignOutEvent());
                },
                text: "Sair".toUpperCase(),
                textStyle: headlineStyle?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ShoeTextButton(
                onPressed: () => onboardingBloc.add(AdvanceOnboardingEvent()),
                text: "Começar cadastro".toUpperCase(),
                textStyle: headlineStyle?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

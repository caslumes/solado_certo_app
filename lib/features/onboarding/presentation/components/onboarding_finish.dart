import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/common/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingFinish extends StatelessWidget {
  const OnboardingFinish({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);
    return Scaffold(
      body: Column(
        children: [
          Text(
            'Cadastro inicial concluído!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          ShoeTextButton(
            onPressed: () {
              onboardingBloc.add(RetreatOnboardingEvent());
            },
            text: "Voltar",
          ),
          ShoeTextButton(
            onPressed: () {
              onboardingBloc.add(CompleteOnboardingEvent());
            },
            text: "Concluir",
          ),
        ],
      ),
    );
  }
}

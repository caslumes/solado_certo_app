import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingFinish extends StatelessWidget {
  const OnboardingFinish({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);
    final buttonTextStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(color: Colors.white);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
            child: Image(
              image: AssetImage('assets/images/logo.png'),
              width: MediaQuery.of(context).size.width * 0.2,
            ),
          ),
          Container(color: AppColors.primaryColor, height: 5),
          SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Cadastro inicial concluído!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              spacing: 16.0,
              children: [
                ShoeTextButton(
                  onPressed: () {
                    onboardingBloc.add(RetreatOnboardingEvent());
                  },
                  text: "Voltar".toUpperCase(),
                  textStyle: buttonTextStyle,
                ),
                ShoeTextButton(
                  onPressed: () {
                    onboardingBloc.add(CompleteOnboardingEvent());
                  },
                  text: "Concluir".toUpperCase(),
                  textStyle: buttonTextStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/profile/presentation/components/podological_profile_form.dart';

class OnboardingPodologicalProfile extends StatelessWidget {
  const OnboardingPodologicalProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) => current is OnboardingInProgress,
      builder: (context, state) {
        final draft = (state as OnboardingInProgress).onboardingDraft;
        final isSaving = state.isSaving;
        final onboardingBloc = context.read<OnboardingBloc>();
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
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16.0,
                        children: [
                          Center(
                            child: Text(
                              'Perfil Podológico'.toUpperCase(),
                              style: textTheme.headlineSmall,
                            ),
                          ),
                          Text(
                            'Etapa opcional. Essas informações ajudam a encontrar '
                            'produtos adequados aos seus pés.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.tertiaryColor,
                            ),
                          ),
                          PodologicalProfileForm(
                            profile: draft.podologicalProfile,
                            painPoints: draft.painPoints,
                            hasConsent: draft.hasPodologicalConsent,
                            isSaving: isSaving,
                            submitText: 'Salvar e avançar'.toUpperCase(),
                            onSubmit: (update) => onboardingBloc.add(
                              SubmitPodologicalProfileStepEvent(update: update),
                            ),
                            leadingActions: [
                              ShoeTextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => onboardingBloc.add(
                                        SkipOnboardingStepEvent(),
                                      ),
                                text: 'Pular esta etapa'.toUpperCase(),
                                textStyle: buttonTextStyle,
                              ),
                              ShoeTextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => onboardingBloc.add(
                                        RetreatOnboardingEvent(),
                                      ),
                                text: 'Voltar'.toUpperCase(),
                                textStyle: buttonTextStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingPodologicalProfile extends StatelessWidget {
  const OnboardingPodologicalProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);

    final footstrikeTypeController = TextEditingController();
    final clinicalConditionController = TextEditingController();
    final obsController = TextEditingController();

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (BuildContext context, state) {
        final podologicalProfile = (state is OnboardingInProgress)
            ? state.onboardingDraft.podologicalProfile
            : null;

        footstrikeTypeController.text =
            podologicalProfile?.footstrikeType ?? '';
        clinicalConditionController.text =
            podologicalProfile?.clinicalCondition ?? '';
        obsController.text = podologicalProfile?.obs ?? '';

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        children: [
                          Text(
                            'Perfil Podológico',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              0.0,
                              16.0,
                              0.0,
                              16.0,
                            ),
                            child: Form(
                              child: Column(
                                children: [
                                  ShoeTextFormField(
                                    controller: footstrikeTypeController
                                      ..text =
                                          podologicalProfile?.footstrikeType ??
                                          '',
                                    labelText: 'Tipo de pisada',
                                  ),
                                  ShoeTextFormField(
                                    controller: clinicalConditionController
                                      ..text =
                                          podologicalProfile
                                              ?.clinicalCondition ??
                                          '',
                                    labelText: 'Condição clínica',
                                  ),
                                  ShoeTextFormField(
                                    controller: obsController
                                      ..text = podologicalProfile?.obs ?? '',
                                    labelText: 'Observações',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ShoeTextButton(
                            onPressed: () {
                              onboardingBloc.add(RetreatOnboardingEvent());
                            },
                            text: "Voltar",
                          ),
                          ShoeTextButton(
                            onPressed: () {
                              onboardingBloc.add(AdvanceOnboardingEvent());
                            },
                            text: "Avançar",
                          ),
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

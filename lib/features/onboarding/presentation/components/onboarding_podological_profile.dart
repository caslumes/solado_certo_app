import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingPodologicalProfile extends StatefulWidget {
  const OnboardingPodologicalProfile({super.key});

  @override
  State<OnboardingPodologicalProfile> createState() =>
      _OnboardingPodologicalProfileState();
}

class _OnboardingPodologicalProfileState
    extends State<OnboardingPodologicalProfile> {
  late final TextEditingController _footstrikeTypeController;
  late final TextEditingController _clinicalConditionController;
  late final TextEditingController _obsController;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    final podologicalProfile = (state is OnboardingInProgress)
        ? state.onboardingDraft.podologicalProfile
        : null;

    _footstrikeTypeController = TextEditingController(
      text: podologicalProfile?.footstrikeType,
    );
    _clinicalConditionController = TextEditingController(
      text: podologicalProfile?.clinicalCondition,
    );
    _obsController = TextEditingController(text: podologicalProfile?.obs);
  }

  @override
  void dispose() {
    _footstrikeTypeController.dispose();
    _clinicalConditionController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);

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
                                controller: _footstrikeTypeController,
                                labelText: 'Tipo de pisada',
                              ),
                              ShoeTextFormField(
                                controller: _clinicalConditionController,
                                labelText: 'Condição clínica',
                              ),
                              ShoeTextFormField(
                                controller: _obsController,
                                labelText: 'Observações',
                                textInputAction: TextInputAction.done,
                                textCapitalization:
                                    TextCapitalization.sentences,
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
  }
}

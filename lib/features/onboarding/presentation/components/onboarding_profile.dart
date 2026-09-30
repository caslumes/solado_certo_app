import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/common/components/form/shoe_text_form_field.dart';
import 'package:solado_certo_app/common/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingProfile extends StatelessWidget {
  const OnboardingProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final profile =
            (state as OnboardingInProgress).onboardingDraft!.profile;

        nameController.text = profile?.name ?? '';
        emailController.text = profile?.email ?? '';
        phoneController.text = profile?.phone ?? '';

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        children: [
                          Text(
                            'Perfil',
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
                                    labelText: 'Nome',
                                    controller: nameController,
                                  ),
                                  ShoeTextFormField(
                                    labelText: 'Email',
                                    controller: emailController,
                                  ),
                                  ShoeTextFormField(
                                    labelText: 'Telefone',
                                    controller: phoneController,
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

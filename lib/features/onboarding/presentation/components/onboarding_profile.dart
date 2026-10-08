import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingProfile extends StatefulWidget {
  const OnboardingProfile({super.key});

  @override
  State<OnboardingProfile> createState() => _OnboardingProfileState();
}

class _OnboardingProfileState extends State<OnboardingProfile> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    final profile = (state is OnboardingInProgress)
        ? state.onboardingDraft.profile
        : null;

    _nameController = TextEditingController(text: profile?.name);
    _emailController = TextEditingController(text: profile?.email);
    _phoneController = TextEditingController(text: profile?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<OnboardingBloc>().add(
      SubmitProfileStepEvent(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);

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
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            spacing: 16.0,
                            children: [
                              ShoeTextFormField(
                                labelText: 'Nome',
                                controller: _nameController,
                                validator: FieldValidators.combine([
                                  FieldValidators.required,
                                  FieldValidators.maxLength(120),
                                ]),
                                textCapitalization: TextCapitalization.words,
                              ),
                              ShoeTextFormField(
                                labelText: 'Email',
                                controller: _emailController,
                                readOnly: true,
                              ),
                              ShoeTextFormField(
                                labelText: 'Telefone',
                                controller: _phoneController,
                                validator: FieldValidators.phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
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
                      BlocBuilder<OnboardingBloc, OnboardingState>(
                        builder: (context, state) => ShoeTextButton(
                          isLoading:
                              state is OnboardingInProgress && state.isSaving,
                          onPressed: _submit,
                          text: "Avançar",
                        ),
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

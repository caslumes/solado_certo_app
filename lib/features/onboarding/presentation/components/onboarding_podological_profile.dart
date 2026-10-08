import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_hypertext.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/podological_consent_terms_page.dart';

class OnboardingPodologicalProfile extends StatefulWidget {
  const OnboardingPodologicalProfile({super.key});

  @override
  State<OnboardingPodologicalProfile> createState() =>
      _OnboardingPodologicalProfileState();
}

class _OnboardingPodologicalProfileState
    extends State<OnboardingPodologicalProfile> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clinicalConditionController;
  late final TextEditingController _obsController;
  FootstrikeType? _footstrikeType;
  late final Set<String> _painPointIds;
  bool _consented = false;
  bool _showFootstrikeError = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    final draft = state is OnboardingInProgress ? state.onboardingDraft : null;
    final podologicalProfile = draft?.podologicalProfile;

    _footstrikeType = podologicalProfile?.footstrikeType;
    _painPointIds = {...?podologicalProfile?.painPoints.map((p) => p.id)};
    _consented = draft?.hasPodologicalConsent ?? false;
    _clinicalConditionController = TextEditingController(
      text: podologicalProfile?.clinicalCondition,
    );
    _obsController = TextEditingController(text: podologicalProfile?.obs);
  }

  @override
  void dispose() {
    _clinicalConditionController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  static String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _submit() {
    final formValid = _formKey.currentState!.validate();
    setState(() => _showFootstrikeError = _footstrikeType == null);
    if (!_consented || !formValid || _footstrikeType == null) return;

    context.read<OnboardingBloc>().add(
      SubmitPodologicalProfileStepEvent(
        update: PodologicalProfileUpdate(
          footstrikeType: _footstrikeType!,
          painPointIds: _painPointIds.toList(),
          clinicalCondition: _optional(_clinicalConditionController),
          obs: _optional(_obsController),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final inProgress = state is OnboardingInProgress ? state : null;
        final painPoints = inProgress?.onboardingDraft.painPoints ?? const [];
        final isSaving = inProgress?.isSaving ?? false;
        final onboardingBloc = context.read<OnboardingBloc>();

        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16.0,
                    children: [
                      Center(
                        child: Text(
                          'Perfil Podológico',
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
                      Text('Tipo de pisada', style: textTheme.bodyMedium),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          for (final type in FootstrikeType.values)
                            ChoiceChip(
                              label: Text(
                                type.label,
                                style: _footstrikeType == type
                                    ? textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                      )
                                    : textTheme.bodySmall,
                              ),
                              selectedColor: AppColors.primaryColor,
                              checkmarkColor: Colors.white,
                              selected: _footstrikeType == type,
                              onSelected: (_) => setState(() {
                                _footstrikeType = type;
                                _showFootstrikeError = false;
                              }),
                            ),
                        ],
                      ),
                      if (_showFootstrikeError)
                        Text(
                          'Selecione o tipo de pisada',
                          style: textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (painPoints.isNotEmpty) ...[
                        Text(
                          'Onde você sente dor? (opcional)',
                          style: textTheme.bodyMedium,
                        ),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            for (final painPoint in painPoints)
                              FilterChip(
                                label: Text(
                                  painPoint.name,
                                  style: _painPointIds.contains(painPoint.id)
                                      ? textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                        )
                                      : textTheme.bodySmall,
                                ),
                                selectedColor: AppColors.primaryColor,
                                checkmarkColor: Colors.white,
                                tooltip: painPoint.description,
                                selected: _painPointIds.contains(painPoint.id),
                                onSelected: (selected) => setState(
                                  () => selected
                                      ? _painPointIds.add(painPoint.id)
                                      : _painPointIds.remove(painPoint.id),
                                ),
                              ),
                          ],
                        ),
                      ],
                      ShoeTextFormField(
                        controller: _clinicalConditionController,
                        labelText: 'Condição clínica (opcional)',
                        hintText: 'Ex.: fascite plantar',
                        validator: FieldValidators.maxLength(120),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      ShoeTextFormField(
                        controller: _obsController,
                        labelText: 'Observações (opcional)',
                        validator: FieldValidators.maxLength(1000),
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      _ConsentBox(
                        value: _consented,
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() => _consented = value),
                      ),
                      ShoeTextButton(
                        isLoading: isSaving,
                        onPressed: _consented ? _submit : null,
                        text: 'Salvar e avançar',
                      ),
                      ShoeTextButton(
                        onPressed: isSaving
                            ? null
                            : () =>
                                  onboardingBloc.add(SkipOnboardingStepEvent()),
                        text: 'Pular esta etapa',
                      ),
                      ShoeTextButton(
                        onPressed: isSaving
                            ? null
                            : () =>
                                  onboardingBloc.add(RetreatOnboardingEvent()),
                        text: 'Voltar',
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConsentBox extends StatelessWidget {
  const _ConsentBox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v!),
            title: Text(
              podologicalConsentText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ShoeHypertext(
              text: 'Ler termos',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PodologicalConsentTermsPage(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

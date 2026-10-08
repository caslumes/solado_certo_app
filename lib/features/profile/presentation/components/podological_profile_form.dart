import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_hypertext.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/podological_consent_terms_page.dart';

class PodologicalProfileForm extends StatefulWidget {
  const PodologicalProfileForm({
    super.key,
    required this.profile,
    required this.painPoints,
    required this.hasConsent,
    required this.isSaving,
    required this.submitText,
    required this.onSubmit,
    this.actions = const [],
  });

  final PodologicalProfileEntity profile;
  final List<PainPointEntity> painPoints;
  final bool hasConsent;
  final bool isSaving;
  final String submitText;
  final ValueChanged<PodologicalProfileUpdate> onSubmit;

  final List<Widget> actions;

  @override
  State<PodologicalProfileForm> createState() => _PodologicalProfileFormState();
}

class _PodologicalProfileFormState extends State<PodologicalProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _clinicalConditionController = TextEditingController(
    text: widget.profile.clinicalCondition,
  );
  late final _obsController = TextEditingController(text: widget.profile.obs);
  late FootstrikeType? _footstrikeType = widget.profile.footstrikeType;
  late final Set<String> _painPointIds = {
    ...widget.profile.painPoints.map((p) => p.id),
  };
  late bool _consented = widget.hasConsent;
  bool _showFootstrikeError = false;

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

    widget.onSubmit(
      PodologicalProfileUpdate(
        footstrikeType: _footstrikeType!,
        painPointIds: _painPointIds.toList(),
        clinicalCondition: _optional(_clinicalConditionController),
        obs: _optional(_obsController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16.0,
        children: [
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
                        ? textTheme.bodySmall?.copyWith(color: Colors.white)
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
          if (widget.painPoints.isNotEmpty) ...[
            Text(
              'Onde você sente dor? (opcional)',
              style: textTheme.bodyMedium,
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final painPoint in widget.painPoints)
                  FilterChip(
                    label: Text(
                      painPoint.name,
                      style: _painPointIds.contains(painPoint.id)
                          ? textTheme.bodySmall?.copyWith(color: Colors.white)
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
            onChanged: widget.isSaving
                ? null
                : (value) => setState(() => _consented = value),
          ),
          ShoeTextButton(
            isLoading: widget.isSaving,
            onPressed: _consented ? _submit : null,
            text: widget.submitText,
          ),
          ...widget.actions,
        ],
      ),
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

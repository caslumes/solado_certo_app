import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    required this.onSubmit,
    this.initialReceiver,
    this.initialIsDefault = false,
  });

  final Future<void> Function(NewAddress address) onSubmit;
  final String? initialReceiver;
  final bool initialIsDefault;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  late final _receiverController = TextEditingController(
    text: widget.initialReceiver,
  );
  final _zipCodeController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  late bool _isDefault = widget.initialIsDefault;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [
      _labelController,
      _receiverController,
      _zipCodeController,
      _streetController,
      _numberController,
      _complementController,
      _districtController,
      _cityController,
      _stateController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final address = NewAddress(
      label: _optional(_labelController),
      receiver: _receiverController.text.trim(),
      zipCode: FieldValidators.zipCodeDigits(_zipCodeController.text.trim()),
      street: _streetController.text.trim(),
      number: _numberController.text.trim(),
      complement: _optional(_complementController),
      district: _districtController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().toUpperCase(),
      isDefault: _isDefault,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(address);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Novo endereço',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                spacing: 16.0,
                children: [
                  const SizedBox.shrink(),
                  ShoeTextFormField(
                    labelText: 'Identificação (opcional)',
                    hintText: 'Casa, Trabalho',
                    controller: _labelController,
                    validator: FieldValidators.maxLength(80),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  ShoeTextFormField(
                    labelText: 'Destinatário',
                    controller: _receiverController,
                    validator: FieldValidators.combine([
                      FieldValidators.required,
                      FieldValidators.maxLength(120),
                    ]),
                    textCapitalization: TextCapitalization.words,
                  ),
                  ShoeTextFormField(
                    labelText: 'CEP',
                    hintText: '13010-111',
                    controller: _zipCodeController,
                    validator: FieldValidators.zipCode,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.postalCode],
                  ),
                  ShoeTextFormField(
                    labelText: 'Rua',
                    controller: _streetController,
                    validator: FieldValidators.combine([
                      FieldValidators.required,
                      FieldValidators.maxLength(180),
                    ]),
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.streetAddressLine1],
                  ),
                  ShoeTextFormField(
                    labelText: 'Número',
                    controller: _numberController,
                    validator: FieldValidators.combine([
                      FieldValidators.required,
                      FieldValidators.maxLength(20),
                    ]),
                  ),
                  ShoeTextFormField(
                    labelText: 'Complemento (opcional)',
                    controller: _complementController,
                    validator: FieldValidators.maxLength(80),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  ShoeTextFormField(
                    labelText: 'Bairro',
                    controller: _districtController,
                    validator: FieldValidators.combine([
                      FieldValidators.required,
                      FieldValidators.maxLength(80),
                    ]),
                    textCapitalization: TextCapitalization.words,
                  ),
                  ShoeTextFormField(
                    labelText: 'Cidade',
                    controller: _cityController,
                    validator: FieldValidators.combine([
                      FieldValidators.required,
                      FieldValidators.maxLength(80),
                    ]),
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.addressCity],
                  ),
                  ShoeTextFormField(
                    labelText: 'UF',
                    hintText: 'SP',
                    controller: _stateController,
                    validator: FieldValidators.state,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.addressState],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'Endereço principal',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: _isDefault,
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isDefault = value!),
                  ),
                  ShoeTextButton(
                    isLoading: _isSaving,
                    onPressed: _submit,
                    text: 'Salvar endereço',
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

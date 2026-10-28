import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/measurements_fields.dart';

class CustomOrderComplementPage extends StatefulWidget {
  const CustomOrderComplementPage({
    super.key,
    required this.detail,
    this.question,
    required this.submit,
  });

  final CustomOrderDetailEntity detail;
  final String? question;
  final Future<Failure?> Function(CustomOrderComplement complement) submit;

  @override
  State<CustomOrderComplementPage> createState() =>
      _CustomOrderComplementPageState();
}

class _CustomOrderComplementPageState extends State<CustomOrderComplementPage> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  late final _measurements = MeasurementsController(widget.detail.measurements);
  late final _notes = TextEditingController(
    text: widget.detail.technicalNotes ?? '',
  );
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    _measurements.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final measurements = _measurements.read();
    final notes = _notes.text.trim();
    setState(() => _sending = true);
    final failure = await widget.submit(
      CustomOrderComplement(
        message: _message.text.trim(),
        measurements: measurements == widget.detail.measurements
            ? null
            : measurements,
        technicalNotes:
            notes.isEmpty || notes == (widget.detail.technicalNotes ?? '')
            ? null
            : notes,
      ),
    );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text('Responder'.toUpperCase(), style: textTheme.bodyMedium),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.question case final question?) ...[
              Text('O vendedor perguntou', style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(question, style: textTheme.bodyLarge),
              const SizedBox(height: 16),
            ],
            ShoeTextFormField(
              labelText: 'Sua resposta',
              controller: _message,
              readOnly: _sending,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              validator: FieldValidators.combine([
                FieldValidators.required,
                FieldValidators.maxLength(
                  CustomOrderComplement.maxMessageLength,
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Corrija as medidas se precisar', style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Só as medidas e observações alteradas são enviadas.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            MeasurementsFields(controller: _measurements, enabled: !_sending),
            const SizedBox(height: 16),
            ShoeTextFormField(
              labelText: 'Observações técnicas',
              controller: _notes,
              readOnly: _sending,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              validator: FieldValidators.maxLength(
                NewCustomOrder.maxNotesLength,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ShoeTextButton(
            onPressed: _sending ? null : _submit,
            isLoading: _sending,
            text: 'Enviar resposta',
          ),
        ),
      ),
    );
  }
}

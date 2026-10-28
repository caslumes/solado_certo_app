import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/orders/presentation/components/prescription_source_sheet.dart';

Future<UploadFile?> pickFittingReport(BuildContext context) => pickDocumentFile(
  context,
  title: 'Enviar laudo',
  hint: 'PDF, JPEG ou PNG de até 5 MB, com o laudo de fabricação ou ajuste.',
);

class FittingReportPage extends StatefulWidget {
  const FittingReportPage({
    super.key,
    required this.submit,
    this.pickFile = pickFittingReport,
  });

  static const maxInstructionsLength = 4000;

  final Future<Failure?> Function(UploadFile file, String instructions) submit;
  final Future<UploadFile?> Function(BuildContext context) pickFile;

  @override
  State<FittingReportPage> createState() => _FittingReportPageState();
}

class _FittingReportPageState extends State<FittingReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _instructions = TextEditingController();
  UploadFile? _file;
  bool _missingFile = false;
  bool _sending = false;

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await widget.pickFile(context);
    if (file == null || !mounted) return;
    setState(() {
      _file = file;
      _missingFile = false;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    final file = _file;
    setState(() => _missingFile = file == null);
    if (!valid || file == null) return;
    setState(() => _sending = true);
    final failure = await widget.submit(file, _instructions.text.trim());
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
    final file = _file;

    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text('Laudo'.toUpperCase(), style: textTheme.bodyMedium),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'O comprador recebe o laudo e as instruções antes de começar a '
              'usar o item. O pedido só pode ser enviado depois disso.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text('Laudo de fabricação ou ajuste', style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 12.0,
                  children: [
                    Expanded(
                      child: Text(
                        file?.filename ?? 'Nenhum arquivo escolhido',
                        overflow: TextOverflow.ellipsis,
                        style: _missingFile
                            ? textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              )
                            : textTheme.bodyLarge?.copyWith(
                                color: file == null
                                    ? AppColors.tertiaryColor
                                    : null,
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _sending ? null : _pick,
                      child: Text(file == null ? 'Escolher arquivo' : 'Trocar'),
                    ),
                  ],
                ),
                if (_missingFile)
                  Text(
                    'Escolha o arquivo do laudo.',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ShoeTextFormField(
              labelText: 'Instruções de adaptação gradual',
              hintText:
                  'Ex.: use 1 hora no primeiro dia e aumente 1 hora por dia.',
              controller: _instructions,
              readOnly: _sending,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              validator: FieldValidators.combine([
                FieldValidators.required,
                FieldValidators.maxLength(
                  FittingReportPage.maxInstructionsLength,
                ),
              ]),
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
            text: 'Enviar laudo',
          ),
        ),
      ),
    );
  }
}

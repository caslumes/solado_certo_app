import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';

class ReasonDialog extends StatefulWidget {
  const ReasonDialog({
    super.key,
    required this.title,
    this.message,
    this.label = 'Motivo',
    required this.confirmText,
    this.minLength = 5,
    this.maxLength = 500,
  });

  final String title;
  final String? message;
  final String label;
  final String confirmText;
  final int minLength;
  final int maxLength;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String label = 'Motivo',
    required String confirmText,
    int minLength = 5,
    int maxLength = 500,
  }) => showDialog<String>(
    context: context,
    builder: (_) => ReasonDialog(
      title: title,
      message: message,
      label: label,
      confirmText: confirmText,
      minLength: minLength,
      maxLength: maxLength,
    ),
  );

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = widget.message;

    return AlertDialog(
      title: Text(widget.title, style: textTheme.bodyMedium),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.0,
          children: [
            if (message != null) Text(message, style: textTheme.bodySmall),
            TextFormField(
              key: const ValueKey('reason-field'),
              controller: _controller,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              maxLength: widget.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: widget.label),
              validator: FieldValidators.textLength(
                widget.minLength,
                widget.maxLength,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        TextButton(onPressed: _confirm, child: Text(widget.confirmText)),
      ],
    );
  }
}

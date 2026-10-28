import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';

class CancelCustomOrderDialog extends StatefulWidget {
  const CancelCustomOrderDialog({super.key});

  static Future<({String? reason})?> show(BuildContext context) =>
      showDialog<({String? reason})>(
        context: context,
        builder: (_) => const CancelCustomOrderDialog(),
      );

  @override
  State<CancelCustomOrderDialog> createState() =>
      _CancelCustomOrderDialogState();
}

class _CancelCustomOrderDialogState extends State<CancelCustomOrderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _controller.text.trim();
    Navigator.of(context).pop((reason: reason.isEmpty ? null : reason));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Cancelar solicitação?', style: textTheme.bodyMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          Text(
            'O vendedor é avisado e a solicitação não poderá ser retomada. '
            'Para pedir de novo, faça uma nova solicitação.',
            style: textTheme.bodySmall,
          ),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            maxLength: CustomOrderComplement.maxMessageLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        TextButton(
          onPressed: _confirm,
          child: const Text('Cancelar solicitação'),
        ),
      ],
    );
  }
}

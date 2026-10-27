import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/error/failure.dart';

class RejectPrescriptionDialog extends StatefulWidget {
  const RejectPrescriptionDialog({super.key, required this.reject});

  final Future<Failure?> Function(String reason) reject;

  static const maxReasonLength = 500;

  @override
  State<RejectPrescriptionDialog> createState() =>
      _RejectPrescriptionDialogState();
}

class _RejectPrescriptionDialogState extends State<RejectPrescriptionDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Explique ao comprador o que está errado.');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final failure = await widget.reject(reason);
    if (!mounted) return;
    if (failure is InvalidInputFailure || failure is MissingFieldsFailure) {
      setState(() {
        _sending = false;
        _error = 'Verifique o motivo informado.';
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Recusar receita?', style: textTheme.bodyMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          Text(
            'O comprador recebe o motivo e precisa enviar outra receita. O '
            'pedido só pode ser enviado depois disso.',
            style: textTheme.bodySmall,
          ),
          TextField(
            controller: _controller,
            enabled: !_sending,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: RejectPrescriptionDialog.maxReasonLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Motivo',
              hintText: 'Ex.: a receita está ilegível ou vencida',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        TextButton(
          onPressed: _sending ? null : _submit,
          child: const Text('Recusar receita'),
        ),
      ],
    );
  }
}

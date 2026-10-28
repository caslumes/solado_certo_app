import 'package:flutter/material.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';

class CustomOrderReasonDialog extends StatefulWidget {
  const CustomOrderReasonDialog({
    super.key,
    required this.title,
    required this.explanation,
    required this.label,
    required this.hint,
    required this.emptyError,
    required this.confirmText,
    required this.submit,
  });

  const CustomOrderReasonDialog.reject({super.key, required this.submit})
    : title = 'Recusar solicitação?',
      explanation =
          'O comprador recebe o motivo e a solicitação é encerrada. Não dá '
          'para desfazer.',
      label = 'Motivo',
      hint = 'Ex.: não trabalhamos com essa numeração',
      emptyError = 'Explique ao comprador por que você recusou.',
      confirmText = 'Recusar';

  const CustomOrderReasonDialog.requestInfo({super.key, required this.submit})
    : title = 'Pedir mais informações',
      explanation =
          'O comprador recebe a pergunta e pode corrigir as medidas ao '
          'responder. A análise continua depois da resposta.',
      label = 'Pergunta',
      hint = 'Ex.: qual a altura do arco do pé esquerdo?',
      emptyError = 'Escreva o que você precisa saber.',
      confirmText = 'Enviar pergunta';

  static const maxLength = 1000;

  final String title;
  final String explanation;
  final String label;
  final String hint;
  final String emptyError;
  final String confirmText;
  final Future<Failure?> Function(String text) submit;

  @override
  State<CustomOrderReasonDialog> createState() =>
      _CustomOrderReasonDialogState();
}

class _CustomOrderReasonDialogState extends State<CustomOrderReasonDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = widget.emptyError);
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final failure = await widget.submit(text);
    if (!mounted) return;
    if (failure is InvalidInputFailure || failure is MissingFieldsFailure) {
      setState(() {
        _sending = false;
        _error = 'Verifique o texto informado.';
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(widget.title, style: textTheme.bodyMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          Text(widget.explanation, style: textTheme.bodySmall),
          TextField(
            controller: _controller,
            enabled: !_sending,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: CustomOrderReasonDialog.maxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
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
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

class AcceptCustomOrderDialog extends StatefulWidget {
  const AcceptCustomOrderDialog({super.key, required this.submit});

  final Future<Failure?> Function(String quotedPrice) submit;

  static String? parsePrice(String text) {
    final price = FieldValidators.parseDecimal(text);
    if (price == null || double.parse(price) <= 0) return null;
    return price;
  }

  @override
  State<AcceptCustomOrderDialog> createState() =>
      _AcceptCustomOrderDialogState();
}

class _AcceptCustomOrderDialogState extends State<AcceptCustomOrderDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = AcceptCustomOrderDialog.parsePrice(_controller.text);
    if (price == null) {
      setState(
        () => _error = _controller.text.trim().isEmpty
            ? 'Informe o preço do item.'
            : 'Valor inválido (ex.: 189,90)',
      );
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final failure = await widget.submit(price);
    if (!mounted) return;
    if (failure is InvalidInputFailure || failure is MissingFieldsFailure) {
      setState(() {
        _sending = false;
        _error = 'Valor inválido (ex.: 189,90)';
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Aceitar solicitação', style: textTheme.bodyMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          Text(
            'Informe o preço do item feito sob medida. O comprador confirma, '
            'escolhe o frete e paga; a produção começa depois do pagamento.',
            style: textTheme.bodySmall,
          ),
          TextField(
            controller: _controller,
            enabled: !_sending,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Preço (R\$)',
              hintText: '189,90',
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
          child: const Text('Aceitar'),
        ),
      ],
    );
  }
}

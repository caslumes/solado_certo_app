import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/custom_order_consent_terms_page.dart';

Future<bool> askCustomOrderConsent(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => const CustomOrderConsentDialog(),
  );
  return accepted == true;
}

class CustomOrderConsentDialog extends StatelessWidget {
  const CustomOrderConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Medidas dos pés', style: textTheme.bodyMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customOrderConsentText, style: textTheme.bodySmall),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CustomOrderConsentTermsPage(),
              ),
            ),
            child: const Text('Ler os termos'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Agora não'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Aceito'),
        ),
      ],
    );
  }
}

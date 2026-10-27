import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/prescription_consent_terms_page.dart';

Future<bool> askPrescriptionConsent(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => const PrescriptionConsentDialog(),
  );
  return accepted == true;
}

class PrescriptionConsentDialog extends StatelessWidget {
  const PrescriptionConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Dados de saúde', style: textTheme.bodyMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prescriptionConsentText, style: textTheme.bodySmall),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrescriptionConsentTermsPage(),
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

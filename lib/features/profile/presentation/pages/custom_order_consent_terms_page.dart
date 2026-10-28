import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

const customOrderConsentText =
    'Autorizo o Solado Certo a guardar as medidas dos meus pés, as '
    'observações e a foto que eu enviar, e a mostrá-las ao vendedor do '
    'anúncio, para que ele avalie e produza o item sob medida.';

class CustomOrderConsentTermsPage extends StatelessWidget {
  const CustomOrderConsentTermsPage({super.key});

  static const _sections = [
    (
      'Quais dados',
      'As medidas dos seus pés (comprimento, largura, tipo de arco e '
          'numeração), as observações técnicas, as respostas que você der ao '
          'vendedor e a foto opcional do pé. Como podem revelar condições de '
          'saúde, são tratados como dados pessoais sensíveis (Lei 13.709/2018, '
          'art. 5º, II).',
    ),
    (
      'Para que usamos',
      'Somente para que o vendedor avalie se consegue fazer o item, informe o '
          'preço e o produza depois do pagamento. O aplicativo confere se as '
          'medidas estão dentro de limites plausíveis; elas não são avaliadas '
          'clinicamente.',
    ),
    (
      'Quem vê',
      'Você, o vendedor do anúncio e a administração da plataforma. Cada '
          'acesso do vendedor à foto fica registrado.',
    ),
    (
      'Base legal',
      'Seu consentimento específico e destacado (LGPD, art. 11, I). '
          'Registramos a data e a versão destes termos quando você aceita.',
    ),
    (
      'Seus direitos',
      'Você pode retirar o consentimento a qualquer momento. Sem ele, não é '
          'possível fazer novas solicitações sob medida nem complementar as '
          'que estão em análise (LGPD, art. 8º, § 5º, e art. 18).',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final paragraphStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.tertiaryColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Termos do sob medida', style: textTheme.bodyMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          for (final (title, body) in _sections) ...[
            Text(title, style: textTheme.bodyMedium),
            const SizedBox(height: 8.0),
            Text(body, style: paragraphStyle),
            const SizedBox(height: 24.0),
          ],
          Text(
            'Versão dos termos: ${ConsentTermsVersions.customOrder}',
            style: paragraphStyle,
          ),
        ],
      ),
    );
  }
}

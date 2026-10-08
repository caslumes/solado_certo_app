import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

const podologicalConsentText =
    'Autorizo o Solado Certo a tratar meus dados de saúde (tipo de pisada, '
    'pontos de dor, condição clínica e observações) para personalizar buscas '
    'e recomendações de produtos.';

class PodologicalConsentTermsPage extends StatelessWidget {
  const PodologicalConsentTermsPage({super.key});

  static const _sections = [
    (
      'Quais dados',
      'Tipo de pisada, pontos de dor, condição clínica declarada e '
          'observações que você escrever no perfil podológico. Pela Lei Geral '
          'de Proteção de Dados (Lei 13.709/2018, art. 5º, II), são dados '
          'pessoais sensíveis, porque dizem respeito à sua saúde.',
    ),
    (
      'Para que usamos',
      'Somente para personalizar buscas e recomendações de produtos '
          'ortopédicos no aplicativo. Os dados não são vendidos nem '
          'compartilhados com vendedores ou terceiros.',
    ),
    (
      'Base legal',
      'Seu consentimento específico e destacado (LGPD, art. 11, I). '
          'Registramos a data e a versão destes termos quando você aceita.',
    ),
    (
      'Etapa opcional',
      'Você pode usar o aplicativo sem preencher o perfil podológico. '
          'Sem o seu consentimento, esses dados não são salvos.',
    ),
    (
      'Seus direitos',
      'Você pode consultar e corrigir esses dados a qualquer momento e '
          'retirar o consentimento. Ao retirar, o perfil podológico e os '
          'pontos de dor são excluídos (LGPD, art. 8º, § 5º, e art. 18).',
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
        title: Text('Termos do perfil podológico', style: textTheme.bodyMedium),
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
            'Versão dos termos: ${ConsentTermsVersions.podologicalProfile}',
            style: paragraphStyle,
          ),
        ],
      ),
    );
  }
}

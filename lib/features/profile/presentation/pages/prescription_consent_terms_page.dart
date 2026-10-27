import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';

const prescriptionConsentText =
    'Autorizo o Solado Certo a guardar as receitas que eu enviar e a '
    'mostrá-las ao vendedor do pedido, para comprovar a prescrição dos '
    'produtos que a exigem.';

class PrescriptionConsentTermsPage extends StatelessWidget {
  const PrescriptionConsentTermsPage({super.key});

  static const _sections = [
    (
      'Quais dados',
      'A receita ou prescrição que você enviar (foto ou PDF) e o que estiver '
          'escrito nela, como o seu nome, o diagnóstico e o nome do '
          'profissional. Pela Lei Geral de Proteção de Dados (Lei 13.709/2018, '
          'art. 5º, II), são dados pessoais sensíveis, porque dizem respeito à '
          'sua saúde.',
    ),
    (
      'Para que usamos',
      'Somente para liberar a compra de produtos que exigem prescrição. O '
          'aplicativo confere se o arquivo está legível; o conteúdo da receita '
          'não é avaliado clinicamente.',
    ),
    (
      'Quem vê',
      'Você, o vendedor do pedido (depois do pagamento, para conferir a '
          'receita antes do envio) e a administração da plataforma. Cada '
          'acesso de outra pessoa fica registrado.',
    ),
    (
      'Base legal',
      'Seu consentimento específico e destacado (LGPD, art. 11, I). '
          'Registramos a data e a versão destes termos quando você aceita.',
    ),
    (
      'Seus direitos',
      'Você pode retirar o consentimento a qualquer momento. Sem ele, não é '
          'possível enviar novas receitas nem comprar produtos que as exigem '
          '(LGPD, art. 8º, § 5º, e art. 18).',
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
        title: Text('Termos das receitas', style: textTheme.bodyMedium),
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
            'Versão dos termos: ${ConsentTermsVersions.prescription}',
            style: paragraphStyle,
          ),
        ],
      ),
    );
  }
}

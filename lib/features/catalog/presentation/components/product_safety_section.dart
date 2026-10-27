import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';

class ProductSafetySection extends StatelessWidget {
  const ProductSafetySection({super.key, required this.product});

  final ProductDetailEntity product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12.0,
      children: [
        Text('Segurança de uso', style: textTheme.bodyMedium),
        if (!product.safetyInfoComplete) const _IncompleteSafetyWarning(),
        if (product.prescriptionRequired)
          const _Notice(
            icon: Icons.medical_information_outlined,
            text: 'Exige prescrição de um profissional de saúde.',
          ),
        _SafetyItem(title: 'Indicações', text: product.usageIndication),
        _SafetyItem(title: 'Alertas', text: product.safetyAlerts),
        _SafetyItem(title: 'Contraindicações', text: product.contraindications),
      ],
    );
  }
}

class _IncompleteSafetyWarning extends StatelessWidget {
  const _IncompleteSafetyWarning();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.warningBackgroundColor,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warningColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: [
                Text(
                  'Informações de segurança incompletas',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'O vendedor não informou todos os alertas e '
                  'contraindicações deste produto. Consulte um profissional '
                  'de saúde antes de usar.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.warningColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8.0,
      children: [
        Icon(icon),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _SafetyItem extends StatelessWidget {
  const _SafetyItem({required this.title, required this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = text?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2.0,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          value.isEmpty ? 'Não informado' : value,
          style: textTheme.bodyLarge?.copyWith(
            color: value.isEmpty ? AppColors.tertiaryColor : null,
            fontStyle: value.isEmpty ? FontStyle.italic : null,
          ),
        ),
      ],
    );
  }
}

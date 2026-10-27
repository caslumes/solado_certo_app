import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_field.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

class SellerAdTile extends StatelessWidget {
  const SellerAdTile({
    super.key,
    required this.ad,
    required this.isBusy,
    required this.isEnabled,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onRemove,
  });

  final SellerAdEntity ad;
  final bool isBusy;
  final bool isEnabled;
  final VoidCallback onEdit;
  final void Function(AdStatusAction action) onChangeStatus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detailStyle = textTheme.labelMedium?.copyWith(
      color: AppColors.tertiaryColor,
    );
    final action = AdStatusAction.availableFor(ad.status);
    final canChangeStatus =
        action != null && (action == AdStatusAction.pause || ad.isComplete);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          SizedBox.square(
            dimension: 72,
            child: ProductImage(url: ad.coverImageUrl, semanticLabel: ad.title),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: [
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.black),
                ),
                Text(
                  '${formatCurrency(ad.price)} · Estoque: ${ad.stock}',
                  style: detailStyle,
                ),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: [
                    _StatusChip(label: ad.status.label),
                    if (ad.isSoldOut) const _StatusChip(label: 'Esgotado'),
                    if (!ad.isComplete)
                      const _StatusChip(label: 'Incompleto', isWarning: true),
                  ],
                ),
                if (!ad.isComplete)
                  Text(
                    'Falta preencher: '
                    '${ad.missingFields.map(adFieldLabel).join(', ')}.',
                    style: detailStyle?.copyWith(color: AppColors.warningColor),
                  ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 48,
            child: isBusy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<_AdMenuItem>(
                    enabled: isEnabled,
                    tooltip: 'Ações do anúncio',
                    onSelected: (item) => switch (item) {
                      _AdMenuItem.edit => onEdit(),
                      _AdMenuItem.changeStatus => onChangeStatus(action!),
                      _AdMenuItem.remove => onRemove(),
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _AdMenuItem.edit,
                        child: Text('Editar'),
                      ),
                      if (canChangeStatus)
                        PopupMenuItem(
                          value: _AdMenuItem.changeStatus,
                          child: Text(action.label),
                        ),
                      const PopupMenuItem(
                        value: _AdMenuItem.remove,
                        child: Text('Remover'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

enum _AdMenuItem { edit, changeStatus, remove }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.isWarning = false});

  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.warningBackgroundColor
            : AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isWarning ? AppColors.warningColor : AppColors.tertiaryColor,
        ),
      ),
    );
  }
}

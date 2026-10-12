import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item, this.onTap});

  final CatalogItemEntity item;
  final VoidCallback? onTap;

  static final _rating = NumberFormat('0.0', appLocale);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detailStyle = textTheme.labelMedium?.copyWith(
      color: AppColors.tertiaryColor,
    );
    final details = [
      if (item.averageRating != null)
        '★ ${_rating.format(item.averageRating)} (${item.reviewCount})',
      if (item.sellerState != null) item.sellerState!,
    ];

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4.0,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(url: item.coverImageUrl),
                if (!item.isAvailable)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      color: AppColors.tertiaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Esgotado',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(color: Colors.black),
          ),
          Text(formatCurrency(item.price), style: textTheme.bodySmall),
          if (details.isNotEmpty)
            Text(
              details.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: detailStyle,
            ),
        ],
      ),
    );
  }
}

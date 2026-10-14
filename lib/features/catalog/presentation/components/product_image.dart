import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/network/api_urls.dart';

/// A product photo that fills its box, with a placeholder icon when there
/// is no [url] or the image fails to load.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.semanticLabel});

  final String? url;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.secondaryColor,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.tertiaryColor),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;

    return Semantics(
      image: true,
      label: semanticLabel,
      child: CachedNetworkImage(
        imageUrl: resolveApiUrl(url!),
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            const ColoredBox(color: AppColors.secondaryColor),
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

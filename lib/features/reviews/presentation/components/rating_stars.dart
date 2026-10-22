import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';

/// [rating] of 5 stars, read only.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating de 5 estrelas',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var star = 1; star <= 5; star++)
              Icon(
                star <= rating ? Icons.star : Icons.star_border,
                size: size,
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Picks 1 to 5 stars; [errorText] shows below when set.
class StarRatingField extends StatelessWidget {
  const StarRatingField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final int? value;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = value ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: star == 1 ? '1 estrela' : '$star estrelas',
                isSelected: star <= rating,
                icon: const Icon(Icons.star_border),
                selectedIcon: const Icon(Icons.star),
                color: AppColors.primaryColor,
                onPressed: () => onChanged(star),
              ),
          ],
        ),
        if (errorText case final error?)
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}

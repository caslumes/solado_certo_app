import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_options_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/catalog_page.dart';

/// Top-level categories on the home page; three fit across, the rest scroll.
class CategoryShortcuts extends StatelessWidget {
  const CategoryShortcuts({super.key});

  static const _height = 50.0;
  static const _spacing = 16.0;
  static const _padding = 8.0;
  static const _visible = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - 2 * _padding - (_visible - 1) * _spacing) /
            _visible;

        return BlocBuilder<CatalogOptionsCubit, CatalogOptionsState>(
          builder: (context, state) {
            final categories = switch (state) {
              CatalogOptionsLoaded(:final options) => options.categories,
              _ => const <CategoryEntity>[],
            };

            return SizedBox(
              height: _height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _padding),
                itemCount: categories.isEmpty ? _visible : categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: _spacing),
                itemBuilder: (context, index) => SizedBox(
                  width: width,
                  child: categories.isEmpty
                      ? const ColoredBox(color: AppColors.secondaryColor)
                      : _CategoryShortcut(category: categories[index]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryColor,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          CatalogPage.route(
            context,
            filters: CatalogFilters(categoryId: category.id),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              category.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.tertiaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

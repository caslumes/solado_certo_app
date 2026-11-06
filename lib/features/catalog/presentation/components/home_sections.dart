import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/home_section.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/home_sections_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_card.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/product_detail_page.dart';

class HomeSections extends StatelessWidget {
  const HomeSections({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeSectionsCubit, List<HomeSectionEntity>>(
      builder: (context, sections) => Column(
        spacing: 16.0,
        children: [
          for (final section in sections)
            _HomeSection(key: ValueKey(section.code), section: section),
        ],
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({super.key, required this.section});

  static const _cardWidth = 160.0;
  static const _cardHeight = 270.0;

  final HomeSectionEntity section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.black),
          ),
        ),
        SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            itemCount: section.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return SizedBox(
                width: _cardWidth,
                child: ProductCard(
                  item: item,
                  onTap: () => Navigator.of(
                    context,
                  ).push(ProductDetailPage.route(item.id)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

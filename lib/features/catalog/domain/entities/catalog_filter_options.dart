import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';

class CatalogFilterOptions {
  final List<CategoryEntity> categories;
  final List<PurposeEntity> purposes;
  final List<ConditionEntity> conditions;

  const CatalogFilterOptions({
    required this.categories,
    required this.purposes,
    required this.conditions,
  });
}

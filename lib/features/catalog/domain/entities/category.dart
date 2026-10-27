class CategoryEntity {
  final String id;
  final String name;
  final List<CategoryEntity> children;

  final List<String> requiredAttributes;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.children = const [],
    this.requiredAttributes = const [],
  });
}

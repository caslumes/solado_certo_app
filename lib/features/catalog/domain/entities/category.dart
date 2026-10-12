class CategoryEntity {
  final String id;
  final String name;
  final List<CategoryEntity> children;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.children = const [],
  });
}

class CategoryEntity {
  final String id;
  final String name;
  final List<CategoryEntity> children;

  /// Technical attributes an ad of this category must fill to be published
  /// (RF-031), as the backend's JSON names.
  final List<String> requiredAttributes;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.children = const [],
    this.requiredAttributes = const [],
  });
}

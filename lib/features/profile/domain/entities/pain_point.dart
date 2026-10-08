class PainPointEntity {
  final String id;
  final String name;
  final String? description;

  const PainPointEntity({
    required this.id,
    required this.name,
    this.description,
  });
}

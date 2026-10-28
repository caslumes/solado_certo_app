enum ArchType {
  flat('Plano', 'flat'),
  normal('Normal', 'normal'),
  high('Alto (cavo)', 'high'),
  unknown('Não sei', 'unknown');

  const ArchType(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static ArchType fromApi(String value) => values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => throw ArgumentError.value(value, 'arch_type'),
  );
}

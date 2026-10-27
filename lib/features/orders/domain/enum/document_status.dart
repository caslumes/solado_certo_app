enum DocumentStatus {
  pending('Em análise'),
  approved('Aprovada'),
  rejected('Recusada'),
  expired('Vencida');

  const DocumentStatus(this.label);

  final String label;

  static DocumentStatus fromApi(String value) => switch (value) {
    'pending' => pending,
    'approved' => approved,
    'rejected' => rejected,
    'expired' => expired,
    _ => throw ArgumentError.value(value, 'status'),
  };
}

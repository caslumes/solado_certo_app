enum CustomOrderStatus {
  requested('Enviada'),
  underReview('Em análise'),
  needsInfo('Aguardando informações'),
  approved('Aceita'),
  rejected('Recusada'),
  inProduction('Em produção'),
  completed('Concluída'),
  cancelled('Cancelada');

  const CustomOrderStatus(this.label);

  final String label;

  static CustomOrderStatus fromApi(String value) => switch (value) {
    'requested' => requested,
    'under_review' => underReview,
    'needs_info' => needsInfo,
    'approved' => approved,
    'rejected' => rejected,
    'in_production' => inProduction,
    'completed' => completed,
    'cancelled' => cancelled,
    _ => throw ArgumentError.value(value, 'status'),
  };

  String get apiValue => switch (this) {
    requested => 'requested',
    underReview => 'under_review',
    needsInfo => 'needs_info',
    approved => 'approved',
    rejected => 'rejected',
    inProduction => 'in_production',
    completed => 'completed',
    cancelled => 'cancelled',
  };
}

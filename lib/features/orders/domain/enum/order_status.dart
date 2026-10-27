enum OrderStatus {
  awaitingPayment('Aguardando pagamento'),
  paid('Pago'),
  processing('Em preparação'),
  shipped('Enviado'),
  delivered('Entregue'),
  cancelled('Cancelado'),
  returned('Devolvido');

  const OrderStatus(this.label);

  final String label;

  static OrderStatus fromApi(String value) => switch (value) {
    'awaiting_payment' => awaitingPayment,
    'paid' => paid,
    'processing' => processing,
    'shipped' => shipped,
    'delivered' => delivered,
    'cancelled' => cancelled,
    'returned' => returned,
    _ => throw ArgumentError.value(value, 'status'),
  };

  String get apiValue => switch (this) {
    awaitingPayment => 'awaiting_payment',
    paid => 'paid',
    processing => 'processing',
    shipped => 'shipped',
    delivered => 'delivered',
    cancelled => 'cancelled',
    returned => 'returned',
  };
}

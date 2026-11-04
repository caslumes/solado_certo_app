enum SupportTicketCategory {
  order('order', 'Pedido'),
  payment('payment', 'Pagamento'),
  adaptation('adaptation', 'Adaptação ao produto'),
  other('other', 'Outro assunto');

  const SupportTicketCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static const withoutOrder = [adaptation, other];

  static SupportTicketCategory fromApi(String value) => values.firstWhere(
    (category) => category.apiValue == value,
    orElse: () => throw ArgumentError.value(value, 'category'),
  );
}

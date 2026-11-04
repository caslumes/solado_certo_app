enum SupportTicketStatus {
  open('Aberto'),
  inProgress('Em atendimento'),
  awaitingCustomer('Aguardando resposta'),
  resolved('Resolvido'),
  closed('Encerrado');

  const SupportTicketStatus(this.label);

  final String label;

  static SupportTicketStatus fromApi(String value) => switch (value) {
    'open' => open,
    'in_progress' => inProgress,
    'awaiting_customer' => awaitingCustomer,
    'resolved' => resolved,
    'closed' => closed,
    _ => throw ArgumentError.value(value, 'status'),
  };
}

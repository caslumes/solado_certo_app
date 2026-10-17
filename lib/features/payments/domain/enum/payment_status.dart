/// The payment status machine of the backend (RF-017).
enum PaymentStatus {
  pending('pending', 'Aguardando pagamento'),
  captured('captured', 'Aprovado'),
  failed('failed', 'Não aprovado'),
  refunded('refunded', 'Estornado'),
  cancelled('cancelled', 'Cancelado');

  const PaymentStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PaymentStatus fromApi(String value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => throw ArgumentError.value(value, 'status'),
  );
}

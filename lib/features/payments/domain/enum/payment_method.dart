enum PaymentMethod {
  pix('pix', 'Pix'),
  boleto('boleto', 'Boleto'),
  creditCard('credit_card', 'Cartão de crédito');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PaymentMethod fromApi(String value) => values.firstWhere(
    (method) => method.apiValue == value,
    orElse: () => throw ArgumentError.value(value, 'method'),
  );
}

enum CheckoutStep {
  address('Endereço'),
  shipping('Frete'),
  review('Resumo');

  const CheckoutStep(this.label);

  final String label;
}

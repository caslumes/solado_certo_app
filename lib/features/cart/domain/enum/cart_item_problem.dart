/// Why a cart item can't be bought as it is.
enum CartItemProblem {
  unavailable('Indisponível'),
  outOfStock('Esgotado'),
  insufficientStock('Estoque insuficiente');

  const CartItemProblem(this.label);

  final String label;

  static CartItemProblem? fromApi(String? value) => switch (value) {
    'unavailable' => unavailable,
    'out_of_stock' => outOfStock,
    'insufficient_stock' => insufficientStock,
    _ => null,
  };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';

void main() {
  // pt_BR puts a non-breaking space between the symbol and the amount.
  test('formats prices in Brazilian reais', () {
    expect(formatCurrency(89.9), 'R\$ 89,90');
    expect(formatCurrency(1234.5), 'R\$ 1.234,50');
    expect(formatCurrency(0), 'R\$ 0,00');
  });
}

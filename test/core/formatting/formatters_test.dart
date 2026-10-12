import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';

void main() {
  test('formats prices in Brazilian reais, with a non-breaking space', () {
    expect(formatCurrency(89.9), 'R\$\u00A089,90');
    expect(formatCurrency(1234.5), 'R\$\u00A01.234,50');
    expect(formatCurrency(0), 'R\$\u00A00,00');
  });
}

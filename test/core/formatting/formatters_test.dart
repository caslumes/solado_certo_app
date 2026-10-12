import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';

void main() {
  setUpAll(initializeFormatting);

  test('formats prices in Brazilian reais, with a non-breaking space', () {
    expect(formatCurrency(89.9), 'R\$ 89,90');
    expect(formatCurrency(1234.5), 'R\$ 1.234,50');
    expect(formatCurrency(0), 'R\$ 0,00');
  });

  test('formats month and year in Portuguese', () {
    expect(formatMonthYear(DateTime(2026, 10, 12)), 'outubro de 2026');
  });
}

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const appLocale = 'pt_BR';

Future<void> initializeFormatting() async {
  Intl.defaultLocale = appLocale;
  await initializeDateFormatting(appLocale);
}

final _currency = NumberFormat.currency(locale: appLocale, symbol: r'R$');

String formatCurrency(num value) => _currency.format(value);

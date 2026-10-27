import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const appLocale = 'pt_BR';

Future<void> initializeFormatting() async {
  Intl.defaultLocale = appLocale;
  await initializeDateFormatting(appLocale);
}

final _currency = NumberFormat.currency(locale: appLocale, symbol: r'R$');

String formatCurrency(num value) => _currency.format(value);

final _monthYear = DateFormat.yMMMM(appLocale);

String formatMonthYear(DateTime date) => _monthYear.format(date);

final _date = DateFormat('dd/MM/yyyy', appLocale);
final _dateTime = DateFormat("dd/MM/yyyy 'às' HH:mm", appLocale);

String formatDate(DateTime date) => _date.format(date.toLocal());

String formatDateTime(DateTime date) => _dateTime.format(date.toLocal());

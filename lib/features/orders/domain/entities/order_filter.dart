import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

enum OrderPeriod {
  any('Qualquer data', null),
  last30Days('Últimos 30 dias', 30),
  last3Months('Últimos 3 meses', 90),
  last12Months('Últimos 12 meses', 365);

  const OrderPeriod(this.label, this.days);

  final String label;
  final int? days;
}

class OrderFilter {
  final OrderStatus? status;
  final OrderPeriod period;

  const OrderFilter({this.status, this.period = OrderPeriod.any});

  bool get isEmpty => status == null && period == OrderPeriod.any;

  OrderFilter withStatus(OrderStatus? status) =>
      OrderFilter(status: status, period: period);

  String query(DateTime today) => [
    if (status case final status?) '&status=${status.apiValue}',
    if (period.days case final days?)
      '&from=${_day(DateTime(today.year, today.month, today.day - days + 1))}',
  ].join();

  static String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is OrderFilter && other.status == status && other.period == period;

  @override
  int get hashCode => Object.hash(status, period);
}

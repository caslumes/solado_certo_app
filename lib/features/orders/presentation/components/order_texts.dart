import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';

String shippingOptionName(ShippingOptionEntity option) =>
    option.carrier == null ? option.name : '${option.name} (${option.carrier})';

String deliveryTime(int days) =>
    days == 1 ? 'Até 1 dia útil' : 'Até $days dias úteis';

String formatShippingAddress(ShippingAddressEntity address) =>
    formatAddressLines(
      street: address.street,
      number: address.number,
      complement: address.complement,
      district: address.district,
      city: address.city,
      state: address.state,
      zipCode: address.zipCode,
    );

/// Street and number, district and city, then the CEP, one per line.
String formatAddressLines({
  required String street,
  required String number,
  required String? complement,
  required String district,
  required String city,
  required String state,
  required String zipCode,
}) {
  final cep = zipCode.length == 8
      ? '${zipCode.substring(0, 5)}-${zipCode.substring(5)}'
      : zipCode;
  final line = complement == null
      ? '$street, $number'
      : '$street, $number, $complement';
  return '$line\n$district, $city - $state\nCEP $cep';
}

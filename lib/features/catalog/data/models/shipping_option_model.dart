import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';

class ShippingOptionModel {
  const ShippingOptionModel({
    required this.id,
    required this.name,
    this.carrier,
    required this.price,
    required this.deliveryDays,
  });

  final String id;
  final String name;
  final String? carrier;
  final double price;
  final int deliveryDays;

  factory ShippingOptionModel.fromJson(Map<String, dynamic> json) =>
      ShippingOptionModel(
        id: json['id'] as String,
        name: json['name'] as String,
        carrier: json['carrier'] as String?,
        price: double.parse(json['price'] as String),
        deliveryDays: json['delivery_days'] as int,
      );

  ShippingOptionEntity toEntity() => ShippingOptionEntity(
    id: id,
    name: name,
    carrier: carrier,
    price: price,
    deliveryDays: deliveryDays,
  );
}

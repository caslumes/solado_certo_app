class ShippingOptionEntity {
  final String id;
  final String name;
  final String? carrier;
  final double price;
  final int deliveryDays;

  const ShippingOptionEntity({
    required this.id,
    required this.name,
    this.carrier,
    required this.price,
    required this.deliveryDays,
  });
}

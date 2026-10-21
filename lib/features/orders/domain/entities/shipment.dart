/// The carrier and tracking code the seller gave when shipping (RF-021).
class ShipmentEntity {
  final String carrier;
  final String trackingCode;

  /// `posted` or `delivered`.
  final String status;
  final DateTime? postedAt;
  final DateTime? deliveredAt;

  const ShipmentEntity({
    required this.carrier,
    required this.trackingCode,
    required this.status,
    this.postedAt,
    this.deliveredAt,
  });

  bool get isCorreios => carrier.toLowerCase().startsWith('correios');
}

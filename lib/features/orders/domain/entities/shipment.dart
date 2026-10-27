class ShipmentEntity {
  final String carrier;
  final String trackingCode;

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

  Uri? get trackingUrl => isCorreios
      ? Uri.https('rastreamento.correios.com.br', '/app/index.php', {
          'objetos': trackingCode,
        })
      : null;
}

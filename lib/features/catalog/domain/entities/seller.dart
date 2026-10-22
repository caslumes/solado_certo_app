class SellerEntity {
  final String id;
  final String name;
  final String? state;
  final double? averageRating;
  final int reviewCount;
  final DateTime memberSince;

  const SellerEntity({
    required this.id,
    required this.name,
    this.state,
    this.averageRating,
    this.reviewCount = 0,
    required this.memberSince,
  });
}

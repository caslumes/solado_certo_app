class CatalogItemEntity {
  final String id;
  final String title;
  final double price;
  final int stock;
  final String? coverImageUrl;
  final double? averageRating;
  final int reviewCount;
  final String? sellerState;
  final bool prescriptionRequired;

  const CatalogItemEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    this.coverImageUrl,
    this.averageRating,
    this.reviewCount = 0,
    this.sellerState,
    this.prescriptionRequired = false,
  });

  bool get isAvailable => stock > 0;
}

class CatalogFilters {
  final String query;
  final String? categoryId;
  final double? priceMin;
  final double? priceMax;
  final int? ratingMin;
  final String? state;
  final Set<String> purposes;
  final Set<String> conditions;

  /// Only ads matching the buyer's podological profile; needs a login
  /// and the profile consent.
  final bool forMe;

  const CatalogFilters({
    this.query = '',
    this.categoryId,
    this.priceMin,
    this.priceMax,
    this.ratingMin,
    this.state,
    this.purposes = const {},
    this.conditions = const {},
    this.forMe = false,
  });

  int get activeCount => [
    categoryId != null,
    priceMin != null || priceMax != null,
    ratingMin != null,
    state != null,
    purposes.isNotEmpty,
    conditions.isNotEmpty,
  ].where((isActive) => isActive).length;

  bool get isEmpty => query.trim().isEmpty && activeCount == 0;

  CatalogFilters withQuery(String query) => CatalogFilters(
    query: query,
    categoryId: categoryId,
    priceMin: priceMin,
    priceMax: priceMax,
    ratingMin: ratingMin,
    state: state,
    purposes: purposes,
    conditions: conditions,
    forMe: forMe,
  );

  CatalogFilters withSheetFilters(CatalogFilters sheet) => CatalogFilters(
    query: query,
    categoryId: sheet.categoryId,
    priceMin: sheet.priceMin,
    priceMax: sheet.priceMax,
    ratingMin: sheet.ratingMin,
    state: sheet.state,
    purposes: sheet.purposes,
    conditions: sheet.conditions,
    forMe: forMe,
  );
}

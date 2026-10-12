enum CatalogSort {
  relevance('relevance', 'Relevância'),
  priceAsc('price_asc', 'Menor preço'),
  priceDesc('price_desc', 'Maior preço'),
  newest('newest', 'Mais recentes');

  const CatalogSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

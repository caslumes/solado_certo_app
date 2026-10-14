/// Labels for the JSON field names the backend lists in `missing_fields`
/// and in a 422 response.
const adFieldLabels = {
  'title': 'Título',
  'description': 'Descrição',
  'category_id': 'Categoria',
  'price': 'Preço',
  'side': 'Lado',
  'size': 'Tamanho',
  'material': 'Material',
  'rigidity': 'Rigidez',
  'usage_indication': 'Indicação de uso',
  'safety_alerts': 'Alertas de segurança',
  'contraindications': 'Contraindicações',
  'images': 'Fotos',
  'shipping_options': 'Opções de envio',
};

String adFieldLabel(String field) => adFieldLabels[field] ?? field;

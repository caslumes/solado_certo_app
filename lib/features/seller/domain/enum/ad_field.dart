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

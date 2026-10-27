import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

SellerAdEntity sellerAdFromJson(Map<String, dynamic> json) => SellerAdEntity(
  id: json['id'] as String,
  title: json['title'] as String,
  price: double.parse(json['price'] as String),
  stock: json['stock'] as int,
  status: AdStatus.fromApi(json['status'] as String),
  coverImageUrl: json['cover_image_url'] as String?,
  missingFields: _strings(json['missing_fields']),
  categoryId: json['category_id'] as String?,
  description: json['description'] as String? ?? '',
  prescriptionRequired: json['prescription_required'] as bool? ?? false,
  customMadeAllowed: json['custom_made_allowed'] as bool? ?? false,
  side: json['side'] as String?,
  size: json['size'] as String?,
  material: json['material'] as String?,
  rigidity: json['rigidity'] as String?,
  usageIndication: json['usage_indication'] as String?,
  safetyAlerts: json['safety_alerts'] as String?,
  contraindications: json['contraindications'] as String?,
  shippingNotes: json['shipping_notes'] as String?,
  purposes: _strings(json['purposes']),
  conditionIds: _strings(json['condition_ids']),
  shippingOptions: [
    for (final option in json['shipping_options'] as List? ?? const [])
      SellerShippingOption(
        id: option['id'] as String,
        name: option['name'] as String,
        carrier: option['carrier'] as String?,
        price: double.parse(option['price'] as String),
        deliveryDays: option['delivery_days'] as int,
      ),
  ],
  images: [
    for (final image in json['images'] as List? ?? const [])
      SellerAdImage(
        id: image['id'] as String,
        url: image['url'] as String,
        altText: image['alt_text'] as String? ?? '',
        isCover: image['is_cover'] as bool? ?? false,
      ),
  ],
);

List<String> _strings(Object? list) => [
  for (final value in list as List? ?? const []) value as String,
];

Map<String, dynamic> adDraftToJson(AdDraft draft) => {
  'title': draft.title,
  if (draft.categoryId != null) 'category_id': draft.categoryId,
  'description': draft.description,
  'price': draft.price.isEmpty ? '0' : draft.price,
  'stock': draft.stock,
  'prescription_required': draft.prescriptionRequired,
  'custom_made_allowed': draft.customMadeAllowed,
  'side': draft.side ?? '',
  'size': draft.size,
  'material': draft.material,
  'rigidity': draft.rigidity ?? '',
  'usage_indication': draft.usageIndication,
  'safety_alerts': draft.safetyAlerts,
  'contraindications': draft.contraindications,
  'shipping_notes': draft.shippingNotes,
  'purposes': draft.purposes,
  'condition_ids': draft.conditionIds,
  'shipping_options': [
    for (final option in draft.shippingOptions)
      {
        if (option.id != null) 'id': option.id,
        'name': option.name,
        'carrier': option.carrier,
        'price': option.price,
        'delivery_days': option.deliveryDays,
      },
  ],
};

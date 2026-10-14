import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';

/// The editable values of the ad form, kept by the page across steps.
class AdFormFields {
  AdFormFields.from(SellerAdEntity? ad)
    : title = TextEditingController(text: ad?.title),
      description = TextEditingController(text: ad?.description),
      price = TextEditingController(
        text: ad == null || ad.price == 0 ? '' : formatDecimalInput(ad.price),
      ),
      stock = TextEditingController(text: '${ad?.stock ?? 1}'),
      size = TextEditingController(text: ad?.size),
      material = TextEditingController(text: ad?.material),
      usageIndication = TextEditingController(text: ad?.usageIndication),
      safetyAlerts = TextEditingController(text: ad?.safetyAlerts),
      contraindications = TextEditingController(text: ad?.contraindications),
      shippingNotes = TextEditingController(text: ad?.shippingNotes),
      categoryId = ad?.categoryId,
      prescriptionRequired = ad?.prescriptionRequired ?? false,
      customMadeAllowed = ad?.customMadeAllowed ?? false,
      side = ad?.side,
      rigidity = ad?.rigidity,
      purposes = {...?ad?.purposes},
      conditionIds = {...?ad?.conditionIds},
      shippingOptions = [
        for (final option in ad?.shippingOptions ?? const [])
          ShippingOptionFields.from(option),
      ];

  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController price;
  final TextEditingController stock;
  final TextEditingController size;
  final TextEditingController material;
  final TextEditingController usageIndication;
  final TextEditingController safetyAlerts;
  final TextEditingController contraindications;
  final TextEditingController shippingNotes;
  String? categoryId;
  bool prescriptionRequired;
  bool customMadeAllowed;
  String? side;
  String? rigidity;
  final Set<String> purposes;
  final Set<String> conditionIds;
  List<ShippingOptionFields> shippingOptions;

  /// Whether [field] (a backend JSON name) still has no value.
  bool isEmpty(String field) => switch (field) {
    'title' => title.text.trim().isEmpty,
    'category_id' => categoryId == null,
    'description' => description.text.trim().isEmpty,
    'price' => (double.tryParse(_price) ?? 0) == 0,
    'side' => side == null,
    'size' => size.text.trim().isEmpty,
    'material' => material.text.trim().isEmpty,
    'rigidity' => rigidity == null,
    'usage_indication' => usageIndication.text.trim().isEmpty,
    'safety_alerts' => safetyAlerts.text.trim().isEmpty,
    'contraindications' => contraindications.text.trim().isEmpty,
    'shipping_options' => shippingOptions.isEmpty,
    _ => false,
  };

  String get _price => FieldValidators.parseDecimal(price.text) ?? '';

  AdDraft toDraft() => AdDraft(
    title: title.text.trim(),
    categoryId: categoryId,
    description: description.text.trim(),
    price: _price,
    stock: int.tryParse(stock.text.trim()) ?? 0,
    prescriptionRequired: prescriptionRequired,
    customMadeAllowed: customMadeAllowed,
    side: side,
    size: size.text.trim(),
    material: material.text.trim(),
    rigidity: rigidity,
    usageIndication: usageIndication.text.trim(),
    safetyAlerts: safetyAlerts.text.trim(),
    contraindications: contraindications.text.trim(),
    shippingNotes: shippingNotes.text.trim(),
    purposes: purposes.toList(),
    conditionIds: conditionIds.toList(),
    shippingOptions: [for (final option in shippingOptions) option.toDraft()],
  );

  /// Takes the saved shipping options, which now have ids, so the next save
  /// edits them instead of creating new ones.
  void syncShippingOptions(List<SellerShippingOption> saved) {
    shippingOptions.forEach(disposeShippingOptionLater);
    shippingOptions = [
      for (final option in saved) ShippingOptionFields.from(option),
    ];
  }

  void dispose() {
    for (final controller in [
      title,
      description,
      price,
      stock,
      size,
      material,
      usageIndication,
      safetyAlerts,
      contraindications,
      shippingNotes,
    ]) {
      controller.dispose();
    }
    for (final option in shippingOptions) {
      option.dispose();
    }
  }
}

class ShippingOptionFields {
  ShippingOptionFields({this.id})
    : name = TextEditingController(),
      carrier = TextEditingController(),
      price = TextEditingController(),
      deliveryDays = TextEditingController();

  ShippingOptionFields.from(SellerShippingOption option)
    : id = option.id,
      name = TextEditingController(text: option.name),
      carrier = TextEditingController(text: option.carrier),
      price = TextEditingController(text: formatDecimalInput(option.price)),
      deliveryDays = TextEditingController(text: '${option.deliveryDays}');

  final String? id;
  final TextEditingController name;
  final TextEditingController carrier;
  final TextEditingController price;
  final TextEditingController deliveryDays;

  ShippingOptionDraft toDraft() => ShippingOptionDraft(
    id: id,
    name: name.text.trim(),
    carrier: carrier.text.trim(),
    price: FieldValidators.parseDecimal(price.text) ?? '0',
    deliveryDays: int.tryParse(deliveryDays.text.trim()) ?? 0,
  );

  void dispose() {
    name.dispose();
    carrier.dispose();
    price.dispose();
    deliveryDays.dispose();
  }
}

/// Disposes the controllers after the frame, once the fields using them
/// are gone.
void disposeShippingOptionLater(ShippingOptionFields option) =>
    SchedulerBinding.instance.addPostFrameCallback((_) => option.dispose());

/// Shows an amount the way the seller types it, e.g. `89,90`.
String formatDecimalInput(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');

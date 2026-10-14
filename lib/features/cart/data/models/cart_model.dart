import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/domain/enum/cart_item_problem.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';

/// Reads the cart returned by every `/cart` endpoint.
CartEntity cartFromJson(Map<String, dynamic> json) => CartEntity(
  id: json['id'] as String?,
  groups: [
    for (final group in json['groups'] as List? ?? const [])
      CartGroupEntity(
        sellerId: group['seller']['id'] as String,
        sellerName: group['seller']['name'] as String,
        subtotal: double.parse(group['subtotal'] as String),
        items: [for (final item in group['items'] as List) _item(item)],
      ),
  ],
  itemCount: json['item_count'] as int? ?? 0,
  subtotal: double.parse(json['subtotal'] as String? ?? '0'),
  hasProblems: json['has_problems'] as bool? ?? false,
  hasPriceChanges: json['has_price_changes'] as bool? ?? false,
);

CartItemEntity _item(Map<String, dynamic> json) => CartItemEntity(
  advertisementId: json['advertisement_id'] as String,
  title: json['title'] as String,
  coverImageUrl: json['cover_image_url'] as String?,
  quantity: json['quantity'] as int,
  unitPrice: double.parse(json['unit_price'] as String),
  addedUnitPrice: double.parse(json['added_unit_price'] as String),
  priceChanged: json['price_changed'] as bool? ?? false,
  stock: json['stock'] as int,
  problem: CartItemProblem.fromApi(json['problem'] as String?),
  subtotal: double.parse(json['subtotal'] as String),
  shippingOptions: [
    for (final option in json['shipping_options'] as List? ?? const [])
      ShippingOptionEntity(
        id: option['id'] as String,
        name: option['name'] as String,
        carrier: option['carrier'] as String?,
        price: double.parse(option['price'] as String),
        deliveryDays: option['delivery_days'] as int,
      ),
  ],
);

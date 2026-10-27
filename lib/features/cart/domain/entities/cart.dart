import 'package:solado_certo_app/features/cart/domain/enum/cart_item_problem.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';

class CartEntity {
  final String? id;

  final List<CartGroupEntity> groups;
  final int itemCount;
  final double subtotal;
  final bool hasProblems;
  final bool hasPriceChanges;

  const CartEntity({
    this.id,
    this.groups = const [],
    this.itemCount = 0,
    this.subtotal = 0,
    this.hasProblems = false,
    this.hasPriceChanges = false,
  });

  static const empty = CartEntity();

  bool get isEmpty => groups.isEmpty;

  List<CartItemEntity> get items => [
    for (final group in groups) ...group.items,
  ];

  int get unitCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartItemEntity? item(String advertisementId) {
    for (final item in items) {
      if (item.advertisementId == advertisementId) return item;
    }
    return null;
  }
}

class CartGroupEntity {
  final String sellerId;
  final String sellerName;
  final List<CartItemEntity> items;
  final double subtotal;

  const CartGroupEntity({
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.subtotal,
  });
}

class CartItemEntity {
  final String advertisementId;
  final String title;
  final String? coverImageUrl;
  final int quantity;

  final double unitPrice;

  final double addedUnitPrice;
  final bool priceChanged;
  final int stock;
  final CartItemProblem? problem;
  final double subtotal;
  final List<ShippingOptionEntity> shippingOptions;

  const CartItemEntity({
    required this.advertisementId,
    required this.title,
    this.coverImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.addedUnitPrice,
    this.priceChanged = false,
    required this.stock,
    this.problem,
    required this.subtotal,
    this.shippingOptions = const [],
  });

  bool get isAvailable => problem == null;

  String? get problemDescription => switch (problem) {
    null => null,
    CartItemProblem.insufficientStock =>
      stock == 1
          ? 'Só há 1 unidade disponível'
          : 'Só há $stock unidades disponíveis',
    CartItemProblem.unavailable => 'Indisponível no momento',
    CartItemProblem.outOfStock => CartItemProblem.outOfStock.label,
  };
}

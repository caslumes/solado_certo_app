import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/orders/domain/entities/prescription.dart';
import 'package:solado_certo_app/features/orders/domain/enum/document_status.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';

class OrderEntity {
  final String id;
  final String number;
  final OrderStatus status;
  final String sellerId;
  final String sellerName;

  final String? buyerName;
  final ShippingAddressEntity address;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double shippingTotal;
  final double discountTotal;
  final double total;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;

  const OrderEntity({
    required this.id,
    required this.number,
    required this.status,
    required this.sellerId,
    required this.sellerName,
    this.buyerName,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.shippingTotal,
    required this.discountTotal,
    required this.total,
    required this.createdAt,
    this.paidAt,
    this.deliveredAt,
  });

  List<OrderItemEntity> get itemsAwaitingPrescription =>
      items.where((item) => item.awaitsPrescription).toList();
}

class OrderItemEntity {
  final String? id;
  final String advertisementId;
  final String title;
  final String? coverImageUrl;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final ShippingOptionEntity shippingOption;

  final ReviewEntity? review;

  final bool prescriptionRequired;
  final PrescriptionEntity? prescription;
  final bool canUploadPrescription;
  final bool canRejectPrescription;

  const OrderItemEntity({
    this.id,
    required this.advertisementId,
    required this.title,
    this.coverImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.shippingOption,
    this.review,
    this.prescriptionRequired = false,
    this.prescription,
    this.canUploadPrescription = false,
    this.canRejectPrescription = false,
  });

  bool get awaitsPrescription =>
      prescriptionRequired && prescription?.status != DocumentStatus.approved;
}

class ShippingAddressEntity {
  final String? label;
  final String receiver;
  final String zipCode;
  final String street;
  final String number;
  final String? complement;
  final String district;
  final String city;
  final String state;

  const ShippingAddressEntity({
    this.label,
    required this.receiver,
    required this.zipCode,
    required this.street,
    required this.number,
    this.complement,
    required this.district,
    required this.city,
    required this.state,
  });
}

import 'package:dio/dio.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/domain/enum/cart_item_problem.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/seller.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/measurements.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/arch_type.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/prescription.dart';
import 'package:solado_certo_app/features/orders/domain/entities/shipment.dart';
import 'package:solado_certo_app/features/orders/domain/enum/document_status.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

ProfileEntity buildProfile() => ProfileEntity(
  name: 'Maria Souza',
  email: 'maria@example.com',
  phone: '19999999999',
  avatarUrl: '',
);

OnboardingEntity buildOnboarding({
  OnboardingStep step = OnboardingStep.welcome,
  OnboardingStatus status = OnboardingStatus.inProgress,
}) => OnboardingEntity(currentStep: step, status: status);

OnboardingDraft buildDraft({OnboardingStep step = OnboardingStep.welcome}) =>
    OnboardingDraft(
      onboarding: buildOnboarding(step: step),
      profile: buildProfile(),
      addresses: const [],
      podologicalProfile: PodologicalProfileEntity(),
    );

DioException buildDioException({
  int? statusCode,
  DioExceptionType type = DioExceptionType.badResponse,
  Object? data,
}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode == null
        ? null
        : Response(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: data,
          ),
  );
}

CatalogItemEntity buildCatalogItem({String id = '601', int stock = 10}) =>
    CatalogItemEntity(id: id, title: 'Palmilha $id', price: 89.9, stock: stock);

CatalogPageEntity buildCatalogPage({
  List<CatalogItemEntity>? items,
  int page = 1,
  int totalItems = 1,
  bool hasNext = false,
}) => CatalogPageEntity(
  items: items ?? [buildCatalogItem()],
  currentPage: page,
  totalItems: totalItems,
  hasNext: hasNext,
);

ProductDetailEntity buildProductDetail({
  int stock = 15,
  bool prescriptionRequired = true,
  bool customMadeAllowed = false,
  String? contraindications = 'Pós-operatório recente.',
  bool safetyInfoComplete = true,
  SellerEntity? seller,
}) => ProductDetailEntity(
  id: '603',
  title: 'Órtese corretora para joanete',
  description: 'Órtese noturna para alinhamento do hálux.',
  price: 129.5,
  stock: stock,
  prescriptionRequired: prescriptionRequired,
  customMadeAllowed: customMadeAllowed,
  side: 'left',
  rigidity: 'rigid',
  usageIndication: 'Uso noturno',
  safetyAlerts: 'Uso apenas com orientação profissional.',
  contraindications: contraindications,
  purposes: const [PurposeEntity(code: 'correction', name: 'Correção')],
  conditions: const [ConditionEntity(id: '504', name: 'Joanete')],
  seller:
      seller ??
      SellerEntity(
        id: '2',
        name: 'Loja Pé Bem',
        state: 'SP',
        memberSince: DateTime(2026, 10, 1),
      ),
  shippingOptions: const [
    ShippingOptionEntity(
      id: '701',
      name: 'PAC',
      carrier: 'Correios',
      price: 19.9,
      deliveryDays: 7,
    ),
  ],
  safetyInfoComplete: safetyInfoComplete,
);

const catalogFilterOptions = CatalogFilterOptions(
  categories: [
    CategoryEntity(
      id: '301',
      name: 'Palmilhas',
      children: [CategoryEntity(id: '305', name: 'Palmilhas sob medida')],
    ),
    CategoryEntity(id: '302', name: 'Calçados ortopédicos'),
  ],
  purposes: [PurposeEntity(code: 'prevention', name: 'Prevenção')],
  conditions: [ConditionEntity(id: '501', name: 'Fascite plantar')],
);

SellerAdEntity buildSellerAd({
  String id = '601',
  String? title,
  AdStatus status = AdStatus.published,
  int stock = 10,
  List<String> missingFields = const [],
}) => SellerAdEntity(
  id: id,
  title: title ?? 'Palmilha $id',
  price: 89.9,
  stock: stock,
  status: status,
  missingFields: missingFields,
);

CartItemEntity buildCartItem({
  String id = '601',
  int quantity = 1,
  double price = 89.9,
  double? addedPrice,
  int stock = 10,
  CartItemProblem? problem,
}) => CartItemEntity(
  advertisementId: id,
  title: 'Palmilha $id',
  quantity: quantity,
  unitPrice: price,
  addedUnitPrice: addedPrice ?? price,
  priceChanged: addedPrice != null && addedPrice != price,
  stock: stock,
  problem: problem,
  subtotal: price * quantity,
  shippingOptions: const [
    ShippingOptionEntity(
      id: 'pac',
      name: 'PAC',
      carrier: 'Correios',
      price: 19.9,
      deliveryDays: 7,
    ),
  ],
);

CartEntity buildCart(Map<String, List<CartItemEntity>> itemsBySeller) {
  double sum(Iterable<CartItemEntity> items) => items
      .where((item) => item.isAvailable)
      .fold(0.0, (total, item) => total + item.subtotal);
  final items = itemsBySeller.values.expand((items) => items).toList();
  return CartEntity(
    id: 'cart-1',
    groups: [
      for (final MapEntry(key: seller, value: sellerItems)
          in itemsBySeller.entries)
        CartGroupEntity(
          sellerId: seller,
          sellerName: 'Loja $seller',
          items: sellerItems,
          subtotal: sum(sellerItems),
        ),
    ],
    itemCount: items
        .where((item) => item.isAvailable)
        .fold(0, (total, item) => total + item.quantity),
    subtotal: sum(items),
    hasProblems: items.any((item) => !item.isAvailable),
    hasPriceChanges: items.any((item) => item.priceChanged),
  );
}

AddressEntity buildAddress({
  String id = 'a1',
  String? label = 'Casa',
  bool isDefault = false,
}) => AddressEntity(
  id: id,
  label: label,
  receiver: 'Maria Souza',
  zipCode: '13010111',
  street: 'Rua das Flores',
  number: '10',
  district: 'Centro',
  city: 'Campinas',
  state: 'SP',
  country: 'BR',
  isDefault: isDefault,
);

const shippingAddress = ShippingAddressEntity(
  label: 'Casa',
  receiver: 'Maria Souza',
  zipCode: '13010111',
  street: 'Rua das Flores',
  number: '10',
  district: 'Centro',
  city: 'Campinas',
  state: 'SP',
);

PrescriptionEntity buildPrescription({
  String id = 'd1',
  DocumentStatus status = DocumentStatus.approved,
  String? rejectionReason,
}) => PrescriptionEntity(
  id: id,
  status: status,
  rejectionReason: rejectionReason,
  url: '/documents/$id',
  createdAt: DateTime(2026, 10, 14, 9, 30),
);

OrderItemEntity buildOrderItem({
  String id = '601',
  int quantity = 1,
  String? itemId,
  ReviewEntity? review,
  bool prescriptionRequired = false,
  PrescriptionEntity? prescription,
  bool canUploadPrescription = false,
  bool canRejectPrescription = false,
}) => OrderItemEntity(
  id: itemId,
  advertisementId: id,
  title: 'Palmilha $id',
  quantity: quantity,
  unitPrice: 89.9,
  subtotal: 89.9 * quantity,
  shippingOption: const ShippingOptionEntity(
    id: 'pac',
    name: 'PAC',
    carrier: 'Correios',
    price: 19.9,
    deliveryDays: 7,
  ),
  review: review,
  prescriptionRequired: prescriptionRequired,
  prescription: prescription,
  canUploadPrescription: canUploadPrescription,
  canRejectPrescription: canRejectPrescription,
);

CheckoutPlanEntity buildCheckoutPlan({List<String> sellers = const ['s1']}) =>
    CheckoutPlanEntity(
      address: shippingAddress,
      orders: [
        for (final seller in sellers)
          PlannedOrderEntity(
            sellerId: seller,
            sellerName: 'Loja $seller',
            items: [buildOrderItem()],
            subtotal: 89.9,
            shippingTotal: 19.9,
            discountTotal: 0,
            total: 109.8,
          ),
      ],
      subtotal: 89.9 * sellers.length,
      shippingTotal: 19.9 * sellers.length,
      discountTotal: 0,
      total: 109.8 * sellers.length,
    );

OrderEntity buildOrder({
  String id = 'o1',
  String number = 'SC-20261014-ABC123',
  String seller = 's1',
  OrderStatus status = OrderStatus.awaitingPayment,
  List<OrderItemEntity>? items,
  double subtotal = 89.9,
  String? buyerName,
  DateTime? paidAt,
}) => OrderEntity(
  id: id,
  number: number,
  status: status,
  sellerId: seller,
  sellerName: 'Loja $seller',
  buyerName: buyerName,
  address: shippingAddress,
  items: items ?? [buildOrderItem()],
  subtotal: subtotal,
  shippingTotal: 19.9,
  discountTotal: 0,
  total: 109.8,
  createdAt: DateTime(2026, 10, 14, 9, 5),
  paidAt: paidAt,
);

OrderDetailEntity buildSellerOrderDetail({
  String id = 'o1',
  OrderStatus status = OrderStatus.paid,
  List<OrderItemEntity>? items,
  bool? canShip,
}) => OrderDetailEntity(
  order: buildOrder(
    id: id,
    status: status,
    items: items,
    buyerName: 'Maria Souza',
    paidAt: DateTime(2026, 10, 14, 10, 30),
  ),
  history: [
    OrderStatusChangeEntity(
      to: OrderStatus.awaitingPayment,
      reason: 'checkout',
      createdAt: DateTime(2026, 10, 14, 9, 5),
    ),
    OrderStatusChangeEntity(
      from: OrderStatus.awaitingPayment,
      to: OrderStatus.paid,
      reason: 'payment_captured',
      createdAt: DateTime(2026, 10, 14, 10, 30),
    ),
  ],
  shipment: status == OrderStatus.shipped || status == OrderStatus.delivered
      ? ShipmentEntity(
          carrier: 'Correios',
          trackingCode: 'AA123456789BR',
          status: status == OrderStatus.delivered ? 'delivered' : 'posted',
          postedAt: DateTime(2026, 10, 15, 8),
        )
      : null,
  canCancel: false,
  canStartProcessing: status == OrderStatus.paid,
  canShip: canShip ?? status == OrderStatus.processing,
);

OrderDetailEntity buildOrderDetail({
  bool cancelled = false,
  bool paid = false,
  List<OrderItemEntity>? items,
}) => OrderDetailEntity(
  order: buildOrder(
    items: items,
    status: cancelled
        ? OrderStatus.cancelled
        : paid
        ? OrderStatus.paid
        : OrderStatus.awaitingPayment,
  ),
  history: [
    OrderStatusChangeEntity(
      to: OrderStatus.awaitingPayment,
      reason: 'checkout',
      createdAt: DateTime(2026, 10, 14, 9, 5),
    ),
    if (cancelled)
      OrderStatusChangeEntity(
        from: OrderStatus.awaitingPayment,
        to: OrderStatus.cancelled,
        reason: 'buyer_cancelled',
        createdAt: DateTime(2026, 10, 14, 10, 30),
      ),
    if (paid)
      OrderStatusChangeEntity(
        from: OrderStatus.awaitingPayment,
        to: OrderStatus.paid,
        reason: 'payment_captured',
        createdAt: DateTime(2026, 10, 15, 10, 0),
      ),
  ],
  canCancel: !cancelled,
);

OrderDetailEntity buildShippedOrderDetail({
  bool delivered = false,
  ReviewEntity? review,
}) => OrderDetailEntity(
  order: buildOrder(
    status: delivered ? OrderStatus.delivered : OrderStatus.shipped,
    items: [buildOrderItem(itemId: 'i1', review: review)],
  ),
  history: [
    OrderStatusChangeEntity(
      from: OrderStatus.processing,
      to: OrderStatus.shipped,
      reason: 'seller_shipped',
      createdAt: DateTime(2026, 10, 15, 8),
    ),
  ],
  shipment: ShipmentEntity(
    carrier: 'Correios',
    trackingCode: 'AA123456789BR',
    status: delivered ? 'delivered' : 'posted',
    postedAt: DateTime(2026, 10, 15, 8),
    deliveredAt: delivered ? DateTime(2026, 10, 20, 18) : null,
  ),
  canCancel: false,
  canConfirmDelivery: !delivered,
);

ReviewEntity buildReview({int? comfortRating = 4}) => ReviewEntity(
  productRating: 5,
  sellerRating: 4,
  comfortRating: comfortRating,
  comment: 'Muito boa',
  adaptationFeedback: 'Duas semanas para acostumar',
  createdAt: DateTime(2026, 10, 21, 10),
);

PublicReviewEntity buildPublicReview({String id = 'r1'}) => PublicReviewEntity(
  id: id,
  reviewerName: 'Maria',
  productRating: 4,
  comfortRating: 5,
  comment: 'Confortável desde o primeiro dia',
  createdAt: DateTime(2026, 10, 21, 10),
);

CheckoutResultEntity buildCheckoutResult({List<OrderEntity>? orders}) {
  final created = orders ?? [buildOrder()];
  return CheckoutResultEntity(
    id: 'checkout-1',
    orders: created,
    total: created.fold(0.0, (total, order) => total + order.total),
  );
}

PaymentEntity buildPayment({
  String id = 'p1',
  PaymentMethod method = PaymentMethod.pix,
  PaymentStatus status = PaymentStatus.pending,
  double? amount,
  String? failureReason,
  String? failureMessage,
  DateTime? refundRequestedAt,
  String? refundUrl,
}) => PaymentEntity(
  id: id,
  orderId: 'o1',
  method: method,
  status: status,
  amount: amount ?? (method == PaymentMethod.pix ? 105.3 : 109.8),
  dueDate: method == PaymentMethod.creditCard ? null : DateTime(2026, 10, 17),
  failureReason: failureReason,
  failureMessage: failureMessage,
  pix: method == PaymentMethod.pix
      ? PixChargeEntity(
          payload: '00020101021226820014br.gov.bcb.pix',
          expiresAt: DateTime(2026, 10, 17, 23, 59),
        )
      : null,
  boletoUrl: method == PaymentMethod.boleto
      ? 'https://sandbox.asaas.com/b/pdf/1'
      : null,
  card: method == PaymentMethod.creditCard
      ? const CardSummaryEntity(last4: '4444', brand: 'MASTERCARD')
      : null,
  capturedAt: status == PaymentStatus.captured
      ? DateTime(2026, 10, 15, 10, 0)
      : null,
  refundRequestedAt: refundRequestedAt,
  refundUrl: refundUrl,
  createdAt: DateTime(2026, 10, 15, 9, 30),
);

NotificationEntity buildNotification({
  String id = 'n1',
  NotificationType type = NotificationType.orderShipped,
  String? orderId = 'o1',
  bool read = false,
}) => NotificationEntity(
  id: id,
  type: type,
  title: 'Título $id',
  body: 'Corpo $id',
  orderId: orderId,
  read: read,
  createdAt: DateTime.utc(2026, 10, 20, 12),
);

const footMeasurements = Measurements(
  left: FootMeasurement(lengthCm: 25.5, widthCm: 9.5),
  right: FootMeasurement(lengthCm: 25.8, widthCm: 9.6),
  archType: ArchType.flat,
  shoeSize: 39,
);

CustomOrderEntity buildCustomOrder({
  String id = 'c1',
  CustomOrderStatus status = CustomOrderStatus.requested,
  double? quotedPrice,
}) => CustomOrderEntity(
  id: id,
  status: status,
  advertisementId: '603',
  advertisementTitle: 'Palmilha sob medida',
  buyerName: 'Maria Souza',
  sellerName: 'Loja Pé Bem',
  quotedPrice: quotedPrice,
  createdAt: DateTime(2026, 10, 26, 9, 0),
  updatedAt: DateTime(2026, 10, 27, 10, 0),
);

CustomOrderDetailEntity buildCustomOrderDetail({
  CustomOrderStatus status = CustomOrderStatus.requested,
  Set<CustomOrderAction> actions = const {
    CustomOrderAction.cancel,
    CustomOrderAction.sendPhoto,
  },
  double? quotedPrice,
  String? orderId,
  String? technicalNotes = 'Dor no calcanhar',
  String? rejectionReason,
  String? adaptationInstructions,
  String? footPhotoUrl,
  FittingReportEntity? fittingReport,
  List<CustomOrderChangeEntity>? history,
}) => CustomOrderDetailEntity(
  request: buildCustomOrder(status: status, quotedPrice: quotedPrice),
  orderId: orderId,
  measurements: footMeasurements,
  technicalNotes: technicalNotes,
  rejectionReason: rejectionReason,
  adaptationInstructions: adaptationInstructions,
  footPhotoUrl: footPhotoUrl,
  fittingReport: fittingReport,
  history:
      history ??
      [
        CustomOrderChangeEntity(
          to: CustomOrderStatus.requested,
          changedBy: CustomOrderActor.buyer,
          createdAt: DateTime(2026, 10, 26, 9, 0),
        ),
      ],
  actions: actions,
);

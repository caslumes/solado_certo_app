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
import 'package:solado_certo_app/features/notifications/domain/entities/notification.dart';
import 'package:solado_certo_app/features/notifications/domain/enum/notification_type.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
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

/// The dev seed's 603 without images, so widget tests load nothing from the
/// network.
ProductDetailEntity buildProductDetail({
  int stock = 15,
  bool prescriptionRequired = true,
  String? contraindications = 'Pós-operatório recente.',
  bool safetyInfoComplete = true,
}) => ProductDetailEntity(
  id: '603',
  title: 'Órtese corretora para joanete',
  description: 'Órtese noturna para alinhamento do hálux.',
  price: 129.5,
  stock: stock,
  prescriptionRequired: prescriptionRequired,
  side: 'left',
  rigidity: 'rigid',
  usageIndication: 'Uso noturno',
  safetyAlerts: 'Uso apenas com orientação profissional.',
  contraindications: contraindications,
  purposes: const [PurposeEntity(code: 'correction', name: 'Correção')],
  conditions: const [ConditionEntity(id: '504', name: 'Joanete')],
  seller: SellerEntity(
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

/// A seller's ad without a cover, so widget tests load nothing from the
/// network.
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

/// A cart with one group per seller, totals counting only available items.
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

OrderItemEntity buildOrderItem({String id = '601', int quantity = 1}) =>
    OrderItemEntity(
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
    );

/// One order per seller, each with one unit of 601 and PAC.
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
}) => OrderEntity(
  id: id,
  number: number,
  status: status,
  sellerId: seller,
  sellerName: 'Loja $seller',
  address: shippingAddress,
  items: items ?? [buildOrderItem()],
  subtotal: subtotal,
  shippingTotal: 19.9,
  discountTotal: 0,
  total: 109.8,
  createdAt: DateTime(2026, 10, 14, 9, 5),
);

/// An order awaiting payment, cancelled by the buyer when [cancelled] or
/// paid when [paid].
OrderDetailEntity buildOrderDetail({
  bool cancelled = false,
  bool paid = false,
}) => OrderDetailEntity(
  order: buildOrder(
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

CheckoutResultEntity buildCheckoutResult({List<OrderEntity>? orders}) {
  final created = orders ?? [buildOrder()];
  return CheckoutResultEntity(
    id: 'checkout-1',
    orders: created,
    total: created.fold(0.0, (total, order) => total + order.total),
  );
}

/// A payment of [buildOrder]'s o1: a pending Pix with its code by default.
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

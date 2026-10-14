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

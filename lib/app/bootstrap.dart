import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:solado_certo_app/core/network/api_client.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/auth/data/repositories/api_auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:solado_certo_app/features/cart/data/repositories/api_cart_repository.dart';
import 'package:solado_certo_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:solado_certo_app/features/cart/domain/usecases/cart_use_cases.dart';
import 'package:solado_certo_app/features/catalog/data/repositories/api_catalog_repository.dart';
import 'package:solado_certo_app/features/checkout/data/repositories/api_checkout_repository.dart';
import 'package:solado_certo_app/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:solado_certo_app/features/checkout/domain/usecases/checkout_use_cases.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_items_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_product_detail_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_recommended_items_use_case.dart';
import 'package:solado_certo_app/features/notifications/data/repositories/api_notification_repository.dart';
import 'package:solado_certo_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:solado_certo_app/features/notifications/domain/usecases/notification_use_cases.dart';
import 'package:solado_certo_app/features/onboarding/data/repositories/api_onboarding_repository.dart';
import 'package:solado_certo_app/features/orders/data/repositories/api_order_repository.dart';
import 'package:solado_certo_app/features/orders/domain/repositories/order_repository.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/payments/data/repositories/api_payment_repository.dart';
import 'package:solado_certo_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';
import 'package:solado_certo_app/features/reviews/data/repositories/api_review_repository.dart';
import 'package:solado_certo_app/features/reviews/domain/repositories/review_repository.dart';
import 'package:solado_certo_app/features/reviews/domain/usecases/review_use_cases.dart';
import 'package:solado_certo_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/add_address_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/become_seller_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/change_avatar_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_roles_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/remove_avatar_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_prescription_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_prescription_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/revoke_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/profile/data/repositories/api_profile_repository.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:solado_certo_app/features/seller/data/repositories/api_seller_repository.dart';
import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/ad_images_use_cases.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/change_ad_status_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_my_ads_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/remove_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/save_ad_use_case.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<ClientInterface>(() => ApiClient.instance);

  getIt.registerLazySingleton<AuthRepositoryInterface>(
    () => ApiAuthRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<ProfileRepositoryInterface>(
    () => ApiProfileRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<OnboardingRepository>(
    () => ApiOnboardingRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<CatalogRepositoryInterface>(
    () => ApiCatalogRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<SellerRepositoryInterface>(
    () => ApiSellerRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<CartRepositoryInterface>(
    () => ApiCartRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<CheckoutRepositoryInterface>(
    () => ApiCheckoutRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<OrderRepositoryInterface>(
    () => ApiOrderRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<ReviewRepositoryInterface>(
    () => ApiReviewRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<PaymentRepositoryInterface>(
    () => ApiPaymentRepository(getIt<ClientInterface>()),
  );
  getIt.registerLazySingleton<NotificationRepositoryInterface>(
    () => ApiNotificationRepository(getIt<ClientInterface>()),
  );

  getIt.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(authRepository: getIt<AuthRepositoryInterface>()),
  );
  getIt.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(
      getIt<AuthRepositoryInterface>(),
      getIt<FlutterSecureStorage>(),
    ),
  );
  getIt.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(
      repository: getIt<AuthRepositoryInterface>(),
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );
  getIt.registerLazySingleton<GetProfileUseCase>(
    () => GetProfileUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<AddAddressUseCase>(
    () => AddAddressUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetPainPointsUseCase>(
    () => GetPainPointsUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<HasPodologicalConsentUseCase>(
    () => HasPodologicalConsentUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<SavePodologicalProfileUseCase>(
    () => SavePodologicalProfileUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<RevokePodologicalConsentUseCase>(
    () => RevokePodologicalConsentUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<BecomeSellerUseCase>(
    () => BecomeSellerUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ChangeAvatarUseCase>(
    () => ChangeAvatarUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetRolesUseCase>(
    () => GetRolesUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<RemoveAvatarUseCase>(
    () => RemoveAvatarUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetOnboardingUseCase>(
    () => GetOnboardingUseCase(getIt<OnboardingRepository>()),
  );
  getIt.registerLazySingleton<GetAddressesUseCase>(
    () => GetAddressesUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetPodologicalProfileUseCase>(
    () => GetPodologicalProfileUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ChangeOnboardingStepUseCase>(
    () => ChangeOnboardingStepUseCase(getIt<OnboardingRepository>()),
  );
  getIt.registerLazySingleton<GetCatalogItemsUseCase>(
    () => GetCatalogItemsUseCase(getIt<CatalogRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetCatalogFilterOptionsUseCase>(
    () => GetCatalogFilterOptionsUseCase(getIt<CatalogRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetProductDetailUseCase>(
    () => GetProductDetailUseCase(getIt<CatalogRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetRecommendedItemsUseCase>(
    () => GetRecommendedItemsUseCase(getIt<CatalogRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetMyAdsUseCase>(
    () => GetMyAdsUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ChangeAdStatusUseCase>(
    () => ChangeAdStatusUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<RemoveAdUseCase>(
    () => RemoveAdUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetAdUseCase>(
    () => GetAdUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<SaveAdUseCase>(
    () => SaveAdUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<AddAdImageUseCase>(
    () => AddAdImageUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<RemoveAdImageUseCase>(
    () => RemoveAdImageUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ReorderAdImagesUseCase>(
    () => ReorderAdImagesUseCase(getIt<SellerRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetCartUseCase>(
    () => GetCartUseCase(getIt<CartRepositoryInterface>()),
  );
  getIt.registerLazySingleton<AddToCartUseCase>(
    () => AddToCartUseCase(getIt<CartRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ChangeCartItemQuantityUseCase>(
    () => ChangeCartItemQuantityUseCase(getIt<CartRepositoryInterface>()),
  );
  getIt.registerLazySingleton<RemoveCartItemUseCase>(
    () => RemoveCartItemUseCase(getIt<CartRepositoryInterface>()),
  );
  getIt.registerLazySingleton<PreviewCheckoutUseCase>(
    () => PreviewCheckoutUseCase(getIt<CheckoutRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CheckoutUseCase>(
    () => CheckoutUseCase(getIt<CheckoutRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetOrdersUseCase>(
    () => GetOrdersUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetOrderUseCase>(
    () => GetOrderUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CancelOrderUseCase>(
    () => CancelOrderUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ConfirmDeliveryUseCase>(
    () => ConfirmDeliveryUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetSellerOrdersUseCase>(
    () => GetSellerOrdersUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetSellerOrderUseCase>(
    () => GetSellerOrderUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<StartProcessingUseCase>(
    () => StartProcessingUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ShipOrderUseCase>(
    () => ShipOrderUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<UploadPrescriptionUseCase>(
    () => UploadPrescriptionUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<RejectPrescriptionUseCase>(
    () => RejectPrescriptionUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<OpenDocumentUseCase>(
    () => OpenDocumentUseCase(getIt<OrderRepositoryInterface>()),
  );
  getIt.registerLazySingleton<HasPrescriptionConsentUseCase>(
    () => HasPrescriptionConsentUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GrantPrescriptionConsentUseCase>(
    () => GrantPrescriptionConsentUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateReviewUseCase>(
    () => CreateReviewUseCase(getIt<ReviewRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetProductReviewsUseCase>(
    () => GetProductReviewsUseCase(getIt<ReviewRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreatePaymentUseCase>(
    () => CreatePaymentUseCase(getIt<PaymentRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetPaymentsUseCase>(
    () => GetPaymentsUseCase(getIt<PaymentRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetNotificationsUseCase>(
    () => GetNotificationsUseCase(getIt<NotificationRepositoryInterface>()),
  );
  getIt.registerLazySingleton<MarkNotificationReadUseCase>(
    () => MarkNotificationReadUseCase(getIt<NotificationRepositoryInterface>()),
  );
  getIt.registerLazySingleton<MarkAllNotificationsReadUseCase>(
    () => MarkAllNotificationsReadUseCase(
      getIt<NotificationRepositoryInterface>(),
    ),
  );
}

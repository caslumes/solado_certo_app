import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:solado_certo_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:solado_certo_app/features/cart/domain/usecases/cart_use_cases.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/add_to_cart_cubit.dart';
import 'package:solado_certo_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_items_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_product_detail_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_recommended_items_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/become_seller_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/change_avatar_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/revoke_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_roles_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/remove_avatar_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/ad_images_use_cases.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/change_ad_status_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_my_ads_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/remove_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/save_ad_use_case.dart';

import 'builders.dart';

class MockAuthRepository extends Mock implements AuthRepositoryInterface {}

class MockProfileRepository extends Mock
    implements ProfileRepositoryInterface {}

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockGetAddressesUseCase extends Mock implements GetAddressesUseCase {}

class MockGetPodologicalProfileUseCase extends Mock
    implements GetPodologicalProfileUseCase {}

class MockSavePodologicalProfileUseCase extends Mock
    implements SavePodologicalProfileUseCase {}

class MockGetPainPointsUseCase extends Mock implements GetPainPointsUseCase {}

class MockHasPodologicalConsentUseCase extends Mock
    implements HasPodologicalConsentUseCase {}

class MockRevokePodologicalConsentUseCase extends Mock
    implements RevokePodologicalConsentUseCase {}

class MockChangeAvatarUseCase extends Mock implements ChangeAvatarUseCase {}

class MockRemoveAvatarUseCase extends Mock implements RemoveAvatarUseCase {}

class MockGetRolesUseCase extends Mock implements GetRolesUseCase {}

class MockBecomeSellerUseCase extends Mock implements BecomeSellerUseCase {}

class MockGetMyAdsUseCase extends Mock implements GetMyAdsUseCase {}

class MockChangeAdStatusUseCase extends Mock implements ChangeAdStatusUseCase {}

class MockRemoveAdUseCase extends Mock implements RemoveAdUseCase {}

class MockGetAdUseCase extends Mock implements GetAdUseCase {}

class MockSaveAdUseCase extends Mock implements SaveAdUseCase {}

class MockAddAdImageUseCase extends Mock implements AddAdImageUseCase {}

class MockRemoveAdImageUseCase extends Mock implements RemoveAdImageUseCase {}

class MockReorderAdImagesUseCase extends Mock
    implements ReorderAdImagesUseCase {}

class MockGetOnboardingUseCase extends Mock implements GetOnboardingUseCase {}

class MockChangeOnboardingStepUseCase extends Mock
    implements ChangeOnboardingStepUseCase {}

class MockCatalogRepository extends Mock
    implements CatalogRepositoryInterface {}

class MockGetCatalogItemsUseCase extends Mock
    implements GetCatalogItemsUseCase {}

class MockGetCatalogFilterOptionsUseCase extends Mock
    implements GetCatalogFilterOptionsUseCase {}

class MockGetProductDetailUseCase extends Mock
    implements GetProductDetailUseCase {}

class MockGetRecommendedItemsUseCase extends Mock
    implements GetRecommendedItemsUseCase {}

/// The home shell loads the "Para você" items through getIt when signed in.
MockGetRecommendedItemsUseCase registerRecommendedItems({
  List<CatalogItemEntity> items = const [],
}) {
  final useCase = MockGetRecommendedItemsUseCase();
  when(useCase.execute).thenAnswer((_) async => items);
  getIt.registerSingleton<GetRecommendedItemsUseCase>(useCase);
  return useCase;
}

/// The home shell loads the catalog filter options through getIt.
void registerCatalogFilterOptions() {
  final useCase = MockGetCatalogFilterOptionsUseCase();
  when(useCase.execute).thenAnswer((_) async => catalogFilterOptions);
  getIt.registerSingleton<GetCatalogFilterOptionsUseCase>(useCase);
  addTearDown(getIt.reset);
}

class MockCartRepository extends Mock implements CartRepositoryInterface {}

class MockGetCartUseCase extends Mock implements GetCartUseCase {}

class MockAddToCartUseCase extends Mock implements AddToCartUseCase {}

class MockChangeCartItemQuantityUseCase extends Mock
    implements ChangeCartItemQuantityUseCase {}

class MockRemoveCartItemUseCase extends Mock implements RemoveCartItemUseCase {}

class MockCartBloc extends MockBloc<CartEvent, CartState> implements CartBloc {}

class MockAddToCartCubit extends MockCubit<AddToCartState>
    implements AddToCartCubit {}

/// A cart bloc that stays in [state]; the app provides one above every page.
MockCartBloc buildCartBloc([CartState? state]) {
  final bloc = MockCartBloc();
  when(() => bloc.state).thenReturn(state ?? CartInactive());
  return bloc;
}

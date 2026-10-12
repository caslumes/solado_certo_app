import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_items_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/revoke_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';

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

class MockGetOnboardingUseCase extends Mock implements GetOnboardingUseCase {}

class MockChangeOnboardingStepUseCase extends Mock
    implements ChangeOnboardingStepUseCase {}

class MockCatalogRepository extends Mock
    implements CatalogRepositoryInterface {}

class MockGetCatalogItemsUseCase extends Mock
    implements GetCatalogItemsUseCase {}

class MockGetCatalogFilterOptionsUseCase extends Mock
    implements GetCatalogFilterOptionsUseCase {}

/// The home shell loads the catalog filter options through getIt.
void registerCatalogFilterOptions() {
  final useCase = MockGetCatalogFilterOptionsUseCase();
  when(useCase.execute).thenAnswer((_) async => catalogFilterOptions);
  getIt.registerSingleton<GetCatalogFilterOptionsUseCase>(useCase);
  addTearDown(getIt.reset);
}

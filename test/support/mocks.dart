import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';

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

class MockGetOnboardingUseCase extends Mock implements GetOnboardingUseCase {}

class MockChangeOnboardingStepUseCase extends Mock
    implements ChangeOnboardingStepUseCase {}

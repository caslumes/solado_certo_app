import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:solado_certo_app/core/network/api_client.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/api_auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/repositories/api_onboarding_repository.dart';
import 'package:solado_certo_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/change_onboarding_step_use_case.dart';
import 'package:solado_certo_app/features/onboarding/domain/usecases/get_onboarding_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/api_profile_repository.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

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
}

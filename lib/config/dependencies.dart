import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:solado_certo_app/common/network/api_client.dart';
import 'package:solado_certo_app/common/network/client.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/api_auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
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

  getIt.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(
      getIt<AuthRepositoryInterface>(),
      getIt<FlutterSecureStorage>(),
    ),
  );
  getIt.registerLazySingleton<GetProfileUseCase>(
    () => GetProfileUseCase(getIt<ProfileRepositoryInterface>()),
  );
  getIt.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(
      repository: getIt<AuthRepositoryInterface>(),
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );
}

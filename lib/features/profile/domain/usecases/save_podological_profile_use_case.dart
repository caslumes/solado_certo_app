import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class SavePodologicalProfileUseCase {
  final ProfileRepositoryInterface profileRepository;

  SavePodologicalProfileUseCase(this.profileRepository);

  Future<PodologicalProfileEntity> execute(
    PodologicalProfileUpdate update,
  ) async {
    await profileRepository.grantConsent(
      ConsentPurposes.podologicalProfile,
      ConsentTermsVersions.podologicalProfile,
    );
    return await profileRepository.savePodologicalProfile(update);
  }
}

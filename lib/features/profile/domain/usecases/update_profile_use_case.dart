import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepositoryInterface profileRepository;

  UpdateProfileUseCase(this.profileRepository);

  Future<ProfileEntity> execute(ProfileEntity profile) async {
    return await profileRepository.updateProfile(profile);
  }
}

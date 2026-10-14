import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class RemoveAvatarUseCase {
  final ProfileRepositoryInterface profileRepository;

  RemoveAvatarUseCase(this.profileRepository);

  Future<ProfileEntity> execute() async {
    return await profileRepository.removeAvatar();
  }
}

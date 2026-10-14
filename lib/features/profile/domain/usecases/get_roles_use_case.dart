import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class GetRolesUseCase {
  final ProfileRepositoryInterface profileRepository;

  GetRolesUseCase(this.profileRepository);

  Future<List<UserRole>> execute() async {
    return await profileRepository.getRoles();
  }
}

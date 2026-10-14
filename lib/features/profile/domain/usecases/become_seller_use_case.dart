import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class BecomeSellerUseCase {
  final ProfileRepositoryInterface profileRepository;

  BecomeSellerUseCase(this.profileRepository);

  Future<List<UserRole>> execute() async {
    return await profileRepository.becomeSeller();
  }
}

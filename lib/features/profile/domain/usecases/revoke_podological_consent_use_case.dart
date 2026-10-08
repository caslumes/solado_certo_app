import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class RevokePodologicalConsentUseCase {
  final ProfileRepositoryInterface profileRepository;

  RevokePodologicalConsentUseCase(this.profileRepository);

  Future<void> execute() async {
    await profileRepository.revokeConsent(ConsentPurposes.podologicalProfile);
  }
}

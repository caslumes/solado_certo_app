import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class HasCustomOrderConsentUseCase {
  final ProfileRepositoryInterface profileRepository;

  HasCustomOrderConsentUseCase(this.profileRepository);

  Future<bool> execute() async {
    final consents = await profileRepository.getConsents();
    return consents.any(
      (consent) =>
          consent.purpose == ConsentPurposes.customOrder &&
          consent.termsVersion == ConsentTermsVersions.customOrder,
    );
  }
}

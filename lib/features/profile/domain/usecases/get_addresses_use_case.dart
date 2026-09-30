import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class GetAddressesUseCase {
  final ProfileRepositoryInterface _profileRepository;

  GetAddressesUseCase(this._profileRepository);

  Future<List<AddressEntity>> execute() async {
    return await _profileRepository.getAddresses();
  }
}

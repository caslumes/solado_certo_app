import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';

Map<String, dynamic> newAddressToJson(NewAddress address) => {
  'label': address.label,
  'receiver': address.receiver,
  'zip_code': address.zipCode,
  'street': address.street,
  'number': address.number,
  'complement': address.complement,
  'district': address.district,
  'city': address.city,
  'state': address.state,
  'country': address.country,
  'is_default': address.isDefault,
};

class AddressModel {
  const AddressModel({
    required this.id,
    this.label,
    required this.receiver,
    required this.zipCode,
    required this.street,
    required this.number,
    this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.country,
    required this.isDefault,
  });

  final String id;
  final String? label;
  final String receiver;
  final String zipCode;
  final String street;
  final String number;
  final String? complement;
  final String district;
  final String city;
  final String state;
  final String country;
  final bool isDefault;

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'] as String,
    label: json['label'] as String?,
    receiver: json['receiver'] as String,
    zipCode: json['zip_code'] as String,
    street: json['street'] as String,
    number: json['number'] as String,
    complement: json['complement'] as String?,
    district: json['district'] as String,
    city: json['city'] as String,
    state: json['state'] as String,
    country: json['country'] as String,
    isDefault: json['is_default'] as bool? ?? false,
  );

  AddressEntity toEntity() => AddressEntity(
    id: id,
    label: label,
    receiver: receiver,
    zipCode: zipCode,
    street: street,
    number: number,
    complement: complement,
    district: district,
    city: city,
    state: state,
    country: country,
    isDefault: isDefault,
  );
}

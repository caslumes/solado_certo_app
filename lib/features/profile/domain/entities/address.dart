class AddressEntity {
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

  AddressEntity({
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

  factory AddressEntity.fromJson(Map<String, dynamic> json) {
    return AddressEntity(
      id: json['id'],
      label: json['label'],
      receiver: json['receiver'],
      zipCode: json['zip_code'],
      street: json['street'],
      number: json['number'],
      complement: json['complement'],
      district: json['district'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'receiver': receiver,
      'zip_code': zipCode,
      'street': street,
      'number': number,
      'complement': complement,
      'district': district,
      'city': city,
      'state': state,
      'country': country,
      'is_default': isDefault,
    };
  }
}

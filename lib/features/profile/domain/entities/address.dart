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
}

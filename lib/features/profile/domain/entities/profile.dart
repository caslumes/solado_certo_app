class ProfileEntity {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;

  /// Whether the CPF was given; it is asked only before the first payment.
  final bool hasTaxId;

  ProfileEntity({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.hasTaxId = false,
  });

  ProfileEntity copyWith({String? name, String? phone}) => ProfileEntity(
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl,
    hasTaxId: hasTaxId,
  );
}

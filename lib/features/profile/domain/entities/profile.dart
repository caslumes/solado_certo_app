class ProfileEntity {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;

  ProfileEntity({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
  });

  ProfileEntity copyWith({String? name, String? phone}) => ProfileEntity(
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl,
  );
}

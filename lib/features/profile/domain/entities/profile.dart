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

  factory ProfileEntity.fromJson(Map<String, dynamic> json) {
    return ProfileEntity(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }
}

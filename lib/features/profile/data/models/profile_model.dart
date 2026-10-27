import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

Map<String, dynamic> profileToJson(ProfileEntity profile) => {
  'name': profile.name,
  'email': profile.email,
  'phone': profile.phone,
};

class ProfileModel {
  const ProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.hasTaxId = false,
  });

  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final bool hasTaxId;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    avatarUrl: json['avatar_url'] as String,
    hasTaxId: json['has_tax_id'] as bool? ?? false,
  );

  ProfileEntity toEntity() => ProfileEntity(
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    hasTaxId: hasTaxId,
  );
}

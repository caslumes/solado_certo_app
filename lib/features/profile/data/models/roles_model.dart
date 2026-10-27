import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';

List<UserRole> rolesFromJson(Map<String, dynamic> json) => [
  for (final value in json['roles'] as List)
    if (UserRole.fromApi(value as String) case final role?) role,
];

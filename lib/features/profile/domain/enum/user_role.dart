enum UserRole {
  buyer,
  seller,
  admin;

  static UserRole? fromApi(String? value) {
    for (final role in values) {
      if (role.name == value) return role;
    }
    return null;
  }
}

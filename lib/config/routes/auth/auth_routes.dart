import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';

class AuthRoutes {
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';

  static Map<String, WidgetBuilder> get routes => {
    signIn: (context) => const SignInPage(),
  };
}

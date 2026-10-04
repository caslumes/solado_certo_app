import 'package:flutter/widgets.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/onboarding/presentation/routes/onboarding_routes.dart';

final appRoutes = <String, WidgetBuilder>{
  ...AuthRoutes.routes,
  ...OnboardingRoutes.routes,
};

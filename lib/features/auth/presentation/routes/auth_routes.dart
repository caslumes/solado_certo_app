import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/request_password_reset_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/password_recovery_cubit.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/sign_up_page.dart';

class AuthRoutes {
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  static Map<String, WidgetBuilder> get routes => {
    signIn: (context) => const SignInPage(),
    signUp: (context) => const SignUpPage(),
    forgotPassword: (context) => BlocProvider(
      create: (_) => PasswordRecoveryCubit(
        requestPasswordResetUseCase: getIt<RequestPasswordResetUseCase>(),
        resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
      ),
      child: const ForgotPasswordPage(),
    ),
  };
}

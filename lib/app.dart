import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/config/dependencies.dart';
import 'package:solado_certo_app/config/routes/auth/auth_routes.dart';
import 'package:solado_certo_app/config/theme/app_themes.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:solado_certo_app/features/auth/presentation/pages/auth_gate.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(
        signInUseCase: getIt<SignInUseCase>(),
        getProfileUseCase: getIt<GetProfileUseCase>(),
        signOutUseCase: getIt<SignOutUseCase>(),
        signUpUseCase: getIt<SignUpUseCase>(),
      )..add(CheckAuthEvent()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: primaryTheme,
        home: const AuthGate(),
        routes: {...AuthRoutes.routes},
      ),
    );
  }
}

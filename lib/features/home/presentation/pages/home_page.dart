import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/revoke_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/my_profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.isSignedIn});

  final bool isSignedIn;

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(
            getProfileUseCase: getIt<GetProfileUseCase>(),
            updateProfileUseCase: getIt<UpdateProfileUseCase>(),
            getAddressesUseCase: getIt<GetAddressesUseCase>(),
            getPodologicalProfileUseCase: getIt<GetPodologicalProfileUseCase>(),
            savePodologicalProfileUseCase:
                getIt<SavePodologicalProfileUseCase>(),
            getPainPointsUseCase: getIt<GetPainPointsUseCase>(),
            hasPodologicalConsentUseCase: getIt<HasPodologicalConsentUseCase>(),
            revokePodologicalConsentUseCase:
                getIt<RevokePodologicalConsentUseCase>(),
          )..add(LoadProfileEvent()),
          child: const MyProfilePage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const userImage = Image(
      image: AssetImage('assets/images/user.png'),
      width: 70,
    );

    return Scaffold(
      body: Column(
        spacing: 16.0,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Image(
                  image: const AssetImage('assets/images/logo.png'),
                  width: MediaQuery.of(context).size.width * 0.5,
                ),
                const Spacer(),
                isSignedIn
                    ? IconButton(
                        tooltip: 'Meu perfil',
                        onPressed: () => _openProfile(context),
                        icon: userImage,
                      )
                    : InkWell(
                        onTap: () =>
                            Navigator.of(context).pushNamed(AuthRoutes.signIn),
                        child: Column(
                          spacing: 8.0,
                          children: [
                            userImage,
                            Text(
                              'Entre na sua conta',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          Container(color: AppColors.primaryColor, height: 5),
          if (isSignedIn)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ShoeTextButton(
                text: 'Sair',
                onPressed: () => context.read<AuthBloc>().add(SignOutEvent()),
              ),
            ),
        ],
      ),
    );
  }
}

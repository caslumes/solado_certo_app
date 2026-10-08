import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
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
  const HomePage({super.key});

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
    final authBloc = BlocProvider.of<AuthBloc>(context);

    return Scaffold(
      body: Column(
        spacing: 16.0,
        children: [
          ShoeTextButton(
            text: "Meu perfil",
            onPressed: () => _openProfile(context),
          ),
          ShoeTextButton(
            text: "Sair",
            onPressed: () {
              authBloc.add(SignOutEvent());
            },
          ),
        ],
      ),
    );
  }
}

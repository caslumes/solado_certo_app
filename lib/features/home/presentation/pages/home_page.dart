import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/common/components/shoe_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);

    return Scaffold(
      body: ShoeButton(
        text: "Sair",
        onPressed: () {
          authBloc.add(SignOutEvent());
        },
      ),
    );
  }
}

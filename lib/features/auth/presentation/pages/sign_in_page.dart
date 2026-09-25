import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/common/components/form/shoe_text_form_field.dart';
import 'package:solado_certo_app/common/components/shoe_button.dart';
import 'package:solado_certo_app/common/components/shoe_hypertext.dart';
import 'package:solado_certo_app/config/theme/app_colors.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late SignInUseCase useCase;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AuthBloc>(context);
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
            child: Image(
              image: AssetImage('assets/images/logo.png'),
              width: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          Container(color: AppColors.primaryColor, height: 5),
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Text(
                    'Entrar na sua conta'.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Form(
            key: _formKey,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                spacing: 25,
                children: [
                  ShoeTextFormField(
                    hintText: 'email@exemplo.com',
                    controller: _emailController,
                  ),
                  ShoeTextFormField(
                    hintText: 'senha',
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  ShoeButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final email = _emailController.text;
                        final password = _passwordController.text;

                        bloc.add(SignInEvent(email: email, password: password));
                      }
                    },
                    text: 'Entrar',
                    textStyle: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                Text(
                  'Já tem uma conta?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                ShoeHypertext(text: 'Cadastre-se', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          Center(child: Image(image: AssetImage('assets/images/logo.png'))),
          Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

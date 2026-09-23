import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/splash/presentation/pages/splash_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {'/': (context) => SplashPage()},
    );
  }
}

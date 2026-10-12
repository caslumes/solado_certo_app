import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/app.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFormatting();
  configureDependencies();
}

Future<void> main() async {
  await initializeApp();
  runApp(const App());
}

import 'package:flutter/material.dart';
import 'package:solado_certo_app/app.dart';
import 'package:solado_certo_app/core/config/dependencies.dart';

void initializeApp() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
}

void main() {
  initializeApp();
  runApp(const App());
}

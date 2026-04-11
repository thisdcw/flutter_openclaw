import 'package:flutter/material.dart';
import 'src/app/app_dependencies.dart';
import 'src/app/openclaw_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.create();
  runApp(OpenClawApp(dependencies: dependencies));
}

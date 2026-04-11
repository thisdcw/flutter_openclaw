import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'app_theme.dart';
import '../presentation/screens/settings_screen.dart';

class OpenClawApp extends StatelessWidget {
  const OpenClawApp({
    super.key,
    required this.dependencies,
  });

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenClaw',
      theme: buildAppTheme(),
      home: SettingsScreen(
        settingsController: dependencies.settingsController,
        connectionController: dependencies.connectionController,
        chatController: dependencies.chatController,
      ),
    );
  }
}

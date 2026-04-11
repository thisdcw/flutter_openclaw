import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'app_theme.dart';
import '../presentation/screens/chat_screen.dart';

class OpenClawApp extends StatelessWidget {
  const OpenClawApp({
    super.key,
    required this.dependencies,
  });

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OpenClaw',
      theme: buildAppTheme(),
      home: ChatScreen(
        settingsController: dependencies.settingsController,
        connectionController: dependencies.connectionController,
        chatController: dependencies.chatController,
      ),
    );
  }
}

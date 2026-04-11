import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/app/openclaw_app.dart';
import 'package:flutter_openclaw/src/app/app_dependencies.dart';
import 'package:flutter_openclaw/src/presentation/screens/chat_screen.dart';

void main() {
  testWidgets('settings screen shows config fields and reset actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(OpenClawApp(dependencies: AppDependencies.fake()));

    expect(find.text('Gateway URL'), findsOneWidget);
    expect(find.text('Auth Token'), findsOneWidget);
    expect(find.text('Reset Device Identity'), findsOneWidget);
  });

  testWidgets('chat composer is disabled when operator.write is missing',
      (WidgetTester tester) async {
    final connectionController = ConnectionController.fake()
      ..phase = 'ready'
      ..grantedScopes = ['operator.read'];
    final chatController = ChatController.fake();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatController: chatController,
          connectionController: connectionController,
        ),
      ),
    );

    expect(find.text('missing scope: operator.write'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/app/openclaw_app.dart';
import 'package:flutter_openclaw/src/app/app_dependencies.dart';
import 'package:flutter_openclaw/src/presentation/screens/chat_screen.dart';

void main() {
  testWidgets('chat screen is the home view', (WidgetTester tester) async {
    await tester.pumpWidget(OpenClawApp(dependencies: AppDependencies.fake()));

    expect(find.text('Cici'), findsOneWidget);
  });

  testWidgets('failed connection shows strip and Connection button',
      (WidgetTester tester) async {
    final connectionController = ConnectionController.fake()
      ..markFailed('Gateway unavailable');
    final chatController = ChatController.fake();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatController: chatController,
          connectionController: connectionController,
        ),
      ),
    );

    expect(find.text('Gateway unavailable'), findsOneWidget);
    expect(
      find.text('Check your gateway settings and tap Connection to retry.'),
      findsOneWidget,
    );
    expect(find.text('Connection'), findsOneWidget);
  });

  testWidgets('connecting state shows strip text and no Connection button',
      (WidgetTester tester) async {
    final connectionController = ConnectionController.fake()..markConnecting();
    final chatController = ChatController.fake();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatController: chatController,
          connectionController: connectionController,
        ),
      ),
    );

    expect(find.text('Connecting to gateway…'), findsOneWidget);
    expect(find.text('Connection'), findsNothing);
  });

  testWidgets('ready but blocked shows reason and no Connection button',
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
    expect(find.text('Connection'), findsNothing);
  });
}

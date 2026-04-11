import 'package:flutter/material.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../domain/models/gateway_config.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import 'chat_screen.dart';
import '../widgets/connection_summary_card.dart';
import '../widgets/settings_form.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settingsController,
    required this.connectionController,
    required this.chatController,
  });

  final SettingsController settingsController;
  final ConnectionController connectionController;
  final ChatController chatController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController gatewayUrlController;
  late final TextEditingController authTokenController;
  late final TextEditingController sessionIdController;
  late final TextEditingController localeController;
  late final TextEditingController timeoutController;

  @override
  void initState() {
    super.initState();
    final config = widget.settingsController.config;
    gatewayUrlController = TextEditingController(text: config.gatewayUrl);
    authTokenController = TextEditingController(text: config.authToken);
    sessionIdController = TextEditingController(text: config.sessionId);
    localeController = TextEditingController(text: config.locale);
    timeoutController = TextEditingController(text: '${config.timeoutMs}');
  }

  @override
  void dispose() {
    gatewayUrlController.dispose();
    authTokenController.dispose();
    sessionIdController.dispose();
    localeController.dispose();
    timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionController = widget.connectionController;
    final deviceId = connectionController.status.deviceId ?? 'pending-device';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'OpenClaw Gateway',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ConnectionSummaryCard(
              phase: connectionController.phase,
              deviceId: deviceId,
              scopes: connectionController.grantedScopes,
            ),
            if ((connectionController.errorMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(connectionController.errorMessage!),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SettingsForm(
              gatewayUrlController: gatewayUrlController,
              authTokenController: authTokenController,
              sessionIdController: sessionIdController,
              localeController: localeController,
              timeoutController: timeoutController,
              onSave: _saveSettings,
              onTestConnection: _testConnection,
              onClearDeviceToken: _clearDeviceToken,
              onResetDeviceIdentity: _resetDeviceIdentity,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _openChat,
                child: const Text('Open Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final current = widget.settingsController.config;
    final timeoutMs =
        int.tryParse(timeoutController.text.trim()) ?? current.timeoutMs;
    final next = GatewayConfig(
      gatewayUrl: gatewayUrlController.text.trim(),
      authToken: authTokenController.text.trim(),
      sessionId: sessionIdController.text.trim(),
      timeoutMs: timeoutMs,
      locale: localeController.text.trim(),
    );

    openClawLog(
      'SettingsScreen',
      'save tapped',
      fields: <String, Object?>{
        'gatewayUrl': next.gatewayUrl,
        'sessionId': next.sessionId,
        'timeoutMs': next.timeoutMs,
        'locale': next.locale,
        'authToken': redactValue(next.authToken),
      },
    );
    await widget.settingsController.save(next);
  }

  Future<void> _testConnection() async {
    openClawLog('SettingsScreen', 'test connection tapped');
    await _saveSettings();
    await widget.connectionController.testConnection();
  }

  Future<void> _clearDeviceToken() async {
    openClawLog('SettingsScreen', 'clear device token tapped');
    await widget.settingsController.clearDeviceToken();
    widget.connectionController.reset(
      deviceId: widget.connectionController.status.deviceId,
    );
  }

  Future<void> _resetDeviceIdentity() async {
    openClawLog('SettingsScreen', 'reset device identity tapped');
    await widget.settingsController.resetDeviceIdentity();
    widget.connectionController.reset();
  }

  void _openChat() {
    openClawLog(
      'SettingsScreen',
      'open chat tapped',
      fields: <String, Object?>{
        'phase': widget.connectionController.phase,
        'canSend': widget.connectionController.canSend,
      },
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          chatController: widget.chatController,
          connectionController: widget.connectionController,
        ),
      ),
    );
  }
}

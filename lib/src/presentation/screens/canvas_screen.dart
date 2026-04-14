import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../application/use_cases/send_canvas_user_action_use_case.dart';
import '../../domain/models/gateway_config.dart';
import '../../infrastructure/util/openclaw_logger.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({
    super.key,
    required this.initialCanvasHostUrl,
    required this.configProvider,
    required this.sendCanvasUserActionUseCase,
    this.canvasCapability,
  });

  final String initialCanvasHostUrl;
  final GatewayConfig Function() configProvider;
  final SendCanvasUserActionUseCase sendCanvasUserActionUseCase;
  final String? canvasCapability;

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  late final WebViewController webViewController;
  final List<_CanvasLogEntry> logs = <_CanvasLogEntry>[];
  bool helperInjected = false;
  bool actionInFlight = false;
  String? currentPageUrl;

  @override
  void initState() {
    super.initState();
    final hostUrl = widget.initialCanvasHostUrl.trim();
    currentPageUrl = hostUrl;
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'openclawCanvasA2UIAction',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            helperInjected = false;
            setState(() {
              currentPageUrl = url;
            });
            _appendLog(
              level: _CanvasLogLevel.info,
              message: 'Canvas page loading: $url',
            );
          },
          onPageFinished: (url) async {
            setState(() {
              currentPageUrl = url;
            });
            _appendLog(
              level: _CanvasLogLevel.success,
              message: 'Canvas page ready: $url',
            );
            await _injectOpenclawSendUserActionHelper();
          },
          onWebResourceError: (error) {
            _appendLog(
              level: _CanvasLogLevel.error,
              message:
                  'WebView error(${error.errorCode}): ${error.description}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(hostUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenClaw Canvas'),
        actions: [
          IconButton(
            onPressed: actionInFlight ? null : _sendSmokeTestAction,
            icon: const Icon(Icons.play_circle_outline_rounded),
            tooltip: 'Send smoke test action',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CanvasStatusBar(
              currentPageUrl: currentPageUrl ?? '(none)',
              helperInjected: helperInjected,
              actionInFlight: actionInFlight,
            ),
            Expanded(
              child: WebViewWidget(
                controller: webViewController,
              ),
            ),
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1628),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.35),
                  ),
                ),
              ),
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Canvas log is empty',
                        style: TextStyle(color: Color(0xFFB7C0D4)),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final entry = logs[logs.length - 1 - index];
                        final color = switch (entry.level) {
                          _CanvasLogLevel.info => const Color(0xFFB7C0D4),
                          _CanvasLogLevel.success => const Color(0xFF8CF6C8),
                          _CanvasLogLevel.error => const Color(0xFFFFA6A6),
                        };
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
                          child: Text(
                            '[${entry.time}] ${entry.message}',
                            style: TextStyle(
                              color: color,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBridgeMessage(JavaScriptMessage message) async {
    final payload = _decodeStructuredPayload(message.message);
    if (payload == null) {
      _appendLog(
        level: _CanvasLogLevel.error,
        message: 'Ignored non-structured bridge message',
      );
      return;
    }
    final userAction = Map<String, dynamic>.from(payload['userAction'] as Map);
    final actionId = userAction['id'] as String;
    _appendLog(
      level: _CanvasLogLevel.info,
      message:
          'recv userAction id=$actionId name=${userAction['name']} source=${userAction['sourceComponentId'] ?? '(none)'}',
    );
    if (mounted) {
      setState(() {
        actionInFlight = true;
      });
    }
    final result = await widget.sendCanvasUserActionUseCase.call(
      config: widget.configProvider(),
      payload: payload,
      canvasCapability: widget.canvasCapability,
    );
    final statusMessage = result.ok
        ? 'sent userAction id=${result.actionId} method=${result.method}'
        : 'send failed id=${result.actionId} error=${result.error}';
    _appendLog(
      level: result.ok ? _CanvasLogLevel.success : _CanvasLogLevel.error,
      message: statusMessage,
    );
    await _dispatchActionStatus(
      id: result.actionId,
      ok: result.ok,
      error: result.error,
    );
    if (mounted) {
      setState(() {
        actionInFlight = false;
      });
    }
  }

  Future<void> _injectOpenclawSendUserActionHelper() async {
    if (helperInjected) {
      return;
    }
    const helperScript = '''
(() => {
  if (window.__openclawCanvasHelperInstalled === true) {
    return;
  }
  window.__openclawCanvasHelperInstalled = true;
  const iosBridge = window.webkit &&
    window.webkit.messageHandlers &&
    window.webkit.messageHandlers.openclawCanvasA2UIAction;
  if (!window.openclawCanvasA2UIAction &&
      iosBridge &&
      typeof iosBridge.postMessage === 'function') {
    window.openclawCanvasA2UIAction = {
      postMessage: (message) => iosBridge.postMessage(message),
    };
  }
  const resolveBridge = () => {
    if (window.openclawCanvasA2UIAction &&
        typeof window.openclawCanvasA2UIAction.postMessage === 'function') {
      return window.openclawCanvasA2UIAction;
    }
    if (iosBridge && typeof iosBridge.postMessage === 'function') {
      return iosBridge;
    }
    return null;
  };
  if (typeof window.openclawSendUserAction !== 'function') {
    window.openclawSendUserAction = (input) => {
      const bridge = resolveBridge();
      if (!bridge) {
        throw new Error('openclawCanvasA2UIAction bridge missing');
      }
      let payload = input;
      if (typeof payload === 'string') {
        payload = JSON.parse(payload);
      }
      if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
        throw new Error('openclawSendUserAction requires structured object payload');
      }
      const root = payload.userAction ? payload : { userAction: payload };
      const userAction = root.userAction;
      if (!userAction || typeof userAction !== 'object' || Array.isArray(userAction)) {
        throw new Error('payload.userAction is required');
      }
      if (typeof userAction.id !== 'string' || userAction.id.trim() === '') {
        throw new Error('userAction.id is required');
      }
      if (typeof userAction.name !== 'string' || userAction.name.trim() === '') {
        throw new Error('userAction.name is required');
      }
      bridge.postMessage(JSON.stringify({ userAction }));
      return userAction.id;
    };
  }
})();
''';
    try {
      await webViewController.runJavaScript(helperScript);
      helperInjected = true;
      _appendLog(
        level: _CanvasLogLevel.success,
        message:
            'Helper ready: window.openclawSendUserAction + openclawCanvasA2UIAction',
      );
    } catch (error) {
      _appendLog(
        level: _CanvasLogLevel.error,
        message: 'Inject helper failed: $error',
      );
    }
  }

  Map<String, dynamic>? _decodeStructuredPayload(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);
      final userActionRaw = map['userAction'] is Map ? map['userAction'] : map;
      if (userActionRaw is! Map) {
        return null;
      }
      final userAction = Map<String, dynamic>.from(userActionRaw);
      final actionId = userAction['id'];
      final actionName = userAction['name'];
      if (actionId is! String || actionId.trim().isEmpty) {
        return null;
      }
      if (actionName is! String || actionName.trim().isEmpty) {
        return null;
      }
      return <String, dynamic>{'userAction': userAction};
    } catch (error) {
      openClawLog(
        'CanvasScreen',
        'bridge message decode failed',
        fields: <String, Object?>{
          'error': error.toString(),
          'raw': message,
        },
      );
      return null;
    }
  }

  Future<void> _dispatchActionStatus({
    required String id,
    required bool ok,
    String? error,
  }) async {
    final detail = jsonEncode(
      <String, Object?>{
        'id': id,
        'ok': ok,
        'error': error,
      },
    );
    final script = '''
(() => {
  const detail = $detail;
  window.dispatchEvent(new CustomEvent('openclaw:a2ui-action-status', {
    detail,
  }));
})();
''';
    try {
      await webViewController.runJavaScript(script);
    } catch (dispatchError) {
      _appendLog(
        level: _CanvasLogLevel.error,
        message: 'dispatch openclaw:a2ui-action-status failed: $dispatchError',
      );
    }
  }

  Future<void> _sendSmokeTestAction() async {
    final actionId = 'a2ui_smoke_${DateTime.now().millisecondsSinceEpoch}';
    final payload = <String, dynamic>{
      'userAction': <String, Object?>{
        'id': actionId,
        'name': 'flutter.canvas.smoke_test',
        'surfaceId': 'flutter.canvas',
        'sourceComponentId': 'flutter.host.toolbar',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'context': <String, Object?>{
          'kind': 'manual-smoke-test',
        },
      },
    };
    _appendLog(
      level: _CanvasLogLevel.info,
      message: 'smoke test trigger id=$actionId',
    );
    if (mounted) {
      setState(() {
        actionInFlight = true;
      });
    }
    final result = await widget.sendCanvasUserActionUseCase.call(
      config: widget.configProvider(),
      payload: payload,
      canvasCapability: widget.canvasCapability,
    );
    _appendLog(
      level: result.ok ? _CanvasLogLevel.success : _CanvasLogLevel.error,
      message: result.ok
          ? 'smoke test sent method=${result.method}'
          : 'smoke test failed: ${result.error}',
    );
    await _dispatchActionStatus(
      id: result.actionId,
      ok: result.ok,
      error: result.error,
    );
    if (mounted) {
      setState(() {
        actionInFlight = false;
      });
    }
  }

  void _appendLog({
    required _CanvasLogLevel level,
    required String message,
  }) {
    if (!mounted) {
      return;
    }
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      logs.add(
        _CanvasLogEntry(
          level: level,
          message: message,
          time: time,
        ),
      );
      if (logs.length > 120) {
        logs.removeRange(0, logs.length - 120);
      }
    });
  }
}

class _CanvasStatusBar extends StatelessWidget {
  const _CanvasStatusBar({
    required this.currentPageUrl,
    required this.helperInjected,
    required this.actionInFlight,
  });

  final String currentPageUrl;
  final bool helperInjected;
  final bool actionInFlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F8FF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'canvasHostUrl: $currentPageUrl',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'bridge helper: ${helperInjected ? 'ready' : 'injecting...'} | action state: ${actionInFlight ? 'sending' : 'idle'}',
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF415A8B),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CanvasLogLevel {
  info,
  success,
  error,
}

class _CanvasLogEntry {
  const _CanvasLogEntry({
    required this.level,
    required this.message,
    required this.time,
  });

  final _CanvasLogLevel level;
  final String message;
  final String time;
}

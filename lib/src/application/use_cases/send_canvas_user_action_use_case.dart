import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/models/gateway_config.dart';
import '../../infrastructure/gateway/gateway_protocol_parser.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import 'test_connection_use_case.dart';

class CanvasUserActionDispatchResult {
  const CanvasUserActionDispatchResult({
    required this.ok,
    required this.actionId,
    this.method,
    this.error,
  });

  final bool ok;
  final String actionId;
  final String? method;
  final String? error;

  static CanvasUserActionDispatchResult success({
    required String actionId,
    required String method,
  }) {
    return CanvasUserActionDispatchResult(
      ok: true,
      actionId: actionId,
      method: method,
    );
  }

  static CanvasUserActionDispatchResult failed({
    required String actionId,
    String? method,
    required String error,
  }) {
    return CanvasUserActionDispatchResult(
      ok: false,
      actionId: actionId,
      method: method,
      error: error,
    );
  }
}

class SendCanvasUserActionUseCase {
  SendCanvasUserActionUseCase(
    this._testConnectionUseCase, {
    GatewayProtocolParser? parser,
    Uuid? uuid,
  })  : _parser = parser ?? const GatewayProtocolParser(),
        _uuid = uuid ?? const Uuid();

  static const List<String> _methodCandidates = <String>[
    'node.canvas.user_action.send',
    'node.canvas.user_action',
    'node.canvas.userAction.send',
    'node.canvas.userAction',
  ];

  final TestConnectionUseCase _testConnectionUseCase;
  final GatewayProtocolParser _parser;
  final Uuid _uuid;

  Future<CanvasUserActionDispatchResult> call({
    required GatewayConfig config,
    required Map<String, dynamic> payload,
    String? canvasCapability,
  }) async {
    final userAction = _safeObject(payload['userAction']);
    final actionId = _safeString(userAction?['id']) ??
        'a2ui-unknown-${DateTime.now().millisecondsSinceEpoch}';
    if (userAction == null) {
      return CanvasUserActionDispatchResult.failed(
        actionId: actionId,
        error: 'payload.userAction is required',
      );
    }

    final session = await _testConnectionUseCase.connect(config: config);
    try {
      String? fallbackError;
      for (final method in _methodCandidates) {
        final requestId = 'canvas-action-${_uuid.v4()}';
        openClawLog(
          'CanvasAction',
          'dispatch userAction',
          fields: <String, Object?>{
            'requestId': requestId,
            'method': method,
            'actionId': actionId,
          },
        );
        session.client.send(
          <String, Object?>{
            'type': 'req',
            'id': requestId,
            'method': method,
            'params': <String, Object?>{
              'userAction': userAction,
              if (canvasCapability != null && canvasCapability.trim().isNotEmpty)
                'canvasCapability': canvasCapability.trim(),
            },
          },
        );

        final response = await session.client.frames
            .firstWhere((frame) => frame.type == 'res' && frame.id == requestId)
            .timeout(Duration(milliseconds: config.timeoutMs));
        final failure = _parser.extractFailure(response);
        if (failure != null) {
          final message = failure.message;
          if (_responseMayBeUnsupported(message)) {
            fallbackError = message;
            continue;
          }
          return CanvasUserActionDispatchResult.failed(
            actionId: actionId,
            method: method,
            error: message,
          );
        }
        final status = _safeString(response.payload['status'])?.toLowerCase();
        if (status == 'error') {
          final message = _safeString(response.payload['message']) ??
              'node canvas action response error';
          if (_responseMayBeUnsupported(message)) {
            fallbackError = message;
            continue;
          }
          return CanvasUserActionDispatchResult.failed(
            actionId: actionId,
            method: method,
            error: message,
          );
        }
        return CanvasUserActionDispatchResult.success(
          actionId: actionId,
          method: method,
        );
      }
      return CanvasUserActionDispatchResult.failed(
        actionId: actionId,
        error: fallbackError ?? 'no supported node canvas action method',
      );
    } on TimeoutException {
      return CanvasUserActionDispatchResult.failed(
        actionId: actionId,
        error: 'node canvas action request timeout',
      );
    } catch (error) {
      return CanvasUserActionDispatchResult.failed(
        actionId: actionId,
        error: error.toString(),
      );
    } finally {
      await session.dispose();
    }
  }

  static bool _responseMayBeUnsupported(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('method not found') ||
        normalized.contains('unknown method') ||
        normalized.contains('not implemented') ||
        normalized.contains('unsupported method');
  }

  static Map<String, dynamic>? _safeObject(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _safeString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }
}

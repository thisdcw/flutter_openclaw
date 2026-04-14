import 'package:flutter/foundation.dart';

import '../models/app_error_notice.dart';
import 'app_error_controller.dart';
import '../../domain/models/canvas_capability_snapshot.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/gateway_failure.dart';
import '../../domain/models/gateway_config.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/test_connection_use_case.dart';
import '../../infrastructure/util/failure_mapper.dart';

class ConnectionController extends ChangeNotifier {
  ConnectionController({
    ConnectionStatus? initialStatus,
    TestConnectionUseCase? testConnectionUseCase,
    GatewayConfig Function()? configProvider,
    AppErrorController? appErrorController,
    bool isStub = false,
  })  : _status =
            initialStatus ?? const ConnectionStatus(phase: ConnectionPhase.idle),
        _testConnectionUseCase = testConnectionUseCase,
        _configProvider = configProvider,
        _appErrorController = appErrorController,
        _isStub = isStub;

  factory ConnectionController.fake() => ConnectionController(isStub: true);

  ConnectionStatus _status;
  final TestConnectionUseCase? _testConnectionUseCase;
  final GatewayConfig Function()? _configProvider;
  final AppErrorController? _appErrorController;
  final bool _isStub;
  bool _autoConnectInFlight = false;
  bool _autoConnectSucceeded = false;
  AppErrorNotice? errorNotice;

  bool get isStub => _isStub;

  String get phase => _status.phase.value;

  set phase(String value) {
    try {
      _status = _status.copyWith(
        phase: ConnectionPhase.fromValue(value),
      );
      notifyListeners();
    } on FormatException catch (error, stackTrace) {
      openClawLog(
        'ConnectionController',
        'phase update ignored: unsupported value',
        fields: <String, Object?>{
          'value': value,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  List<String> get grantedScopes =>
      List<String>.unmodifiable(_status.grantedScopes);

  set grantedScopes(List<String> value) {
    _status = _status.copyWith(
      grantedScopes: List<String>.from(value),
    );
    notifyListeners();
  }

  String? get errorMessage => _status.failure?.message;

  bool get canSend => _status.canSend;

  String get sendBlockedReason => _status.sendBlockedReason;

  ConnectionStatus get status => _status;

  Future<void> connectIfNeeded() async {
    if (_autoConnectSucceeded) {
      openClawLog(
        'ConnectionController',
        'connectIfNeeded skipped: already connected',
      );
      return;
    }
    if (_autoConnectInFlight) {
      openClawLog(
        'ConnectionController',
        'connectIfNeeded skipped: already in flight',
      );
      return;
    }

    if (_isStub) {
      openClawLog('ConnectionController', 'connectIfNeeded skipped: stub');
      return;
    }
    if (_status.isReady) {
      _autoConnectSucceeded = true;
      openClawLog('ConnectionController', 'connectIfNeeded skipped: already ready');
      return;
    }
    if (_isInProgressPhase(_status.phase)) {
      openClawLog(
        'ConnectionController',
        'connectIfNeeded skipped: connection in progress',
        fields: <String, Object?>{
          'phase': _status.phase.value,
        },
      );
      return;
    }

    _autoConnectInFlight = true;
    try {
      await testConnection();
      if (_status.isReady) {
        _autoConnectSucceeded = true;
      }
    } finally {
      _autoConnectInFlight = false;
    }
  }

  Future<void> testConnection() async {
    final useCase = _testConnectionUseCase;
    final configProvider = _configProvider;
    if (useCase == null || configProvider == null) {
      openClawLog('ConnectionController', 'testConnection skipped: not configured');
      markFailed('Gateway 未配置完成', code: 'NOT_CONFIGURED');
      return;
    }

    final config = configProvider();
    openClawLog(
      'ConnectionController',
      'testConnection begin',
      fields: <String, Object?>{
        'gatewayUrl': config.gatewayUrl,
        'sessionId': config.sessionId,
      },
    );
    markConnecting();
    try {
      final status = await useCase.call(config: config);
      _status = status;
      errorNotice = null;
      openClawLog(
        'ConnectionController',
        'testConnection success',
        fields: <String, Object?>{
          'phase': status.phase.value,
          'deviceId': status.deviceId,
          'scopes': status.grantedScopes.join(','),
        },
      );
      notifyListeners();
    } catch (error, stackTrace) {
      openClawLog(
        'ConnectionController',
        'testConnection failed',
        fields: <String, Object?>{
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      markFailed(error.toString(), code: 'CONNECT_FAILED');
    }
  }

  void markConnecting() {
    _status = _status.copyWith(
      phase: ConnectionPhase.connecting,
      clearFailure: true,
    );
    errorNotice = null;
    notifyListeners();
  }

  void markReady({
    required List<String> grantedScopes,
    String? deviceId,
    CanvasCapabilitySnapshot? canvasCapability,
  }) {
    _status = ConnectionStatus(
      phase: ConnectionPhase.ready,
      grantedScopes: List<String>.from(grantedScopes),
      deviceId: deviceId ?? _status.deviceId,
      canvasCapability: canvasCapability ?? _status.canvasCapability,
    );
    errorNotice = null;
    notifyListeners();
  }

  void markFailed(String message, {String code = 'UNKNOWN'}) {
    final mappedMessage = mapGatewayFailure(code: code, reason: message);
    errorNotice = AppErrorNotice.fromRaw(
      id: _nextErrorId(),
      scope: AppErrorScope.connection,
      presentation: AppErrorPresentation.inline,
      rawMessage: message,
      code: code,
    );
    _status = _status.copyWith(
      phase: ConnectionPhase.failed,
      failure: GatewayFailure.fromCode(
        code: code,
        reason: message,
        message: mappedMessage,
      ),
    );
    if (errorNotice!.kind == AppErrorKind.unexpected) {
      _appErrorController?.publish(
        errorNotice!.copyWith(
          presentation: AppErrorPresentation.global,
        ),
      );
    }
    notifyListeners();
  }

  void reset({
    String? deviceId,
  }) {
    _status = ConnectionStatus(
      phase: ConnectionPhase.idle,
      grantedScopes: const <String>[],
      deviceId: deviceId,
    );
    errorNotice = null;
    notifyListeners();
  }

  String _nextErrorId() {
    return _appErrorController?.nextId() ??
        'connection-error-${DateTime.now().microsecondsSinceEpoch}';
  }

  static bool _isInProgressPhase(ConnectionPhase phase) {
    switch (phase) {
      case ConnectionPhase.connecting:
      case ConnectionPhase.waitingChallenge:
      case ConnectionPhase.authenticating:
      case ConnectionPhase.reconnecting:
        return true;
      case ConnectionPhase.idle:
      case ConnectionPhase.ready:
      case ConnectionPhase.failed:
        return false;
    }
  }
}

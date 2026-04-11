import 'package:flutter/foundation.dart';

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
    bool isStub = false,
  })  : _status =
            initialStatus ?? const ConnectionStatus(phase: ConnectionPhase.idle),
        _testConnectionUseCase = testConnectionUseCase,
        _configProvider = configProvider,
        _isStub = isStub;

  factory ConnectionController.fake() => ConnectionController(isStub: true);

  ConnectionStatus _status;
  final TestConnectionUseCase? _testConnectionUseCase;
  final GatewayConfig Function()? _configProvider;
  final bool _isStub;

  bool get isStub => _isStub;

  String get phase => _status.phase.value;

  set phase(String value) {
    _status = _status.copyWith(
      phase: ConnectionPhase.fromValue(value),
    );
    notifyListeners();
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
    } catch (error) {
      openClawLog(
        'ConnectionController',
        'testConnection failed',
        fields: <String, Object?>{
          'error': error.toString(),
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
    notifyListeners();
  }

  void markReady({
    required List<String> grantedScopes,
    String? deviceId,
  }) {
    _status = ConnectionStatus(
      phase: ConnectionPhase.ready,
      grantedScopes: List<String>.from(grantedScopes),
      deviceId: deviceId ?? _status.deviceId,
    );
    notifyListeners();
  }

  void markFailed(String message, {String code = 'UNKNOWN'}) {
    final mappedMessage = mapGatewayFailure(code: code, reason: message);
    _status = _status.copyWith(
      phase: ConnectionPhase.failed,
      failure: GatewayFailure.fromCode(
        code: code,
        reason: message,
        message: mappedMessage,
      ),
    );
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
    notifyListeners();
  }
}

enum AppErrorScope {
  chat,
  connection,
  settings,
  system,
  unknown,
}

enum AppErrorPresentation {
  inline,
  global,
}

enum AppErrorKind {
  pairingRequired,
  missingWriteScope,
  timeout,
  disconnect,
  authFailed,
  pickerUnavailable,
  pickerChannel,
  pickerGeneric,
  emptyResponse,
  chatSendFailed,
  aiGenerationFailed,
  gatewayNotConfigured,
  unexpected,
}

class AppErrorNotice {
  AppErrorNotice({
    required this.id,
    required this.kind,
    required this.scope,
    required this.presentation,
    required this.technicalDetails,
    this.code,
  });

  final String id;
  final AppErrorKind kind;
  final AppErrorScope scope;
  final AppErrorPresentation presentation;
  final String technicalDetails;
  final String? code;

  bool get hasTechnicalDetails => technicalDetails.trim().isNotEmpty;

  AppErrorNotice copyWith({
    String? id,
    AppErrorKind? kind,
    AppErrorScope? scope,
    AppErrorPresentation? presentation,
    String? technicalDetails,
    String? code,
  }) {
    return AppErrorNotice(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      scope: scope ?? this.scope,
      presentation: presentation ?? this.presentation,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      code: code ?? this.code,
    );
  }

  factory AppErrorNotice.fromRaw({
    required String id,
    required AppErrorScope scope,
    required AppErrorPresentation presentation,
    required String rawMessage,
    String? code,
    AppErrorKind? kind,
  }) {
    return AppErrorNotice(
      id: id,
      kind: kind ?? inferAppErrorKind(rawMessage: rawMessage, code: code),
      scope: scope,
      presentation: presentation,
      technicalDetails: rawMessage.trim(),
      code: code,
    );
  }

  static AppErrorKind inferAppErrorKind({
    required String rawMessage,
    String? code,
  }) {
    final normalizedMessage = rawMessage.toLowerCase();
    final normalizedCode = (code ?? '').toLowerCase();

    if (normalizedCode == 'not_configured') {
      return AppErrorKind.gatewayNotConfigured;
    }
    if (normalizedMessage.contains('operator.write')) {
      return AppErrorKind.missingWriteScope;
    }
    if (normalizedMessage.contains('pairing') ||
        normalizedMessage.contains('no pair') ||
        normalizedMessage.contains('not-paired') ||
        normalizedMessage.contains('not paired')) {
      return AppErrorKind.pairingRequired;
    }
    if (normalizedMessage.contains('timeout') ||
        normalizedMessage.contains('timed out')) {
      return AppErrorKind.timeout;
    }
    if (normalizedMessage.contains('disconnect') ||
        normalizedMessage.contains('socketexception') ||
        normalizedMessage.contains('connection reset')) {
      return AppErrorKind.disconnect;
    }
    if (normalizedMessage.contains('authentication') ||
        normalizedMessage.contains('auth failed') ||
        normalizedMessage.contains('device token')) {
      return AppErrorKind.authFailed;
    }
    if (normalizedMessage.contains('missingpluginexception') ||
        normalizedMessage.contains('plugin is unavailable') ||
        normalizedMessage.contains('插件不可用')) {
      return AppErrorKind.pickerUnavailable;
    }
    if (normalizedMessage.contains('channel-error')) {
      return AppErrorKind.pickerChannel;
    }
    if (normalizedMessage.contains('picking images failed') ||
        normalizedMessage.contains('选择图片失败')) {
      return AppErrorKind.pickerGeneric;
    }
    if (normalizedMessage.contains('收到空响应') ||
        normalizedMessage.contains('empty response')) {
      return AppErrorKind.emptyResponse;
    }
    if (normalizedMessage.contains('chat.send 启动失败') ||
        normalizedMessage.contains('message send failed')) {
      return AppErrorKind.chatSendFailed;
    }
    if (normalizedMessage.contains('ai 生成失败') ||
        normalizedMessage.contains('assistant reply failed')) {
      return AppErrorKind.aiGenerationFailed;
    }

    return AppErrorKind.unexpected;
  }
}

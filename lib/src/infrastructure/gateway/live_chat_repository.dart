import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/models/chat_draft.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_request_state.dart';
import '../../domain/repositories/chat_repository.dart';
import '../config/dev_defaults.dart';
import '../util/openclaw_logger.dart';
import 'gateway_client.dart';
import 'gateway_frame.dart';
import 'gateway_protocol_parser.dart';
import 'request_tracker.dart';

class LiveChatRepository implements ChatRepository {
  LiveChatRepository(
    this._client,
    this._tracker, {
    GatewayProtocolParser? parser,
    Uuid? uuid,
    Duration? timeout,
  })  : _parser = parser ?? const GatewayProtocolParser(),
        _uuid = uuid ?? const Uuid(),
        _timeout =
            timeout ?? Duration(milliseconds: defaultGatewayConfig.timeoutMs);

  final GatewayClient _client;
  final RequestTracker _tracker;
  final GatewayProtocolParser _parser;
  final Uuid _uuid;
  final Duration _timeout;

  @override
  Stream<ChatMessage> sendMessage(
    ChatDraft draft, {
    required String sessionId,
  }) {
    _client.start();

    final controller = StreamController<ChatMessage>();
    final requestId = 'req-${_uuid.v4()}';
    final assistantMessageId = 'assistant-$requestId';
    final request = _tracker.create(requestId: requestId);
    final normalizedText = draft.normalizedText;
    final gatewayMessage = draft.toGatewayMessage();
    final gatewayAttachments = draft.toGatewayAttachments();
    openClawLog(
      'ChatRepository',
      'create chat request',
      fields: <String, Object?>{
        'requestId': requestId,
        'sessionId': sessionId,
        'textLength': normalizedText.length,
        'attachmentCount': draft.attachments.length,
        'messageLength': gatewayMessage.length,
        'textPreview': truncateForLog(normalizedText, maxLength: 80),
        'timeoutMs': _timeout.inMilliseconds,
      },
    );

    Timer? timeoutTimer;
    StreamSubscription<GatewayFrame>? subscription;

    void disposeRequest() {
      timeoutTimer?.cancel();
      _tracker.remove(request);
      openClawLog(
        'ChatRepository',
        'dispose chat request',
        fields: <String, Object?>{
          'requestId': request.requestId,
          'runId': request.runId,
          'finished': request.finished,
        },
      );
    }

    void finishWithError(Object error, [StackTrace? stackTrace]) {
      if (controller.isClosed || request.finished) {
        return;
      }
      openClawLog(
        'ChatRepository',
        'request failed',
        fields: <String, Object?>{
          'requestId': request.requestId,
          'runId': request.runId,
          'error': error.toString(),
        },
      );
      request.finished = true;
      if (request.streamedText.isNotEmpty) {
        controller.add(
          ChatMessage(
            id: assistantMessageId,
            role: MessageRole.assistant,
            text: request.streamedText,
            isStreaming: false,
          ),
        );
      }
      disposeRequest();
      controller.addError(error, stackTrace);
      unawaited(controller.close());
      unawaited(subscription?.cancel());
    }

    void finishWithText(String text, {required bool isStreaming}) {
      if (controller.isClosed || request.finished) {
        return;
      }
      final messageText = isStreaming ? text : text.trim();
      if (!isStreaming && messageText.isEmpty) {
        finishWithError(StateError('收到空响应'));
        return;
      }

      openClawLog(
        'ChatRepository',
        isStreaming ? 'stream update' : 'request completed',
        fields: <String, Object?>{
          'requestId': request.requestId,
          'runId': request.runId,
          'textLength': messageText.length,
          'preview': truncateForLog(messageText, maxLength: 120),
        },
      );
      if (!isStreaming &&
          _parser.looksLikePseudoCanvasDirective(messageText)) {
        openClawLog(
          'ChatRepository',
          'ignored pseudo canvas directive from assistant text',
          fields: <String, Object?>{
            'requestId': request.requestId,
            'runId': request.runId,
            'preview': truncateForLog(messageText, maxLength: 160),
          },
        );
      }
      request.finished = !isStreaming;
      controller.add(
        ChatMessage(
          id: assistantMessageId,
          role: MessageRole.assistant,
          text: messageText,
          isStreaming: isStreaming,
        ),
      );

      if (!isStreaming) {
        disposeRequest();
        unawaited(controller.close());
        unawaited(subscription?.cancel());
      }
    }

    subscription = _client.frames.listen(
      (frame) {
        if (_handleChatSendResponse(frame, request, onError: finishWithError)) {
          return;
        }
        _handleStreamEvent(
          frame,
          request,
          onStreaming: (message) => finishWithText(message, isStreaming: true),
          onFinished: (message) => finishWithText(message, isStreaming: false),
          onError: finishWithError,
        );
      },
      onError: finishWithError,
    );

    timeoutTimer = Timer(_timeout, () {
      openClawLog(
        'ChatRepository',
        'request timeout',
        fields: <String, Object?>{
          'requestId': request.requestId,
          'runId': request.runId,
        },
      );
      finishWithError(TimeoutException('请求超时', _timeout));
    });

    controller.onCancel = () async {
      disposeRequest();
      await subscription?.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
    };

    controller.add(
      ChatMessage(
        id: assistantMessageId,
        role: MessageRole.assistant,
        text: '',
        isStreaming: true,
      ),
    );

    _client.send(
      <String, Object?>{
        'type': 'req',
        'id': requestId,
        'method': 'chat.send',
        'params': <String, Object?>{
          'sessionKey': sessionId,
          'message': gatewayMessage,
          'deliver': false,
          'idempotencyKey': _uuid.v4(),
          if (gatewayAttachments.isNotEmpty)
            'attachments': gatewayAttachments
                .map((attachment) => attachment.toJson())
                .toList(growable: false),
        },
      },
    );

    return controller.stream;
  }

  bool _handleChatSendResponse(
    GatewayFrame frame,
    ChatRequestState request, {
    required void Function(Object error, [StackTrace? stackTrace]) onError,
  }) {
    if (frame.type != 'res' || frame.id != request.requestId) {
      return false;
    }

    final failure = _parser.extractFailure(frame);
    if (failure != null) {
      openClawLog(
        'ChatRepository',
        'chat.send response failure',
        fields: <String, Object?>{
          'requestId': request.requestId,
          'code': failure.code,
          'reason': failure.reason,
        },
      );
      onError(StateError(failure.message));
      return true;
    }

    final payload = frame.payload;
    final rawRunId = payload['runId'];
    if (rawRunId is String && rawRunId.isNotEmpty) {
      _tracker.attachRunId(requestId: request.requestId, runId: rawRunId);
      openClawLog(
        'ChatRepository',
        'attached runId',
        fields: <String, Object?>{
          'requestId': request.requestId,
          'runId': rawRunId,
        },
      );
    }

    final status = payload['status'];
    if (status is String && status == 'error') {
      final message = payload['message'];
      onError(StateError(message is String ? message : 'chat.send 启动失败'));
      return true;
    }

    return true;
  }

  void _handleStreamEvent(
    GatewayFrame frame,
    ChatRequestState request, {
    required void Function(String message) onStreaming,
    required void Function(String message) onFinished,
    required void Function(Object error, [StackTrace? stackTrace]) onError,
  }) {
    if (frame.type != 'event') {
      return;
    }

    final payload = frame.payload;
    final runId = payload['runId'];
    if (runId is! String || runId.isEmpty || runId != request.runId) {
      return;
    }

    if (frame.event == 'chat') {
      final state = payload['state'];
      if (state is String && state == 'final') {
        final finalText = _buildReplyFromRequest(request, payload['message']);
        onFinished(finalText);
        return;
      }
    }

    final streamName = payload['stream'];
    if (streamName is String && streamName == 'assistant') {
      final delta = _parser.extractAssistantDelta(frame);
      if (delta.isNotEmpty) {
        request.appendChunk(delta);
        openClawLog(
          'ChatRepository',
          'assistant delta',
          fields: <String, Object?>{
            'requestId': request.requestId,
            'runId': request.runId,
            'deltaLength': delta.length,
            'deltaPreview': truncateForLog(delta, maxLength: 80),
          },
        );
        onStreaming(request.streamedText);
      }
      return;
    }

    if (streamName is String && streamName == 'lifecycle') {
      final data = payload['data'];
      if (data is! Map) {
        return;
      }

      final json = Map<String, dynamic>.from(data);
      final phase = json['phase'];
      if (phase is String && phase == 'error') {
        final nestedError = json['error'];
        if (nestedError is Map) {
          final errorMessage = nestedError['message'];
          onError(
            StateError(
              errorMessage is String ? errorMessage : 'AI 生成失败',
            ),
          );
          return;
        }
        if (nestedError is String) {
          onError(StateError(nestedError));
          return;
        }
        final message = json['message'];
        onError(
          StateError(message is String ? message : 'AI 生成失败'),
        );
        return;
      }

      if (phase is String && phase == 'end') {
        final finalText = _buildReplyFromRequest(request, payload['message']);
        onFinished(finalText);
      }
    }
  }

  String _buildReplyFromRequest(
    ChatRequestState request,
    Object? fallbackMessage,
  ) {
    if (request.streamedText.isNotEmpty) {
      return request.streamedText;
    }

    if (fallbackMessage is! Map) {
      return '';
    }

    final json = Map<String, dynamic>.from(fallbackMessage);
    return _parser.extractTextFromContent(json['content']);
  }
}

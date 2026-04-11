import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'gateway_frame.dart';
import 'gateway_protocol_parser.dart';
import '../util/openclaw_logger.dart';

class GatewayClient {
  GatewayClient({
    required WebSocketChannel channel,
    GatewayProtocolParser? parser,
  })  : _channel = channel,
        _parser = parser ?? const GatewayProtocolParser();

  final WebSocketChannel _channel;
  final GatewayProtocolParser _parser;
  final StreamController<GatewayFrame> _frames =
      StreamController<GatewayFrame>.broadcast();

  StreamSubscription<dynamic>? _subscription;

  Stream<GatewayFrame> get frames => _frames.stream;

  void start() {
    openClawLog('GatewayClient', 'start listening');
    _subscription ??= _channel.stream.listen(
      (event) {
        final raw = _normalizeIncoming(event);
        openClawLog(
          'GatewayClient',
          'incoming raw frame',
          fields: <String, Object?>{
            'length': raw.length,
            'preview': truncateForLog(raw, maxLength: 220),
          },
        );
        _frames.add(_parser.parse(raw));
      },
      onError: (Object error, StackTrace stackTrace) {
        openClawLog(
          'GatewayClient',
          'stream error',
          fields: <String, Object?>{
            'error': error.toString(),
          },
        );
        _frames.addError(error, stackTrace);
      },
      onDone: () {
        openClawLog('GatewayClient', 'stream done');
        if (!_frames.isClosed) {
          _frames.close();
        }
      },
    );
  }

  void send(Map<String, Object?> frame) {
    openClawLog(
      'GatewayClient',
      'send frame',
      fields: <String, Object?>{
        'type': frame['type'],
        'id': frame['id'],
        'method': frame['method'],
        'payload': truncateForLog(jsonEncode(frame), maxLength: 220),
      },
    );
    _channel.sink.add(jsonEncode(frame));
  }

  Future<void> dispose() async {
    openClawLog('GatewayClient', 'dispose');
    await _subscription?.cancel();
    await _channel.sink.close();
    if (!_frames.isClosed) {
      await _frames.close();
    }
  }

  String _normalizeIncoming(Object? event) {
    if (event is String) {
      return event;
    }
    if (event is List<int>) {
      return utf8.decode(event);
    }
    throw FormatException(
      'GatewayClient: incoming frame must be a String or byte list.',
    );
  }
}

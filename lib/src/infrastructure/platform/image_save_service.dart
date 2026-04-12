import 'dart:typed_data';

import 'package:flutter/services.dart';

class ImageSaveException implements Exception {
  const ImageSaveException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'ImageSaveException(code: $code, message: $message)';
}

class ImageSaveService {
  ImageSaveService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('openclaw/media');

  final MethodChannel _channel;

  Future<String?> saveImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final result = await _channel.invokeMethod<Object?>(
        'saveImage',
        <String, Object?>{
          'bytes': bytes,
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );
      if (result is String) {
        return result;
      }
      return null;
    } on PlatformException catch (error) {
      throw ImageSaveException(
        code: error.code,
        message: error.message ?? 'Saving image failed.',
      );
    }
  }
}

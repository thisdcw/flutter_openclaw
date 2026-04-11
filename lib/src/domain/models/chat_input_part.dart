import 'dart:convert';

import 'selected_image_attachment.dart';

sealed class ChatInputPart {
  const ChatInputPart();

  Map<String, dynamic> toJson();
}

class ChatInputTextPart extends ChatInputPart {
  const ChatInputTextPart(this.text);

  final String text;

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatInputTextPart && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'ChatInputTextPart(text: $text)';
}

class ChatInputImageSource {
  const ChatInputImageSource({
    required this.type,
    required this.mimeType,
    required this.data,
  });

  final String type;
  final String mimeType;
  final String data;

  Map<String, dynamic> toJson() => {
        'type': type,
        'mimeType': mimeType,
        'data': data,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatInputImageSource &&
        other.type == type &&
        other.mimeType == mimeType &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(type, mimeType, data);

  @override
  String toString() {
    return 'ChatInputImageSource(type: $type, mimeType: $mimeType, '
        'data: ${data.length})';
  }
}

class ChatInputImagePart extends ChatInputPart {
  const ChatInputImagePart({required this.source});

  final ChatInputImageSource source;

  factory ChatInputImagePart.fromAttachment(SelectedImageAttachment value) {
    return ChatInputImagePart(
      source: ChatInputImageSource(
        type: 'base64',
        mimeType: value.mimeType,
        data: base64.encode(value.bytes),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'image', 'source': source.toJson()};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatInputImagePart && other.source == source;
  }

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => 'ChatInputImagePart(source: $source)';
}

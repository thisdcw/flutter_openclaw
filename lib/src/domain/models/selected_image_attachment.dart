import 'package:collection/collection.dart';

class SelectedImageAttachment {
  SelectedImageAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required List<int> bytes,
  }) : bytes = List<int>.unmodifiable(bytes);

  final String id;
  final String fileName;
  final String mimeType;
  final List<int> bytes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedImageAttachment &&
        other.id == id &&
        other.fileName == fileName &&
        other.mimeType == mimeType &&
        _listEquality.equals(other.bytes, bytes);
  }

  @override
  int get hashCode => Object.hash(
        id,
        fileName,
        mimeType,
        _listEquality.hash(bytes),
      );

  @override
  String toString() {
    return 'SelectedImageAttachment(id: $id, fileName: $fileName, '
        'mimeType: $mimeType, bytes: ${bytes.length})';
  }
  static const ListEquality<int> _listEquality = ListEquality<int>();
}

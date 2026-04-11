class ChatRequestState {
  ChatRequestState({
    required this.requestId,
    this.runId,
    this.buffer = '',
    this.finished = false,
  });

  final String requestId;
  String? runId;
  String buffer;
  bool finished;

  void appendChunk(String value) {
    buffer += value;
  }

  String get streamedText => buffer.trim();

  @override
  String toString() {
    return 'ChatRequestState(requestId: $requestId, runId: $runId, buffer: '
        '$buffer, finished: $finished)';
  }
}

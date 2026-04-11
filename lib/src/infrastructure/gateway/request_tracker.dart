import '../../domain/models/chat_request_state.dart';

class RequestTracker {
  final Map<String, ChatRequestState> _byRequestId =
      <String, ChatRequestState>{};
  final Map<String, ChatRequestState> _byRunId = <String, ChatRequestState>{};

  ChatRequestState create({required String requestId}) {
    final state = ChatRequestState(requestId: requestId);
    _byRequestId[requestId] = state;
    return state;
  }

  void attachRunId({
    required String requestId,
    required String runId,
  }) {
    final request = _byRequestId[requestId];
    if (request == null || runId.trim().isEmpty) {
      return;
    }

    final previousRunId = request.runId;
    if (previousRunId != null && previousRunId.isNotEmpty) {
      _byRunId.remove(previousRunId);
    }

    request.runId = runId;
    _byRunId[runId] = request;
  }

  ChatRequestState? byRequestId(String requestId) => _byRequestId[requestId];

  ChatRequestState? byRunId(String runId) => _byRunId[runId];

  void remove(ChatRequestState request) {
    _byRequestId.remove(request.requestId);
    final runId = request.runId;
    if (runId != null && runId.isNotEmpty) {
      _byRunId.remove(runId);
    }
  }

  void clear() {
    _byRequestId.clear();
    _byRunId.clear();
  }

  List<ChatRequestState> get activeRequests =>
      List<ChatRequestState>.unmodifiable(_byRequestId.values);
}

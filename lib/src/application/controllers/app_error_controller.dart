import 'package:flutter/foundation.dart';

import '../../infrastructure/util/openclaw_logger.dart';
import '../models/app_error_notice.dart';

class AppErrorController extends ChangeNotifier {
  AppErrorNotice? _activeGlobalNotice;
  int _sequence = 0;

  AppErrorNotice? get activeGlobalNotice => _activeGlobalNotice;

  String nextId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _sequence += 1;
    return 'app-error-$timestamp-$_sequence';
  }

  void publish(AppErrorNotice notice) {
    _activeGlobalNotice = notice.presentation == AppErrorPresentation.global
        ? notice
        : notice.copyWith(presentation: AppErrorPresentation.global);
    notifyListeners();
  }

  void clear([String? id]) {
    if (_activeGlobalNotice == null) {
      return;
    }
    if (id != null && _activeGlobalNotice!.id != id) {
      return;
    }
    _activeGlobalNotice = null;
    notifyListeners();
  }

  void reportUnexpected(
    Object error,
    StackTrace stackTrace, {
    AppErrorScope scope = AppErrorScope.system,
    String? code,
  }) {
    openClawLog(
      'AppErrorController',
      'report unexpected error',
      fields: <String, Object?>{
        'scope': scope.name,
        'code': code,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      },
    );
    publish(
      AppErrorNotice.fromRaw(
        id: nextId(),
        scope: scope,
        presentation: AppErrorPresentation.global,
        rawMessage: '${error.toString().trim()}\n$stackTrace'.trim(),
        code: code,
      ),
    );
  }
}

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show NetworkImageLoadException;
import 'package:flutter_openclaw/src/application/controllers/app_error_controller.dart';
import 'package:flutter_openclaw/src/application/models/app_error_notice.dart';
import 'package:flutter_openclaw/src/infrastructure/util/openclaw_logger.dart';
import 'src/app/app_dependencies.dart';
import 'src/app/openclaw_app.dart';

Future<void> main() async {
  final appErrorController = AppErrorController();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        if (_shouldIgnoreFlutterError(details.exception)) {
          openClawLog(
            'main',
            'ignored expected flutter error',
            fields: <String, Object?>{
              'error': details.exception.toString(),
            },
          );
          return;
        }
        FlutterError.presentError(details);
        appErrorController.reportUnexpected(
          details.exception,
          details.stack ?? StackTrace.current,
          scope: AppErrorScope.system,
          code: 'FLUTTER_ERROR',
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        appErrorController.reportUnexpected(
          error,
          stackTrace,
          scope: AppErrorScope.system,
          code: 'PLATFORM_ERROR',
        );
        return true;
      };

      final dependencies = await AppDependencies.create(
        appErrorController: appErrorController,
      );
      runApp(OpenClawApp(dependencies: dependencies));
    },
    (error, stackTrace) {
      openClawLog(
        'main',
        'runZonedGuarded caught error',
        fields: <String, Object?>{
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      appErrorController.reportUnexpected(
        error,
        stackTrace,
        scope: AppErrorScope.system,
        code: 'ZONE_ERROR',
      );
    },
  );
}

bool _shouldIgnoreFlutterError(Object exception) {
  if (exception is NetworkImageLoadException) {
    return exception.statusCode == 429;
  }
  final text = exception.toString().toLowerCase();
  return text.contains('networkimageloadexception') &&
      text.contains('statuscode: 429');
}

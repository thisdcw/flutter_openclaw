import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
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

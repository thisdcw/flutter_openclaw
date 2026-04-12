import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../domain/models/gateway_failure.dart';

String localizedPhaseLabel(AppLocalizations l10n, String phase) {
  switch (phase) {
    case 'idle':
      return l10n.phaseIdle;
    case 'connecting':
      return l10n.phaseConnecting;
    case 'waitingChallenge':
      return l10n.phaseWaitingChallenge;
    case 'authenticating':
      return l10n.phaseAuthenticating;
    case 'ready':
      return l10n.phaseReady;
    case 'reconnecting':
      return l10n.phaseReconnecting;
    case 'failed':
      return l10n.phaseFailed;
    default:
      return phase;
  }
}

String localizedBlockedReason(AppLocalizations l10n, String rawReason) {
  if (rawReason.contains('operator.write')) {
    return l10n.blockedReasonMissingWriteScope;
  }
  if (rawReason.contains('connection not ready')) {
    return l10n.blockedReasonNotReady;
  }
  return rawReason;
}

String localizedGatewayFailure(
  AppLocalizations l10n, {
  GatewayFailure? failure,
  String? rawReason,
}) {
  final resolvedFailure = failure ??
      GatewayFailure.fromCode(
        code: 'UNKNOWN',
        reason: rawReason ?? 'unknown',
      );

  if (resolvedFailure.code == 'NOT_CONFIGURED') {
    return l10n.gatewayFailureNotConfigured;
  }

  switch (resolvedFailure.type) {
    case GatewayFailureType.pairingRequired:
      return l10n.gatewayFailurePairingRequired;
    case GatewayFailureType.missingWriteScope:
      return l10n.gatewayFailureMissingWriteScope;
    case GatewayFailureType.timeout:
      return l10n.gatewayFailureTimeout;
    case GatewayFailureType.disconnect:
      return l10n.gatewayFailureDisconnect;
    case GatewayFailureType.authFailed:
      return l10n.gatewayFailureAuthFailed;
    case GatewayFailureType.protocolError:
      return l10n.gatewayFailureProtocolError;
    case GatewayFailureType.unknown:
      if (resolvedFailure.reason.trim().isNotEmpty) {
        return resolvedFailure.reason;
      }
      return l10n.gatewayFailureUnknown(
        resolvedFailure.code,
        resolvedFailure.reason,
      );
  }
}

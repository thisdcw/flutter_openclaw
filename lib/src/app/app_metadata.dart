const String appCopyrightOwner = 'thisdcw';

const String _fallbackBuildName = '1.0.0';
const String _fallbackBuildNumber = '1';

String get appCopyrightText => '© $appCopyrightOwner';

String get appVersionText {
  const buildName = String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: _fallbackBuildName,
  );
  const buildNumber = String.fromEnvironment(
    'FLUTTER_BUILD_NUMBER',
    defaultValue: _fallbackBuildNumber,
  );

  if (buildNumber.isEmpty) {
    return 'v$buildName';
  }

  return 'v$buildName+$buildNumber';
}

# Flutter OpenClaw App Icon Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the default Flutter launcher icon set with the approved OpenClaw `O/C + claw` brand icon across Android, iOS, macOS, and web.

**Architecture:** Keep the icon source of truth in repo-owned branding assets, use a checked-in `flutter_launcher_icons` configuration to fan out the exports, and verify the rollout with narrow file-based tests before running full Flutter verification. The implementation stays asset-focused and does not touch app behavior, controllers, or UI logic.

**Tech Stack:** Flutter, Dart, `flutter_launcher_icons`, platform icon asset catalogs, PNG source assets, existing Flutter test tooling

---

## File Structure

- Create: `flutter_openclaw/assets/branding/README.md`
- Create: `flutter_openclaw/assets/branding/app_icon_master.png`
- Create: `flutter_openclaw/assets/branding/app_icon_android_foreground.png`
- Modify: `flutter_openclaw/pubspec.yaml`
- Modify: `flutter_openclaw/web/manifest.json`
- Modify: `flutter_openclaw/web/favicon.png`
- Modify: `flutter_openclaw/web/icons/Icon-192.png`
- Modify: `flutter_openclaw/web/icons/Icon-512.png`
- Modify: `flutter_openclaw/web/icons/Icon-maskable-192.png`
- Modify: `flutter_openclaw/web/icons/Icon-maskable-512.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png`
- Create: `flutter_openclaw/test/tool/app_icon_source_assets_test.dart`
- Create: `flutter_openclaw/test/tool/app_icon_generation_config_test.dart`
- Create: `flutter_openclaw/test/tool/generated_app_icon_assets_test.dart`

## Task 1: Add Checked-In Source Icon Assets

**Files:**
- Create: `flutter_openclaw/assets/branding/README.md`
- Create: `flutter_openclaw/assets/branding/app_icon_master.png`
- Create: `flutter_openclaw/assets/branding/app_icon_android_foreground.png`
- Create: `flutter_openclaw/test/tool/app_icon_source_assets_test.dart`

- [ ] **Step 1: Write the failing source-asset test**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('branding source icons exist at 1024 square', () {
    expect(_readPngSize('assets/branding/app_icon_master.png'), [1024, 1024]);
    expect(
      _readPngSize('assets/branding/app_icon_android_foreground.png'),
      [1024, 1024],
    );
  });
}

List<int> _readPngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.take(8).toList(), <int>[137, 80, 78, 71, 13, 10, 26, 10]);

  final header = ByteData.sublistView(
    Uint8List.fromList(bytes.sublist(16, 24)),
  );
  return [header.getUint32(0), header.getUint32(4)];
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/tool/app_icon_source_assets_test.dart`
Expected: FAIL with `PathNotFoundException` for `assets/branding/app_icon_master.png`.

- [ ] **Step 3: Create the source artwork files**

Create `assets/branding/README.md`:

```md
# App Icon Source Assets

This folder is the source of truth for generated launcher icons.

- `app_icon_master.png`: 1024 x 1024 full-tile icon for iOS, macOS, and web.
- `app_icon_android_foreground.png`: 1024 x 1024 transparent foreground symbol for Android adaptive export.

Approved visual rules:

- Outer shape: rounded square tile
- Symbol: fused `O/C` monogram with a single claw-like opening
- Background: deep ocean blue / blue-cyan gradient family
- Highlights: cyan with a restrained aqua-green edge
- Tone: professional product icon with subtle claw character
```

Create the two PNG files with these exact constraints:

- `assets/branding/app_icon_master.png`
  - size: `1024 x 1024`
  - includes the full dark rounded-square tile
  - uses the approved `O/C + claw` symbol centered with comfortable margin
  - avoids text, mascots, mirrored pincers, and white background tiles
- `assets/branding/app_icon_android_foreground.png`
  - size: `1024 x 1024`
  - transparent background
  - contains only the fused `O/C + claw` symbol
  - keeps the symbol comfortably inside the adaptive safe area so no edge gets clipped

Recommended production values while drawing the final asset:

- tile base: `#0E1B2D` to `#123A57`
- symbol body: `#61D5FF`
- highlight edge: `#71F0D5`
- shadow/depth accent: `#184C84`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/tool/app_icon_source_assets_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add assets/branding/README.md assets/branding/app_icon_master.png assets/branding/app_icon_android_foreground.png test/tool/app_icon_source_assets_test.dart
git commit -m "feat: add openclaw app icon source assets"
```

## Task 2: Add Repeatable Launcher Icon Generation Config

**Files:**
- Modify: `flutter_openclaw/pubspec.yaml`
- Create: `flutter_openclaw/test/tool/app_icon_generation_config_test.dart`

- [ ] **Step 1: Write the failing configuration test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec declares launcher icon generation config', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('flutter_launcher_icons: ^0.14.4'));
    expect(pubspec, contains('image_path: "assets/branding/app_icon_master.png"'));
    expect(
      pubspec,
      contains(
        'adaptive_icon_foreground: "assets/branding/app_icon_android_foreground.png"',
      ),
    );
    expect(pubspec, contains('adaptive_icon_background: "#0E1B2D"'));
    expect(pubspec, contains('remove_alpha_ios: true'));
    expect(pubspec, contains('web:'));
    expect(pubspec, contains('macos:'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/tool/app_icon_generation_config_test.dart`
Expected: FAIL because `pubspec.yaml` does not yet contain launcher icon config.

- [ ] **Step 3: Add the package and checked-in config**

Update `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: true
  ios: true
  remove_alpha_ios: true
  image_path: "assets/branding/app_icon_master.png"
  adaptive_icon_background: "#0E1B2D"
  adaptive_icon_foreground: "assets/branding/app_icon_android_foreground.png"
  web:
    generate: true
    image_path: "assets/branding/app_icon_master.png"
    background_color: "#0E1B2D"
    theme_color: "#0E1B2D"
  macos:
    generate: true
    image_path: "assets/branding/app_icon_master.png"
  windows:
    generate: false
```

- [ ] **Step 4: Install dependencies**

Run: `flutter pub get`
Expected: PASS with `flutter_launcher_icons` added to the lockfile.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/tool/app_icon_generation_config_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock test/tool/app_icon_generation_config_test.dart
git commit -m "build: add repeatable app icon generation config"
```

## Task 3: Generate Platform Icon Assets And Brand The Web Manifest

**Files:**
- Modify: `flutter_openclaw/web/manifest.json`
- Modify: `flutter_openclaw/web/favicon.png`
- Modify: `flutter_openclaw/web/icons/Icon-192.png`
- Modify: `flutter_openclaw/web/icons/Icon-512.png`
- Modify: `flutter_openclaw/web/icons/Icon-maskable-192.png`
- Modify: `flutter_openclaw/web/icons/Icon-maskable-512.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- Modify: `flutter_openclaw/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- Modify: `flutter_openclaw/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png`
- Modify: `flutter_openclaw/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png`
- Create: `flutter_openclaw/test/tool/generated_app_icon_assets_test.dart`

- [ ] **Step 1: Write the failing generated-assets test**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated launcher icon files exist with expected sizes', () {
    expect(_readPngSize('android/app/src/main/res/mipmap-mdpi/ic_launcher.png'), [48, 48]);
    expect(_readPngSize('android/app/src/main/res/mipmap-hdpi/ic_launcher.png'), [72, 72]);
    expect(_readPngSize('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'), [96, 96]);
    expect(_readPngSize('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'), [144, 144]);
    expect(_readPngSize('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'), [192, 192]);

    expect(
      _readPngSize(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      ),
      [1024, 1024],
    );
    expect(
      _readPngSize(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png',
      ),
      [1024, 1024],
    );

    expect(_readPngSize('web/favicon.png'), [32, 32]);
    expect(_readPngSize('web/icons/Icon-192.png'), [192, 192]);
    expect(_readPngSize('web/icons/Icon-512.png'), [512, 512]);
    expect(_readPngSize('web/icons/Icon-maskable-192.png'), [192, 192]);
    expect(_readPngSize('web/icons/Icon-maskable-512.png'), [512, 512]);

    final manifest = File('web/manifest.json').readAsStringSync();
    expect(manifest, contains('"background_color": "#0E1B2D"'));
    expect(manifest, contains('"theme_color": "#0E1B2D"'));
  });
}

List<int> _readPngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.take(8).toList(), <int>[137, 80, 78, 71, 13, 10, 26, 10]);

  final header = ByteData.sublistView(
    Uint8List.fromList(bytes.sublist(16, 24)),
  );
  return [header.getUint32(0), header.getUint32(4)];
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/tool/generated_app_icon_assets_test.dart`
Expected: FAIL because the current platform assets are still the default Flutter icon set and `web/manifest.json` still uses `#0175C2`.

- [ ] **Step 3: Generate icons and update the branded web manifest**

Run: `dart run flutter_launcher_icons`
Expected: PASS with launcher assets regenerated for Android, iOS, macOS, and web.

Update `web/manifest.json`:

```json
{
  "name": "flutter_openclaw",
  "short_name": "flutter_openclaw",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0E1B2D",
  "theme_color": "#0E1B2D",
  "description": "A new Flutter project.",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

- [ ] **Step 4: Run targeted verification**

Run: `flutter test test/tool/generated_app_icon_assets_test.dart`
Expected: PASS

Manual review checklist:

- Open `assets/branding/app_icon_master.png`, `web/icons/Icon-192.png`, and `web/favicon.png`
- Confirm the `O/C` structure is still readable at full, launcher, and favicon sizes
- Confirm the claw opening still reads as a deliberate notch rather than an accidental gap
- Confirm the icon remains clear on both a white background and a near-black background

Run: `flutter analyze`
Expected: PASS

Run: `flutter test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock web/manifest.json web/favicon.png web/icons/Icon-192.png web/icons/Icon-512.png web/icons/Icon-maskable-192.png web/icons/Icon-maskable-512.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png test/tool/generated_app_icon_assets_test.dart
git commit -m "feat: roll out branded app icon assets"
```
